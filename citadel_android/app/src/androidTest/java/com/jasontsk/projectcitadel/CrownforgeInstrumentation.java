package com.jasontsk.projectcitadel;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.MotionEvent;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;
import org.json.JSONObject;

/** Self-contained native device tests. No AndroidX runtime is added to the game. */
public final class CrownforgeInstrumentation extends Instrumentation {
    private static final long NOW = 1_700_000_000_000L;
    private static final int TEST_COUNT = 12;
    private int tests, failures;
    private Context context;
    private MainActivity activity;
    private VillageView village;
    private final StringBuilder report = new StringBuilder();
    private interface Case { void run() throws Exception; }

    @Override public void onCreate(Bundle arguments) { super.onCreate(arguments); start(); }
    @Override public void onStart() {
        context = getTargetContext();
        runCase("saveRoundTripAndSettings", this::saveRoundTrip);
        runCase("legacyMigrationPreservesProgress", this::legacyMigration);
        runCase("malformedSaveRepairsPositions", this::malformedSave);
        runCase("corruptPrimaryRecoversBackup", this::backupRecovery);
        runCase("futureVersionIsProtected", this::futureVersion);
        runCase("clockRollbackCannotReplaySavedProduction", this::clockRollback);
        runCase("launchSplashAndVillage", this::launch);
        runCase("panPinchAndSelection", this::gestures);
        runCase("shopPlacementMoveAndCancel", this::placement);
        runCase("originalBuildingArtAllLevels", this::buildingArt);
        runCase("audioSynthesisAndLifecycle", this::audio);
        runCase("activityRestartRestoresVillage", this::restart);
        if (activity != null) runOnMainSync(() -> activity.finish());
        Bundle result = new Bundle();
        result.putString("stream", "\n" + report + "\nTests: " + tests + ", Failures: " + failures + "\nCROWNFORGE_RESULT: " + (failures == 0 ? "PASS" : "FAIL") + "\n");
        finish(Activity.RESULT_OK, result);
    }

    private void runCase(String name, Case body) {
        tests++;
        Bundle status = new Bundle();
        status.putString("id", "CrownforgeInstrumentation");
        status.putString("class", getClass().getName());
        status.putString("test", name);
        status.putInt("current", tests); status.putInt("numtests", TEST_COUNT);
        sendStatus(1, status);
        try {
            body.run();
            status.putString("stream", "PASS " + name + "\n");
            report.append("PASS ").append(name).append('\n');
            sendStatus(0, status);
        } catch (Throwable failure) {
            failures++;
            String detail = android.util.Log.getStackTraceString(failure);
            status.putString("stack", detail); status.putString("stream", "FAIL " + name + "\n" + detail);
            report.append("FAIL ").append(name).append(": ").append(failure).append('\n');
            sendStatus(-2, status);
        }
    }

    private void saveRoundTrip() throws Exception {
        clearSaves();
        GameState state = GameState.fresh(NOW);
        state.gold = 927.25; state.elixir = 341.5;
        state.playerLevel = 7; state.xp = 17;
        state.masterVolume = .25f; state.musicVolume = .5f; state.sfxVolume = .75f; state.muted = true;
        BuildingInstance hall = state.townHall();
        hall.startedAt = NOW; hall.finishAt = NOW + 12000; hall.targetLevel = 2;
        SaveManager saves = new SaveManager(context);
        check(saves.save(state), "Initial save failed");
        GameState loaded = new SaveManager(context).load(NOW + 1000);
        check(loaded.buildings.size() == state.buildings.size(), "Building count changed");
        for (BuildingInstance b : state.buildings) {
            BuildingInstance restored = loaded.find(b.id);
            check(restored != null && restored.x == b.x && restored.y == b.y && restored.level == b.level, "Building identity/position lost");
        }
        close(state.gold, loaded.gold, "Gold"); close(state.elixir, loaded.elixir, "Elixir");
        check(loaded.playerLevel == 7 && loaded.xp == 17, "Player progress lost");
        check(loaded.lastProductionAt == NOW, "Production timestamp lost");
        check(loaded.townHall().finishAt == NOW + 12000, "Upgrade deadline lost");
        check(new BuilderManager(loaded).busy() == 1, "Builder state lost");
        close(.25, loaded.masterVolume, "Master volume"); close(.5, loaded.musicVolume, "Music volume"); close(.75, loaded.sfxVolume, "Effects volume");
        check(loaded.muted, "Mute lost");
        JSONObject json = new JSONObject(new String(java.nio.file.Files.readAllBytes(new File(context.getFilesDir(), SaveManager.FILE_NAME).toPath()), StandardCharsets.UTF_8));
        check(json.getInt("saveVersion") == 2 && json.has("builders") && json.has("unlocks"), "Versioned metadata missing");
    }

