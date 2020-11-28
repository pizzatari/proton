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
;       :  world                    :
;       . . . . . . . . . . . . . . .
;       :                           :
;       . . . . . . . . . . . . . . .
;       :                           :
;       . . . . . . . . . . . . . . .
;       :                           :
;       . . . . . . . . . . . . . . .
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
;       : world                     :
;       . . . . . . . . . . . . . . .
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

; -----------------------------------------------------------------------------
; Rom Begin
; -----------------------------------------------------------------------------
    SEG rom
    ORG ORG_ADDR

Reset
    sei
    CLEAN_START
    jsr TitleInit

FrameStart SUBROUTINE
    inc FrameCtr
    jsr VerticalSync

    lda Mode
    CALL_PROC_TABLE ModeVertBlank

    lda Mode
    CALL_PROC_TABLE ModeKernel

    lda Mode
    CALL_PROC_TABLE ModeOverscan

    jmp FrameStart

VerticalSync SUBROUTINE
    VERTICAL_SYNC
    rts

; -----------------------------------------------------------------------------
; Title code
; -----------------------------------------------------------------------------
TitleInit
    ldx #TITLE_DELAY
    stx Delay
    ldx #$0f
    stx LaserPF
    stx LaserPF+3
    ldx #0
    stx LaserPF+1
    stx LaserPF+2
    stx LaserPF+4
    stx LaserPF+5
    rts

TitleVertBlank SUBROUTINE
    lda #LINES_VBLANK*76/64
    sta TIM64T

    lda #COLOR_WHITE
    sta COLUP0
    lda #0
    sta GRP0
    sta GRP1

    lda #<LaserGfx0
    sta LaserPtr
    lda #>LaserGfx0
    sta LaserPtr+1

    lda FrameCtr
    and #%00001000
    bne .SkipAnim
    lda #<LaserGfx1
    sta LaserPtr
.SkipAnim

    jsr SetTitleBattle

    ldx #P0_OBJ
    lda #19
    jsr HorizPosition
    ldx #P1_OBJ
    lda #19+8
    jsr HorizPosition
    sta WSYNC
    sta HMOVE

    jsr TitleAnimate

    TIMER_WAIT
    sta VBLANK      ; turn on the display
    sta CTRLPF
    rts

TitleKernel SUBROUTINE
    sta WSYNC               ; WSYNC for timing
    lda #COLOR_BLACK        ; 2 (2)
    sta COLUBK              ; 3 (5)
    sta COLUPF              ; 3 (8)

    ; ------------------------------------------------------------------------
    ; blank space
    ; ------------------------------------------------------------------------
    SLEEP_LINES 84          ; 84 (16)

    lda #3
    sta VDELP0              ; 3 (19)
    sta VDELP1              ; 3 (22)
    sta NUSIZ0              ; 3 (25)
    sta NUSIZ1              ; 3 (28)

    lda #COLOR_WHITE        ; 2 (30)
    sta COLUP0              ; 2 (32)
    sta COLUP1              ; 2 (34)

    lda #0                  ; 2 (36)
    sta GRP0                ; 3 (39) 
    sta GRP1                ; 3 (42) 
    sta GRP0                ; 3 (45) 
    lda #$ff                ; 2 (47)
    sta PF0                 ; 3 (50)

    ; ------------------------------------------------------------------------
    ; planet
    ; ------------------------------------------------------------------------
    clc                     ; 2 (52)
    ldy #TITLEPLANET_HEIGHT*4-1     ; 2 (54)
.TitleLoop
    tya                     ; 2 (58)
    lsr                     ; 2 (60)
    lsr                     ; 2 (62)
    sta WSYNC
    tax                     ; 2 (2)
    lda #$ff                ; 2 (4)
    sta PF1                 ; 3 (7)
    sta PF2                 ; 3 (10)
    lda TitlePalette,x      ; 4 (14)
    sta COLUBK              ; 3 (17)
    SLEEP 20                ; 20 (37)
    lda TitlePlanet1,x      ; 4 (41)
    sta PF1                 ; 3 (44)
    lda TitlePlanet2,x      ; 4 (48)
    sta PF2                 ; 3 (51)
    dey                     ; 2 (53)
    cpy #4                  ; 2 (55) 
    bpl .TitleLoop          ; 2 (57)

    ldy #4-1                ; 2 (59)
    jsr DrawTitleSprite     ; 6 (65)    returns on cycle 18

    ; ------------------------------------------------------------------------
    ; 1 (19) line blank spacer
    ; ------------------------------------------------------------------------
    ldy #0                  ; 2 (21)
    sta GRP0                ; 3 (24)
    sta GRP1                ; 3 (27)

    ldx #P0_OBJ             ; 2 (29)
    lda #164                ; 2 (31)
    jsr HorizPositionBG     ; 6 (37)

    lda #0                  ; 2 (20)
    sta NUSIZ0              ; 3 (23)
    sta NUSIZ1              ; 3 (26)
    sta VDELP0              ; 3 (29)
    sta VDELP1              ; 3 (32)
    ldx #COLOR_YELLOW       ; 2 (34)
    sta WSYNC
    sta HMOVE               ; 3 (37) 
    sta PF0                 ; 3 (40)
    sta PF1                 ; 3 (43)
    sta PF2                 ; 3 (46)
    stx COLUPF              ; 3 (49)

    ; ------------------------------------------------------------------------
    ; laser top
    ; ------------------------------------------------------------------------
    ldy #7                  ; 2 (51)
.Laser0
    lda (LaserPtr),y        ; 5 (5)
    sta GRP0                ; 3 (3)
    sta WSYNC
    dey                     ; 2 (5)
    cpy #4                  ; 2 (7)
    bne .Laser0             ; 2 (9)

    ; ------------------------------------------------------------------------
    ; laser middle line
    ; ------------------------------------------------------------------------
    lda (LaserPtr),y        ; 5 (14)
    ldy #0                  ; 2 (16)
    sta GRP0                ; 3 (19)

    lda LaserPF             ; 3 (22)
    ldx LaserPF+1           ; 3 (25)

    sta WSYNC
    sta PF0                 ; 3 (3)
    stx PF1                 ; 3 (6)
    lda LaserPF+2           ; 3 (9)
    sta PF2                 ; 3 (12)

    SLEEP_21                ; 21 (33)
    lda LaserPF+3           ; 3 (36)
    sta PF0                 ; 3 (39)
    lda LaserPF+4           ; 3 (42)
    sta PF1                 ; 3 (45)
    lda LaserPF+5           ; 3 (48)
    sta PF2                 ; 3 (51)

    ; ------------------------------------------------------------------------
    ; laser bottom
    ; ------------------------------------------------------------------------
    ldx #0                  ; 2 (54)
    ldy #3                  ; 2 (56)
