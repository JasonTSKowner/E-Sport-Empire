# E-Sport Empire

**Alpha v0.5.0 — Career Identity**

A portrait-first Android esports career and organization game built with Godot 4. Start with zero cash, zero fans and only yourself as captain, then grow from solo ranked matches into a real esports organization.

## Current playable systems

- Origin-story start: €0, 0 fans, 0 reputation and one captain
- Ten-level Career Path from Unknown Grinder to Esports Icon with permanent, save-safe XP progression
- Twelve transparent career milestones with exact progress and guaranteed cash/XP rewards
- Three freely switchable Club DNA identities: Relentless Press, Calculated Control and Counter Culture
- Club DNA adds a visible +4 percentage-point scoring bonus to its matching tactical call
- Persistent team chemistry for every division; team matches and instant paid scrims build chemistry
- Chemistry directly affects team strength in 2v2, 3v3 and squad formats while 1v1 remains purely solo
- Persistent Rival Watch with head-to-head records, rivalry tiers and guaranteed fan bonuses for rivalry wins
- Dynamic player archetypes such as Mechanical Finisher, Defensive Anchor, Field General and Clutch Specialist
- Independent Rocket League 1v1, 2v2 and 3v3 ratings with ten-match placements
- All three ladders now seed at 100 MMR; existing v0.4.5 progress is rebased without deleting earned/lost points
- Interactive Rocket League matches with six tactical reads, meaningful counter-calls and limited overtime
- Match decisions display exact score, concede and no-goal percentages before every call
- Full Bronze-to-SSL tier/division system with distinct scalable I/II/III emblem designs
- Prestige-only Title Locker with GC/SSL reward progress and seasonal Top 100, Top 10 and World #1 titles
- Equipped titles appear on the captain profile, roster card and ranked ladder identity
- 2v2 global ladder reaches the current 3002-MMR benchmark while SSL remains open-ended
- Competitive overview with record, winrate, streak, peaks, Last 10 and MMR graph
- ALL RANKS/MMR tables plus Top 12 and Around You simulated ladders
- Ranked changes only from win/loss and opponent MMR: roughly ±9–11 normally and ±20–30 in placements
- Rebuilt post-match flow with MMR before/after, rank transitions, promotions, demotions and rank reveals
- Dynamic ranked situations including smurfs, boosted players, peaking players and returning players
- PulseLive streaming with optional paid creator plans, live chat, viewers, followers and post-stream comments
- Streamed matches can receive occasional virtual viewer donations; donation odds are visible and all revenue stays inside the game economy
- Opponents and other players can notice you and become future teammates
- Free-entry community cups display their exact win chance and provide the first virtual prize-money path
- Eight meaningful player attributes: Mechanics, Rotation, Shooting, Defense, Game Sense, Boost Control, Consistency and Mentality
- Six paid and targeted development programs instead of free random stat clicks
- Instant repeatable training with visible guaranteed gains, price, fatigue and breakthrough chance
- Bronze-to-SSL coaching market with rank emblems, specialties, guaranteed boosts, transparent extra-gain odds and very rare free sessions
- No global energy gate or manual recovery button; player fatigue recovers automatically every real minute, including offline
- Mechanics Arsenal progression from recoveries and aerials through Mustys, resets, Psycho and Triple Reset
- Player attributes directly influence attack, defense, boost, performance variance and overtime composure
- Amateur scouting with visible 90+ potential odds and progressively priced facilities
- Sponsors unlock only after enough reputation and audience growth
- Real device clock in the career header; ranked matches never skip a day or week, while 36 fixtures complete a season
- Local JSON savegame with non-destructive v0.4.5 → v0.5 migration for MMR, career XP, chemistry, rivals, real-time fatigue, coaching, titles, development stats and stream revenue
- Mobile portrait UI with screen-wide swipe scrolling, safer release buttons and word-safe wrapping
- Unchanged Android package ID and persistent update-signing workflow

## Run locally

Open `project.godot` in Godot 4.4 or newer and press Run Project.

## Android build

Every push to `main` starts the Android workflow. The resulting debug APK is available as the `E-Sport-Empire-Android` workflow artifact. Debug builds are installable for testing and do not require a private signing key.

## Project status

This is an early playable alpha. Balancing and presentation will continue to evolve while saves remain compatible.