    private void legacyMigration() throws Exception {
        clearSaves();
        context.getSharedPreferences("citadel_v01", Context.MODE_PRIVATE).edit()
            .putString("gold", "1111.5").putString("elixir", "500")
            .putInt("playerLevel", 4).putInt("xp", 25)
            .putString("buildings", "townhall,2,0,0;goldmine,2," + (NOW + 10000) + ",3;wall,3,0,0;builderhut,1,0,0;bad,row;goldmine,broken;unknown,1,0,0;").commit();
        SaveManager saves = new SaveManager(context);
        GameState state = saves.load(NOW);
        check(state.townHallLevel() == 2 && state.playerLevel == 4 && state.xp == 25, "Legacy levels lost");
        check(state.buildings.size() == 4, "Valid legacy buildings not preserved");
        check(state.lastProductionAt == NOW, "Migration invented offline time");
        close(1111.5, state.gold, "Legacy Gold");
        check(new BuilderManager(state).total() == 3 && new BuilderManager(state).busy() == 1, "Migrated builders duplicated/lost");
        assertValidVillage(state);
        check(context.getSharedPreferences("citadel_v01", 0).contains("buildings"), "Legacy backup erased");
        check(new BuildingManager(state).advance(NOW + 10000) == 1, "Migrated deadline failed");
        check(new SaveManager(context).load(NOW).buildings.size() == 4, "Migration not persisted");
    }

    private void malformedSave() throws Exception {
        clearSaves();
        writePrimary("{\"saveVersion\":2,\"gold\":-9,\"playerLevel\":0,\"buildings\":[{\"id\":\"duplicate\",\"type\":\"townhall\",\"level\":2,\"x\":18,\"y\":18},{\"id\":\"duplicate\",\"type\":\"goldmine\",\"level\":1,\"x\":18,\"y\":18},{\"type\":\"wall\",\"level\":-4,\"x\":-99,\"y\":300},{\"type\":\"unknown\"},null]}");
        GameState state = new SaveManager(context).load(NOW);
        check(state.buildings.size() == 3, "Recoverable buildings discarded");
        check(state.gold >= 0 && state.playerLevel >= 1, "Unsafe missing field defaults");
        assertValidVillage(state);
        Set<String> ids = new HashSet<>();
        for (BuildingInstance b : state.buildings) check(ids.add(b.id), "Duplicate IDs not repaired");
    }

    private void backupRecovery() throws Exception {
        clearSaves();
        GameState state = GameState.fresh(NOW);
        state.gold = 321;
        SaveManager saves = new SaveManager(context);
        check(saves.save(state), "Snapshot A failed");
        state.gold = 654;
        check(saves.save(state), "Snapshot B failed");
        writePrimary("{truncated");
        SaveManager recovered = new SaveManager(context);
        GameState loaded = recovered.load(NOW);
        close(321, loaded.gold, "Backup must contain previous good snapshot");
        check(recovered.message.contains("backup"), "Recovery not reported");
        assertValidVillage(loaded);
    }

    private void futureVersion() throws Exception {
        clearSaves();
        writePrimary("{\"saveVersion\":999,\"buildings\":[]}");
        SaveManager saves = new SaveManager(context);
        GameState state = saves.load(NOW);
        check(!saves.save(state), "Newer save was overwritten");
        check(saves.message.contains("newer"), "Newer version not explained");
        clearSaves();
    }

    private void clockRollback() throws Exception {
        clearSaves();
        GameState state = GameState.fresh(NOW);
        state.gold = 0;
        BuildingManager manager = new BuildingManager(state);
        manager.advance(NOW + 10000);
        double earned = state.gold;
        check(new SaveManager(context).save(state), "Clock fixture save failed");
        GameState loaded = new SaveManager(context).load(NOW + 5000);
        check(loaded.lastProductionAt == NOW + 10000, "Loading reset the production cursor after clock rollback");
        BuildingManager restored = new BuildingManager(loaded);
        restored.advance(NOW + 10000);
        close(earned, loaded.gold, "Already earned production was replayed");
        restored.advance(NOW + 11000);
        close(earned + restored.resources.goldPerSecond(), loaded.gold, "Production did not resume after clock caught up");
        clearSaves();
    }