.Laser1
    lda LaserGfx0,y         ; 4 (21)
    lda (LaserPtr),y        ; 5 (26)
    sta WSYNC
    sta GRP0                ; 3 (3)
    stx PF0                 ; 3 (6)
    stx PF1                 ; 3 (9)
    stx PF2                 ; 3 (12)
    dey                     ; 2 (14)
    bpl .Laser1             ; 2 (16)

    lda #0                  ; 2 (18)
    sta GRP0                ; 3 (21)

    ; ------------------------------------------------------------------------
    ; PROTON title
    ; ------------------------------------------------------------------------
    clc                     ; 2 (23)
    ldy #TITLEPROTON_HEIGHT-1; 2 (25)
.NameLoop
    tya                     ; 2 (60)
    sta WSYNC
    tax                     ; 2 (2)
    lda TitleNamePalette,x  ; 4 (6)
    sta COLUPF              ; 3 (9)
    lda TitleProton0,x      ; 4 (13)
    sta PF0                 ; 3 (16)
    lda TitleProton1,x      ; 4 (20)
    sta PF1                 ; 3 (23)
    lda TitleProton2,x      ; 4 (27)
    sta PF2                 ; 3 (30)
    nop                     ; 2 (32)
    lda TitleProton3,x      ; 4 (36)
    sta PF0                 ; 3 (39)
    lda TitleProton4,x      ; 4 (43)
    sta PF1                 ; 3 (46)
    lda TitleProton5,x      ; 4 (50)
    sta PF2                 ; 3 (53)
    dey                     ; 2 (55)
    bpl .NameLoop           ; 2 (57)

    ; ------------------------------------------------------------------------
    ; blank space
    ; ------------------------------------------------------------------------
    lda #0                  ; 2 (59)
    sta WSYNC
    sta PF0                 ; 3 (3)
    sta PF1                 ; 3 (6) 
    sta PF2                 ; 3 (9)

    ; ------------------------------------------------------------------------
    ; copyright
    ; ------------------------------------------------------------------------
    ldx #P0_OBJ
    lda #71
    jsr HorizPosition
    ldx #P1_OBJ
    lda #71+8
    jsr HorizPosition
    sta WSYNC
    sta HMOVE

    lda #3
    sta VDELP0
    sta VDELP1
    sta NUSIZ0
    sta NUSIZ1

    lda #$86
    sta COLUP0
    sta COLUP1

    SLEEP_LINES 34

    jsr SetTitleCopy
    ldy #7-1
    jsr DrawWideSprite56

    jsr SetTitleName
    ldy #5-1
    jsr DrawWideSprite56

    lda #0
    sta VDELP0
    sta VDELP1
    sta GRP0
    sta GRP1
    sta NUSIZ0
    sta NUSIZ1

    SLEEP_LINES 2
    rts

TitleOverscan SUBROUTINE
    sta WSYNC
    lda #2
    sta VBLANK

    lda #[LINES_OVERSCAN-1]*76/64
    sta TIM64T

    lda #COLOR_BLACK
    sta COLUBK
    sta COLUPF

    ldx #MODE_WAVE
    jsr GeneralIO
    TIMER_WAIT
    rts

TitleAnimate SUBROUTINE
    lda FrameCtr
    cmp #255
    bne .Anim
    jsr TitleInit
    rts

.Anim
    ; slow down animation speed
    and #1
    bne .Return

    lda Delay
    beq .Return

    sec
    sbc #1
    sta Delay

    sec
    rol LaserPF+0
    ror LaserPF+1
    rol LaserPF+2
    bcc .Return

    rol LaserPF+3
    ror LaserPF+4
    rol LaserPF+5

.Return
    rts

; -----------------------------------------------------------------------------
; Wave code
; -----------------------------------------------------------------------------
WaveInit SUBROUTINE
    lda #JOY_DELAY
    sta Delay
    jsr SpritePtrsClear
    lda #0
    sta GRP0
    sta GRP1
    sta GRP0
    rts

WaveVertBlank SUBROUTINE
    lda #LINES_VBLANK*76/64
    sta TIM64T

    lda #COLOR_BLACK
    sta COLUBK
    sta COLUPF

    lda #COLOR_WHITE
    sta COLUP0
    sta COLUP1

    lda #<WaveText0
    sta SpritePtrs
    lda #<WaveText1
    sta SpritePtrs+2
    lda #<WaveText2
    sta SpritePtrs+4
    lda #<WaveText3
    sta SpritePtrs+6

    lda #>WaveText0
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7

    lda #<Digit0
    sta SpritePtrs+8
    lda #<Digit1
    sta SpritePtrs+10

    lda #>Digits
    sta SpritePtrs+9
    sta SpritePtrs+11

    lda StatusPos0
    ldx #P0_OBJ
    jsr HorizPosition
    lda StatusPos1
    ldx #P1_OBJ
    jsr HorizPosition
    sta WSYNC
    sta HMOVE

    lda #3
    sta VDELP0
    sta VDELP1
    sta NUSIZ0
    sta NUSIZ1

    TIMER_WAIT
    sta VBLANK      ; turn on the display
    sta CTRLPF
    rts

WaveKernel SUBROUTINE
    ldy #96+1
.Top
    sty WSYNC
    dey
    bne .Top

    ldy #DIGIT_HEIGHT-1
    jsr DrawWideSprite56

    ldy #96-DIGIT_HEIGHT
.Bot
    sty WSYNC
    dey
    bne .Bot

    rts

WaveOverscan SUBROUTINE
    sta WSYNC
    lda #2
    sta VBLANK

    lda #[LINES_OVERSCAN-1]*76/64
    sta TIM64T

    lda #0
    sta VDELP0
    sta VDELP1
    sta NUSIZ0
    sta NUSIZ1

    lda Delay
    beq .SkipDec
    dec Delay
    bne .Delay
.SkipDec
    ldx #MODE_GAME
    jsr GeneralIO
.Delay

    TIMER_WAIT
    rts

; -----------------------------------------------------------------------------
; Game code
; -----------------------------------------------------------------------------
GameInit SUBROUTINE
    jsr InitScreen
    jsr InitPlayer
    jsr SpritePtrsClear
    jsr SpawnGroundSprites

    lda #>RAND_SEED
    eor INTIM
    bne .Good
    lda #<RAND_SEED
.Good
    sta RandLFSR8
    lda #JOY_DELAY
    sta Delay
    rts

