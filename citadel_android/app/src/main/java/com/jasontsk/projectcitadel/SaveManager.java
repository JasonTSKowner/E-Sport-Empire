package com.jasontsk.projectcitadel;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.AtomicFile;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Versioned, transactional local persistence. The legacy preferences are never deleted. */
public final class SaveManager {
    public static final int SAVE_VERSION = 2;
    public static final String FILE_NAME = "crownforge-v2.json";
    public static final String BACKUP_NAME = "crownforge-v2.backup.json";
    private static final int MAX_BYTES = 2 * 1024 * 1024;
    private final Context context;
    private final AtomicFile primary;
    private final AtomicFile backup;
    private byte[] lastGood;
    private boolean newerSave;
    public String message = "";

    public SaveManager(Context context) {
        this.context = context.getApplicationContext();
        primary = new AtomicFile(new File(context.getFilesDir(), FILE_NAME));
        backup = new AtomicFile(new File(context.getFilesDir(), BACKUP_NAME));
    }

    public synchronized GameState load(long now) {
        message = "";
        newerSave = false;
        boolean damaged = primary.getBaseFile().exists();
        try {
            byte[] bytes = read(primary);
            GameState state = decode(bytes, now);
            lastGood = bytes;
            return state;
        } catch (FutureVersionException future) {
            newerSave = true;
            message = "This village was saved by a newer Crownforge version. Your save is protected.";
            return GameState.fresh(now);
        } catch (Exception ignored) { /* Recover below without erasing the original. */ }
        try {
            byte[] bytes = read(backup);
            GameState state = decode(bytes, now);
            lastGood = bytes;
            message = "Your village was recovered from its local backup.";
            return state;
        } catch (FutureVersionException future) {
            newerSave = true;
            message = "Your newer Crownforge backup is protected from changes.";
            return GameState.fresh(now);
        } catch (Exception ignored) { }
        preserveUnreadable(primary);
        preserveUnreadable(backup);
        SharedPreferences old = context.getSharedPreferences("citadel_v01", Context.MODE_PRIVATE);
        if (!old.getAll().isEmpty()) {
            GameState state = migrate(old.getAll(), now);
            message = "Your Project Citadel village has been restored in Crownforge.";
            save(state);
            return state;
        }
        if (damaged) message = "The local save could not be read. A new village is ready.";
        return GameState.fresh(now);
    }

    public synchronized boolean save(GameState state) {
        if (newerSave) return false;
        try {
            byte[] data = encode(state).toString().getBytes(StandardCharsets.UTF_8);
            // Keep the previous known-good snapshot, including when recovering a damaged primary.
            write(backup, lastGood == null ? data : lastGood);
            write(primary, data);
            lastGood = data;
            return true;
        } catch (Exception exception) {
            message = "Village could not be saved. Check available device storage.";
            return false;
        }
    }

    private JSONObject encode(GameState state) throws Exception {
        JSONObject root = new JSONObject();
        root.put("saveVersion", SAVE_VERSION);
        root.put("game", "Crownforge");
        root.put("version", "0.2");
        root.put("playerLevel", state.playerLevel);
        root.put("xp", state.xp);
        root.put("gold", finite(state.gold, 0));
        root.put("elixir", finite(state.elixir, 0));
        root.put("lastProductionAt", state.lastProductionAt);
        root.put("townHallLevel", state.townHallLevel());
        JSONObject settings = new JSONObject();
        settings.put("masterVolume", volume(state.masterVolume, 0.8f));
        settings.put("musicVolume", volume(state.musicVolume, 0.35f));
        settings.put("sfxVolume", volume(state.sfxVolume, 0.8f));
        settings.put("muted", state.muted);
        root.put("settings", settings);
        JSONArray list = new JSONArray();
        for (BuildingInstance building : state.buildings) {
            JSONObject row = new JSONObject();
            row.put("id", building.id);
            row.put("type", building.type);
            row.put("level", building.level);
            row.put("x", building.x);
            row.put("y", building.y);
            row.put("targetLevel", building.targetLevel);
            row.put("startedAt", building.startedAt);
            row.put("finishAt", building.finishAt);
            list.put(row);
        }
        root.put("buildings", list);
        // This metadata is useful to future migrations. Buildings remain its source of truth.
        ResourceManager resources = new ResourceManager(state);
        BuilderManager builders = new BuilderManager(state);
        root.put("goldCapacity", resources.goldCapacity());
        root.put("elixirCapacity", resources.elixirCapacity());
        JSONObject builderData = new JSONObject();
        builderData.put("total", builders.total());
        builderData.put("busy", builders.busy());
        root.put("builders", builderData);
        JSONArray unlocks = new JSONArray();
        for (BuildingDefinition definition : BuildingDefinition.all()) {
            if (definition.limit(state.townHallLevel()) > 0) unlocks.put(definition.type);
        }
        root.put("unlocks", unlocks);
        return root;
    }