    private void launch() throws Exception {
        clearSaves();
        activity = (MainActivity) startActivitySync(new Intent(context, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        check(activity != null, "Activity launch failed");
        screenshot("01-startup");
        waitForVillage();
        onUi(() -> {
            check(village.getWidth() > 0 && village.getHeight() > 0, "Village not laid out");
            check(village.state.townHallLevel() == 1, "Fresh Town Hall missing");
            assertValidVillage(village.state);
        });
        screenshot("02-village");
    }

    private void gestures() throws Exception {
        requireVillage();
        final float[] before = new float[3];
        onUi(() -> { village.select(null); village.camera.home(); before[0] = village.camera.x; before[1] = village.camera.y; before[2] = village.camera.zoom; });
        float w = village.getWidth(), h = village.getHeight();
        long time = SystemClock.uptimeMillis();
        dispatch(time, MotionEvent.ACTION_DOWN, w * .5f, h * .47f);
        for (int i = 1; i <= 8; i++) dispatch(time, MotionEvent.ACTION_MOVE, w * .5f + i * 14, h * .47f + i * 4);
        dispatch(time, MotionEvent.ACTION_UP, w * .5f + 112, h * .47f + 32);
        onUi(() -> {
            check(Math.abs(village.camera.x - before[0]) > 20 || Math.abs(village.camera.y - before[1]) > 20, "Drag did not pan camera");
            check(village.selected == null, "Pan accidentally selected a building");
            village.camera.home(); before[2] = village.camera.zoom;
        });
        time = SystemClock.uptimeMillis();
        dispatch(time, MotionEvent.ACTION_DOWN, w * .35f, h * .45f);
        multi(time, MotionEvent.ACTION_POINTER_DOWN | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT), w * .35f, w * .65f, h * .45f);
        for (int i = 1; i <= 10; i++) multi(time, MotionEvent.ACTION_MOVE, w * .35f - i * 14, w * .65f + i * 14, h * .45f);
        multi(time, MotionEvent.ACTION_POINTER_UP | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT), w * .35f - 140, w * .65f + 140, h * .45f);
        dispatch(time, MotionEvent.ACTION_UP, w * .35f - 140, h * .45f);
        onUi(() -> { check(village.camera.zoom > before[2] * 1.15f, "Pinch did not zoom"); check(village.selected == null, "Pinch selected building"); village.camera.home(); });
        drawFrame();
        final float[] hallPoint = new float[2];
        onUi(() -> {
            BuildingInstance hall = village.state.townHall();
            float gx = hall.x + 2, gy = hall.y + 2;
            hallPoint[0] = VillageGrid.worldX(gx, gy) * village.camera.zoom + village.camera.x;
            hallPoint[1] = VillageGrid.worldY(gx, gy) * village.camera.zoom + village.camera.y - 35 * village.camera.zoom;
        });
        tap(hallPoint[0], hallPoint[1]);
        onUi(() -> check(village.selected == village.state.townHall(), "Town Hall tap did not select"));
        screenshot("03-townhall-selected");
    }

    private void placement() throws Exception {
        requireVillage();
        onUi(() -> village.select(null)); drawFrame();
        float scale = village.getWidth() / 420f;
        tap(320 * scale, village.getHeight() - 38 * scale);
        onUi(() -> check(village.ui.panel == UIController.Panel.SHOP, "Build button did not open shop"));
        screenshot("04-build-shop");
        onUi(() -> { village.ui.panel = UIController.Panel.NONE; village.beginBuild("wall"); });
        final int[] original = new int[3];
        onUi(() -> {
            original[0] = village.state.buildings.size();
            village.placement.preview.x = 18; village.placement.preview.y = 18;
            check(!village.placement.valid(), "Occupied placement reported valid");
            village.confirmPlacement();
            check(village.placement.active() && village.state.buildings.size() == original[0], "Invalid placement was committed");
            village.cancelPlacement(); village.beginBuild("wall");
            check(village.placement.valid(), "No valid initial wall preview");
            original[1] = village.placement.preview.x; original[2] = village.placement.preview.y;
        });
        drawFrame(); screenshot("05-wall-preview");
        tap(280 * scale, village.getHeight() - 46 * scale);
        onUi(() -> {
            check(!village.placement.active(), "Confirm button did not commit");
            check(village.state.buildings.size() == original[0] + 1, "Wall not added");
            check(village.selected != null && village.selected.type.equals("wall"), "New wall not selected");
            village.beginMove(); village.placement.position(8.5f, 8.5f);
            check(village.selected.x == original[1] && village.selected.y == original[2], "Move preview changed committed position");
            village.cancelPlacement();
            check(village.selected.x == original[1] && village.selected.y == original[2], "Cancel failed to restore wall");
            village.beginMove();
        });
        drawFrame();
        final float[] target = new float[2];
        onUi(() -> {
            target[0] = VillageGrid.worldX(15.5f, 23.5f) * village.camera.zoom + village.camera.x;
            target[1] = VillageGrid.worldY(15.5f, 23.5f) * village.camera.zoom + village.camera.y;
        });
        tap(target[0], target[1]);
        onUi(() -> check(village.placement.preview.x == 15 && village.placement.preview.y == 23, "Touch placement did not snap to tiles"));
        drawFrame(); tap(280 * scale, village.getHeight() - 46 * scale);
        onUi(() -> check(village.selected.x == 15 && village.selected.y == 23, "Move confirmation did not persist position"));
        screenshot("06-wall-moved");
    }

