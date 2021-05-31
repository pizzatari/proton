; -----------------------------------------------------------------------------
; Game:     Battle for Proton
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.3 (beta)
; -----------------------------------------------------------------------------
; Treadmill kernel: The rows are pushed downward and the terrain is drawn
; fixed relative to the top of the row. The first and last rows expand and
; shrink in tandem.
;
;       . . . . . . . . . . . . . . .
;       :                           :
;       :                           :
;   Row :___________________________:
;    10 |  screen                   | expander: 16px -> 1px 
;       :___________________________:
;     9 |                           |
;       |___________________________|
;     8 |                           | row: 16px
;       |___________________________|
;     7 |                           |
;       |___________________________|
;     6 |                           |
;       |___________________________|
;     5 |                           |
;       |___________________________|
;     4 |                           |
;       |___________________________|
;     3 |                           |
;       |___________________________|
;     2 |                           |
;       |___________________________|
;     1 :                           :
;       : . . . . . . . . . . . . . : shrinker: 31px -> 16px
;     0 :           /_\             : player
;       :___________________________:
;       |      |             |      | HUD
;       |______|_____________|______|
;       :                           :
;       :                           :
;       . . . . . . . . . . . . . . .
;
; 4 banks (4 KB each):
;   Bank 0:     title & wave kernels
;   Bank 1:		game kernel
;   Bank 2:     game logic
;   Bank 3:     sound data
;
; Each bank has duplicated sections:
;   $*000:      reset handler
;   $*ff6:      bankswitching hot spots
;   $*ffa:      interrupt handlers
; -----------------------------------------------------------------------------
    processor 6502

VIDEO_MODE          SET VIDEO_NTSC 
NO_ILLEGAL_OPCODES  = 1

	include "atarilib.h"
    include "sys/video.h"
    ;include "include/debug.h"
    ;nclude "include/io.h"
    ;include "include/macro.h"
    ;include "include/time.h"
    ;include "include/vcs.h"

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
; F6 bank switching (16KB)
BANK0_ORG           = $1000
BANK0_RORG          = $9000
BANK1_ORG           = $2000
BANK1_RORG          = $b000
BANK2_ORG           = $3000
BANK2_RORG          = $d000
BANK3_ORG           = $4000
BANK3_RORG          = $f000
BANK0_HOTSPOT       = $fff6
BANK1_HOTSPOT       = BANK0_HOTSPOT+1
BANK2_HOTSPOT       = BANK0_HOTSPOT+2
BANK3_HOTSPOT       = BANK0_HOTSPOT+3

RAND_GALOIS8        = 1
RAND_GALOIS16       = 1
RAND_JUMBLE8        = 1

COLOR_BG            = COLOR_DGREEN
COLOR_FG            = COLOR_GREEN
COLOR_HUD_SCORE     = COLOR_WHITE
COLOR_LASER         = COLOR_RED
COLOR_BUILDING      = COLOR_LGRAY
COLOR_ENEMY         = COLOR_ORANGE

MODE_TITLE          = 0
MODE_WAVE           = 1
MODE_GAME_INIT      = 2
MODE_GAME           = 2

FPOINT_SCALE        = 1 ; fixed point integer bit format: 1111111.1

; bounds of the screen
MIN_POS_X           = 23 + 11
MAX_POS_X           = SCREEN_WIDTH - 11

; Max/min speed must be less than half the pattern height otherwise an
; optical illusion occurs giving the impression of reversing direction.
MAX_SPEED_Y         =  7 << FPOINT_SCALE
MIN_SPEED_Y         = -7 << FPOINT_SCALE
MAX_SPEED_X         =  3
MIN_SPEED_X         = -3
ACCEL_Y             =  1
ACCEL_X             =  1
FRICTION            =  1

MAX_ROWS            = 12
MAX_NUM_PTRS        = 6

; Objects
P0_OBJ              = 0
P1_OBJ              = 1
M0_OBJ              = 2
M1_OBJ              = 3
BL_OBJ              = 4

TYPE_ENEMY          = 0
TYPE_BUILDING       = 1
TYPE_ACTION         = 2

LASER_DAMAGE        = 4

TITLE_DELAY         = 38
JOY_DELAY           = 30

RAND_SEED           = $fb11
RAND_JUMBLE         = 1

PF_ROW_HEIGHT       = 16

; -----------------------------------------------------------------------------
; Variables
; -----------------------------------------------------------------------------
    SEG.U RAM
    ORG $80

; Variables global to the all banks
GlobalVars

FrameCtr        ds.b 1
RowNum          ds.w 1              ; row number associated with the bottom row
Mode            ds.b 1
Delay           ds.b 1
SpritePtrs      ds.w MAX_NUM_PTRS
TempPtr         ds.w 1
RandLFSR8       ds.b 1
RandLFSR16		= SpritePtrs
Temp            = TempPtr
Temp2           = TempPtr+1
MemEnd

    ORG MemEnd
; Title vars
LaserPtr        ds.w 1
LaserPF         ds.c 6

    ORG MemEnd
; Game vars 
Status          ds.b 1
ST_NORM         = 0
ST_ALERT        = 1

; screen motion
ScreenPosY      ds.b 1
ScreenSpeedY    ds.b 1

; player data
PlyrSpeedX      ds.b 1
PlyrPosX        ds.b 1
PlyrLife        ds.b 1          ; [Lives, Shields] 
PL_LIVES_MASK   = %00111000
PL_SHIELDS_MASK = %00000111
PlyrLaser       ds.b 1
PlyrScore       ds.b 3          ; BCD in MSB order
PlyrFire        ds.b 1

; enemy data
SprType0        ds.b MAX_ROWS   ; GRP0: lo byte is gfx and sprite type
SprType1        ds.b MAX_ROWS   ; GRP1: lo byte is gfx and sprite type
SprSpeedX0      ds.b MAX_ROWS
SprPosX0        ds.b MAX_ROWS
SprLife0        ds.b MAX_ROWS   ; enemy HP: hit points and color
SprFire0        ds.b 1          ; row number of attacking enemy
SprFire1        ds.w 1          ; bitmask: bit position is the attacking row

; RandLFSR8 bits
SPR_CONTINUE    = %01110000
SPR_ATTACK0     = %00000111
SPR_ATTACK1     = %00001110
SPR_RETREAT     = %10000000

LaserAudioFrame ds.b 1

CurrRow         ds.b 1
P0Ptr           ds.w 1
P1Ptr           ds.w 1
BotPtr          ds.w 1

LocalVars       ds.b 4
TempColor       = LocalVars+1
EndLine         = LocalVars+1
PlyrIdx         = LocalVars+2
HUDHeight       = LocalVars+1

    RAM_BYTES_USAGE

    SEG rom
PAGE_CURR_BANK SET 0
    include "bank0/bank0.asm"

PAGE_CURR_BANK SET 1
    include "bank1/bank1.asm"

PAGE_CURR_BANK SET 2
    include "bank2/bank2.asm"

PAGE_CURR_BANK SET 3
    include "bank3/bank3.asm"