GameVertBlank SUBROUTINE
    lda #LINES_VBLANK*76/64
    sta TIM64T

    lda #0
    sta GRP0
    sta PF0
    sta PF1
    sta PF2
    sta COLUBK
    sta COLUPF
    sta VDELP0
    sta VDELP1
    sta NUSIZ0
    sta NUSIZ1

    lda #COLOR_BG
    sta COLUBK
    lda #COLOR_FG
    sta COLUPF

    jsr ScreenScroll
    jsr EnemyTurn

    lda #ST_ALERT
    sta Status

    ; top row ID
    lda RowNum
    clc
    adc #MAX_ROWS-1
    sta CurrRow

#if 0
    ; customize spacing
    lda CurrRow
    lsr
    and #3
    sta NUSIZ1
#endif
    lda #3
    sta NUSIZ1

    ; positon sprites
    ldx #P0_OBJ
    lda SprPosX0+MAX_ROWS-1
    jsr HorizPosition
    ldx #P1_OBJ
    lda #76
    jsr HorizPosition
    ldx #M0_OBJ
    lda PlyrPosX
    clc
    adc #4          ; adjust offset
    jsr HorizPosition
    sta WSYNC
    sta HMOVE

    ; enable/disable laser
    lda Delay
    bne .Continue
    lda PlyrFire
    sta ENAM0
    beq .Continue
    stx LaserAudioFrame
    jsr DetectPlayerHit
.Continue

    lda #>BlankGfx
    sta P0Ptr+1
    sta P1Ptr+1
    sta BotPtr+1

    ; setup top row sprite graphics
    lda SprType0+MAX_ROWS-1
    sta P0Ptr
    lda SprType1+MAX_ROWS-1
    sta P1Ptr

    ; setup bottom two sprite graphics
    lda SprType1+1
    sec
    sbc #PF_ROW_HEIGHT
    sta BotPtr
    lda #>BlankGfx
    sbc #0
    sta BotPtr+1

    lda #COLOR_LASER
    sta COLUP0
    lda #COLOR_BUILDING
    sta COLUP1

    ; clear fine motion for subsequent HMOVEs
    lda #0
    sta HMM0
    sta HMP0
    sta HMM1
    sta HMP1

    TIMER_WAIT
    ; turn on the display
    sta VBLANK

    rts

GameOverscan SUBROUTINE
    ; -2 because ShrinkerRowKernel consumes an extra line
    lda #[LINES_OVERSCAN-2]*76/64
    sta TIM64T

    ; turn off display
    sta WSYNC
    lda #2
    sta VBLANK

    lda #COLOR_BLACK
    sta COLUBK
    sta COLUPF

    lda Delay
    beq .SkipDec
    dec Delay
.SkipDec
    bne .Delay

    jsr GameIO
    jsr ShipUpdatePosition
    jsr EnemiesUpdatePosition
    jsr PlayAudio

.Delay
    TIMER_WAIT
    rts

GameIO SUBROUTINE
    lda SWCHB
    and #SWITCH_RESET
    bne .Joystick
    jmp Reset

.Joystick
    lda Delay
    beq .Continue
    rts

.Continue
    ; update every even frame
    lda FrameCtr
    and #1
    bne .CheckMoveX

.CheckRight
    ; read joystick
    ldy SWCHA
    tya
    and #JOY0_RIGHT
    bne .CheckLeft
    lda PlyrSpeedX
    bpl .Dec1           ; instant decceleration on change of direction
    lda #0
.Dec1
    clc
    adc #ACCEL_X
    cmp #MAX_SPEED_X+1
    bpl .CheckLeft
    sta PlyrSpeedX

.CheckLeft
    tya
    and #JOY0_LEFT
    bne .CheckDown
    lda PlyrSpeedX
    bmi .Dec2           ; instant decceleration on change of direction
    lda #0
.Dec2
    sec
    sbc #ACCEL_X
    cmp #MIN_SPEED_X
    bmi .CheckDown
    sta PlyrSpeedX

.CheckDown
    tya
    and #JOY0_DOWN
    bne .CheckUp

    lda ScreenSpeedY
    sec
    sbc #ACCEL_Y
    cmp #MIN_SPEED_Y
    bmi .CheckUp
    sta ScreenSpeedY

.CheckUp
    tya
    and #JOY0_UP
    bne .CheckMoveX

    lda ScreenSpeedY
    clc
    adc #ACCEL_Y
    cmp #MAX_SPEED_Y+1
    bpl .CheckMoveX
    sta ScreenSpeedY

.CheckMoveX
    ; update every eighth frame
    lda FrameCtr
    and #3
    bne .CheckMoveY
    ; deccelerate horizontal motion when there's no input
    tya 
    and #JOY0_LEFT | JOY0_RIGHT
    cmp #JOY0_LEFT | JOY0_RIGHT
    bne .CheckMoveY
    lda PlyrSpeedX
    beq .CheckMoveY
    bpl .Pos1
    clc
    adc #FRICTION
    sta PlyrSpeedX
    jmp .CheckMoveY
.Pos1
    sec
    sbc #FRICTION
    sta PlyrSpeedX

.CheckMoveY
    ; update every 16th frame
    lda FrameCtr
    and #7
    bne .CheckFire
    ; deccelerate vertical motion when there's no input
    tya 
    and #JOY0_UP | JOY0_DOWN
    cmp #JOY0_UP | JOY0_DOWN
    bne .CheckFire
    lda ScreenSpeedY
    beq .CheckFire
    bpl .Pos2
    clc
    adc #FRICTION
    sta ScreenSpeedY
    jmp .CheckFire
.Pos2
    sec
    sbc #FRICTION
    sta ScreenSpeedY

.CheckFire
    lda INPT4
    eor $ff
    and #JOY_FIRE
    clc
    rol
    rol
    rol
    sta PlyrFire

.Return
    rts

InitScreen SUBROUTINE
    ; init screen
    lda #8
    sta ScreenPosY
    lda #0
    sta ScreenSpeedY
    rts

InitPlayer SUBROUTINE
    ; init player's sprite
    lda #[SCREEN_WIDTH/2 - 4]
    sta PlyrPosX
    lda #0
    sta PlyrSpeedX
    sta PlyrScore
    sta PlyrScore+1
    sta PlyrScore+2
    lda #[3 << 3] | 7
    sta PlyrLife
    lda #0
    sta PlyrLaser
    rts

SpawnGroundSprites SUBROUTINE
    ; populate sprites with some values
    ldy #MAX_ROWS-1
    sty Temp
.Loop
    jsr SpritesShiftDown
    jsr RowInc
    jsr SpawnInTop
    dec Temp
    bne .Loop

.Return
    rts

SpawnEnemies SUBROUTINE
    lda #0
    ldy #MAX_ROWS-1
.Loop
    ora SprType0,y
    dey
    bne .Loop

    cmp #0
    bne .Return

    ; populate sprites with some values
    ldx #<FighterGfx
    ldy #MAX_ROWS-1
