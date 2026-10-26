; ===================================================================
; DATA
; ===================================================================
StrPlay     db 'Playing',0
StrLost     db 'BOOM!',0
StrWin      db 'You win!',0
StrClsTank  db 'TANK',0
StrClsMage  db 'MAGE',0
StrClsArtificer db 'ARTIFICER',0
StrClsNone  db '-',0
StrRewardTitle db 'BOARD CLEARED!',0
StrRewardSuffix db ' SHRAPNELS',0
StrRewardHint db 'R: NEW GAME',0
StrShield   db 'SHIELD!',0
StrScanned  db 'SCANNED!',0
StrNoScan   db 'NO SCANS',0
StrArmed    db 'ARMED!',0
StrShldOn   db 'SHIELD ON',0
StrShldOff  db 'NO SHIELD',0
StrScanOn   db 'SCAN RDY',0
StrScanOff  db 'SCAN USED',0
StrScanHint db 'S + click',0
StrBombGet  db 'BOMB +1',0
StrBombUsed db 'BOMBED!',0
StrNoBombs  db 'NO BOMBS',0
StrBombReady db 'BOMB RDY',0
StrBombs    db 'BOMBS: 0',0
StrArtItems db '2X MULT',0

; New Kit & Potion messages
StrOracleFound  db 'SAFE!',0
StrRowSwept     db 'SWEPT!',0
StrMineFlagged  db 'FLAGGED!',0
StrNoPotions    db 'NO STOCK',0
StrRadarArmed   db 'ROW RDY',0

; Compact HUD (wide boards, no room for the sidebars)
StrHudLvl       db 'LVL ',0
StrHudShr       db 'SHR:',0

; Level names
StrLvl1  db 'Gentle Start',0
StrLvl2  db 'Novice',0
StrLvl3  db 'Beginner',0
StrLvl4  db 'Apprentice',0
StrLvl5  db 'Intermediate',0
StrLvl6  db 'Skilled',0
StrLvl7  db 'Advanced',0
StrLvl8  db 'Expert',0
StrLvl9  db 'Master',0
StrLvl10 db 'Legend',0

; Level Table: cols (byte), rows (byte), mines (word), name (word)
LevelTable:
    db 6,  6
    dw 3,   StrLvl1
    db 8,  8
    dw 7,   StrLvl2
    db 9,  9
    dw 10,  StrLvl3
    db 10, 10
    dw 14,  StrLvl4
    db 12, 12
    dw 21,  StrLvl5
    db 16, 12
    dw 30,  StrLvl6
    db 16, 16
    dw 42,  StrLvl7
    db 24, 14
    dw 58,  StrLvl8
    db 30, 16
    dw 90,  StrLvl9
    db 30, 20
    dw 120, StrLvl10

StrGridLvl1:  db '6x6 grid',0
StrGridLvl2:  db '8x8 grid',0
StrGridLvl3:  db '9x9 grid',0
StrGridLvl4:  db '10x10 grd',0
StrGridLvl5:  db '12x12 grd',0
StrGridLvl6:  db '16x12 grd',0
StrGridLvl7:  db '16x16 grd',0
StrGridLvl8:  db '24x14 grd',0
StrGridLvl9:  db '30x16 grd',0
StrGridLvl10: db '30x20 grd',0

StrMinesLvl1:  db '3 mines',0
StrMinesLvl2:  db '7 mines',0
StrMinesLvl3:  db '10 mines',0
StrMinesLvl4:  db '14 mines',0
StrMinesLvl5:  db '21 mines',0
StrMinesLvl6:  db '30 mines',0
StrMinesLvl7:  db '42 mines',0
StrMinesLvl8:  db '58 mines',0
StrMinesLvl9:  db '90 mines',0
StrMinesLvl10: db '120 mines',0

LvlGridTab:
    dw StrGridLvl1, StrGridLvl2, StrGridLvl3, StrGridLvl4, StrGridLvl5
    dw StrGridLvl6, StrGridLvl7, StrGridLvl8, StrGridLvl9, StrGridLvl10

LvlMinesTab:
    dw StrMinesLvl1, StrMinesLvl2, StrMinesLvl3, StrMinesLvl4, StrMinesLvl5
    dw StrMinesLvl6, StrMinesLvl7, StrMinesLvl8, StrMinesLvl9, StrMinesLvl10

