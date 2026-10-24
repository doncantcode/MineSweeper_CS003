# MineSweeper

A Minesweeper clone for DOS: NASM, 16-bit `.COM` binary, VGA mode 13h
(320x200x256), mouse-driven through `INT 33h`, with PC-speaker music and
sound effects. A text-mode front end (ASCII intro, main menu, mode selection, shop, and
credits) runs in 80x25 before the game starts.

## Build

```
build.bat
```

Produces `main.com` (and `main.lst`). `build.bat -run` also launches it
in DOSBox. The script finds NASM on `PATH`, falling back to
`%USERPROFILE%\nasm\nasm-<ver>\nasm.exe`.

Manual equivalent:

```
nasm -f bin main.asm -o main.com -l main.lst
nasm -f bin intro.asm -o intro.com
```

Run test suite:

```
main.com /t
```

## Controls

| Input            | Action                       |
| ---------------- | ---------------------------- |
| `1`-`5`          | Menu selection (no Enter)    |
| `M` in Menu      | Toggle Main Menu music on/off |
| Left click       | Open a tile                  |
| Right click      | Place / remove a flag        |
| Click the face   | New game                     |
| `R`              | New game                     |
| `M` in Game      | In-game music and sound on / off |
| `S`              | Mage only: arm the 3x3 scanner (next click scans) |
| `B`, then left click | Use a bomb pickup on the selected tile's 3x3 area |
| `1` / `O`        | Use Oracle's Sight potion (reveals guaranteed safe tile) |
| `2` / `L`        | Arm Line Radar potion (next click on a row sweeps it) |
| `3` / `D`        | Use Mine Detector potion (auto-flags first unflagged mine) |
| `ESC`            | Back to the main menu (Endless: back to the level select) |
| Arrows / Enter / click | Level select: move, play the highlighted level |

The first click is always guaranteed safe with an opening cascade: mines are generated avoiding the clicked cell and its 3x3 neighbourhood (0 adjacent mines).

## Modes

The game boots into an ASCII intro, then the main menu: `[1] Play`
opens class selection, followed by the gamemode submenu; `[2] Hero Shop`
is where you unlock, buy and equip classes with Shrapnels; `[3] Credits`;
`[4] Music: ON/OFF` toggles main menu music; and `[5] Exit to DOS` exits
to DOS. Modes:

| Mode    | Rules                                                                 |
| ------- | --------------------------------------------------------------------- |
| Vanilla | Classic rules; the timer counts up.                                    |
| Endless | Level select of 10 scaled levels: Level 1 starts unlocked, beating Level N unlocks Level N+1. Economy, post-level item shop & potions. |
| Rapid   | The timer starts at 60 and counts down. Hit 0 and the mines are revealed: instant loss. |

The mode is fixed for the session; `R` and the face button restart the board. `ESC` returns to the main menu; only menu option `[5]` leaves to DOS.

## Endless Mode Level Progression

Endless Mode uses a 10-level scaled difficulty curve capped at 20.0% mine density to ensure high logical solvability and smooth progression:

| Level | Name | Grid Size (W × H) | Total Area | Mine Count | Mine Density |
|:---:|:---|:---:|:---:|:---:|:---:|
| 1 | Gentle Start | 6 × 6 | 36 | 3 | 8.3% |
| 2 | Novice | 8 × 8 | 64 | 7 | 10.9% |
| 3 | Beginner | 9 × 9 | 81 | 10 | 12.3% |
| 4 | Apprentice | 10 × 10 | 100 | 14 | 14.0% |
| 5 | Intermediate | 12 × 12 | 144 | 21 | 14.6% |
| 6 | Skilled | 16 × 12 | 192 | 30 | 15.6% |
| 7 | Advanced | 16 × 16 | 256 | 42 | 16.4% |
| 8 | Expert | 24 × 14 | 336 | 58 | 17.3% |
| 9 | Master | 30 × 16 | 480 | 90 | 18.8% |
| 10 | Legend | 30 × 20 | 600 | 120 | 20.0% |

*Note: After Level 10, subsequent stages repeat Level 10 parameters.*

## Endless Game Flow

