; --- variables ---
MusicOn     db 1
NoteLeft    dw 0
MusicPtr    dw SongTable
SfxOn       db 0
SfxPtr      dw 0
SfxLeft     dw 0
FillCol     db 0
BevTL       db 0
BevBR       db 0
BevFace     db 0
BvX         dw 0
BvY         dw 0
BvW         dw 0
BvH         dw 0
OrgX        dw 0
OrgY        dw 0
CellVal     db 0
CellCol     db 0
GlX         dw 0
GlY         dw 0
GlS         db 0
GlC         db 0
GlBits      db 0
GlRows      db 0
GlCols      db 0
LedVal      dw 0
LedX        dw 0
MouseX      dw 0
MouseY      dw 0
PrevMouse   db 0
GameOver    db 0                ; 0 playing, 1 lost, 2 won
Started     db 0
TimerOn     db 0
Seconds     dw 0
TickAcc     dw 0
LastTick    dw 0
HitCell     dw 0FFFFh
RndSeed     dw 0

; Board: bit0 mine, bit1 opened, bit2 flagged, bit3 hidden item,
;        bits4-7 neighbour count
Board       times CELLS db 0
ItemTilesLeft db 0

; Selected game mode
CurrentMode db 0

; Permanent progression
Shrapnels    dw 0
OwnedClasses db 0                ; bits 0-2: Tank, Mage, Artificer
ProgressError db 0               ; save/load failure shown in menus
ProgressLoaded db 0
SaveHandle   dw 0
LoadValid    db 0
SaveBuffer   times SAVE_SIZE db 0
SaveFile     db 'MINESW.SAV',0

; Character kit: 1 tank, 2 mage, 3 artificer
SelectedClass db 0
TankShield    db 0                ; blasts left to absorb this level
MageScans     db 0                ; scans left this session
ScanArmed     db 0                ; S armed: next click scans a 3x3
BombCount     db 0                ; picked-up bombs available this board
BombArmed     db 0                ; B armed: next click drops a 3x3 bomb
KitMsgN       db 0                ; transient status message id
KitMsgT       db 0                ; ticks (seconds) left to show it

; Text menu state: intro shown only on first boot
IntroShown  db 0
