# Crownforge V0.2 implementation contract

All Java code remains in `com.jasontsk.projectcitadel`; applicationId stays unchanged for migration. Native Android Canvas, no third-party runtime dependencies. Portrait primary layout. Original vector/procedural graphics and synthesized audio.

## Shared model API
- BuildingDefinition: static `get(String type)`, `all()` returns List; public final String type,name,category; int size,buildGold,buildElixir,buildSeconds,xp; methods `limit(int th)`, `maxLevel(int th)`, `upgradeGold(int level)`, `upgradeElixir(int level)`, `upgradeSeconds(int level)`, `hp(int level)`, `production(int level)`, `capacity(int level)`, `damage(int level)`, `requiredTownHall()`.
- BuildingInstance: public String id,type; public int level,x,y,targetLevel; public long startedAt,finishAt; `definition()`, `isBusy()` (finishAt>0), `isConstructing()` (level==0). Constructor `(String type,int level,int x,int y)` generates ID.
- GameState: public List<BuildingInstance> buildings; double gold,elixir; int playerLevel,xp; long lastProductionAt; int revision; public float masterVolume,musicVolume,sfxVolume; boolean muted; static `fresh(long now)`; `townHallLevel()`, `townHall()`, `find(String id)`, `addXp(int amount)`, `xpNeeded()`.
- VillageGrid: SIZE=40; HALF_W=32f, HALF_H=16f; static `worldX(float gx,float gy)`, `worldY(float gx,float gy)`, `gridX(float wx,float wy)`, `gridY(float wx,float wy)`; constructor `(GameState)`; `canPlace(String type,int x,int y,String ignoreId)`; `at(int x,int y)`; `blocked(int x,int y)`. Reserved 2-tile map boundary. Tile-state enum for future obstacles.
- ResourceManager `(GameState)`: `goldCapacity()`, `elixirCapacity()`, `goldPerSecond()`, `elixirPerSecond()`, `clamp()`.
- BuilderManager `(GameState)`: `total()`, `busy()`, `free()` (two base builders + completed hut).
- BuildingManager `(GameState)`: public final state,grid,resources,builders; `advance(long now)` returns completion count, integrates production chronologically around completion events; `build(String type,int x,int y,long now)` returns String null=success or reason; `move(String id,int x,int y)` same; `upgrade(String id,boolean payElixir,long now)` same; `upgradeProblem(BuildingInstance b,boolean payElixir)`; wall Elixir allowed when TARGET level>=3; busy/cost validation before deduction.
- WallConnectionManager `(GameState)` with `mask(BuildingInstance)` bits 1 east(+x),2 south(+y),4 west(-x),8 north(-y), connected regardless of wall level.

## Renderer API
- CameraController: public float x,y,zoom; `resize(int width,int height)`, `pan(float dx,float dy)`, `zoomAt(float factor,float sx,float sy)`, `home()`, `screenToWorldX(float sx)`, `screenToWorldY(float sy)`; camera transforms use screen = world*zoom+x/y. Bounds clamped; fit reasonable part village at home.
- VillageRenderer `(GameState,CameraController)`; `draw(Canvas c,int width,int height,long now,BuildingInstance selected,BuildingInstance preview,boolean valid)`; `hit(float worldX,float worldY)` returns instance; `drawBuildingPreview(Canvas c,BuildingInstance b,float cx,float cy,float scale)` for shop/loading optional. Cache terrain and building visuals. Render sorting by footprint ground depth; original art, shadows, trees, no debug grid. Preview position owned by placement, never mutate committed instance until confirm.

## Persistence/audio API
- SaveManager `(Context)`; `load(long now)` -> GameState; `save(GameState)` -> boolean; `message` public String for migration/recovery message. Atomic save version 2 with backup and V0.1 SharedPreferences citadel_v01 migration. No deletion of legacy save. Derived capacities/builders/unlocks saved as metadata but recomputed from buildings.
- GameAudio `(Context,GameState)`; `play(String event)`, `startAmbience()`, `pause()`, `resume()`, `applySettings()`, `release()`. Events startup,button,select,place,upgrade,complete,error,collect,levelup,townhall. Own original synthesis.

Root owns MainActivity, VillageView, UIController, TouchController, PlacementManager, LoadingController. Core agent owns model/managers/grid. Renderer agent owns renderer/camera/art. Persistence agent owns save/audio/resources manifest/icon. Tests agent owns Gradle/workflow/tests, coordinating APIs with root. Only citadel_android/ and .github/workflows/build-citadel-apk.yml may change.
