package com.jasontsk.projectcitadel;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Immutable balance data. Production is expressed in resource units per hour. */
public final class BuildingDefinition {
    private static final Map<String, BuildingDefinition> DEFINITIONS = new LinkedHashMap<>();
    private static final List<BuildingDefinition> ALL;
    private static final int[] STANDARD_LEVELS = {2, 3, 4, 6, 8};

    static {
        register(new BuildingDefinition("townhall", "Town Hall", "Village", 4, 500, 0, 12, 80,
                new int[]{1, 1, 1, 1, 1}, new int[]{5, 5, 5, 5, 5}, 1200, 0, 500, 0));
        register(new BuildingDefinition("goldmine", "Gold Mine", "Resources", 3, 150, 0, 8, 20,
                new int[]{1, 2, 2, 3, 3}, STANDARD_LEVELS, 380, 7920, 0, 0));
        register(new BuildingDefinition("elixirmine", "Elixir Collector", "Resources", 3, 300, 0, 10, 25,
                new int[]{0, 1, 2, 3, 3}, STANDARD_LEVELS, 360, 6480, 0, 0));
        register(new BuildingDefinition("goldstorage", "Gold Storage", "Resources", 3, 250, 0, 9, 24,
                new int[]{1, 1, 2, 2, 3}, STANDARD_LEVELS, 650, 0, 1200, 0));
        register(new BuildingDefinition("elixirstorage", "Elixir Storage", "Resources", 3, 400, 0, 11, 28,
                new int[]{0, 1, 1, 2, 3}, STANDARD_LEVELS, 650, 0, 1200, 0));
        register(new BuildingDefinition("cannon", "Cannon", "Defense", 2, 350, 0, 12, 30,
                new int[]{0, 1, 2, 2, 3}, STANDARD_LEVELS, 500, 0, 0, 28));
        register(new BuildingDefinition("archer", "Archer Tower", "Defense", 2, 700, 0, 16, 42,
                new int[]{0, 0, 1, 2, 2}, STANDARD_LEVELS, 440, 0, 0, 36));
        register(new BuildingDefinition("builderhut", "Builder Hut", "Village", 2, 1000, 500, 20, 50,
                new int[]{0, 0, 1, 1, 1}, new int[]{1, 1, 1, 1, 1}, 300, 0, 0, 0));
        register(new BuildingDefinition("wall", "Wall", "Walls", 1, 50, 0, 0, 5,
                new int[]{10, 20, 30, 40, 50}, STANDARD_LEVELS, 280, 0, 0, 0));
        ALL = Collections.unmodifiableList(new ArrayList<>(DEFINITIONS.values()));
    }

    public final String type, name, category, visualAsset;
    public final int size, buildGold, buildElixir, buildSeconds, xp;
    private final int[] limits, levels;
    private final int baseHp, hourlyProduction, baseCapacity, baseDamage;

    private BuildingDefinition(String type, String name, String category, int size, int gold,
            int elixir, int seconds, int xp, int[] limits, int[] levels, int hp,
            int production, int capacity, int damage) {
        this.type = type;
        this.name = name;
        this.category = category;
        this.visualAsset = "crownforge/" + type;
        this.size = size;
        this.buildGold = gold;
        this.buildElixir = elixir;
        this.buildSeconds = seconds;
        this.xp = xp;
        this.limits = limits.clone();
        this.levels = levels.clone();
        this.baseHp = hp;
        this.hourlyProduction = production;
        this.baseCapacity = capacity;
        this.baseDamage = damage;
    }

    private static void register(BuildingDefinition definition) {
        DEFINITIONS.put(definition.type, definition);
    }

    /** Returns null for unknown types so malformed/forward-version saves can be recovered. */
    public static BuildingDefinition get(String type) { return DEFINITIONS.get(type); }
    public static List<BuildingDefinition> all() { return ALL; }
    private int thIndex(int th) { return Math.max(0, Math.min(limits.length - 1, th - 1)); }
    public int limit(int th) { return limits[thIndex(th)]; }
    public int maxLevel(int th) { return levels[thIndex(th)]; }

    /** Upgrade costs/durations take the CURRENT level, not the destination level. */
    public int upgradeGold(int level) { return exponential(buildGold, 1.75, level); }
    public int upgradeElixir(int level) {
        return "wall".equals(type) ? (level >= 2 ? upgradeGold(level) : 0)
                : exponential(buildElixir, 1.75, level);
    }
    public int upgradeSeconds(int level) { return exponential(buildSeconds, 1.35, level); }
    public int hp(int level) { return level <= 0 ? 0 : exponential(baseHp, 1.28, level); }
    public int production(int level) { return scaled(hourlyProduction, level); }
    public int capacity(int level) { return scaled(baseCapacity, level); }
    public int damage(int level) { return level <= 0 ? 0 : exponential(baseDamage, 1.3, level); }
    public int requiredTownHall() {
        for (int i = 0; i < limits.length; i++) if (limits[i] > 0) return i + 1;
        return limits.length + 1;
    }

    private static int scaled(int value, int level) {
        return (int) Math.min(Integer.MAX_VALUE, (long) value * Math.max(0, level));
    }
    private static int exponential(int base, double factor, int level) {
        if (base == 0) return 0;
        return (int) Math.min(Integer.MAX_VALUE,
                Math.round(base * Math.pow(factor, Math.max(0, Math.min(100, level - 1)))));
    }
}