    private GameState decode(byte[] data, long now) throws Exception {
        JSONObject root = new JSONObject(new String(data, StandardCharsets.UTF_8));
        int version = root.optInt("saveVersion", SAVE_VERSION);
        if (version > SAVE_VERSION) throw new FutureVersionException();
        JSONArray rows = root.optJSONArray("buildings");
        if (rows == null || rows.length() == 0) throw new IllegalArgumentException("Missing village");
        GameState state = GameState.fresh(now);
        state.buildings.clear();
        state.gold = finite(root.optDouble("gold", 1200), 1200);
        state.elixir = finite(root.optDouble("elixir", 600), 600);
        state.playerLevel = bounded(root.optInt("playerLevel", 1), 1, 100000);
        state.xp = bounded(root.optInt("xp", 0), 0, 100000000);
        state.lastProductionAt = timestamp(root.optLong("lastProductionAt", now), now);
        JSONObject settings = root.optJSONObject("settings");
        if (settings != null) {
            state.masterVolume = volume(settings.optDouble("masterVolume", state.masterVolume), state.masterVolume);
            state.musicVolume = volume(settings.optDouble("musicVolume", state.musicVolume), state.musicVolume);
            state.sfxVolume = volume(settings.optDouble("sfxVolume", state.sfxVolume), state.sfxVolume);
            state.muted = settings.optBoolean("muted", false);
        }
        List<BuildingInstance> parsed = new ArrayList<>();
        Set<String> ids = new HashSet<>();
        for (int i = 0; i < Math.min(rows.length(), 1296); i++) {
            try {
                JSONObject row = rows.getJSONObject(i);
                String type = row.optString("type", "");
                if (!knownType(type)) continue;
                BuildingInstance building = new BuildingInstance(type, row.optInt("level", 1), row.optInt("x", -1), row.optInt("y", -1));
                String id = row.optString("id", "");
                if (!id.isEmpty() && id.length() < 120 && !ids.contains(id)) building.id = id;
                ids.add(building.id);
                building.targetLevel = row.optInt("targetLevel", row.optInt("target", 0));
                building.finishAt = Math.max(0, row.optLong("finishAt", 0));
                building.startedAt = Math.max(0, row.optLong("startedAt", 0));
                sanitizeTimer(building, now);
                parsed.add(building);
            } catch (Exception ignored) { /* One broken row must not destroy the whole village. */ }
        }
        if (parsed.isEmpty()) throw new IllegalArgumentException("No recoverable buildings");
        placeRecovered(state, parsed);
        new ResourceManager(state).clamp();
        normalizeXp(state);
        state.revision++;
        return state;
    }

    private GameState migrate(Map<String, ?> legacy, long now) {
        GameState state = GameState.fresh(now);
        state.gold = number(legacy.get("gold"), 1200);
        state.elixir = number(legacy.get("elixir"), 600);
        state.playerLevel = bounded((int) number(legacy.get("playerLevel"), 1), 1, 100000);
        state.xp = bounded((int) number(legacy.get("xp"), 0), 0, 100000000);
        state.lastProductionAt = now; // V0.1 never persisted a production timestamp.
        List<BuildingInstance> parsed = new ArrayList<>();
        Object raw = legacy.get("buildings");
        if (raw instanceof String) {
            for (String text : ((String) raw).split(";")) {
                String[] cells = text.split(",");
                if (cells.length < 2 || !knownType(cells[0])) continue;
                try {
                    BuildingInstance building = new BuildingInstance(cells[0], Integer.parseInt(cells[1]), -1, -1);
                    building.finishAt = cells.length > 2 ? Math.max(0, Long.parseLong(cells[2])) : 0;
                    building.targetLevel = cells.length > 3 ? Integer.parseInt(cells[3]) : 0;
                    sanitizeTimer(building, now);
                    parsed.add(building);
                } catch (Exception ignored) { }
            }
        }
        if (!parsed.isEmpty()) {
            state.buildings.clear();
            placeRecovered(state, parsed);
        }
        new ResourceManager(state).clamp();
        normalizeXp(state);
        state.revision++;
        return state;
    }

