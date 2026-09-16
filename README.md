# E-Sport Empire

**Alpha v0.4.6 — Competitive Core Loop**

A portrait-first Android esports career and organization game built with Godot 4. Start with zero cash, zero fans and only yourself as captain, then grow from solo ranked matches into a real esports organization.

## Current playable systems

- Origin-story start: €0, 0 fans, 0 reputation and one captain
- Independent Rocket League 1v1, 2v2 and 3v3 ratings with ten-match placements
- All three ladders now seed at 100 MMR; existing v0.4.5 progress is rebased without deleting earned/lost points
- Interactive Rocket League matches with six tactical reads, meaningful counter-calls and limited overtime
- Full Bronze-to-SSL tier/division system with original scalable rank emblems
- Competitive overview with record, winrate, streak, peaks, Last 10 and MMR graph
- ALL RANKS/MMR tables plus Top 12 and Around You simulated ladders
- Ranked changes only from win/loss and opponent MMR: roughly ±9–11 normally and ±20–30 in placements
- Rebuilt post-match flow with MMR before/after, rank transitions, promotions, demotions and rank reveals
- Dynamic ranked situations including smurfs, boosted players, peaking players and returning players
- PulseLive streaming with optional paid creator plans, live chat, viewers, followers and post-stream comments
- Opponents and other players can notice you and become future teammates
- Small community cups provide the first realistic prize-money path
- Player training, form, potential and fatigue with three-week training/recovery cooldowns
- Amateur scouting and progressively priced facilities
- Sponsors unlock only after enough reputation and audience growth
- Local JSON savegame with non-destructive v0.4.5 → v0.4.6 MMR and cooldown migration
- Mobile portrait UI with screen-wide swipe scrolling, safer release buttons and word-safe wrapping
- Unchanged Android package ID and persistent update-signing workflow

## Run locally

Open `project.godot` in Godot 4.4 or newer and press Run Project.

## Android build

Every push to `main` starts the Android workflow. The resulting debug APK is available as the `E-Sport-Empire-Android` workflow artifact. Debug builds are installable for testing and do not require a private signing key.

## Project status

This is an early playable alpha. Balancing and presentation will continue to evolve while saves remain compatible.