.Pop
    ; init sprite
    stx SprType0,y

    ; init horizontal position
    tya 
    asl
    asl
    asl
    adc #25
    sta SprPosX0,y

    ; init speed
    tya
    and #1
    bne .Good
    sec
    sbc #1
.Good
    sta SprSpeedX0,y
    dey
    bne .Pop

.Return
    rts

HUDSetup SUBROUTINE
    lda #>Digits
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11

    ldx Status
    cpx #ST_ALERT
    beq .Alert

    sta SpritePtrs+1

    ldx PlyrScore
    txa
    and #$f0
    lsr
    lsr
    lsr
    lsr
    tay
    lda DigitTable,y
    sta SpritePtrs
    txa
    and #$0f
    tay
    lda DigitTable,y
    sta SpritePtrs+2

    ldx PlyrScore+1
    txa
    and #$f0
    lsr
    lsr
    lsr
    lsr
    tay
    lda DigitTable,y
    sta SpritePtrs+4
    txa
    and #$0f
    tay
    lda DigitTable,y
    sta SpritePtrs+6

    ldx PlyrScore+2
    txa
    and #$f0
    lsr
    lsr
    lsr
    lsr
    tay
    lda DigitTable,y
    sta SpritePtrs+8
    txa
    and #$0f
    tay
    lda DigitTable,y
    sta SpritePtrs+10
    rts

.Alert
    lda #<WaveGfx
    sta SpritePtrs
    lda #<ShieldGfx
    sta SpritePtrs+4
    lda #<LifeGfx
    sta SpritePtrs+8

    lda #<Digit1
    sta SpritePtrs+2

    ; player lives
    lda PlyrLife
    and #PL_SHIELDS_MASK
    tay
    lda DigitTable,y
    sta SpritePtrs+6

    ; player lives
    lda PlyrLife
    lsr
    lsr
    lsr
    tay
    lda DigitTable,y
    sta SpritePtrs+10
    rts

EnemyTurn SUBROUTINE
    ; foreach enemy, decide an action
    ;   hover, move, change direction, attack player, attack ground, retreat
    lda RandLFSR8
    jsr RandGalois8
    sta RandLFSR8

    ldx #0
    ldy #9
    stx SprFire0,y

    lda #SPR_CONTINUE
    bit RandLFSR8
    cmp #SPR_CONTINUE
    beq .Return

    lda #SPR_ATTACK0
    bit RandLFSR8
    bne .Attack1
    
    lda #$ff
    sta SprFire0,y

    ldx #M1_OBJ
    lda SprPosX0,y
    clc
    adc #4
    jsr HorizPosition

.Attack0
    

.Attack1
    lda #SPR_ATTACK1
    bit RandLFSR8
    bne .Return

    
.Return
    rts

DetectCollision SUBROUTINE
    lda SprType0
    beq .Return
.Return
    rts

DetectPlayerHit SUBROUTINE
    lda #0
    sta Temp
    
    ldy #MAX_ROWS-1
.Loop
    lda SprType0,y
    beq .Continue

    ; detect if laser > enemy left edge
    lda SprPosX0,y
    sec
    sbc #4      ; -4 adjust offset
    cmp PlyrPosX
    bcs .Continue

    ; detect if laser < enemy right edge
    clc
    adc #8      ; +8 enemy width
    cmp PlyrPosX
    bcc .Continue
    
    ; hit
    lda SprLife0,y
    sec
    sbc #LASER_DAMAGE
    sta SprLife0,y
    bpl .Continue

    lda #<BlankGfx
    sta SprType0,y
    inc Temp
    
.Continue
    dey
    bne .Loop

    ; update the score
    sed
    ldy Temp
    beq .Return
.Score
    clc
    lda PlyrScore+2
    adc #$25
    sta PlyrScore+2

    lda PlyrScore+1
    adc #$00
    sta PlyrScore+1

    lda PlyrScore
    adc #$00
    sta PlyrScore

    dey
    bne .Score

.Return
    cld
    rts

SpritePtrsClear SUBROUTINE
    lda #<BlankGfx
    sta SpritePtrs
    sta SpritePtrs+2
    sta SpritePtrs+4
    sta SpritePtrs+6
    sta SpritePtrs+8
    sta SpritePtrs+10
    lda #>BlankGfx
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
    rts

ShipUpdatePosition SUBROUTINE
    ; update player's vertical position
    lda ScreenPosY
    clc
    adc ScreenSpeedY
    sta ScreenPosY

    ; update player's horizontal position
    lda PlyrPosX
    clc
    adc PlyrSpeedX
    cmp #MAX_POS_X
    bcs .HaltShip
    cmp #MIN_POS_X
    bcc .HaltShip
    sta PlyrPosX
    jmp .Return
.HaltShip
    lda #0
    sta PlyrSpeedX

.Return
    rts

EnemiesUpdatePosition SUBROUTINE
    ldy #MAX_ROWS-1
.Enemies
    lda SprType0,y
    beq .Continue

    lda SprPosX0,y
    clc
    adc SprSpeedX0,y
    cmp #MAX_POS_X
    bcs .Reverse
    cmp #MIN_POS_X
    bcc .Reverse
    sta SprPosX0,y
    jmp .Continue
.Reverse
    ; flip the sign; positive <--> negative
    lda SprSpeedX0,y
    eor #$ff
    clc
    adc #1
    sta SprSpeedX0,y

.Continue
    dey
    bne .Enemies

    rts

UpdateVerticalPositions SUBROUTINE
    rts

ScreenScroll SUBROUTINE
    ; if motionless, do nothing
    ; if traveling forward when Y = 0, then spawn a new top row
    ; if traveling backward when Y = 15, then spawn a new bottom row
    lda ScreenSpeedY
    beq .Return
    bmi .Reverse

.Foward
    lda ScreenPosY
    cmp #PF_ROW_HEIGHT
    bcc .Return
    sec
    sbc #PF_ROW_HEIGHT
    sta ScreenPosY
    jsr SpritesShiftDown
    jsr RowInc
    jsr SpawnInTop
    jmp .Return

.Reverse
    lda ScreenPosY
    bpl .Return
    clc
    adc #PF_ROW_HEIGHT
    sta ScreenPosY
    jsr SpritesShiftUp
    jsr RowDec
    jsr SpawnInBottom

.Return
    rts

SpritesShiftDown SUBROUTINE
    ; shift rows down
    ldy #0
.ShiftDown
    lda SprType0+1,y
    sta SprType0,y
    lda SprType1+1,y
    sta SprType1,y

    lda SprLife0+1,y
    sta SprLife0,y

    lda SprSpeedX0+1,y
    sta SprSpeedX0,y

    lda SprPosX0+1,y
    sta SprPosX0,y

    iny
    cpy #MAX_ROWS-1
    bne .ShiftDown

    rts

