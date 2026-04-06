# D4RTS — AI Build Instructions

> **Goal:** Build a complete Flutter darts scoring & tournament app from scratch.
> This file is the single source of truth for an AI coding agent to implement the project.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Environment](#2-tech-stack--environment)
3. [Project Structure](#3-project-structure)
4. [Data Models](#4-data-models)
5. [Core Game Logic](#5-core-game-logic)
6. [Screens & Navigation](#6-screens--navigation)
7. [Scoring Input](#7-scoring-input)
8. [Statistics (PDC-style)](#8-statistics-pdc-style)
9. [Game Modes](#9-game-modes)
10. [Import / Export](#10-import--export)
11. [Settings & Persistence](#11-settings--persistence)
12. [CI / CD](#12-ci--cd)
13. [Testing](#13-testing)
14. [Implementation Order](#14-implementation-order)
15. [Appendix — Base Requirements](#appendix--base-requirements)

---

## 1. Project Overview

**D4RTS** is a steel-darts companion app that tracks scoring, legs, sets, and tournaments. It targets **Web** (GitHub Pages) and **Android** (APK release). The app is fully offline-capable — all data lives on-device via local storage.

Key user journeys:

| Journey | Description |
|---------|-------------|
| Quick Vs Game | Add 2+ players → configure options → play legs → view result |
| Tournament | Add players → group stage (round-robin) → tiebreakers → knockout (all places played out) → final standings |
| Stats Review | Filter by today / overall, view PDC-style stats per player |
| Data Transfer | Export game history as JSON → import on another device |

---

## 2. Tech Stack & Environment

| Concern | Choice |
|---------|--------|
| Framework | Flutter (stable channel, latest) |
| Language | Dart (SDK ^3.11.0) |
| State management | `provider` (or `riverpod` — pick one, stay consistent) |
| Local persistence | `shared_preferences` for settings, `sqflite` (+ `sqflite_common_ffi_web` for web) or `hive` for game/stats data |
| Serialization | `json_serializable` + `build_runner` |
| Testing | `flutter_test`, `mockito` |
| Linting | `flutter_lints` (same as teamup) |
| Platforms | Web, Android |

### Flutter project init

```bash
flutter create --org com.d4rts --platforms web,android d4rts
```

---

## 3. Project Structure

Follow the same layout conventions used in the sibling `teamup` project:

```
lib/
├── main.dart                  # App entry, theme, routing
├── app_state.dart             # Global app state / providers
├── models/
│   ├── player.dart            # Player identity (unique name)
│   ├── dart_throw.dart        # Single throw value object
│   ├── turn.dart              # A turn = up to 3 throws
│   ├── leg.dart               # One leg of a game
│   ├── game.dart              # Full game (multiple legs)
│   ├── match.dart             # A match between two players (used in tournament)
│   ├── tournament.dart        # Tournament bracket / groups
│   └── player_stats.dart      # Aggregated statistics per player
├── screens/
│   ├── home_screen.dart       # Main menu
│   ├── game_setup_screen.dart # Player entry, options
│   ├── game_screen.dart       # Active game scoring
│   ├── game_result_screen.dart# Post-game summary
│   ├── tournament_setup_screen.dart
│   ├── tournament_bracket_screen.dart
│   ├── stats_screen.dart      # Statistics with filters
│   ├── settings_screen.dart   # App settings
│   └── import_export_screen.dart
├── services/
│   ├── game_service.dart      # Game logic controller
│   ├── stats_service.dart     # Stat calculation
│   ├── storage_service.dart   # Persistence layer
│   ├── tournament_service.dart# Tournament bracket generation & progression
│   └── import_export_service.dart
├── utils/
│   ├── dart_input_parser.dart # Parse shorthand like "T20", "D17", "25"
│   ├── checkout_tables.dart   # Known checkout combinations
│   └── constants.dart         # Default values, enums
├── widgets/
│   ├── dartboard_input.dart   # Visual dartboard matrix input
│   ├── score_display.dart     # Player score card
│   ├── throw_input_field.dart # Text-based throw input
│   ├── player_list_tile.dart
│   └── bracket_view.dart      # Visual tournament bracket
test/
├── models/
├── services/
├── utils/
│   └── dart_input_parser_test.dart
└── widget_test.dart
```

---

## 4. Data Models

### 4.1 `Player`

```dart
class Player {
  final String name; // unique identifier — case-insensitive equality
}
```

### 4.2 `DartThrow`

Represents a **single** dart throw.

```dart
enum ThrowMultiplier { single, double, triple }

class DartThrow {
  final int baseValue;           // 0–20, or 25
  final ThrowMultiplier multiplier;

  int get score => baseValue * multiplier.index + baseValue; // simplified — compute properly
  bool get isBull => baseValue == 25;
  bool get isDouble => multiplier == ThrowMultiplier.double;
  bool get isTriple => multiplier == ThrowMultiplier.triple;
  // A miss is baseValue=0, multiplier=single
}
```

**Valid values:**
- `0` (miss)
- `1`–`20` as single, double, triple
- `25` as single (outer bull) or double (bullseye / double bull)
- Triple 25 does **not** exist on a real dartboard → reject it

### 4.3 `Turn`

```dart
class Turn {
  final List<DartThrow> darts; // 1–3 darts (can be fewer if player checks out or busts)
  int get totalScore => darts.fold(0, (s, d) => s + d.score);
}
```

### 4.4 `Leg`

```dart
class Leg {
  final int startingScore;         // e.g. 501
  final CheckoutMode checkoutMode;
  final Map<Player, List<Turn>> turns;
  Player? winner;
}
```

### 4.5 `Game`

```dart
class Game {
  final String id;               // UUID
  final DateTime startedAt;
  final List<Player> players;
  final int startingScore;       // 301 / 501 / 701
  final Map<Player, int> handicaps; // additional points added to starting score
  final int legsToWin;
  final CheckoutMode checkoutMode;
  final List<Leg> legs;
  Player? winner;
}
```

### 4.6 `CheckoutMode` enum

```dart
enum CheckoutMode {
  straightOut,  // Any dart can finish
  doubleOut,    // Must finish on a double
  tripleOut,    // Must finish on a triple
  masterOut,    // Must finish on a double or triple
}
```

### 4.7 `Tournament`

```dart
class Tournament {
  final String id;
  final DateTime createdAt;
  final List<Player> players;
  final int numberOfGroups;
  final List<TournamentGroup> groups;
  final List<KnockoutRound> knockoutRounds;
  final List<Player> finalStandings; // ordered 1st → last
  // game settings (startingScore, legsToWin, checkoutMode)
}

class TournamentGroup {
  final List<Player> players;
  final List<Game> matches; // round-robin
  final List<Player> standings; // ordered by wins, then leg diff
}

class KnockoutRound {
  final String name; // "Quarter Finals", "Semi Finals", "Final", "3rd Place"...
  final List<Game> matches;
}
```

---

## 5. Core Game Logic

### 5.1 Scoring flow

1. A **turn** consists of up to **3 darts**.
2. After each dart, compute the remaining score for the active player.
3. **Bust rules:** if the remaining score goes below 0, or equals exactly 1 (in double-out, since no double scores 1), or reaches 0 without satisfying the checkout mode → the turn is void and the score resets to what it was before the turn.
4. **Checkout validation:** when remaining == 0 after a dart:
   - `straightOut` → always valid
   - `doubleOut` → last dart must be a double (including D25 / bullseye)
   - `tripleOut` → last dart must be a triple
   - `masterOut` → last dart must be a double or triple
5. If valid checkout → player wins the leg.
6. If player has won enough legs (`legsToWin`) → player wins the game.

### 5.2 Handicap

A player's effective starting score = `startingScore + handicap`. E.g. 501 + 100 = 601. This gives weaker players more points to throw down, equalizing the match.

### 5.3 Turn order

Players throw in the order they were added. The starting player alternates each leg (standard darts convention).
In Tournament mode, the starting player for each game is measured with a throw to the bullseye. Nearer starts the Game. The starting player alternates each leg.

---

## 6. Screens & Navigation

Use `Navigator 2.0` (or `go_router`) for routing. Main flow:

```
Home
 ├── Vs Mode → Game Setup → Game (active) → Game Result
 ├── Tournament → Tournament Setup → Tournament Bracket → (individual games) → Final Standings
 ├── Statistics
 ├── Import / Export
 └── Settings
```

### 6.1 Home Screen

- App title/logo
- Four main buttons: **Vs Mode**, **Tournament**, **Statistics**, **Settings**
- Optional: Import/Export accessible from an icon or the Settings screen

### 6.2 Game Setup Screen

- Add players by name (text field + add button). Show list of added players.
- For each player: optional handicap input (dropdown or number picker: 0, 50, 100, 150, 200).
- Starting score selector: **301 / 501 / 701** (default from settings, override per game).
- Legs to win selector: 1, 2, 3, 5, 7 (default from settings).
- Checkout mode selector: straight out / double out / triple out / master out (default from settings).
- **Start Game** button (enabled when ≥2 players added).

### 6.3 Game Screen (active scoring)

- Top: display each player's current remaining score prominently (large font, highlight active player).
- Show leg progress (wins per player).
- **Scoring input area** — see [Section 7](#7-scoring-input).
- **Undo** button to revert the last turn.
- Show the last 3 turns per player for context.
- **Checkout suggestion:** when a player is on a finishable score (≤170 for double-out), display the recommended checkout combination.

### 6.4 Game Result Screen

- Winner announcement.
- Per-player stats for this game: average per dart, average per turn (3-dart avg), highest turn, checkout %, number of 180s, number of 100+ turns.
- Button to return to home or play again with same settings.

### 6.5 Tournament Setup Screen

- Add players (same as game setup).
- Number of groups selector (default: 2, max: players/2 rounded down).
- Game settings (starting score, legs to win, checkout mode).
- **Generate Bracket** button.

### 6.6 Tournament Bracket Screen

- Visual overview: group stage → knockout stage.
- Tap a match to play it (opens Game Screen).
- After group stage completes → auto-generate knockout bracket.
- Tiebreaker matches generated automatically for tied players within a group.
- Knockout bracket: all places played out (winners bracket + losers bracket for every position).
- When all matches complete → show **Final Standings**.

### 6.7 Stats Screen

- Filter: **Today** (default) / **Overall** / date range.
- Per-player cards showing key stats (see [Section 8](#8-statistics-pdc-style)).
- Sorting/ranking by 3-dart average.

### 6.8 Settings Screen

- Default starting score (301/501/701) — default 501
- Default legs to win — default 1
- Default checkout mode — default double out
- Default number of tournament groups — default 2
- Theme toggle (light/dark) — optional
- Data management: clear all data, import/export shortcut

---

## 7. Scoring Input

Provide **two** input methods the user can toggle between:

### 7.1 Text-based shorthand input

A single text field per dart. The parser (`dart_input_parser.dart`) interprets:

| Input | Meaning | Score |
|-------|---------|-------|
| `20` | Single 20 | 20 |
| `D20` / `d20` | Double 20 | 40 |
| `T20` / `t20` | Triple 20 | 60 |
| `25` | Outer bull (single bull) | 25 |
| `D25` / `d25` | Bullseye (double bull) | 50 |
| `0` | Miss | 0 |
| `1`–`20` | Single 1–20 | face value |
| `D1`–`D20` | Double 1–20 | 2× face |
| `T1`–`T20` | Triple 1–20 | 3× face |

**Validation rules:**
- `T25` is **invalid** (no triple bull on a real board) → show error
- Numbers > 20 (except 25) are **invalid**
- Empty input treated as miss (0)

Display three input slots (dart 1, dart 2, dart 3). Auto-advance focus after valid input. A **Confirm** button submits the turn.

### 7.2 Visual dartboard matrix

A grid/matrix button layout that mirrors dartboard segments:

```
[1 ] [2 ] [3 ] [4 ] [5 ] [6 ] [7 ] [8 ] [9 ] [10]
[11] [12] [13] [14] [15] [16] [17] [18] [19] [20]
[25] [BULL]
────────────────────
[Single] [Double] [Triple]   ← multiplier toggle
[Miss]
```

**Flow:** Select multiplier (default: Single) → tap number → dart is recorded. The multiplier resets to Single after each tap. Show the 3 darts being built up with a **Confirm** and **Clear** action.

> **Note:** `BULL` = D25 (double bull / bullseye). `25` = single bull. Triple is disabled when 25/BULL is selected.

---

## 8. Statistics (PDC-style)

Player names are treated as **unique identifiers** (case-insensitive). All completed games contribute to statistics.

### Key metrics to track:

| Stat | Description | How to compute |
|------|-------------|----------------|
| **3-Dart Average** | Average score per 3-dart turn | Total points scored ÷ total turns |
| **First 9 Average** | Average over the first 3 turns (9 darts) of each leg | Avg of first 9 darts per leg |
| **First 21 Average** | Average over the first 7 turns of each leg | Avg of the first 21 darts per leg |
| **Checkout %** | Percentage of successful checkouts vs attempts | Successful checkouts ÷ turns where remaining was ≤ checkout range |
| **Highest Checkout** | Highest score finished in a single turn | Track per leg |
| **180s** | Number of maximum turns (3× T20) | Count turns where score == 180 |
| **140+** | Turns scoring 140 or more | Count |
| **100+** | Turns scoring 100 or more (includes 140+ and 180s) | Count |
| **Ton-80s per leg** | Average 180s per leg | Total 180s ÷ total legs |
| **Best Leg (darts)** | Fewest darts to win a leg | Track minimum |
| **Worst Leg (darts)** | Most darts to win a leg | Track maximum |
| **Games Played** | Total completed games | Count |
| **Games Won** | Total games won | Count |
| **Win %** | Games won ÷ games played | Percentage |
| **Legs Played** | Total legs across all games | Count |
| **Legs Won** | Total legs won | Count |

### Filters:

- **Today** (default): only games from the current calendar day
- **Overall**: all games ever recorded
- Future nice-to-have: custom date range

### Display:

- Show a ranked list of players sorted by 3-dart average.
- Each player card expands to show all metrics.
- Highlight personal bests.

---

## 9. Game Modes

### 9.1 Vs Mode

Standard mode. 2+ players. One game at a time.

1. Setup: add players, configure game settings → start.
2. Play: scoring screen, one turn at a time, rotating players.
3. Result: show winner + stats → option to rematch or go home.

### 9.2 Tournament Mode

Full tournament bracket supporting any number of players.

#### Group Stage

1. Players are **randomly** distributed into `N` groups (default 2) as evenly as possible.
2. Within each group, every player plays every other player once (**round-robin**).
3. Group standings determined by: **(1) games won → (2) leg difference → (3) 3-dart average**.
4. **Tiebreaker:** if players are still tied after the above criteria, they play a 1v1 tiebreaker match.

#### Knockout Stage

After the group stage, generate a seeded single-elimination bracket:

1. **Seeding:** 1st from Group A vs last from Group B, etc. (cross-group seeding to avoid same-group rematches in early rounds, following standard championship tournament convention).
2. **All places played out:** every loss leads to a placement match. E.g. with 4 players:
   - Semi-final losers play for 3rd/4th place.
   - Semi-final winners play the final for 1st/2nd place.
   
   With 8 players:
   - Quarter-final losers play for 5th–8th (mini bracket).
   - Semi-final losers play for 3rd/4th.
   - Winners play the final.

3. **Equal game count:** ensure every player plays the same total number of matches across the tournament. If a player would have fewer games, add friendly/placement rounds.

#### Final Standings

Display the complete ranked list (1st through last) once all matches are complete.

#### Tournament Algorithm (pseudo-code):

```
1. Shuffle players, split into groups
2. For each group:
     Generate round-robin fixture list
     Play all matches
     Rank players
     Resolve ties with tiebreaker matches
3. Seed knockout bracket from group standings
4. Generate knockout rounds:
     While positions remain unresolved:
       Create matches (winners advance, losers go to placement bracket)
5. Play all knockout matches
6. Compile final standings
```

---

## 10. Import / Export

### Format: JSON

```json
{
  "version": 1,
  "exportedAt": "2026-04-06T14:30:00Z",
  "games": [ /* array of Game objects */ ],
  "tournaments": [ /* array of Tournament objects */ ],
  "settings": { /* current settings snapshot */ }
}
```

### Export

- Serialize all local data to a JSON file.
- Use `share_plus` (or `file_saver`) to trigger the platform share/download dialog.
- Filename: `d4rts_export_YYYYMMDD_HHmmss.json`.

### Import

- Pick a JSON file from device (use `file_picker`).
- Parse and validate the schema.
- Ask user: **Replace** all data or **Merge** (append games, skip duplicates by game ID).
- Show a confirmation summary before applying.

---

## 11. Settings & Persistence

### Defaults persisted via `shared_preferences`:

| Key | Type | Default |
|-----|------|---------|
| `default_starting_score` | int | 501 |
| `default_legs_to_win` | int | 1 |
| `default_checkout_mode` | String | `doubleOut` |
| `default_tournament_groups` | int | 2 |
| `theme_mode` | String | `system` |

### Game & stats data

Use `hive` (or `sqflite`) to store:
- All completed `Game` objects (with full turn-by-turn data).
- All `Tournament` objects.
- Derived stats can be recomputed on the fly from game data, or cached for performance.

---

## 12. CI / CD

Create GitHub Actions workflows in `.github/workflows/`. Mirror the patterns from the sibling `teamup` project:

### 12.1 `test.yml` — Run on PRs to main

```yaml
name: Tests
on:
  pull_request:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter analyze --no-fatal-infos
      - run: flutter test
```

### 12.2 `pages.yml` — Deploy web on push to main

```yaml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: pages
  cancel-in-progress: true
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build web --release --base-href /${{ github.event.repository.name }}/
      - uses: actions/upload-pages-artifact@v3
        with:
          path: build/web
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

### 12.3 `release.yml` — Manual release (APK + Web)

Triggered via `workflow_dispatch`. Builds a signed Android APK and creates a GitHub Release with the artifacts. Mirror the structure from `teamup/.github/workflows/release.yml`.

---

## 13. Testing

### Unit tests (priority)

- `dart_input_parser_test.dart` — every valid/invalid input combination
- `game_service_test.dart` — scoring, bust logic, checkout validation for all modes
- `stats_service_test.dart` — stat computation accuracy
- `tournament_service_test.dart` — group generation, round-robin fixtures, knockout bracket, tiebreakers

### Widget tests

- Game setup screen: player add/remove, option selection
- Scoring screen: input submission, score update, undo
- Dartboard matrix: tap interactions

### Integration tests (nice-to-have)

- Full Vs Mode game flow
- Full Tournament flow

---

## 14. Implementation Order

Build the app in this sequence. Each phase should be **fully working and testable** before moving on.

### Phase 1: Project scaffold
- [ ] `flutter create` with web + android
- [ ] Set up `pubspec.yaml` dependencies
- [ ] Create folder structure
- [ ] Set up linting and analysis options
- [ ] Set up basic routing and home screen

### Phase 2: Core models & logic
- [ ] Implement all data models (Player, DartThrow, Turn, Leg, Game, CheckoutMode)
- [ ] Implement `dart_input_parser.dart` with full test coverage
- [ ] Implement `game_service.dart` (scoring, bust, checkout) with tests
- [ ] Implement checkout suggestion table for double-out (scores ≤170)

### Phase 3: Vs Mode
- [ ] Game Setup screen (add players, configure options)
- [ ] Game Screen with text-based scoring input
- [ ] Dartboard matrix input (alternative)
- [ ] Game Result screen
- [ ] Undo functionality

### Phase 4: Persistence
- [ ] Set up storage service (hive or sqflite)
- [ ] Persist completed games
- [ ] Settings screen + shared_preferences

### Phase 5: Statistics
- [ ] Stats service — compute all PDC metrics from stored games
- [ ] Stats screen with today/overall filter
- [ ] Player ranking display

### Phase 6: Tournament Mode
- [ ] Tournament setup screen
- [ ] Group stage: round-robin generation + play
- [ ] Tiebreaker logic
- [ ] Knockout bracket generation (all places played out)
- [ ] Tournament bracket visualization
- [ ] Final standings display

### Phase 7: Import / Export
- [ ] JSON serialization of all data
- [ ] Export to file
- [ ] Import with replace/merge option

### Phase 8: CI / CD
- [ ] `test.yml` workflow
- [ ] `pages.yml` workflow
- [ ] `release.yml` workflow

### Phase 9: Polish
- [ ] Checkout suggestions on game screen
- [ ] Dark/light theme support
- [ ] Responsive layout for web vs mobile
- [ ] Error handling & edge cases
- [ ] README with screenshots and usage

---

## Appendix — Base Requirements

The following are the original requirements as provided by the user. All sections above are derived from and must satisfy these requirements.

---

### General

The user wants to play darts and this app should make the experience smoother.
All best practices for playing steel darts (what is probably the "standard") should apply.

### Environment

* Flutter with Dart
* Web application and Android APK
* Create web application on commit @ main
* Create Release with APK on new tag

### What the app should deliver

- Start a new game and enter the players who attend
- Game starts for every player at 501 (choose from 301, 501, 701) points (default, configurable in settings)
- For every player there should be an option to give them a handicap (e.g. 100 Points, 200 Points)
- Choose winning legs (default: 1, configurable in settings)
- Choose the checkout modes from: straight out, double out, triple out, master out (default double out, configurable in settings)
- Scoring:
  - Input are the three throws, the app should count the score
    - Use codes to make it easier to input the single throw scores
    - `D` stands for double, `T` stands for triple
    - Examples: `D17` == 34, `T20` == 60, `D25` == 50
    - Valid inputs: 1–20 (with optional D/T prefix), 25 (single bull), D25 (double bull / bullseye)
  - Alternatively: a matrix/grid where touch or mouse input makes entering scores easy
- Import/export feature to exchange results between different instances of the app

### Statistics

- Gather statistics important for darts, oriented on the PDC league system
- Available with filters: today (default), overall
- Player names are unique — every "Daniel" is the same player across all games

### Additional features

#### Vs Mode
- Add players
- Play

#### Tournament Mode
- Add players
- Define how many groups (default: 2)
- In every group, every player plays against every other (round-robin)
- Tied players play a 1v1 tiebreaker
- Generate a knockout bracket with all players
  - Every player should have the same amount of games
  - Every place on the final ladder should be played out
- Example with 4 players (A, B, C, D):
  - Groups: {A, C} and {B, D}
  - Group results: A beats C, D beats B → G1: 1.A 2.C / G2: 1.D 2.B
  - Semi-finals: A vs B (A wins), C vs D (C wins)
  - Finals: A vs C (C wins), B vs D (D wins)
  - Final standings: 1.C, 2.A, 3.D, 4.B
