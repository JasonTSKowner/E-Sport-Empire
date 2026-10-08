package com.jasontsk.projectcitadel;

/** Derived resource accounting; an upgrading building keeps its current-level stats. */
public final class ResourceManager {
    private final GameState state;
    public ResourceManager(GameState state) { this.state = state; }
    public int goldCapacity() { return capacity("goldstorage", 1500); }
    public int elixirCapacity() { return capacity("elixirstorage", 1000); }
    private int capacity(String storageType, int base) {
        long result = base;
        for (BuildingInstance b : state.buildings) {
            if (b.level > 0 && (storageType.equals(b.type) || "townhall".equals(b.type)))
                result += b.definition().capacity(b.level);
        }
        return (int) Math.min(Integer.MAX_VALUE, result);
    }
    public double goldPerSecond() { return production("goldmine"); }
    public double elixirPerSecond() { return production("elixirmine"); }
    private double production(String type) {
        double hourly = 0;
        for (BuildingInstance b : state.buildings)
            if (type.equals(b.type) && b.level > 0) hourly += b.definition().production(b.level);
        return hourly / 3600.0;
    }
    public void clamp() {
        state.gold = bounded(state.gold, goldCapacity());
        state.elixir = bounded(state.elixir, elixirCapacity());
    }
    private static double bounded(double value, int capacity) {
        if (Double.isNaN(value)) return 0;
        return Math.max(0, Math.min(capacity, value));
    }
}
