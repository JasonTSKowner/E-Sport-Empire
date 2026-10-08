package com.jasontsk.projectcitadel;

import org.junit.Test;
import static org.junit.Assert.*;

/** Domain regressions: real model operations, no Android runtime or mocked economy. */
public class GameSystemsTest {
    private static final long NOW = 1_700_000_000_000L;

    private GameState village(int townHallLevel) {
        GameState s = GameState.fresh(NOW);
        s.buildings.clear();
        s.buildings.add(new BuildingInstance("townhall", townHallLevel, 18, 18));
        s.gold = 1000;
        s.elixir = 1000;
        return s;
    }

    @Test public void isometricCoordinatesRoundTripAcrossVillage() {
        for (float x = 0; x <= VillageGrid.SIZE; x += .5f) {
            for (float y = 0; y <= VillageGrid.SIZE; y += .5f) {
                float wx = VillageGrid.worldX(x, y), wy = VillageGrid.worldY(x, y);
                assertEquals(x, VillageGrid.gridX(wx, wy), .0001);
                assertEquals(y, VillageGrid.gridY(wx, wy), .0001);
            }
        }
    }

    @Test public void freshVillageHasOneTownHallAndValidDistinctFootprints() {
        GameState s = GameState.fresh(NOW);
        VillageGrid grid = new VillageGrid(s);
        int halls = 0;
        for (BuildingInstance b : s.buildings) {
            if (b.type.equals("townhall")) halls++;
            assertTrue(b.type + " must have a valid initial footprint", grid.canPlace(b.type, b.x, b.y, b.id));
            assertSame(b, grid.at(b.x, b.y));
        }
        assertEquals(1, halls);
    }

    @Test public void placementRejectsOverlapBoundaryAndUnknownTypes() {
        GameState s = village(3);
        VillageGrid grid = new VillageGrid(s);
        assertFalse(grid.canPlace("wall", 18, 18, null));
        assertFalse(grid.canPlace("townhall", 16, 16, null));
        assertFalse(grid.canPlace("wall", 0, 0, null));
        assertFalse(grid.canPlace("goldmine", 37, 37, null));
        assertFalse(grid.canPlace("wall", -1, 20, null));
        assertFalse(grid.canPlace("not_a_building", 8, 8, null));
        assertTrue(grid.canPlace("goldmine", 8, 8, null));
    }

    @Test public void moveIsFreeAndInvalidMoveDoesNotMutatePosition() {
        GameState s = village(3);
        BuildingInstance mine = new BuildingInstance("goldmine", 1, 8, 8);
        s.buildings.add(mine);
        BuildingManager m = new BuildingManager(s);
        double gold = s.gold, elixir = s.elixir;
        assertNotNull(m.move(mine.id, 18, 18));
        assertEquals(8, mine.x);
        assertEquals(8, mine.y);
        assertNull(m.move(mine.id, 9, 9)); // Can overlap its own former footprint.
        assertEquals(9, mine.x);
        assertEquals(9, mine.y);
        assertEquals(gold, s.gold, 0);
        assertEquals(elixir, s.elixir, 0);
        assertTrue(m.grid.canPlace("wall", 8, 8, null));
        assertFalse(m.grid.canPlace("wall", 9, 9, null));
    }

    @Test public void invalidBuildNeverChargesResources() {
        GameState s = village(3);
        BuildingManager m = new BuildingManager(s);
        double gold = s.gold, elixir = s.elixir;
        int count = s.buildings.size();
        assertNotNull(m.build("cannon", 18, 18, NOW));
        assertNotNull(m.build("not_a_building", 8, 8, NOW));
        assertEquals(count, s.buildings.size());
        assertEquals(gold, s.gold, 0);
        assertEquals(elixir, s.elixir, 0);
    }

    @Test public void constructionOccupiesTilesAndBuilderUntilCompletion() {
        GameState s = village(3);
        BuildingManager m = new BuildingManager(s);
        int free = m.builders.free();
        assertNull(m.build("goldmine", 8, 8, NOW));
        BuildingInstance mine = m.grid.at(8, 8);
        assertNotNull(mine);
        assertTrue(mine.isConstructing());
        assertTrue(mine.isBusy());
        assertEquals(free - 1, m.builders.free());
        assertEquals(0, m.resources.goldPerSecond(), .0001);
        long finish = mine.finishAt;
        assertTrue(finish > NOW);
        assertEquals(0, m.advance(finish - 1));
        assertEquals(1, m.advance(finish));
        assertEquals(1, mine.level);
        assertFalse(mine.isBusy());
        assertEquals(free, m.builders.free());
        assertTrue(m.resources.goldPerSecond() > 0);
    }