    private void buildingArt() throws Exception {
        requireVillage();
        onUi(() -> {
            Bitmap atlas = Bitmap.createBitmap(1400, 1350, Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(atlas); canvas.drawColor(0xFF3D6348);
            int n = 0;
            for (BuildingDefinition def : BuildingDefinition.all()) {
                BuildingInstance b = new BuildingInstance(def.type, 1, 0, 0);
                village.renderer.drawBuildingPreview(canvas, b, 175 + (n % 4) * 350, 270 + (n / 4) * 280, .8f);
                n++;
            }
            long previous = 0;
            for (int level = 1; level <= 5; level++) {
                Bitmap frame = Bitmap.createBitmap(360, 340, Bitmap.Config.ARGB_8888);
                village.renderer.drawBuildingPreview(new Canvas(frame), new BuildingInstance("townhall", level, 0, 0), 180, 280, 1f);
                long hash = 1; int nonEmpty = 0;
                for (int y = 0; y < 340; y += 3) for (int x = 0; x < 360; x += 3) { int pixel = frame.getPixel(x, y); hash = hash * 31 + pixel; if (pixel != 0) nonEmpty++; }
                check(nonEmpty > 100, "Town Hall art empty");
                check(level == 1 || hash != previous, "Town Hall levels share identical visuals");
                previous = hash;
                canvas.drawBitmap(frame, (level - 1) * 275, 990, null); frame.recycle();
            }
            saveBitmap(atlas, "07-original-buildings-and-townhall-levels"); atlas.recycle();
        });
    }

    private void audio() throws Exception {
        requireVillage();
        File startup = new File(context.getCacheDir(), "crownforge-synth-v2/startup.wav");
        long deadline = SystemClock.uptimeMillis() + 5000;
        while ((!startup.exists() || startup.length() < 44) && SystemClock.uptimeMillis() < deadline) SystemClock.sleep(40);
        check(startup.length() > 44100 && startup.length() < 100000, "Original startup sound missing or wrong duration");
        byte[] bytes = java.nio.file.Files.readAllBytes(startup.toPath());
        check(bytes[0] == 'R' && bytes[1] == 'I' && bytes[8] == 'W', "Startup is not a valid WAV");
        boolean nonZero = false; for (int i = 44; i < bytes.length; i++) if (bytes[i] != 0) { nonZero = true; break; }
        check(nonZero, "Startup WAV contains silence");
        onUi(() -> {
            check(activity.audio != null, "Audio manager not initialized");
            activity.audio.play("startup"); activity.audio.play("place"); activity.audio.startAmbience();
            village.state.muted = true; activity.audio.applySettings(); activity.audio.pause(); activity.audio.resume();
            village.state.masterVolume = .25f; village.state.musicVolume = .5f; village.state.sfxVolume = .75f;
            village.changed();
        });
    }

    private void restart() throws Exception {
        requireVillage();
        final String[] movedWall = new String[1];
        onUi(() -> {
            BuildingInstance wall = village.manager.grid.at(15, 23);
            check(wall != null && wall.type.equals("wall"), "Moved wall unavailable before restart");
            movedWall[0] = wall.id;
            activity.persist(); activity.finish();
        });
        waitForIdleSync();
        activity = (MainActivity) startActivitySync(new Intent(context, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        waitForVillage();
        onUi(() -> {
            BuildingInstance wall = village.state.find(movedWall[0]);
            check(wall != null && wall.x == 15 && wall.y == 23, "Moved wall lost after activity recreation");
            check(village.state.muted, "Mute lost after recreation");
            close(.25, village.state.masterVolume, "Restart master volume");
            check(village.manager.builders.total() == 2, "Reload duplicated builders");
        });
        screenshot("08-restored-village");
    }

    private void waitForVillage() throws Exception {
        long deadline = SystemClock.uptimeMillis() + 10000;
        while (SystemClock.uptimeMillis() < deadline) {
            runOnMainSync(() -> village = activity.villageView);
            if (village != null && village.getWidth() > 0) { SystemClock.sleep(500); waitForIdleSync(); return; }
            SystemClock.sleep(50);
        }
        throw new AssertionError("Loading did not transition to the village");
    }
    private void requireVillage() { check(village != null, "Launch prerequisite failed"); }
    private void drawFrame() throws Exception {
        onUi(() -> { Bitmap frame = Bitmap.createBitmap(village.getWidth(), village.getHeight(), Bitmap.Config.ARGB_8888); village.draw(new Canvas(frame)); frame.recycle(); });
        waitForIdleSync();
    }
    private void tap(float x, float y) throws Exception { long t = SystemClock.uptimeMillis(); dispatch(t, MotionEvent.ACTION_DOWN, x, y); dispatch(t, MotionEvent.ACTION_UP, x, y); drawFrame(); }
    private void dispatch(long down, int action, float x, float y) throws Exception {
        onUi(() -> { MotionEvent e = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, x, y, 0); village.dispatchTouchEvent(e); e.recycle(); }); SystemClock.sleep(20);
    }
    private void multi(long down, int action, float x1, float x2, float y) throws Exception {
        onUi(() -> {
            MotionEvent.PointerProperties[] properties = new MotionEvent.PointerProperties[2];
            MotionEvent.PointerCoords[] coords = new MotionEvent.PointerCoords[2];
            for (int i = 0; i < 2; i++) { properties[i] = new MotionEvent.PointerProperties(); properties[i].id = i; properties[i].toolType = MotionEvent.TOOL_TYPE_FINGER; coords[i] = new MotionEvent.PointerCoords(); coords[i].x = i == 0 ? x1 : x2; coords[i].y = y; coords[i].pressure = 1; coords[i].size = 1; }
            MotionEvent e = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, 2, properties, coords, 0, 0, 1, 1, 0, 0, InputDevice.SOURCE_TOUCHSCREEN, 0);
            village.dispatchTouchEvent(e); e.recycle();
        }); SystemClock.sleep(25);
    }
    private void onUi(Case body) throws Exception {
        final Throwable[] failure = new Throwable[1];
        runOnMainSync(() -> { try { body.run(); } catch (Throwable t) { failure[0] = t; } });
        if (failure[0] instanceof Exception) throw (Exception) failure[0];
        if (failure[0] != null) throw new AssertionError(failure[0]);
    }
    private void screenshot(String name) throws Exception { Bitmap bitmap = getUiAutomation().takeScreenshot(); check(bitmap != null, "Screenshot failed"); saveBitmap(bitmap, name); bitmap.recycle(); }
    private void saveBitmap(Bitmap bitmap, String name) throws Exception { File directory = new File(context.getExternalFilesDir(null), "verification"); check(directory.exists() || directory.mkdirs(), "Screenshot directory unavailable"); try (FileOutputStream out = new FileOutputStream(new File(directory, name + ".png"))) { check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, out), "Screenshot write failed"); } }
    private void clearSaves() { for (String name : new String[]{SaveManager.FILE_NAME, SaveManager.BACKUP_NAME}) for (String suffix : new String[]{"", ".bak", ".new"}) new File(context.getFilesDir(), name + suffix).delete(); context.getSharedPreferences("citadel_v01", 0).edit().clear().commit(); }
    private void writePrimary(String text) throws Exception { try (FileOutputStream out = new FileOutputStream(new File(context.getFilesDir(), SaveManager.FILE_NAME))) { out.write(text.getBytes(StandardCharsets.UTF_8)); } }
    private static void assertValidVillage(GameState state) { VillageGrid grid = new VillageGrid(state); int halls = 0; for (BuildingInstance b : state.buildings) { check(grid.canPlace(b.type, b.x, b.y, b.id), "Invalid loaded footprint " + b.type); if (b.type.equals("townhall")) halls++; } check(halls == 1, "Village must have one Town Hall"); }
    private static void close(double expected, double actual, String label) { check(Math.abs(expected - actual) < .001, label + ": expected " + expected + ", actual " + actual); }
    private static void check(boolean condition, String message) { if (!condition) throw new AssertionError(message); }
}
