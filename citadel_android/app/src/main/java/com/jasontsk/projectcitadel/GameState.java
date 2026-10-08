package com.jasontsk.projectcitadel;

import java.util.ArrayList;
import java.util.List;

/** Authoritative save state; capacities, unlocks and builder availability are derived from it. */
public final class GameState {
    public static final int SAVE_VERSION = 2;
    /** XP curve preserves V0.1 progress and remains independent of Town Hall progression. */
    public static final int XP_BASE = 100, XP_PER_LEVEL = 70;
    public final List<BuildingInstance> buildings = new ArrayList<>();
    public double gold = 1200, elixir = 600;
    public int playerLevel = 1, xp = 0;
    public long lastProductionAt;
    /** Increment only on structural/stat changes, never for per-frame or production ticks. */
    public int revision;
    public float masterVolume = 0.8f, musicVolume = 0.35f, sfxVolume = 0.7f;
    public boolean muted;

    public static GameState fresh(long now) {
        GameState state = new GameState();
        state.lastProductionAt = now;
        state.buildings.add(new BuildingInstance("townhall", 1, 18, 18));
        state.buildings.add(new BuildingInstance("goldmine", 1, 14, 19));
        state.buildings.add(new BuildingInstance("goldstorage", 1, 23, 19));
        for (int x = 17; x <= 22; x++) state.buildings.add(new BuildingInstance("wall", 1, x, 24));
        state.buildings.add(new BuildingInstance("wall", 1, 17, 23));
        state.buildings.add(new BuildingInstance("wall", 1, 22, 23));
        state.revision = 1;
        return state;
    }

    public BuildingInstance townHall() {
        for (BuildingInstance b : buildings) if ("townhall".equals(b.type)) return b;
        return null;
    }
    public int townHallLevel() {
        BuildingInstance hall = townHall();
        return hall == null ? 1 : Math.max(1, hall.level);
    }
    public BuildingInstance find(String id) {
        if (id == null) return null;
        for (BuildingInstance b : buildings) if (id.equals(b.id)) return b;
        return null;
    }
    public int xpNeeded() {
        return (int) Math.min(Integer.MAX_VALUE,
                XP_BASE + (long) Math.max(0, playerLevel - 1) * XP_PER_LEVEL);
    }
    public void addXp(int amount) {
        if (amount <= 0) return;
        playerLevel = Math.max(1, playerLevel);
        long earned = Math.max(0, xp) + (long) amount;
        while (earned >= xpNeeded() && playerLevel < Integer.MAX_VALUE) {
            earned -= xpNeeded();
            playerLevel++;
        }
        xp = (int) Math.min(Integer.MAX_VALUE, earned);
        revision++;
    }
}