    @Test public void unavailableBuilderRejectsUpgradeBeforeCharging() {
        GameState s = village(5);
        BuildingInstance a = new BuildingInstance("goldmine", 1, 8, 8);
        BuildingInstance b = new BuildingInstance("elixirmine", 1, 8, 12);
        BuildingInstance c = new BuildingInstance("cannon", 1, 12, 8);
        s.buildings.add(a); s.buildings.add(b); s.buildings.add(c);
        a.startedAt = b.startedAt = NOW;
        a.finishAt = b.finishAt = NOW + 100_000;
        a.targetLevel = b.targetLevel = 2;
        BuildingManager m = new BuildingManager(s);
        assertEquals(0, m.builders.free());
        double gold = s.gold, elixir = s.elixir;
        assertNotNull(m.upgrade(c.id, false, NOW));
        assertEquals(gold, s.gold, 0);
        assertEquals(elixir, s.elixir, 0);
        assertFalse(c.isBusy());
    }

    @Test public void builderHutGrantsBuilderOnlyAfterConstruction() {
        GameState s = village(3);
        BuildingInstance hut = new BuildingInstance("builderhut", 0, 8, 8);
        hut.startedAt = NOW; hut.finishAt = NOW + 1000; hut.targetLevel = 1;
        s.buildings.add(hut);
        BuildingManager m = new BuildingManager(s);
        assertEquals(2, m.builders.total());
        assertEquals(1, m.builders.busy());
        m.advance(NOW + 1000);
        assertEquals(3, m.builders.total());
        assertEquals(3, m.builders.free());
        m.advance(NOW + 2000);
        assertEquals(3, m.builders.total());
    }

    @Test public void wallLevelsOneAndTwoUseGoldAndLevelThreeAllowsEitherCurrency() {
        GameState s = village(5);
        BuildingInstance wall = new BuildingInstance("wall", 1, 8, 8);
        s.buildings.add(wall);
        BuildingManager m = new BuildingManager(s);
        double gold = s.gold, elixir = s.elixir;
        assertNotNull(m.upgrade(wall.id, true, NOW)); // Target 2: gold only.
        assertEquals(gold, s.gold, 0);
        assertEquals(elixir, s.elixir, 0);
        assertNull(m.upgrade(wall.id, false, NOW));
        assertEquals(2, wall.level);
        assertTrue(s.gold < gold);
        assertEquals(elixir, s.elixir, 0);
        gold = s.gold;
        assertNull(m.upgrade(wall.id, true, NOW)); // Target 3: elixir is valid.
        assertEquals(3, wall.level);
        assertEquals(gold, s.gold, 0);
        assertTrue(s.elixir < elixir);
        assertFalse(wall.isBusy());
        assertEquals(2, m.builders.free());
    }

    @Test public void wallConnectionsUpdateForMoveAndRemovalAcrossLevels() {
        GameState s = village(5);
        BuildingInstance center = new BuildingInstance("wall", 1, 8, 8);
        BuildingInstance east = new BuildingInstance("wall", 3, 9, 8);
        BuildingInstance south = new BuildingInstance("wall", 2, 8, 9);
        BuildingInstance west = new BuildingInstance("wall", 1, 7, 8);
        BuildingInstance north = new BuildingInstance("wall", 4, 8, 7);
        s.buildings.add(center);
        WallConnectionManager connections = new WallConnectionManager(s);
        assertEquals(0, connections.mask(center));
        s.buildings.add(east); s.buildings.add(west);
        s.revision++;
        assertEquals(5, connections.mask(center));
        s.buildings.add(south); s.revision++;
        assertEquals(7, connections.mask(center));
        s.buildings.add(north); s.revision++;
        assertEquals(15, connections.mask(center));
        assertNull(new BuildingManager(s).move(east.id, 12, 12));
        assertEquals(14, connections.mask(center));
        s.buildings.remove(west); s.revision++;
        assertEquals(10, connections.mask(center));
        assertEquals(0, connections.mask(east));
    }