SpritesShiftUp SUBROUTINE
    ; shift rows up
    ldy #MAX_ROWS-1
.ShiftUp
    lda SprType0-1,y
    sta SprType0,y
    lda SprType1-1,y
    sta SprType1,y

    lda SprLife0-1,y
    sta SprLife0,y

    lda SprSpeedX0-1,y
    sta SprSpeedX0,y

    lda SprPosX0-1,y
    sta SprPosX0,y

    dey
    bne .ShiftUp

    rts

RowInc SUBROUTINE
    clc
    lda RowNum
    adc #1
    sta RowNum
    lda RowNum+1
    adc #0
    sta RowNum+1
    rts

RowDec SUBROUTINE
    sec
    lda RowNum
    sbc #1
    sta RowNum
    lda RowNum+1
    sbc #0
    sta RowNum+1
    rts

SpawnInTop SUBROUTINE
    ; spawn ground structure
    lda RowNum
    clc
    adc #MAX_ROWS-1
    jsr Jumble8
    and #7
    tax
    lda GroundSprites,x
    sta SprType1+MAX_ROWS-1

    ; spawn enemy
    lda RandLFSR16+1
    and #1
    beq .Skip

    ; initialize
    lda #<FighterGfx
    sta SprType0+MAX_ROWS-1
    lda #50
    sta SprPosX0+MAX_ROWS-1
    lda #1
    sta SprSpeedX0+MAX_ROWS-1
    lda #COLOR_ENEMY
    sta SprLife0+MAX_ROWS-1

.Skip
    rts

SpawnInBottom SUBROUTINE
    ; spawn ground structure
    lda RowNum
    jsr Jumble8
    and #7
    tax
    lda GroundSprites,x
    sta SprType1

#if 0
    ; spawn enemy
    lda #<BlankGfx
    sta SprType0
    lda RowNum
    lsr
    lsr
    and #1
    bne .Skip

    lda #<FighterGfx
    sta SprType0
    lda #120
    sta SprPosX0
    lda #-1
    sta SprSpeedX0
    lda #COLOR_ENEMY
    sta SprLife0
.Skip
#endif
    rts

SetTitleBattle SUBROUTINE
    ; set up graphics for battle title
    lda #<TitleBattle0
    sta SpritePtrs
    lda #<TitleBattle1
    sta SpritePtrs+2
    lda #<TitleBattle2
    sta SpritePtrs+4
    lda #<TitleBattle3
    sta SpritePtrs+6

    lda #>TitleBattle
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7

    lda #<BlankGfx
    sta SpritePtrs+8
    sta SpritePtrs+10
    lda #>BlankGfx
    sta SpritePtrs+9
    sta SpritePtrs+11
    rts

SetTitleCopy SUBROUTINE
    lda #<TitleCopy0
    sta SpritePtrs
    lda #<TitleCopy1
    sta SpritePtrs+2
    lda #<TitleCopy2
    sta SpritePtrs+4
    lda #<TitleCopy3
    sta SpritePtrs+6
    lda #<TitleCopy4
    sta SpritePtrs+8

    lda #>TitleCopy
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9

    lda #<BlankGfx
    sta SpritePtrs+10
    lda #>BlankGfx
    sta SpritePtrs+11
    rts

SetTitleName SUBROUTINE
    ; set up graphics for title name
    lda #<TitleName0
    sta SpritePtrs
    lda #<TitleName1
    sta SpritePtrs+2
    lda #<TitleName2
    sta SpritePtrs+4
    lda #<TitleName3
    sta SpritePtrs+6
    lda #<TitleName4
    sta SpritePtrs+8
    lda #<TitleName5
    sta SpritePtrs+10

    lda #>TitleName
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
    rts

    ; platform depedent data
    include "sys/ntsc.asm"
    include "sys/pal.asm"

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $a00
    PAGE_BOUNDARY_SET

GameKernel SUBROUTINE
    ; executes between 1 and 16 lines
    ;ldy #11
    jsr ExpanderRowKernel
                            ; 30 (30)
    dec CurrRow             ; 5 (35)
    ldy #10                 ; 2 (37) 
    jsr RowKernel           ; 6 (43)
                            ; 30 (30)
    dec CurrRow             ; 5 (35)
    ldy #9                  ; 2 (37)
    jsr RowKernel           ; 6 (43)

    dec CurrRow
    ldy #8
    jsr RowKernel

    dec CurrRow
    ldy #7
    jsr RowKernel

    dec CurrRow
    ldy #6
    jsr RowKernel

    dec CurrRow
    ldy #5
    jsr RowKernel

    dec CurrRow
    ldy #4
    jsr RowKernel

    dec CurrRow
    ldy #3
    jsr RowKernel

    dec CurrRow
    ldy #2
    jsr RowKernel

    dec CurrRow
    ldy #1
    jsr ShrinkerRowKernel

    jsr HUDSetup
    jsr HUDKernel
    rts

ExpanderRowKernel SUBROUTINE
    lda SprLife0,y                  ; 4 (4)
    sta TempColor                   ; 3 (7)

#if 0
    ; customize spacing
    lda CurrRow                     ; 3 (10)
    lsr                             ; 2 (12)
    and #3                          ; 2 (14)
    sta NUSIZ1                      ; 3 (17)
#endif

    lda ScreenPosY                  ; 3 (20)
    and #PF_ROW_HEIGHT-1            ; 2 (22)
    tay                             ; 2 (24)
.Row
    lda (P1Ptr),y                   ; 5 (30)
    sta GRP1                        ; 3 (33)
    ldx PFPattern,y                 ; 4 (37)
    lda ShipPalette,y               ; 4 (41)
    adc TempColor                   ; 2 (43)

    sta WSYNC
    sta COLUP0                      ; 3 (3)
    lda (P0Ptr),y                   ; 5 (8)
    sta GRP0                        ; 3 (11)
    stx PF0                         ; 3 (14)
    stx PF1                         ; 3 (17)
    stx PF2                         ; 3 (20)

    dey                             ; 2 (22)
    bpl .Row                        ; 2 (24)
    rts                             ; 6 (30)

RowKernel SUBROUTINE                ; 43 (43)
    lda SprLife0,y                  ; 4 (47)
    sta TempColor                   ; 3 (50)

    ldx #0                          ; 2 (52)
    lda SprPosX0,y                  ; 4 (56)
    jsr HorizPosition               ; 6 (62)

    ; invoke fine horizontal positioning
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    lda PFPattern+PF_ROW_HEIGHT-2   ; 3 (6)
    sta PF0                         ; 3 (9)
    sta PF1                         ; 3 (12)
    sta PF2                         ; 3 (15)
    
    ; setup sprite graphics pointer
    lda SprType0,y                  ; 4 (19)
    sta P0Ptr                       ; 3 (22)
    lda SprType1,y                  ; 4 (26)
    sta P1Ptr                       ; 3 (29)

