package com.jasontsk.projectcitadel;

/** Adjacency bit mask works for every junction, including mixed-level neighboring walls. */
public final class WallConnectionManager {
    public static final int EAST = 1, SOUTH = 2, WEST = 4, NORTH = 8;
    private final GameState state;
    private final int[] occupied = new int[VillageGrid.SIZE * VillageGrid.SIZE];
    private int cachedRevision = Integer.MIN_VALUE, cachedCount = -1;
    public WallConnectionManager(GameState state) { this.state = state; }

    private void refresh() {
        if (cachedRevision == state.revision && cachedCount == state.buildings.size()) return;
        java.util.Arrays.fill(occupied, 0);
        for (BuildingInstance b : state.buildings) {
            if ("wall".equals(b.type) && b.x >= 0 && b.y >= 0
                    && b.x < VillageGrid.SIZE && b.y < VillageGrid.SIZE)
                occupied[b.y * VillageGrid.SIZE + b.x] = 1;
        }
        cachedRevision = state.revision;
        cachedCount = state.buildings.size();
    }
    public int mask(BuildingInstance wall) {
        if (wall == null || !"wall".equals(wall.type)) return 0;
        refresh();
        int result = 0;
        if (exists(wall.x + 1, wall.y)) result |= EAST;
        if (exists(wall.x, wall.y + 1)) result |= SOUTH;
        if (exists(wall.x - 1, wall.y)) result |= WEST;
        if (exists(wall.x, wall.y - 1)) result |= NORTH;
        return result;
    }
    private boolean exists(int x, int y) {
        return x >= 0 && y >= 0 && x < VillageGrid.SIZE && y < VillageGrid.SIZE
                && occupied[y * VillageGrid.SIZE + x] != 0;
    }
}