; Victory Menu strings
StrVicTitle     db '*** LEVEL CLEARED! ***',0
StrVicLvlPrefix db 'LEVEL ',0
StrVicBase      db 'BASE REWARD:      +',0
StrVicShrap     db ' SHRAPNELS',0
StrVicArtBonus  db 'ARTIFICER 2X BONUS ACTIVE!',0
StrVicEarned    db 'SHRAPNELS GAINED: +',0
StrVicBalance   db 'BALANCE: ',0
StrVicOptA      db '[1] CONTINUE (NEXT LEVEL)',0
StrVicOptB      db '[2] ITEM SHOP (POTIONS)',0
StrVicOptC      db '[3] LEVEL SELECT',0
StrVicPrompt    db 'PRESS 1, 2 OR 3',0
StrVicUnlocked  db ' UNLOCKED!',0
StrVicAllBeaten db 'ALL 10 LEVELS BEATEN!',0

; Level select strings
StrLsTitle      db 'E N D L E S S   M O D E',0
StrLsSub        db 'SELECT A LEVEL',0
StrLsHint       db 1Bh,' ',1Ah,' MOVE  ENTER/CLICK PLAY  ESC MENU',0
StrLsDash       db ' - ',0
StrLsLocked     db 'LOCKED',0
StrLsBeat       db 'BEAT LEVEL ',0
StrLsToUnlock   db ' TO UNLOCK',0
StrLsGrid       db ' GRID   ',0
StrLsMines      db ' MINES',0
StrLsStillLock  db 'THAT LEVEL IS STILL LOCKED!',0
StrLsProgress   db 'UNLOCKED: ',0
StrLsOf10       db ' / 10',0

; Level select box icons (rects relative to the 44x40 box)
IconPlay    db 18,25,2,11,1, 20,26,2,9,1, 22,27,2,7,1, 24,28,2,5,1
            db 26,29,2,3,1, 0FFh
IconCheck   db 15,29,3,3,2, 18,32,3,3,2, 21,29,3,3,2, 24,26,3,3,2
            db 27,23,3,3,2, 0FFh
IconLock    db 19,24,6,2,7, 18,25,2,4,7, 24,25,2,4,7, 16,29,12,8,7
            db 21,31,2,3,8, 0FFh

; Skill panel (left sidebar): 3 lines of <= 9 chars, '|' separates lines
SkNone      db 'No class:|plain|sweeping.',0
SkTankOn    db 'Shield up|stops one|mine.',0
SkTankOff   db 'Shield|used; new|next lvl.',0
SkMageRdy   db 'S + click|flags all|mines 3x3',0
SkMageArm   db 'Scan|ARMED -|click!',0
SkMageUsed  db 'Scan used|up for|this run.',0
SkArt       db 'Passive:|2x every|Shrapnel.',0

; Last-use log: 4 lines of <= 9 chars; '#' is replaced by [EventNum]
EvDefault   db 'Skills &|potions|you use|show here',0
EvShield    db 'SHIELD!|Blast was|blocked &|flagged.',0
EvScanArmed db 'SCAN|ARMED:|click a|tile.',0
EvScan      db 'SCANNED!|Mines in|3x3: #|flagged.',0
EvScanFirst db 'SCAN|Open one|tile then|press S.',0
EvNoScan    db 'NO SCAN|Scan is|used up|this run.',0
EvBombGet   db 'BOMB +1|Found a|bomb! Use|B + click',0
EvBombArmed db 'BOMB|ARMED:|click a|tile.',0
EvBombUsed  db 'BOOM!|Bomb|opened #|tiles.',0
EvNoBombs   db 'NO BOMBS|Open item|tiles to|get some.',0
EvCancel    db 'CANCELLED',0
EvOracle    db 'ORACLE|Revealed|# safe|tile(s).',0
EvRadarArm  db 'RADAR|ARMED:|click a|row.',0
EvRadar     db 'SWEPT!|Row open.|Flagged|mines: #',0
EvDetector  db 'DETECTOR|A hidden|mine was|flagged.',0
EvNoPotion  db 'NO STOCK|Buy more|in the|shop.',0
EvTimeUp    db 'TIME UP!|The clock|hit zero.|You lose.',0
EvArtBonus  db 'ARTIFICER|doubled|it: +#|Shrapnel',0

