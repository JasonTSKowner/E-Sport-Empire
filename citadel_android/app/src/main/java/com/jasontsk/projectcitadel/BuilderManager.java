package com.jasontsk.projectcitadel;

/** Builders are computed from structures and active jobs, so save loading cannot duplicate them. */
public final class BuilderManager {
    private final GameState state;
    public BuilderManager(GameState state) { this.state = state; }
    public int total() {
        int total = 2;
        for (BuildingInstance b : state.buildings) if ("builderhut".equals(b.type) && b.level > 0) total++;
        return total;
    }
    public int busy() {
        int busy = 0;
        for (BuildingInstance b : state.buildings) if (b.isBusy() && !"wall".equals(b.type)) busy++;
        return busy;
    }
    public int free() { return Math.max(0, total() - busy()); }
}
