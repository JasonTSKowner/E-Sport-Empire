package com.jasontsk.projectcitadel;

import java.util.UUID;

/** Persisted world entity. Level zero denotes new construction until its timestamp completes. */
public final class BuildingInstance {
    public String id, type;
    public int level, x, y, targetLevel;
    public long startedAt, finishAt;

    public BuildingInstance(String type, int level, int x, int y) {
        if (BuildingDefinition.get(type) == null) throw new IllegalArgumentException("Unknown building: " + type);
        this.id = UUID.randomUUID().toString();
        this.type = type;
        this.level = Math.max(0, level);
        this.x = x;
        this.y = y;
    }

    public BuildingDefinition definition() { return BuildingDefinition.get(type); }
    public boolean isBusy() { return finishAt > 0; }
    public boolean isConstructing() { return level == 0; }
}
