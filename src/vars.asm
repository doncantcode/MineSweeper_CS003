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
Board       times MAX_CELLS db 0
ItemTilesLeft db 0

; Grid configuration (dynamic)
CurCols     db 9
CurRows     db 9
CurMines    dw 10
CurCells    dw 81
StartX      dw 88
StartY      dw 45
TileSize    db 16
HeaderX     dw 86
HeaderY     dw 8
HeaderW     dw 148
WinX        dw 81
WinY        dw 3
WinW        dw 158
WinH        dw 193

; Selected game mode: 0 vanilla, 1 endless, 2 rapid
CurrentMode db 0

; Endless mode state
CurrentLevel    db 1
MinesPlaced     db 0
FirstRow        db 0
FirstCol        db 0
EarnedShrapnel  dw 0
BaseShrapnel    dw 0
EndlessState    db 0            ; 0 = playing, 1 = victory menu, 2 = item shop, 3 = game over, 4 = level select
ShopMsg         db 0

; Endless level progression (persisted in MINESW.SAV)
UnlockedLevel   db 1            ; highest playable level 1..10 (11 = all beaten)
LevelSel        db 0            ; highlighted box on the level select (0..9)
LsIdx           db 0            ; scratch: box being drawn
JustUnlocked    db 0            ; level unlocked by the last win (0 = none)

; Skill / potion log shown in the left sidebar
EventPtr        dw 0            ; text of the last skill / potion event (0 = none)
EventNum        dw 0            ; value substituted for '#' in that text
LineBuf         times 16 db 0

; Run inventory potions
PotionOracle    db 0
PotionRadar     db 0
PotionDetector  db 0
RadarArmed      db 0

; Permanent progression
Shrapnels       dw 0
OwnedClasses    db 0            ; bits 0-2: Tank, Mage, Artificer
ProgressError   db 0            ; save/load failure shown in menus
ProgressLoaded  db 0
SaveHandle      dw 0
LoadValid       db 0
SaveBuffer      times SAVE_SIZE db 0
SaveFile        db 'MINESW.SAV',0

; Character kit: 1 tank, 2 mage, 3 artificer
SelectedClass   db 0
TankShield      db 0            ; blasts left to absorb this level
MageScans       db 0            ; scans left this session
ScanArmed       db 0            ; S armed: next click scans a 3x3
BombCount       db 0            ; picked-up bombs available this board
BombArmed       db 0            ; B armed: next click drops a 3x3 bomb
KitMsgN         db 0            ; transient status message id
KitMsgT         db 0            ; ticks (seconds) left to show it

; Text menu state: intro shown only on first boot
IntroShown      db 0

; Menu music state
MenuMusicOn     db 1
MenuMusicPtr    dw track3
MenuNoteLeft    dw 0

; Number formatting scratch buffer
NumStrBuf       times 8 db 0
RewardBuf       times 24 db 0

; Mode 13h text renderer (see PrintAt)
TextBg          db 0FFh         ; 0FFh = sidebar gradient, else solid colour
TxtFg           db 0
TxtRowBg        db 0
TxtY            dw 0
FontOff         dw 0
FontSeg         dw 0
GlyphBuf        times 8 db 0
Spaces40        times 40 db ' '
                db 0

; Stack pointer at program entry (restored when leaving a game)
StackTop        dw 0

; Self-test mode flag
TestMode        db 0