    private static void sanitizeTimer(BuildingInstance building, long now) {
        int max = "townhall".equals(building.type) ? 5 : ("builderhut".equals(building.type) ? 1 : 8);
        building.level = bounded(building.level, 0, max);
        if (building.finishAt == 0 || building.targetLevel <= building.level || building.targetLevel > max || "wall".equals(building.type)) {
            building.finishAt = building.startedAt = 0;
            building.targetLevel = 0;
            building.level = Math.max(1, building.level);
        } else {
            long duration = 1000L * (building.level == 0 ? building.definition().buildSeconds : building.definition().upgradeSeconds(building.level));
            if (building.startedAt <= 0 || building.startedAt >= building.finishAt) building.startedAt = Math.max(0, building.finishAt - Math.max(1000, duration));
            // Invalid far-future timestamps must not lock a builder for decades.
            long maximumFinish = now + 366L * 24 * 60 * 60 * 1000;
            if (building.finishAt > maximumFinish) {
                building.startedAt = now;
                building.finishAt = now + Math.max(1000, duration);
            }
        }
    }

    private static void placeRecovered(GameState state, List<BuildingInstance> parsed) {
        VillageGrid grid = new VillageGrid(state);
        BuildingInstance hall = null;
        for (BuildingInstance b : parsed) if ("townhall".equals(b.type)) { hall = b; break; }
        if (hall == null) hall = new BuildingInstance("townhall", 1, 18, 18);
        placeOne(state, grid, hall);
        for (BuildingInstance b : parsed) if (!"townhall".equals(b.type)) placeOne(state, grid, b);
    }

    private static void placeOne(GameState state, VillageGrid grid, BuildingInstance b) {
        if (!grid.canPlace(b.type, b.x, b.y, null)) {
            boolean found = false;
            int center = (VillageGrid.SIZE - b.definition().size) / 2;
            // Center-out placement gives legacy villages a compact, camera-friendly layout.
            for (int radius = 0; radius < VillageGrid.SIZE && !found; radius++) {
                for (int y = center - radius; y <= center + radius && !found; y++) {
                    for (int x = center - radius; x <= center + radius; x++) {
                        if (Math.max(Math.abs(x - center), Math.abs(y - center)) != radius) continue;
                        if (grid.canPlace(b.type, x, y, null)) { b.x = x; b.y = y; found = true; break; }
                    }
                }
            }
            if (!found) return;
        }
        state.buildings.add(b);
        state.revision++;
    }

    private static boolean knownType(String type) {
        for (BuildingDefinition definition : BuildingDefinition.all()) if (definition.type.equals(type)) return true;
        return false;
    }

    // Preserve a future cursor after a device clock rollback; the model never credits it twice.
    private static long timestamp(long value, long now) {
        return value <= 0 || value > now + 366L * 24 * 60 * 60 * 1000 ? now : value;
    }
    private static void normalizeXp(GameState state) {
        int earned = state.xp;
        state.xp = 0;
        state.addXp(earned);
    }
    private static int bounded(int value, int min, int max) { return Math.max(min, Math.min(max, value)); }
    private static double finite(double value, double fallback) { return Double.isNaN(value) || Double.isInfinite(value) ? fallback : Math.max(0, value); }
    private static float volume(double value, float fallback) { return (float) Math.min(1, finite(value, fallback)); }
    private static double number(Object value, double fallback) {
        try { return finite(Double.parseDouble(String.valueOf(value)), fallback); } catch (Exception ignored) { return fallback; }
    }
    /** Retain forensic recovery material before a new village can replace an unreadable save. */
    private void preserveUnreadable(AtomicFile source) {
        File file = source.getBaseFile();
        File archive = new File(context.getFilesDir(), file.getName() + ".unreadable");
        if (!file.exists() || archive.exists()) return;
        try (FileInputStream input = new FileInputStream(file); FileOutputStream output = new FileOutputStream(archive)) {
            byte[] buffer = new byte[8192];
            int count;
            while ((count = input.read(buffer)) != -1) output.write(buffer, 0, count);
            output.getFD().sync();
        } catch (Exception ignored) { /* A full disk must not turn save recovery into a crash. */ }
    }
    private static byte[] read(AtomicFile file) throws Exception {
        try (FileInputStream input = file.openRead(); ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[4096];
            int count;
            while ((count = input.read(buffer)) != -1) {
                if (bytes.size() + count > MAX_BYTES) throw new IllegalArgumentException("Save too large");
                bytes.write(buffer, 0, count);
            }
            return bytes.toByteArray();
        }
    }
    private static void write(AtomicFile file, byte[] bytes) throws Exception {
        FileOutputStream stream = null;
        try {
            stream = file.startWrite();
            stream.write(bytes);
            file.finishWrite(stream);
        } catch (Exception failure) {
            if (stream != null) file.failWrite(stream);
            throw failure;
        }
    }
    private static final class FutureVersionException extends Exception { }
}