```
[Main Menu] ──► [Hero Shop] (Select/Upgrade Heroes)
     │
     └──► [Start Endless Run (Level 1)]
               │
               ▼
        [Play Level]
               │
               ├─► Hit Mine ──► [Game Over Screen] ──► [Main Menu]
               │
               └─► Board Cleared ──► [Level Victory Menu]
                                            │
                                            ├──► Option A: [Continue] (Directly load Level N+1)
                                            │
                                            └──► Option B: [Item Shop] (Spend Shrapnel)
                                                                 │
                                                                 └──► [Next Level]
```

## Economy & Hero System

### Currency: Shrapnel
Players earn Shrapnel during Endless runs by clearing tiles, flagging mines, and completing levels.
- **Base Shrapnel on level clear**: `Base_Shrapnel = Cleared_Tiles + (Mine_Count * 2)`
- **Artificer Passive (Shrapnel Multiplication)**: Doubles all Shrapnel earned during gameplay and post-level completion rewards:
  `Earned_Shrapnel = Base_Shrapnel * (Is_Artificer ? 2 : 1)`

### Hero Classes
| Class     | Price | Ability |
| --------- | ----- | ------- |
| Tank      | Free | Absorbs one blast per level: the mine is pinned with a flag instead of game over. |
| Mage      | 10 Shrapnels | Press `S`, then click a tile: every mine in the 3x3 around it is flagged, without stepping on anything. One scan per game. |
| Artificer | 10 Shrapnels | Doubles all Shrapnel earned during gameplay and post-level completion rewards (2x multiplier). |

Currency, class ownership, run state and the highest unlocked Endless level persist in `MINESW.SAV`.

The left sidebar has a **SKILL** panel (your class skill and its current state) and a **LAST USE** log that updates every time a class skill, bomb or potion is used.

## Item Shop & Potions

All consumables cost **10 Shrapnels** each and can be bought in the between-level Item Shop:

| Potion | Cost | Effect | Key |
| --- | :---: | --- | :---: |
| **Oracle’s Sight** | 10 Shrapnel | Instantly highlights / reveals one guaranteed safe tile on current board. | `1` or `O` |
| **Line Radar** | 10 Shrapnel | Target a horizontal row. Safely reveals all safe tiles across that row and auto-flags any mines present. | `2` or `L` |
| **Mine Detector** | 10 Shrapnel | Finds and automatically flags the first unflagged mine on the board, decrementing the mine counter UI. | `3` or `D` |

Purchases are validated to ensure `Shrapnel >= 10`.

## Layout

`main.asm` is the include manifest. Modules are included in **image order**:

| File                  | Contents                                        |
| --------------------- | ----------------------------------------------- |
| `src/macros.inc`      | `HIDEM`/`SHOWM`/`BEVEL`/`TXT` macros and shared constants |
| `src/entry.asm`       | Start, main loop, key handling, restart, self-test mode |
| `src/menu.asm`        | Text-mode intro, main menu, gamemode + hero shop menus |
| `src/progress.asm`    | Shrapnel rewards, class ownership, `MINESW.SAV` persistence |
| `src/credits.asm`     | `show_credits` — team credits screen              |
| `src/palette.asm`     | DAC palette setup (gradient, greys, numbers)     |
| `src/game.asm`        | Level generator, lazy safe opening, potions logic, win check |
| `src/timer.asm`       | Seconds counter on BIOS ticks                    |
| `src/audio.asm`       | Speaker sequencing engine (music + effects)      |
| `src/pcspeaker.asm`   | PIT channel 2 / port 61h hardware layer          |
| `src/input.asm`       | Mouse click handling, potion purchases & arming  |
| `src/video.asm`       | `FillRect`, bevels, sprite lists, glyphs, number printing |
| `src/ui.asm`          | Dynamic board rendering (16x16 & 8x8), HUD, victory/shop modals |
| `src/data.asm`        | Strings, level table, sprites, fonts             |
| `src/music.asm`       | `SongTable` — the looping tune                   |
| `src/sfx.asm`         | `SfxBoom`, `SfxWin`                              |
| `src/vars.asm`        | All mutable variables                            |
| `src/test_suite.inc`  | Built-in verification test suite                 |
