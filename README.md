# MineSweeper

A Minesweeper clone for DOS: NASM, 16-bit `.COM` binary, VGA mode 13h
(320x200x256), mouse-driven through `INT 33h`, with PC-speaker music and
sound effects. A text-mode front end (ASCII intro, main menu, mode
select, credits) runs in 80x25 before the game starts.

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
```

Then, in DOSBox, mount this folder and run `main.com`. Click inside the
DOSBox window so the mouse is captured.

## Controls

| Input            | Action                       |
| ---------------- | ---------------------------- |
| `1`/`2`/`3`/`4`  | Menu selection (no Enter)    |
| Left click       | Open a tile                  |
| Right click      | Place / remove a flag        |
| Click the face   | New game                     |
| `R`              | New game                     |
| `M`              | Music and sound on / off     |
| `ESC`            | Back to the main menu        |

The first click is always safe: if it lands on a mine, the mine is moved
to the first free cell.

## Modes

The game boots into an ASCII intro, then the main menu: `[1] Play`
opens the gamemode submenu, `[2] Credits`, `[3]` exits to DOS. Modes:

| Mode    | Rules                                                                 |
| ------- | --------------------------------------------------------------------- |
| Vanilla | Classic rules; the timer counts up.                                    |
| Endless | Reserved — currently plays like Vanilla.                               |
| Rapid   | The timer starts at 60 and counts down. Hit 0 and the mines are revealed: instant loss. |

The mode is fixed for the session; `R` and the face button start a new
game in the same mode. `ESC` returns to the main menu to pick another
mode; only menu option `[3]` leaves to DOS.

## Layout

`main.asm` is only an include manifest. It declares the shared constants
and `%include`s the modules below **in image order**, so the list in
`main.asm` is the map of the binary.

| File                  | Contents                                        |
| --------------------- | ----------------------------------------------- |
| `src/macros.inc`      | `HIDEM`/`SHOWM`/`BEVEL`/`TXT` macros             |
| `src/entry.asm`       | Start, main loop, key handling, restart          |
| `src/menu.asm`       | Text-mode intro, main menu, gamemode submenu      |
| `src/credits.asm`    | `show_credits` — team credits screen              |
| `src/palette.asm`     | DAC palette setup (gradient, greys, numbers)     |
| `src/game.asm`        | Board state, mine placement, flood fill, win check |
| `src/timer.asm`       | Seconds counter (counts up, or down in Rapid)    |
| `src/audio.asm`       | Speaker sequencing engine (music + effects)      |
| `src/pcspeaker.asm`   | PIT channel 2 / port 61h hardware layer          |
| `src/input.asm`       | Mouse click handling                             |
| `src/video.asm`       | `FillRect`, bevels, sprite lists, glyphs         |
| `src/ui.asm`          | Board, header, face and status rendering         |
| `src/data.asm`        | Strings, palette data, 3x5 font, sprites         |
| `src/music.asm`       | `SongTable` — the looping tune                   |
| `src/sfx.asm`         | `SfxBoom`, `SfxWin`                              |
| `src/vars.asm`        | All mutable variables                            |

Only `pcspeaker.asm` touches the speaker hardware. `audio.asm` is
written against two calls (`SpeakerOn` with the frequency in Hz in `BX`,
and `SpeakerOff`), which is what makes the engine testable.

## Audio

Music and effects share one table format — `dw frequencyHz, durationTicks`
pairs, where `0` Hz is a rest and `0FFFFh` ends the list:

- In `SongTable` the terminator loops back to the start of the tune.
- In `SfxBoom` / `SfxWin` it ends the effect.

Durations are in BIOS timer ticks (18.2 per second). Both effects take
over the speaker, and when the effect finishes the music restarts from
Riff 1. The tune is four riffs over D, C, B and Bb roots, played twice:
once in the base register and once an octave up, then a third pass with
altered tails.
