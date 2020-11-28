; -----------------------------------------------------------------------------
; Game:     Battle for Proton
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.3 (beta)
; -----------------------------------------------------------------------------
; 4 banks (4 KB each):
;   Bank 0:     
;   Bank 1:     
;   Bank 2:     
;   Bank 3:    
;
; Each bank has duplicated sections:
;   $*000:      reset handler
;   $*ff6:      bankswitching hot spots
;   $*ffa:      interrupt handlers
;
    processor 6502

    include "include/vcs.h"
    include "include/macro.h"
    include "include/video.h"
    include "include/time.h"
    include "include/io.h"
    include "include/debug.h"

; -----------------------------------------------------------------------------
; Definitions
; -----------------------------------------------------------------------------
VIDEO_MODE          = VIDEO_NTSC 
RAND_GALOIS8        = 1
RAND_GALOIS16       = 1
RAND_JUMBLE8        = 1

ORG_ADDR            = $f000

COLOR_BG            = COLOR_DGREEN
COLOR_FG            = COLOR_GREEN
COLOR_HUD_SCORE     = COLOR_WHITE
COLOR_LASER         = COLOR_RED
COLOR_BUILDING      = COLOR_LGRAY
COLOR_ENEMY         = COLOR_ORANGE

MODE_TITLE          = 0
MODE_WAVE           = 1
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

; Global vars
FrameCtr        ds.b 1
RowNum          ds.w 1              ; row number associated with the bottom row
Mode            ds.b 1
Delay           ds.b 1
SpritePtrs      ds.w MAX_NUM_PTRS
Ptr             ds.w 1
RandLFSR8       ds.b 1
RandLFSR16      = SpritePtrs
Temp            = Ptr
Temp2           = Ptr+1
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
SprType0        ds.b MAX_ROWS   ; GRP0: encodes gfx and sprite type
SprType1        ds.b MAX_ROWS   ; GRP1: encodes gfx and sprite type
SprSpeedX0      ds.b MAX_ROWS
SprPosX0        ds.b MAX_ROWS
SprLife0        ds.b MAX_ROWS   ; enemy HP: encodes hit points and color
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

; -----------------------------------------------------------------------------
; Macros
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Desc:     Calls the named procedure for the mode.
; Input:    A register (procedure index)
; Param:    table
; Output:
; -----------------------------------------------------------------------------
    MAC CALL_PROC_TABLE 
.PROC   SET {1}
        asl
        tax
        lda .PROC,x
        sta Ptr
        lda .PROC+1,x
        sta Ptr+1
        lda #>[.Return-1]
        pha
        lda #<[.Return-1]
        pha
        jmp (Ptr)
.Return
    ENDM

    SEG rom
    include "bank0/bank0.asm"
    include "bank1/bank1.asm"
    include "bank2/bank2.asm"
    include "bank3/bank3.asm"