#if 0
    ; customize spacing
    lda CurrRow                     ; 3 (32)
    lsr                             ; 2 (34)
    and #3                          ; 2 (36)
    sta NUSIZ1                      ; 3 (39)
#endif

    lda SprFire0+9                  ; 3
    sta ENAM1                       ; 3

    ldy #PF_ROW_HEIGHT-3            ; 2 (41)
.Row
    lda (P1Ptr),y                   ; 5 (30)
    sta GRP1                        ; 3 (33)
    ldx PFPattern,y                 ; 4 (37)
    lda ShipPalette,y               ; 4 (41)
    adc TempColor                   ; 2 (43)

    sta WSYNC
    sta COLUP0                      ; 3 (3)
    lda (P0Ptr),y                   ; 5 (8)
    sta GRP0                        ; 3 (11)
    stx PF0                         ; 3 (14)
    stx PF1                         ; 3 (17)
    stx PF2                         ; 3 (20)

    dey                             ; 2 (22)
    bpl .Row                        ; 2 (24)
    rts                             ; 6 (30)

    PAGE_BOUNDARY_CHECK "(1) Kernels"

; -----------------------------------------------------------------------------
; Desc:     Basic joystick handler. Advances the mode on joystick press.
; Input:    X register (next mode)
; Output:
; -----------------------------------------------------------------------------
GeneralIO SUBROUTINE
    lda SWCHB
    and #SWITCH_RESET
    bne .Joystick
    jmp Reset

.Joystick
    lda #JOY_FIRE
    bit INPT4
    bne .Return
    stx Mode
    txa
    CALL_PROC_TABLE ModeInit
.Return
    rts

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $b00
    PAGE_BOUNDARY_SET

ShrinkerRowKernel SUBROUTINE        ; 43 (43)
    ; calculate ending line
    lda ScreenPosY                  ; 3 (46)
    and #PF_ROW_HEIGHT-1            ; 2 (48)
    tax                             ; 2 (50)
    inx                             ; 2 (52)    2 lines of horiz positioning
    inx                             ; 2 (54)
    stx EndLine                     ; 3 (57)

    ; position player
    ldx #P0_OBJ                     ; 2 (59)
    lda PlyrPosX                    ; 4 (63)
    jsr HorizPosition               ; 6 (69)

    ; invoke fine horizontal positioning
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    lda PFPattern+PF_ROW_HEIGHT-2   ; 3 (6)
    sta PF0                         ; 3 (9)
    sta PF1                         ; 3 (12)
    sta PF2                         ; 3 (15)

    ; calculate index into ship graphics
    lda #PF_ROW_HEIGHT*2-1          ; 2 (17)
    eor EndLine                     ; 2 (19)
    sta PlyrIdx                     ; 3 (22)

    ; setup sprite graphics pointer
    lda SprType1                    ; 4 (26)
    sta P1Ptr                       ; 3 (29)

#if 0
    ; customize spacing
    lda CurrRow                     ; 3 (25)
    lsr                             ; 2 (27)
    and #3                          ; 2 (29)
    sta NUSIZ1                      ; 3 (32)
#endif

    ; fixed height top 14 pixels
    ldy #PF_ROW_HEIGHT*2-3          ; 2 (34)
.TopRow
    lda (BotPtr),y                  ; 5 (36)
    and MaskTop-2,y                 ; 4 (40)
    sta GRP1                        ; 3 (43)

    ldx PlyrIdx                     ; 3 (46)
    lda ShipGfx-2,x                 ; 4 (50)
    and MaskTable-2,x               ; 4 (54)
    dex                             ; 2 (56)
    stx PlyrIdx                     ; 3 (59)

    sta WSYNC
    sta GRP0                        ; 3 (3)
    lda ShipPalette-2,x             ; 4 (7)
    sta COLUP0                      ; 3 (10)
    lda PFPattern,y                 ; 4 (14)
    sta PF0                         ; 3 (17)
    sta PF1                         ; 3 (20)
    sta PF2                         ; 3 (23)

    dey                             ; 2 (25)
    cpy #PF_ROW_HEIGHT+2            ; 3 (28)
    bcs .TopRow                     ; 2 (30)

#if 0
    ; customize spacing
    lda CurrRow                     ; 3 (33)
    sec
    sbc #1                          ; 2 (35)    -1 (carry clear from above)
    lsr                             ; 2 (27)
    and #3                          ; 2 (37)
    sta NUSIZ1                      ; 3 (40)
#endif

    ; variable height bottom 13 to 1 pixels
.BotRow
    lda (P1Ptr),y                   ; 5 (36)
    sta GRP1                        ; 3 (39)

    ldx PlyrIdx                     ; 3 (42)
    lda ShipGfx-2,x                 ; 4 (46)
    and MaskTable-2,x               ; 4 (50)
    dex                             ; 2 (52)
    stx PlyrIdx                     ; 3 (55)

    sta WSYNC
    sta GRP0                        ; 3 (3)
    lda ShipPalette-2,x             ; 4 (7)
    sta COLUP0                      ; 3 (10)

    lda PFPattern,y                 ; 4 (14)
    sta PF0                         ; 3 (17)
    sta PF1                         ; 3 (20)
    sta PF2                         ; 3 (23)

    dey                             ; 2 (25)
    cpy EndLine                     ; 3 (28)
    bcs .BotRow                     ; 2 (30)

.Done
    lda #0                          ; 2 (44)
    sta NUSIZ1                      ; 3 (47)
    sta WSYNC

    sta GRP0                        ; 3 (3)
    sta GRP1                        ; 3 (6)
    sta ENAM0                       ; 3 (9)
    sta COLUBK                      ; 3 (12)
    sta PF0                         ; 3 (15)
    sta PF1                         ; 3 (18)
    sta PF2                         ; 3 (21)

    rts                             ; 6 (27)
    PAGE_BOUNDARY_CHECK "(2) Kernels"

PlayAudio SUBROUTINE
    ; play laser sounds
    lda PlyrFire
    bne .LaserSound
    sta LaserAudioFrame
    sta AUDC1
    sta AUDV1
    sta AUDF1
    jmp .EngineSound

.LaserSound
    ldy LaserAudioFrame
    iny
    cpy #LASER_AUDIO_FRAMES
    bcc .Save
    ldy #0
.Save
    sty LaserAudioFrame
    lda LaserCon,y
    sta AUDC1
    lda LaserVol,y
    sta AUDV1
    lda LaserFreq,y
    sta AUDF1

    ; play engine sounds
.EngineSound
    lda #8
    sta AUDC0
    lda ScreenSpeedY
    bpl .NoInvert
    eor #$ff
    clc
    adc #1
