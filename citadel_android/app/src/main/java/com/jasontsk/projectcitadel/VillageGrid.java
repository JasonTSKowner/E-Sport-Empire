package com.jasontsk.projectcitadel;

/** Centralized geometry and occupancy checks; no drawing or screen coordinates enter this class. */
public final class VillageGrid {
    public static final int SIZE = 40;
    public static final int BORDER = 2;
    public static final float HALF_W = 32f, HALF_H = 16f;
    public enum TileState { FREE, OCCUPIED, BLOCKED, BUILDING, WALL, DECORATION, OBSTACLE }
    private final GameState state;

    public VillageGrid(GameState state) { this.state = state; }
    public static float worldX(float gx, float gy) { return (gx - gy) * HALF_W; }
    public static float worldY(float gx, float gy) { return (gx + gy) * HALF_H; }
    public static float gridX(float wx, float wy) { return (wx / HALF_W + wy / HALF_H) * 0.5f; }
    public static float gridY(float wx, float wy) { return (wy / HALF_H - wx / HALF_W) * 0.5f; }
    public boolean blocked(int x, int y) {
        return x < BORDER || y < BORDER || x >= SIZE - BORDER || y >= SIZE - BORDER;
    }

    /** Footprint intersection is independent of sprite overhang and building level. */
    public boolean canPlace(String type, int x, int y, String ignoreId) {
        BuildingDefinition def = BuildingDefinition.get(type);
        if (def == null || blocked(x, y) || x > SIZE - BORDER - def.size
                || y > SIZE - BORDER - def.size) return false;
        for (BuildingInstance b : state.buildings) {
            if (ignoreId != null && ignoreId.equals(b.id)) continue;
            BuildingDefinition other = b.definition();
            if (other != null && x < b.x + other.size && x + def.size > b.x
                    && y < b.y + other.size && y + def.size > b.y) return false;
        }
        return true;
    }
    public BuildingInstance at(int x, int y) {
        for (BuildingInstance b : state.buildings) {
            BuildingDefinition def = b.definition();
            if (def != null && x >= b.x && y >= b.y && x < b.x + def.size && y < b.y + def.size) return b;
        }
        return null;
    }
    public TileState stateAt(int x, int y) {
        if (blocked(x, y)) return TileState.BLOCKED;
        BuildingInstance b = at(x, y);
        if (b == null) return TileState.FREE;
        return "wall".equals(b.type) ? TileState.WALL : TileState.BUILDING;
    }
}