    @Test public void productionRespectsCapacityAndBackwardClockCannotGrantResources() {
        GameState s = village(3);
        s.buildings.add(new BuildingInstance("goldmine", 1, 8, 8));
        s.buildings.add(new BuildingInstance("elixirmine", 1, 8, 12));
        BuildingManager m = new BuildingManager(s);
        s.gold = s.elixir = 0;
        m.advance(NOW + 10_000);
        assertEquals(m.resources.goldPerSecond() * 10, s.gold, .0001);
        assertEquals(m.resources.elixirPerSecond() * 10, s.elixir, .0001);
        double gold = s.gold, elixir = s.elixir;
        m.advance(NOW);
        assertEquals(gold, s.gold, 0);
        assertEquals(elixir, s.elixir, 0);
        m.advance(NOW + 10_000);
        assertEquals(gold, s.gold, 0); // A backwards clock must not reset the accounting timestamp.
        assertEquals(elixir, s.elixir, 0);
        m.advance(NOW + 31_536_000_000L);
        assertEquals(m.resources.goldCapacity(), s.gold, .0001);
        assertEquals(m.resources.elixirCapacity(), s.elixir, .0001);
    }

    @Test public void offlineConstructionProducesOnlyAfterItsCompletion() {
        GameState s = village(3);
        s.gold = s.elixir = 0;
        BuildingInstance mine = new BuildingInstance("goldmine", 0, 8, 8);
        mine.startedAt = NOW; mine.finishAt = NOW + 10_000; mine.targetLevel = 1;
        s.buildings.add(mine);
        BuildingManager m = new BuildingManager(s);
        assertEquals(1, m.advance(NOW + 30_000));
        assertEquals(mine.definition().production(1) / 3600.0 * 20, s.gold, .0001);
        assertEquals(0, m.advance(NOW + 30_000));
        assertEquals(mine.definition().production(1) / 3600.0 * 20, s.gold, .0001);
    }

    @Test public void offlineCatchupMatchesContinuousProgressAcrossSeveralCompletions() {
        GameState offline = stagedVillage();
        GameState online = stagedVillage();
        BuildingManager om = new BuildingManager(offline), lm = new BuildingManager(online);
        om.advance(NOW + 60_000);
        for (int second = 1; second <= 60; second++) lm.advance(NOW + second * 1000L);
        assertEquals(online.gold, offline.gold, .0001);
        assertEquals(online.elixir, offline.elixir, .0001);
        assertEquals(online.playerLevel, offline.playerLevel);
        assertEquals(online.xp, offline.xp);
        assertEquals(lm.builders.free(), om.builders.free());
        for (int i = 0; i < online.buildings.size(); i++) {
            assertEquals(online.buildings.get(i).level, offline.buildings.get(i).level);
            assertFalse(offline.buildings.get(i).isBusy());
        }
    }

    private GameState stagedVillage() {
        GameState s = village(3);
        s.gold = new ResourceManager(s).goldCapacity() - 10;
        s.elixir = 0;
        BuildingInstance mine = new BuildingInstance("goldmine", 1, 8, 8);
        mine.startedAt = NOW; mine.finishAt = NOW + 10_000; mine.targetLevel = 2;
        BuildingInstance storage = new BuildingInstance("goldstorage", 0, 12, 8);
        storage.startedAt = NOW; storage.finishAt = NOW + 20_000; storage.targetLevel = 1;
        BuildingInstance elixir = new BuildingInstance("elixirmine", 1, 8, 12);
        s.buildings.add(mine); s.buildings.add(storage); s.buildings.add(elixir);
        return s;
    }

    @Test public void expiredUpgradeCompletesOnceAndAwardsXpOnce() {
        GameState s = village(3);
        BuildingInstance b = new BuildingInstance("cannon", 1, 8, 8);
        b.startedAt = NOW - 20_000; b.finishAt = NOW - 1000; b.targetLevel = 2;
        s.buildings.add(b);
        BuildingManager m = new BuildingManager(s);
        assertEquals(1, m.advance(NOW));
        assertEquals(2, b.level);
        assertFalse(b.isBusy());
        int xp = s.xp, level = s.playerLevel;
        assertEquals(0, m.advance(NOW + 60_000));
        assertEquals(xp, s.xp);
        assertEquals(level, s.playerLevel);
    }