.NoInvert
    REPEAT FPOINT_SCALE
    lsr
    REPEND
    tay
    lda EngineVolume,y
    sta AUDV0
    lda EngineFrequency,y
    sta AUDF0
    rts

    include "lib/random.asm"

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $c0f

; Procedure tables
ModeInit
    dc.w TitleInit          ; MODE_TITLE
    dc.w WaveInit           ; MODE_WAVE
    dc.w GameInit           ; MODE_GAME
ModeVertBlank
    dc.w TitleVertBlank     ; MODE_TITLE
    dc.w WaveVertBlank      ; MODE_WAVE
    dc.w GameVertBlank      ; MODE_GAME
ModeKernel
    dc.w TitleKernel        ; MODE_TITLE
    dc.w WaveKernel         ; MODE_WAVE
    dc.w GameKernel         ; MODE_GAME
ModeOverscan
    dc.w TitleOverscan      ; MODE_TITLE
    dc.w WaveOverscan       ; MODE_WAVE
    dc.w GameOverscan       ; MODE_GAME


    PAGE_BOUNDARY_SET
HUDKernel SUBROUTINE                ; 24 (24)
    lda #$ff                        ; 2 (26)
    ldx #0                          ; 2 (28)
    ldy #1                          ; 2 (30)

    ; top border (3 lines)
    sta WSYNC
    stx COLUBK                      ; 3 (3)
    stx COLUPF                      ; 3 (6)
    sta PF0                         ; 3 (9)
    stx PF1                         ; 3 (12)
    stx PF2                         ; 3 (15)
    ; reflect playfield
    sty CTRLPF                      ; 3 (18)
    sty VDELP0                      ; 3 (21)
    sty VDELP1                      ; 3 (24)
    stx GRP0                        ; 3 (27)
    stx GRP1                        ; 3 (30)

    ; X = 0 from above
    ldy Status                      ; 3
    lda StatusPos0,y                ; 4
    ldy HUDPalette                  ; 3 (35)
    jsr HorizPositionBG             ; 6 (41)

    ldy Status                      ; 3
    lda StatusPos1,y                ; 4
    ldx #1                          ; 2 (4)
    ldy HUDPalette+1                ; 3 (7)
    jsr HorizPositionBG             ; 6 (13)

    sta WSYNC
    sta HMOVE                       ; 3 (3)

    ; HUD color
    lda FrameCtr                    ; 3 (6)
    lsr                             ; 2 (8)
    lsr                             ; 2 (10)
    lsr                             ; 2 (12)
    and #3                          ; 2 (14)
    ora Status                      ; 3 (17)
    tax                             ; 2 (19)
    lda StatusColors,x              ; 4 (23)
    sta COLUBK                      ; 3 (26)

    ; text color
    lda #COLOR_WHITE                ; 2 (28)
    sta COLUP0                      ; 3 (31)
    sta COLUP1                      ; 3 (34)

    ; nusize positioning
    ldx Status                      ; 3 (37)
    lda StatusNusiz,x               ; 4 (41)
    sta NUSIZ0                      ; 3 (44)
    sta NUSIZ1                      ; 3 (47)

    ldy #DIGIT_HEIGHT-1             ; 2 (49)
    jsr DrawWideSprite56            ; 6 (55)

    sta WSYNC
    lda HUDPalette+1                ; 3 (3)
    sta COLUBK                      ; 3 (6)

    sta WSYNC
    lda HUDPalette                  ; 3 (3)
    sta COLUBK                      ; 3 (6)
    lda #0                          ; 2 (8)

    ; restore playfield
    sta WSYNC
    sta PF0                         ; 3 (3)
    sta COLUBK                      ; 3 (6)
    sta CTRLPF                      ; 3 (9)
    sta PF1                         ; 3 (12)
    sta PF2                         ; 3 (15)
    rts                             ; 6 (12)

    PAGE_BOUNDARY_CHECK "(3) Kernels"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $d00
    PAGE_BOUNDARY_SET
    include "gen/title-copy.sp"
    PAGE_BOUNDARY_CHECK "TitleCopy"

NusizPattern
    dc.b 3, 1, 6, 3, 4, 2, 0, 3

AirSprites
    dc.b <BlankGfx, <FighterGfx
GroundSprites
    dc.b <BlankGfx, <CondoGfx, <HouseGfx, <IndustryGfx
    dc.b <CropsGfx, <FuelGfx, <DishGfx, <PumpGfx

DigitTable
    dc.b <Digit0, <Digit1, <Digit2, <Digit3, <Digit4
    dc.b <Digit5, <Digit6, <Digit7, <Digit8, <Digit9

    PAGE_BOUNDARY_SET
; -----------------------------------------------------------------------------
; Desc:     Draws a 48-bit wide sprite centered on the screen using the
;           Dragster algorithm.
; Input:    Y register (height-1)
; Output:
; Notes:    Position GRP0 to TIA cycle 124 (on-screen pixel 56)
;           Position GRP1 to TIA cycle 132 (on-screen pixel 64)
; -----------------------------------------------------------------------------
DrawWideSprite56 SUBROUTINE ; 6 (6)
    sty Temp                ; 3 (9)
.Loop
    ;                            CPU   TIA   GRP0  GRP0A    GRP1  GRP1A
    ; -------------------------------------------------------------------------
    ldy Temp                ; 3 (65)  (195)
    lda (SpritePtrs),y      ; 5 (70)  (210)
    sta GRP0                ; 3 (73)  (219)    D1     --      --     --
    sta WSYNC               ; 3  (0)    (0)
    ; -------------------------------------------------------------------------
    lda (SpritePtrs+2),y    ; 5  (5)   (15)
    sta GRP1                ; 3  (8)   (24)    D1     D1      D2     --
    lda (SpritePtrs+4),y    ; 5 (13)   (39)
    sta GRP0                ; 3 (16)   (48)    D3     D1      D2     D2
    lda (SpritePtrs+6),y    ; 5 (21)   (63)
    sta Temp2               ; 3 (24)   (72)
    lda (SpritePtrs+8),y    ; 5 (29)   (87)
    tax                     ; 2 (31)   (93)
    lda (SpritePtrs+10),y   ; 5 (36)  (108)
    tay                     ; 2 (38)  (114)
    lda Temp2               ; 3 (41)  (123)             !
    sta GRP1                ; 3 (44)  (132)    D3     D3      D4     D2!
    stx GRP0                ; 3 (47)  (141)    D5     D3!     D4     D4
    sty GRP1                ; 3 (50)  (150)    D5     D5      D6     D4!
    sta GRP0                ; 3 (53)  (159)    D4*    D5!     D6     D6
    dec Temp                ; 5 (58)  (174)                            !
    bpl .Loop               ; 3 (61)  (183) 
    rts                     ; 6 (67)

