package com.jasontsk.projectcitadel;

/** Gameplay transactions validate completely before charging resources or claiming a builder. */
public final class BuildingManager {
    public final GameState state;
    public final VillageGrid grid;
    public final ResourceManager resources;
    public final BuilderManager builders;

    public BuildingManager(GameState state) {
        this.state = state;
        this.grid = new VillageGrid(state);
        this.resources = new ResourceManager(state);
        this.builders = new BuilderManager(state);
    }

    /**
     * Integrates each interval at the stats that applied DURING that interval. A storage or mine
     * finishing midway through an offline session affects only subsequent production, and repeated
     * calls at the same timestamp never award production or XP twice.
     */
    public int advance(long now) {
        if (now < 0) return 0;
        if (state.lastProductionAt <= 0) state.lastProductionAt = now;
        long cursor = state.lastProductionAt;
        resources.clamp();
        int completions = 0;
        while (true) {
            long next = Long.MAX_VALUE;
            for (BuildingInstance b : state.buildings)
                if (b.isBusy() && b.finishAt <= now) next = Math.min(next, b.finishAt);
            if (next == Long.MAX_VALUE) break;
            if (next > cursor) produce((next - cursor) / 1000.0);
            cursor = Math.max(cursor, next);
            for (BuildingInstance b : state.buildings) {
                if (!b.isBusy() || b.finishAt != next) continue;
                boolean construction = b.isConstructing();
                b.level = Math.max(Math.max(1, b.level), b.targetLevel);
                b.targetLevel = 0;
                b.startedAt = 0;
                b.finishAt = 0;
                state.addXp(construction ? Math.max(3, b.definition().xp / 2)
                        : reward(b.definition().xp, b.level));
                completions++;
            }
            state.revision++;
            resources.clamp();
        }
        if (now > cursor) produce((now - cursor) / 1000.0);
        // A clock rollback cannot replay an already credited interval.
        state.lastProductionAt = Math.max(state.lastProductionAt, now);
        return completions;
    }

    private void produce(double seconds) {
        state.gold = Math.min(resources.goldCapacity(), state.gold + resources.goldPerSecond() * seconds);
        state.elixir = Math.min(resources.elixirCapacity(), state.elixir + resources.elixirPerSecond() * seconds);
    }

    public String build(String type, int x, int y, long now) {
        advance(now);
        BuildingDefinition def = BuildingDefinition.get(type);
        if (def == null) return "That structure is not available.";
        int limit = def.limit(state.townHallLevel());
        if (limit == 0) return "Requires Town Hall " + def.requiredTownHall() + ".";
        int count = 0;
        for (BuildingInstance b : state.buildings) if (type.equals(b.type)) count++;
        if (count >= limit) return "Building limit reached. Upgrade your Town Hall.";
        if (!grid.canPlace(type, x, y, null)) return "Choose clear land inside the village.";
        if (def.buildSeconds > 0 && builders.free() == 0) return "All builders are busy. Wait for a job to finish.";
        if (state.gold < def.buildGold) return "Not enough Gold.";
        if (state.elixir < def.buildElixir) return "Not enough Elixir.";
        state.gold -= def.buildGold;
        state.elixir -= def.buildElixir;
        BuildingInstance b = new BuildingInstance(type, def.buildSeconds == 0 ? 1 : 0, x, y);
        if (def.buildSeconds > 0) start(b, 1, def.buildSeconds, now);
        else state.addXp(Math.max(3, def.xp / 2));
        state.buildings.add(b);
        state.revision++;
        return null;
    }

    public String move(String id, int x, int y) {
        BuildingInstance b = state.find(id);
        if (b == null) return "That building is no longer here.";
        if (!grid.canPlace(b.type, x, y, id)) return "Buildings cannot overlap or leave the village.";
        if (b.x != x || b.y != y) {
            b.x = x;
            b.y = y;
            state.revision++;
        }
        return null;
    }

    public String upgradeProblem(BuildingInstance b, boolean payElixir) {
        if (b == null || state.find(b.id) != b) return "Select a building first.";
        if (b.isBusy()) return "This building already has a builder working on it.";
        if (b.level <= 0) return "Finish construction first.";
        BuildingDefinition def = b.definition();
        if (b.level >= def.maxLevel(state.townHallLevel())) {
            if (b.level >= def.maxLevel(5)) return "Maximum level reached for Crownforge V0.2.";
            return "Upgrade your Town Hall to unlock the next level.";
        }
        boolean wall = "wall".equals(b.type);
        if (payElixir && (!wall || b.level + 1 < 3)) return "Elixir is available for Wall Level 3 and above.";
        if (!wall && builders.free() == 0) return "All builders are busy. Wait for a job to finish.";
        if (payElixir) {
            if (state.elixir < def.upgradeGold(b.level)) return "Not enough Elixir.";
        } else {
            if (state.gold < def.upgradeGold(b.level)) return "Not enough Gold.";
            if (!wall && state.elixir < def.upgradeElixir(b.level)) return "Not enough Elixir.";
        }
        return null;
    }

    public String upgrade(String id, boolean payElixir, long now) {
        advance(now);
        BuildingInstance b = state.find(id);
        String problem = upgradeProblem(b, payElixir);
        if (problem != null) return problem;
        BuildingDefinition def = b.definition();
        boolean wall = "wall".equals(b.type);
        if (payElixir) state.elixir -= def.upgradeGold(b.level);
        else {
            state.gold -= def.upgradeGold(b.level);
            if (!wall) state.elixir -= def.upgradeElixir(b.level);
        }
        if (wall) {
            b.level++;
            state.addXp(reward(def.xp, b.level));
        } else start(b, b.level + 1, def.upgradeSeconds(b.level), now);
        state.revision++;
        return null;
    }

    private void start(BuildingInstance b, int target, int seconds, long now) {
        b.targetLevel = target;
        b.startedAt = Math.max(0, now);
        b.finishAt = b.startedAt + seconds * 1000L;
    }
    private static int reward(int base, int level) {
        return (int) Math.min(Integer.MAX_VALUE, (long) base * level);
    }
}