; Item Shop strings
StrShopTitle    db '*** ITEM SHOP (10 SHRAPNELS) ***',0
StrShopBal      db 'SHRAPNELS: ',0
StrShopItm1     db '[1] ORACLE SIGHT',0
StrShopItm2     db '[2] LINE RADAR',0
StrShopItm3     db '[3] MINE DETECTOR',0
StrShopQty      db 'QTY:',0
StrShopNext     db '[4] NEXT LEVEL',0
StrShopDesc1    db 'Reveals one safe tile',0
StrShopDesc2    db 'Sweeps row: open safe, flag mines',0
StrShopDesc3    db 'Auto-flags first covered mine',0
StrShopPrompt   db '1-3 BUY (10 EACH)   4 NEXT LEVEL',0
StrShopNeed     db 'NOT ENOUGH SHRAPNEL! (NEED 10)',0
StrShopBuy1     db 'BOUGHT ORACLE SIGHT!',0
StrShopBuy2     db 'BOUGHT LINE RADAR!',0
StrShopBuy3     db 'BOUGHT MINE DETECTOR!',0
StrShopMax      db 'CARRYING THE MAX (99)!',0

; Game Over strings
StrGoTitle      db '*** GAME OVER ***',0
StrGoMine       db 'YOU HIT A MINE!',0
StrGoEndless    db 'ENDLESS RUN TERMINATED',0
StrGoLvl        db 'RUN ENDED AT LEVEL ',0
StrGoPrompt     db 'PRESS ANY KEY FOR LEVELS',0

PalGrays    db 48,48,48, 32,32,32
PalNums     db 0,0,63,  0,32,0,  63,0,0,  0,0,32
            db 32,0,0,  0,32,32, 0,0,0,   32,32,32
NumColors   db 52,53,54,55,56,57,58,59

; 3x5 font, digits 0..9, one byte per row (bits 2..0 = pixels)
Font3x5     db 7,5,5,5,7        ; 0
            db 2,6,2,2,7        ; 1
            db 7,1,7,4,7        ; 2
            db 7,1,7,1,7        ; 3
            db 5,5,7,1,1        ; 4
            db 7,4,7,1,7        ; 5
            db 7,4,7,5,7        ; 6
            db 7,1,2,2,2        ; 7
            db 7,5,7,5,7        ; 8
            db 7,5,7,1,7        ; 9

; 16x16 Flag sprite = list of rectangles: x, y, w, h, colour  (0FFh terminates)
FlagRects   db 6,3,1,1,12       ; red pennant
            db 5,4,2,1,12
            db 4,5,3,1,12
            db 3,6,4,1,12
            db 4,7,3,1,12
            db 5,8,2,1,12
            db 6,9,1,1,12
            db 7,3,2,9,0        ; pole
            db 5,11,6,1,0       ; base
            db 3,12,10,2,0
            db 0FFh

; 8x8 Flag sprite
FlagRects8  db 3,1,2,1,12
            db 2,2,3,1,12
            db 3,3,2,1,12
            db 4,1,1,5,0
            db 2,6,5,1,0
            db 0FFh

; 16x16 Mine sprite
MineRects   db 5,4,6,1,0
            db 4,5,8,6,0
            db 5,11,6,1,0
            db 2,7,12,2,0
            db 7,2,2,12,0
            db 3,3,2,2,0
            db 11,3,2,2,0
            db 3,11,2,2,0
            db 11,11,2,2,0
            db 5,5,2,2,15       ; glint
            db 0FFh

; 8x8 Mine sprite
MineRects8  db 2,2,4,4,0
            db 1,3,6,2,0
            db 3,1,2,6,0
            db 3,2,1,1,15
            db 0FFh

FaceDisc    db 5,0,6,1,14
            db 3,1,10,1,14
            db 2,2,12,1,14
            db 1,3,14,10,14
            db 0,5,16,6,14
            db 2,13,12,1,14
            db 3,14,10,1,14
            db 5,15,6,1,14
            db 0FFh

FaceHappy   db 4,5,2,3,0
            db 10,5,2,3,0
            db 4,9,1,1,0
            db 11,9,1,1,0
            db 5,10,6,1,0
            db 0FFh

FaceDead    db 3,4,1,1,0        ; X eyes
            db 5,4,1,1,0
            db 4,5,1,1,0
            db 3,6,1,1,0
            db 5,6,1,1,0
            db 10,4,1,1,0
            db 12,4,1,1,0
            db 11,5,1,1,0
            db 10,6,1,1,0
            db 12,6,1,1,0
            db 5,10,6,1,0       ; frown
            db 4,11,1,1,0
            db 11,11,1,1,0
            db 0FFh

FaceCool    db 2,4,5,3,0        ; sunglasses
            db 9,4,5,3,0
            db 7,4,2,1,0
            db 3,5,1,1,15
            db 10,5,1,1,15
            db 4,9,1,1,0
            db 11,9,1,1,0
            db 5,10,6,1,0
            db 0FFh
