; ===================================================================
;  MINESWEEPER  (NASM / DOS .COM / VGA mode 13h / INT 33h mouse)
;
;  Build : nasm -f bin main.asm -o main.com     (or: build.bat)
;  Run   : in DOSBox ->  main.com   (click inside the window so the
;          mouse is captured)
;
;  Left click  : open tile          Right click : place / remove flag
;  Click face  : new game           R : new game        ESC : quit
;  B + click   : use a collected 3x3 bomb
;  M           : music on/off (PC speaker)
;
;  This file is only the include manifest.  The code lives in src/,
;  included below in the order the modules are laid out in the .COM
;  image, so keeping this list in order matters.
; ===================================================================
bits 16
org 100h

GRID_COLS   equ 9
GRID_ROWS   equ 9
TOTAL_MINES equ 10
CELLS       equ GRID_COLS*GRID_ROWS
START_X     equ 88
START_Y     equ 45
ITEM_BIT    equ 8
WIN_REWARD  equ 5
TANK_PRICE  equ 10
MAGE_PRICE  equ 15
ART_PRICE   equ 20
SAVE_SIZE   equ 8

%include "src/macros.inc"       ; HIDEM/SHOWM/BEVEL/TXT macros

; --- code ----------------------------------------------------------
; Boot flow: start (text mode) -> MainMenu (intro, credits, gamemode
; and shop) -> VGA mode 13h -> game loop. ESC in game returns to the
; menu; leaving via menu option [4] is the only DOS exit.
%include "src/entry.asm"        ; start, main loop, keys, restart
%include "src/menu.asm"         ; text-mode intro, main menu, mode/shop menus
%include "src/progress.asm"     ; permanent currency, class ownership, save file
%include "src/credits.asm"      ; show_credits: team credits screen
%include "src/palette.asm"      ; DAC palette setup
%include "src/game.asm"         ; board state, mines, reveal, win check
%include "src/timer.asm"        ; seconds counter on BIOS ticks
%include "src/audio.asm"        ; PC speaker engine (music + effects)
%include "src/pcspeaker.asm"    ; PIT / port 61h hardware layer
%include "src/input.asm"        ; mouse click handling
%include "src/video.asm"        ; FillRect/bevel/sprite/glyph primitives
%include "src/ui.asm"           ; board, header, face, status rendering

; --- data ----------------------------------------------------------
%include "src/data.asm"         ; strings, palette data, font, sprites
%include "src/music.asm"        ; SongTable
%include "src/sfx.asm"          ; SfxBoom / SfxWin
%include "src/vars.asm"         ; all mutable variables