; positioned on TIA cycle 72 and 80 (on-screen pixel 4 and 12)
DrawTitleSprite SUBROUTINE
    sta WSYNC
    ldx #$ff                ; 2 (2)
    stx PF1                 ; 3 (5)
    stx PF2                 ; 3 (8)
    tya                     ; 2 (10)
    SLEEP_26                ; 26 (36)
    tay                     ; 2 (38)
    ldx TitlePlanet1        ; 3 (41)
    stx PF1                 ; 3 (44)
    ldx TitlePlanet2        ; 3 (47)
    stx PF2                 ; 3 (50)

.Loop
    ;                            CPU   TIA   GRP0  GRP0A    GRP1  GRP1A
    ; -------------------------------------------------------------------------
    ldx #$ff                ; 2 (58)  (174)
    lda (SpritePtrs),y      ; 5 (63)  (189)
    sta GRP0                ; 3 (66)  (198)    D1     --      --     --
    lda (SpritePtrs+2),y    ; 5 (71)  (213)
    sta WSYNC               ; 3 (74)  (222)

    ; -------------------------------------------------------------------------
    sta GRP1                ; 3  (3)    (9)    D1     D1      D2     --
    stx PF1                 ; 3  (6)   (18)
    stx PF2                 ; 3  (9)   (27)
    lda (SpritePtrs+4),y    ; 5 (14)   (42)
    sta GRP0                ; 3 (17)   (51)    D3     D1      D2     D2
    lda (SpritePtrs+6),y    ; 5 (22)   (66)
    ldx #0                  ; 2 (24)   (72)             !
    sta GRP1                ; 3 (27)   (81)    D3     D3      D4     D2!
    stx GRP0                ; 3 (30)   (90)    D5     D3!     D4     D4
    stx GRP1                ; 3 (33)   (99)    D5     D5      D6     D4!
    stx GRP0                ; 3 (36)  (108)    D4*    D5!     D6     D6
    lda TitlePlanet1        ; 4 (40)  (120)
    sta PF1                 ; 3 (43)  (129)
    lda TitlePlanet2        ; 4 (47)  (141)
    sta PF2                 ; 3 (50)  (150)
    dey                     ; 2 (52)  (156)
    bpl .Loop               ; 3 (55)  (165) 

    lda #0                  ; 2 (57) 
    sta WSYNC
    sta COLUBK              ; 3 (3) 
    sta PF0                 ; 3 (6)
    sta PF1                 ; 3 (9)
    sta PF2                 ; 3 (12)
    rts                     ; 6 (18)

; -----------------------------------------------------------------------------
; Desc:     Positions an object horizontally using the Battlezone algorithm.
; Input:    A register (screen pixel position)
;           X register (object index: 0 to 4)
; Output:   A register (fine positioning value)
;
;           Object indexes:
;               0 = Player 0
;               1 = Player 1
;               2 = Missile 0
;               3 = Missile 1
;               4 = Ball
;
;           Follow up with:
;               sta WSYNC
;               sta HMOVE
; -----------------------------------------------------------------------------
HorizPosition SUBROUTINE
    sec             ; 2 (2)
    sta WSYNC       ; 3 (5) 

    ; coarse position timing
.Div15
    sbc #15         ; 2 (2)
    bcs .Div15      ; 3 (5)

    ; computing fine positioning value
    eor #7          ; 2 (11)            ; 4 bit signed subtraction
    asl             ; 2 (13)
    asl             ; 2 (15)
    asl             ; 2 (17)
    asl             ; 2 (19)

    ; position
    sta RESP0,X     ; 4 (23)            ; coarse position
    sta HMP0,X      ; 4 (27)            ; fine position
    rts

; performs horizontal positioning while drawing a background color
HorizPositionBG SUBROUTINE  ; 6 (6)
    sec             ; 2 (8)
    sta WSYNC
    sty COLUBK      ; 3 (3)
    sbc #15         ; 2 (5)

.Div15
    sbc #15         ; 2 (7)
    bcs .Div15      ; 3 (10)

    eor #7          ; 2 (12)
    asl             ; 2 (14)
    asl             ; 2 (16)
    asl             ; 2 (18)
    asl             ; 2 (20)

    sta RESP0,X     ; 4 (24)
    sta HMP0,X      ; 4 (28)
    rts             ; 6 (34)

; performs horizontal positioning while drawing a playfield pattern
; this must enter on or before cycle 62
HorizPositionPF SUBROUTINE
    sty PF0         ; 3 (65)
    sec             ; 2 (67)
    sty PF1         ; 3 (70)
    sty PF2         ; 3 (73)
    sta WSYNC       ; 3 (76)

.Div15
    sbc #15         ; 4 (7)
    bcs .Div15      ; 5 (12)

    eor #7          ; 2 (14)
    asl             ; 2 (16)
    asl             ; 2 (18)
    asl             ; 2 (20)
    asl             ; 2 (22)

    sta RESP0,X     ; 4 (26)
    sta HMP0,X      ; 4 (30)
    rts

    PAGE_BOUNDARY_CHECK "(4) Kernels"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $e00
    PAGE_BOUNDARY_SET
    include "gen/title-battle.sp"
    include "gen/title-name.sp"
    include "gen/title-planet.pf"
    include "gen/title-proton.pf"
    include "gen/wave-text.sp"
    include "gfx/hud.asm"
    include "gfx/playfield.asm"
    PAGE_BOUNDARY_CHECK "Graphics data"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $f00
    include "gfx/sprites.asm"
    include "gfx/title.asm"

StatusColors
    ; Bit:  0 (mode)
    ; Bit:  1 (ctr)
    ;    00         01
    dc.b COLOR_BLUE, COLOR_BLUE
    ;    10         11
    dc.b COLOR_BLUE, COLOR_RED

StatusNusiz
    dc.b 3      ; ST_NORM
    dc.b 6      ; ST_ALERT

StatusPos0
    dc.b 71     ; ST_NORM
    dc.b 55     ; ST_ALERT
StatusPos1
    dc.b 79     ; ST_NORM
    dc.b 63     ; ST_ALERT

Mult7
    dc.b   0,   7,  14,  21,  28,  35,  42,  49,  56,  63
    ;dc.b  70,  77,  84,  91,  98, 105, 112, 119, 126, 133
    ;dc.b 140, 147, 154, 161, 168, 175, 182, 189, 196, 203
    ;dc.b 210, 217, 224, 231, 238, 245, 252

    PAGE_LAST_REMAINING

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $ffa
Interrupts
    dc.w Reset              ; NMI
    dc.w Reset              ; RESET
    dc.w Reset              ; IRQ