    @Test public void townHallControlsUnlocksLimitsAndUpgradeCeilings() {
        for (BuildingDefinition d : BuildingDefinition.all()) {
            int previousLimit = -1, previousMax = -1;
            for (int th = 1; th <= 5; th++) {
                assertTrue(d.limit(th) >= previousLimit);
                assertTrue(d.maxLevel(th) >= previousMax);
                if (th < d.requiredTownHall()) assertEquals(0, d.limit(th));
                previousLimit = d.limit(th); previousMax = d.maxLevel(th);
            }
        }
        GameState s = village(1);
        BuildingManager m = new BuildingManager(s);
        assertNotNull(m.build("archer", 8, 8, NOW));
        s.townHall().level = 5;
        assertNotNull(m.upgrade(s.townHall().id, false, NOW));
        assertEquals(5, s.townHallLevel());
    }

    @Test public void townHallCanAdvanceThroughAllFiveLevels() {
        GameState s = village(1);
        BuildingManager m = new BuildingManager(s);
        long now = NOW;
        for (int next = 2; next <= 5; next++) {
            s.gold = m.resources.goldCapacity();
            s.elixir = m.resources.elixirCapacity();
            assertNull("Town Hall " + next + " should be reachable", m.upgrade(s.townHall().id, false, now));
            assertEquals(next - 1, s.townHallLevel());
            now = s.townHall().finishAt;
            m.advance(now);
            assertEquals(next, s.townHallLevel());
        }
        assertNotNull(m.upgrade(s.townHall().id, false, now));
    }

    @Test public void playerXpAdvancesIndependentlyOfTownHall() {
        GameState s = village(1);
        int first = s.xpNeeded();
        s.addXp(first - 1);
        assertEquals(1, s.playerLevel);
        s.addXp(1);
        assertEquals(2, s.playerLevel);
        assertEquals(0, s.xp);
        s.addXp(100_000);
        assertTrue(s.playerLevel > 5);
        assertTrue(s.xp >= 0 && s.xp < s.xpNeeded());
        assertEquals(1, s.townHallLevel());
    }
    @Test public void placementCancelNeverMutatesCommittedBuildings() {
        GameState s = village(3);
        BuildingInstance mine = new BuildingInstance("goldmine", 1, 8, 8);
        s.buildings.add(mine);
        PlacementManager placement = new PlacementManager(new BuildingManager(s));
        placement.beginMove(mine);
        placement.position(13.5f, 13.5f);
        assertTrue(placement.valid());
        assertEquals(8, mine.x);
        placement.cancel();
        assertFalse(placement.active());
        assertEquals(8, mine.x);
        assertEquals(8, mine.y);
        placement.beginMove(mine);
        placement.position(19.5f, 19.5f);
        assertFalse(placement.valid());
        assertNotNull(placement.confirm(NOW));
        assertEquals(8, mine.x);
        placement.position(13.5f, 13.5f);
        assertNull(placement.confirm(NOW));
        assertEquals(12, mine.x);
        assertEquals(12, mine.y);
    }

    @Test public void cameraZoomAnchorAndBoundsStayFinite() {
        CameraController camera = new CameraController();
        camera.resize(1080, 1920);
        float worldX = camera.screenToWorldX(600), worldY = camera.screenToWorldY(850);
        camera.zoomAt(1.25f, 600, 850);
        assertEquals(worldX, camera.screenToWorldX(600), .001);
        assertEquals(worldY, camera.screenToWorldY(850), .001);
        camera.zoomAt(100000, 540, 960);
        assertTrue(camera.zoom < 5);
        camera.zoomAt(.000001f, 540, 960);
        assertTrue(camera.zoom > .1f);
        for (int direction = -1; direction <= 1; direction += 2) {
            camera.pan(direction * 1000000, direction * 1000000);
            float gx = VillageGrid.gridX(camera.screenToWorldX(540), camera.screenToWorldY(960));
            float gy = VillageGrid.gridY(camera.screenToWorldX(540), camera.screenToWorldY(960));
            assertTrue(gx >= 3.999f && gx <= 36.001f);
            assertTrue(gy >= 3.999f && gy <= 36.001f);
        }
        float zoom = camera.zoom;
        camera.zoomAt(Float.NaN, 0, 0);
        camera.zoomAt(Float.POSITIVE_INFINITY, 0, 0);
        assertEquals(zoom, camera.zoom, 0);
    }

}
