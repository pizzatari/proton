; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.1 (beta)
; Game:     The Battle for Proton
; -----------------------------------------------------------------------------
; Treadmill kernel. The rows are pushed downward and the terrain remains
; fixed within the row. The first and last rows expand and shrink in tandem.
;
;       . . . . . . . . . . . . . . .
;       :  world                    :
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
;     1 |                           |
;       |___________________________|
;     0 |                           | shrinker: 31px -> 16px
;       :           /_\             : player
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

; -----------------------------------------------------------------------------
; Definitions
; -----------------------------------------------------------------------------
VIDEO_MODE          = VIDEO_NTSC 

ORG_ADDR            = $f000

COLOR_BG            = COLOR_DGREEN
COLOR_FG            = COLOR_GREEN
COLOR_HUD_SCORE     = COLOR_WHITE
COLOR_LASER         = COLOR_RED
COLOR_BUILDING      = COLOR_LGRAY

MODE_TITLE          = 0
;MODE_WAVE           = 1
MODE_GAME           = 1

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
FRICTION_X          =  1

MAX_ROWS            = 11
MAX_NUM_PTRS        = 6

P0_OBJ              = 0
P1_OBJ              = 1
M0_OBJ              = 2
M1_OBJ              = 3
BL_OBJ              = 4

PLAYER_ROW          = 0         ; Sprites0[0]
PLAYER_OBJ          = P0_OBJ
ENEMY_OBJ           = P0_OBJ
BUILDING_OBJ        = P1_OBJ
MISSILE_OBJ         = M0_OBJ

; -----------------------------------------------------------------------------
; Variables
; -----------------------------------------------------------------------------
    SEG.U ram
    ORG $80

FrameCtr        ds.b 1
Mode            ds.b 1
Delay           ds.b 1
SpritePtrs      ds.w MAX_NUM_PTRS
Ptr             ds.w 1

Temp            = Ptr
Temp2           = Ptr+1

MemEnd

    ORG MemEnd
; TitleVars
LaserPtr        ds.w 1

    ORG MemEnd
; GameVars 
Score           ds.b 3                      ; BCD in MSB order

; screen motion
ScreenPosY      ds.b 1
ScreenSpeedY    ds.b 1

; sprite type/graphics (GRP0/GRP1)
Sprites0        ds.b MAX_ROWS        ; gfx low byte = sprite type
Sprites1        ds.b MAX_ROWS        ; gfx low byte = sprite type

; sprite motion (GRP0/GRP1)
SpeedX0         ds.b MAX_ROWS
SpeedX1         ds.b MAX_ROWS
PosX0           ds.b MAX_ROWS
PosX1           ds.b MAX_ROWS

JoyFire         ds.b 1
LaserAudioFrame ds.b 1

; graphics data

LocalVars       ds.b 14

EndLine         = LocalVars+1
PlyrIdx         = LocalVars+2

HUDHeight       = LocalVars+1

    ECHO "RAM used =", (* - $80)d, "bytes"
    ECHO "RAM free =", (128 - (* - $80))d, "bytes" 

; -----------------------------------------------------------------------------
; Macros
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Desc:     Calls the named procedure for the mode.
; Input:    A register (procedure index)
; Param:    ProcedureTable
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

Init
    TIMER_WAIT  ; maintain stable line count if we got here from a reset

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
TitleVertBlank SUBROUTINE
    lda #LINES_VBLANK*76/64
    sta TIM64T

    ;ldx #P0_OBJ
    ;lda #150
    ;jsr HorizPosition

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

    TIMER_WAIT

    lda #0
    sta VBLANK      ; turn on the display
    sta CTRLPF
    rts

TitleKernel SUBROUTINE      ; 6 (6)
    lda #COLOR_BLACK        ; 2 (8)
    sta COLUBK              ; 3 (11)
    lda #COLOR_BLACK        ; 3 (14)
    sta COLUPF              ; 3 (17)

    ; ------------------------------------------------------------------------
    ; blank space
    ; ------------------------------------------------------------------------
    SLEEP_LINES 84

    lda #3
    sta VDELP0              ; 3
    sta VDELP1              ; 3
    sta NUSIZ0              ; 3
    sta NUSIZ1              ; 3

    lda #COLOR_WHITE        ; 2
    sta COLUP0              ; 2
    sta COLUP1              ; 2

    lda #0                  ; 2 (27)
    sta GRP0                ; 3 
    sta GRP1                ; 3 
    sta GRP0                ; 3 
    lda #$ff                ; 2 (35)
    sta PF0                 ; 3 (38)

    ; ------------------------------------------------------------------------
    ; planet
    ; ------------------------------------------------------------------------
    clc                     ; 2 (40)
    ldy #TITLEPLANET_HEIGHT*4-1 ; 2 (42)
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
    ; 1 line blank spacer
    ; ------------------------------------------------------------------------
    ldy #0                  ; 2 (20)
    sta GRP0                ; 3 (23)
    sta GRP1                ; 3 (26)

    ldx #P0_OBJ             ; 2 (28)
    lda #164                ; 2 (30)
    jsr HorizPositionBG     ; 6 (36)

    lda #0                  ; 2 (2)
    sta WSYNC
    sta HMOVE               ; 3 (3) 
    sta PF0                 ; 3 (6)
    sta PF1                 ; 3 (9)
    sta PF2                 ; 3 (12)
    ldx #COLOR_YELLOW       ; 2 (14)
    stx COLUPF              ; 3 (17)
    sta NUSIZ0              ; 3 (20)
    sta NUSIZ1              ; 3 (23)
    sta VDELP0              ; 3 (26)
    sta VDELP1              ; 3 (29)

    ; ------------------------------------------------------------------------
    ; laser top
    ; ------------------------------------------------------------------------
    ldy #7                  ; 2 (31)
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
    ldx #$ff                ; 2 (16)
    ldy #0                  ; 2 (18)
    sta GRP0                ; 3 (21)

    sta WSYNC
    stx PF0                 ; 3 (3)
    stx PF1                 ; 3 (6)
    stx PF2                 ; 3 (9)
    SLEEP_38                ; 38 (47)
    lda #$3f                ; 2 (49)
    sta PF2                 ; 3 (52)

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

    SLEEP_LINES 33

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

    lda #COLOR_BLACK
    sta COLUBK
    sta COLUPF
    inc FrameCtr

    lda #LINES_OVERSCAN*76/64
    sta TIM64T
    jsr TitleIO
    TIMER_WAIT
    rts

TitleIO SUBROUTINE
    lda #JOY_FIRE
    bit INPT4
    bne .Return
    lda #MODE_GAME
    sta Mode
    jsr GameInit
.Return
    rts

; -----------------------------------------------------------------------------
; Game code
; -----------------------------------------------------------------------------
GameInit SUBROUTINE
    jsr InitScreen
    jsr InitPlayer
    jsr SpawnBuildings
    jsr SpawnEnemies
    lda #30
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

    lda #COLOR_BG
    sta COLUBK
    lda #COLOR_FG
    sta COLUPF

    ; spawn single row sprite on motion
    jsr SpawnSprite

    ; clear sprite pointers
    jsr SpritePtrsClear

    ; position 3 medium
    lda #3
    sta NUSIZ1

    ; positon sprites
    ldx #ENEMY_OBJ
    lda PosX0+MAX_ROWS-1
    jsr HorizPosition
    ldx #BUILDING_OBJ
    lda #76
    jsr HorizPosition
    ldx #MISSILE_OBJ
    lda PosX0+PLAYER_ROW
    clc
    adc #4          ; adjust offset
    jsr HorizPosition
    sta WSYNC
    sta HMOVE

    ; setup sprite graphics pointer
    lda Sprites0+MAX_ROWS-1
    sta SpritePtrs
    lda Sprites1+MAX_ROWS-1
    sta SpritePtrs+2

    lda #COLOR_LASER
    sta COLUP0+PLAYER_OBJ
    lda #COLOR_BUILDING
    sta COLUP0+BUILDING_OBJ

    ; enable/disable laser
    lda Delay
    bne .Continue
    lda JoyFire
    sta ENAM0
    beq .Continue
    stx LaserAudioFrame
    jsr LaserCollision
.Continue

    ; clear fine motion for subsequent HMOVEs
    lda #0
    sta HMM0
    sta HMP0
    sta HMM1
    sta HMP1

    TIMER_WAIT
   
    ; turn on the display
    lda #0
    sta VBLANK

    rts

GameKernel SUBROUTINE
    ; executes between 1 and 16 lines
    ldy #10
    jsr ExpanderRowKernel
    SLEEP 7
    ldy #9
    jsr RowKernel
    ldy #8
    jsr RowKernel
    ldy #7
    jsr RowKernel
    ldy #6
    jsr RowKernel
    ldy #5
    jsr RowKernel
    ldy #4
    jsr RowKernel
    ldy #3
    jsr RowKernel
    ldy #2
    jsr RowKernel
    ldy #1
    jsr RowKernel
    ldy #0
    jsr ShrinkerRowKernel

    jsr HUDSetup
    jsr HUDKernel
    rts

GameOverscan SUBROUTINE
    lda #[LINES_OVERSCAN-1]*76/64
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
    ;jsr SpawnEnemies

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
    bne .Return

    ; update every even frame
    lda FrameCtr
    and #1
    bne .CheckMovement

.CheckRight
    ; read joystick
    ldy SWCHA
    tya
    and #JOY0_RIGHT
    bne .CheckLeft
    lda SpeedX0+PLAYER_ROW
    bpl .Dec1           ; instant decceleration on change of direction
    lda #0
.Dec1
    clc
    adc #ACCEL_X
    cmp #MAX_SPEED_X+1
    bpl .CheckLeft
    sta SpeedX0+PLAYER_ROW

.CheckLeft
    tya
    and #JOY0_LEFT
    bne .CheckDown
    lda SpeedX0+PLAYER_ROW
    bmi .Dec2           ; instant decceleration on change of direction
    lda #0
.Dec2
    sec
    sbc #ACCEL_X
    cmp #MIN_SPEED_X
    bmi .CheckDown
    sta SpeedX0+PLAYER_ROW

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
    bne .CheckMovement

    lda ScreenSpeedY
    clc
    adc #ACCEL_Y
    cmp #MAX_SPEED_Y+1
    bpl .CheckMovement
    sta ScreenSpeedY

.CheckMovement
    ; update every eighth frame
    lda FrameCtr
    and #3
    bne .CheckFire

    ; deccelerate horizontal motion when there's no input
    tya 
    and #JOY0_LEFT | JOY0_RIGHT
    cmp #JOY0_LEFT | JOY0_RIGHT
    bne .CheckFire
    lda SpeedX0+PLAYER_ROW
    beq .CheckFire
    bpl .Pos
    clc
    adc #FRICTION_X
    sta SpeedX0+PLAYER_ROW
    jmp .CheckFire
.Pos
    sec
    sbc #FRICTION_X
    sta SpeedX0+PLAYER_ROW

.CheckFire
    lda INPT4
    eor $ff
    and #JOY_FIRE
    clc
    rol
    rol
    rol
    sta JoyFire

.Return
    rts

    ALIGN 256
KERNEL_BEGIN SET *

#if 1
ExpanderRowKernel SUBROUTINE
    lda ScreenPosY
    and #PF_ROW_HEIGHT-1
    tay
    ;iny
.Row
    ldx PFPattern,y               ; 4 (37)
    lda ShipPalette0,y              ; 4 (41)
    sta WSYNC

    sta COLUP0+ENEMY_OBJ            ; 3 (3)
    lda (SpritePtrs),y              ; 5 (8)
    sta GRP0+ENEMY_OBJ              ; 3 (11)
    lda (SpritePtrs+2),y            ; 5 (16)
    sta GRP0+BUILDING_OBJ           ; 3 (19)
    stx PF0                         ; 3 (22)
    stx PF1                         ; 3 (25)
    stx PF2                         ; 3 (28)

    dey                             ; 2 (30)
    ;bne .Row                        ; 2 (32)
    bpl .Row                        ; 2 (32)
    rts                             ; 6 (38)
#else
ExpanderRowKernel SUBROUTINE
    lda ScreenPosY
    and #PF_ROW_HEIGHT-1
    tay
    iny
.Row
    lda PFPattern-1,y               ; 4 (17)
    sta WSYNC
    sta PF0                         ; 3 (3)
    sta PF1                         ; 3 (6)
    sta PF2                         ; 3 (9)
    dey                             ; 2 (11)
    bne .Row                        ; 2 (13)
    rts                             ; 6 (19)
#endif

RowKernel SUBROUTINE
    tya                             ; 2 (2)
    pha                             ; 3 (5)

    ; Two lines of the playfield need to be written out during
    ; the horizontal positioning.

    ldx #ENEMY_OBJ                  ; 2 (7)
    lda PosX0,y                     ; 4 (11)
    ;ldy PFPattern+PF_ROW_HEIGHT-1   ; 3 (14)
    ;jsr HorizPositionPF             ; 6 (20)
    jsr HorizPosition               ; 6 (20)

    ; invoke fine horizontal positioning
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    ldy PFPattern+PF_ROW_HEIGHT-2   ; 3 (6)
    sty PF0                         ; 3 (9)
    sty PF1                         ; 3 (12)
    sty PF2                         ; 3 (15)

    ; setup sprite graphics pointer
    pla                             ; 4 (19)
    tay                             ; 2 (21)
    lda Sprites0,y                  ; 4 (25)
    sta SpritePtrs                  ; 3 (28)
    lda Sprites1,y                  ; 4 (32)
    sta SpritePtrs+2                ; 3 (35)

    ldy #PF_ROW_HEIGHT-3            ; 2 (37)
.Row
    ; texture indexed from 0 to PF_ROW_HEIGHT-1
    lda PFPattern,y                 ; 4 (29)
    tax                             ; 2 (31)
    lda #$08                        ; 2 (33)
    sta COLUP0+BUILDING_OBJ         ; 3 (36)
    lda ShipPalette0,y              ; 4 (40)
    sta COLUP0+ENEMY_OBJ            ; 3 (43)
    lda (SpritePtrs+2),y            ; 5 (48)

    sta WSYNC
    sta GRP0+BUILDING_OBJ           ; 3 (3)
    stx PF0                         ; 3 (6)
    stx PF1                         ; 3 (9)
    lda (SpritePtrs),y              ; 5 (14)
    sta GRP0+ENEMY_OBJ              ; 3 (17)
    stx PF2                         ; 3 (20)

    dey                             ; 2 (22)
    bpl .Row                        ; 2 (24)
    rts                             ; 6 (30)
    ; This must exit before or on cycle 42 for the next
    ; row to meet it's cycle timings.

ShrinkerRowKernel SUBROUTINE
    ; position player
    ldx #PLAYER_OBJ                 ; 2 (40)
    lda PosX0+PLAYER_ROW            ; 4 (44)
    jsr HorizPosition               ; 6 (50)

    ; invoke fine horizontal positioning
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    ldy PFPattern+PF_ROW_HEIGHT-2   ; 3 (6)
    sty PF0                         ; 3 (9)
    sty PF1                         ; 3 (12)
    sty PF2                         ; 3 (15)

    ; calculate ending line
    lda ScreenPosY                  ; 3 (18)
    and #PF_ROW_HEIGHT-1
    tax
    inx                             ; 2 (20)
    inx                             ; 2 (22)
    stx EndLine                     ; 3 (25)

    lda #PF_ROW_HEIGHT*2-3          ; 2 (27)
    sbc EndLine                     ; 2 (29)
    sta PlyrIdx                     ; 3 (32)

    ldy #PF_ROW_HEIGHT*2-3          ; 2 (34)
.Row
    tya                             ; 2 (37)
    and #PF_ROW_HEIGHT-1            ; 2 (39)
    tax                             ; 2 (41)
    lda PFPattern,x                 ; 4 (45)
    sta Temp                        ; 3 (48)

    lda PlyrIdx                     ; 3 (51)
    and #PF_ROW_HEIGHT*2-1          ; 2 (53)
    eor #$1f                        ; 2 (55)     reversing idx reduces ROM space
    tax                             ; 3 (58)
    lda ShipGfx,x                   ; 5 (63)

    sta WSYNC
    sta GRP0+PLAYER_OBJ             ; 3 (3)
    lda ShipPalette0,x              ; 4 (7)
    sta COLUP0+PLAYER_OBJ           ; 3 (10)

    lda Temp                        ; 3 (13)
    sta PF0                         ; 3 (16)
    sta PF1                         ; 3 (19)
    sta PF2                         ; 3 (22)

    dec PlyrIdx                     ; 5 (27)
    dey                             ; 2 (29)
    cpy EndLine                     ; 3 (32)
    bcs .Row                        ; 2 (34)

    lda #0                          ; 2 (36)
    sta NUSIZ1                      ; 3 (39)
    sta WSYNC
    sta ENAM0                       ; 3 (3)
    sta COLUBK                      ; 3 (6)
    sta PF0                         ; 3 (9)
    sta PF1                         ; 3 (12)
    sta PF2                         ; 3 (15)

    rts                             ; 6 (21)

    IF >KERNEL_BEGIN != >*
        ECHO "(1) Kernels crossed a page boundary!", (KERNEL_BEGIN&$ff00), (*&$ff00)
    ENDIF

    ALIGN 256
KERNEL_BEGIN SET *
HUDKernel SUBROUTINE
    lda #$ff                        ; 2 (8)
    ldx #0                          ; 2 (10)
    ldy #1                          ; 2 (12)

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

    ; status panel (X = 0 from above)
    lda #71                         ; 2 (20)
    ldy HUDPalette                  ; 3 (23)
    jsr HorizPositionBG             ; 6 (6)

    lda #71+8                       ; 2 (2)
    ldx #1                          ; 2 (4)
    ldy HUDPalette+1                ; 3 (7)
    jsr HorizPositionBG             ; 6 (13)

    lda HUDPalette+2                ; 3 (16)
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    sta COLUBK                      ; 3 (6)

    ; 3 (9) copies, medium spaced
    lda #%011                       ; 2 (11)
    sta NUSIZ0                      ; 3 (14)
    sta NUSIZ1                      ; 3 (17)

    lda #COLOR_WHITE                ; 2 (19)
    sta COLUP0                      ; 3 (22)
    sta COLUP1                      ; 3 (25)

    ldy #DIGIT_HEIGHT-1             ; 2 (27)
    jsr DrawWideSprite56            ; returns on cycle 67

    sta WSYNC
    lda HUDPalette+1                ; 3 (3)
    sta COLUBK                      ; 3 (6)

    sta WSYNC
    lda HUDPalette                  ; 3 (3)
    sta COLUBK                      ; 3 (6)
    lda #0                          ; 2 (8)
    sta VDELP0                      ; 3 (11)
    sta VDELP1                      ; 3 (14)
    sta NUSIZ0                      ; 3 (17)
    sta NUSIZ1                      ; 3 (20)

    ; restore playfield
    sta WSYNC
    sta PF0                         ; 3 (3)
    sta COLUBK                      ; 3 (6)
    sta CTRLPF                      ; 3 (9)
    sta PF1                         ; 3 (12)
    sta PF2                         ; 3 (15)
    rts                             ; 6 (12)

    IF >KERNEL_BEGIN != >*
        ECHO "(2) Kernels crossed a page boundary!", (KERNEL_BEGIN&$ff00), (*&$ff00)
    ENDIF

InitScreen SUBROUTINE
    ; init screen
    lda #8
    sta ScreenPosY
    lda #0
    sta ScreenSpeedY
    rts

InitPlayer SUBROUTINE
    ; init player's sprite
    lda #<ShipGfx
    sta Sprites0+PLAYER_ROW
    lda #[SCREEN_WIDTH/2 - 4]
    sta PosX0+PLAYER_ROW
    
    lda #0
    sta Score
    sta Score+1
    sta Score+2
    rts


SpawnBuildings SUBROUTINE
    lda #0
    ldy #MAX_ROWS-1
.Loop
    ora Sprites1,y
    dey
    bne .Loop

    cmp #0
    bne .Return

    ; populate sprites with some values
    ldy #MAX_ROWS-1
.Pop
    ; init sprite
    ldx #<FuelGfx
    stx Sprites1,y
    ldx #<BaseGfx
    stx Sprites1+1,y
    lda #0
    sta SpeedX1,y
    dey
    dey
    bne .Pop

.Return
    rts

SpawnEnemies SUBROUTINE
    lda #0
    ldy #MAX_ROWS-1
.Loop
    ora Sprites0,y
    dey
    bne .Loop

    cmp #0
    bne .Return

    ; populate sprites with some values
    ldx #<FighterGfx
    ldy #MAX_ROWS-1
.Pop
    ; init sprite
    stx Sprites0,y

    ; init horizontal position
    tya 
    asl
    asl
    asl
    adc #25
    sta PosX0,y

    ; init speed
    tya
    and #1
    bne .Good
    sec
    sbc #1
.Good
    sta SpeedX0,y
    dey
    bne .Pop

.Return
    rts

HUDSetup SUBROUTINE
    ldx Score
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

    ldx Score+1
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

    ldx Score+2
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

    lda #>Digits
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
    rts

LaserCollision SUBROUTINE
    ;lda JoyFire
    ;beq .Return

    lda #0
    sta Temp
    
    ldy #MAX_ROWS-1
.Loop
    lda Sprites0,y
    beq .Continue

    ; detect if laser > enemy left edge
    lda PosX0,y
    sec
    sbc #4      ; -4 adjust offset
    cmp PosX0+PLAYER_ROW
    bcs .Continue

    ; detect if laser < enemy right edge
    clc
    adc #8      ; +8 enemy width
    cmp PosX0+PLAYER_ROW
    bcc .Continue
    
    ; hit
    lda #<BlankGfx
    sta Sprites0,y
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
    lda Score+2
    adc #$25
    sta Score+2

    lda Score+1
    adc #$00
    sta Score+1

    lda Score
    adc #$00
    sta Score

    dey
    bne .Score

.Return
    cld
    rts

SpritePtrsClear SUBROUTINE
    lda #<BlankGfx
    ldx #>BlankGfx
    ldy #MAX_NUM_PTRS*2-2
.Gfx
    sta SpritePtrs,y
    stx SpritePtrs+1,y
    dey
    dey
    bpl .Gfx
    rts

; -----------------------------------------------------------------------------
; Desc:     Updates the ship's position and speed by the fixed point
;           integer values.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
ShipUpdatePosition SUBROUTINE
    ; update player's vertical position
    lda ScreenPosY
    clc
    adc ScreenSpeedY
    sta ScreenPosY

    ; update player's horizontal position
    lda PosX0+PLAYER_ROW
    clc
    adc SpeedX0+PLAYER_ROW
    cmp #MAX_POS_X
    bcs .HaltShip
    cmp #MIN_POS_X
    bcc .HaltShip
    sta PosX0+PLAYER_ROW
    jmp .Return
.HaltShip
    lda #0
    sta SpeedX0+PLAYER_ROW

.Return
    rts

EnemiesUpdatePosition SUBROUTINE
    ldy #MAX_ROWS-1
.Enemies
    lda Sprites0,y
    beq .Continue

    lda PosX0,y
    clc
    adc SpeedX0,y
    cmp #MAX_POS_X
    bcs .Reverse
    cmp #MIN_POS_X
    bcc .Reverse
    sta PosX0,y
    jmp .Continue
.Reverse
    ; flip the sign; positive <--> negative
    lda SpeedX0,y
    eor #$ff
    clc
    adc #1
    sta SpeedX0,y

.Continue
    dey
    bne .Enemies

    rts

UpdateVerticalPositions SUBROUTINE
    rts

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
    sta WSYNC

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
HorizPositionBG SUBROUTINE
    sec             ; 2 (8)
    sta WSYNC       ; 3 (11)
    sty COLUBK      ; 3 (3)
    sbc #15         ; 2 (5)

.Div15
    sbc #15         ; 2 (2)
    bcs .Div15      ; 3 (5)

    eor #7          ; 2 (11)
    asl             ; 2 (13)
    asl             ; 2 (15)
    asl             ; 2 (17)
    asl             ; 2 (19)

    sta RESP0,X     ; 4 (23)
    sta HMP0,X      ; 4 (27)
    rts

; performs horizontal positioning while drawing a playfield pattern
F; this must enter on or before cycle 62
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

PlayAudio SUBROUTINE
    ; play laser sounds
    lda JoyFire
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

SpawnSprite SUBROUTINE
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

    jsr SpawnTop
    jmp .Return

.Reverse
    lda ScreenPosY
    bpl .Return

    clc
    adc #PF_ROW_HEIGHT
    sta ScreenPosY
    
    jsr SpawnBottom

.Return
    rts

SpawnTop SUBROUTINE
    ; shift rows down
    ldy #1
.ShiftDown
    lda Sprites0+1,y
    sta Sprites0,y

    lda Sprites1+1,y
    sta Sprites1,y

    lda SpeedX0+1,y
    sta SpeedX0,y

    lda SpeedX1+1,y
    sta SpeedX1,y

    lda PosX0+1,y
    sta PosX0,y

    lda PosX1+1,y
    sta PosX1,y

    iny
    cpy #MAX_ROWS-1
    bne .ShiftDown

    ; load blank
    lda #<BlankGfx
    sta Sprites0+MAX_ROWS-1
    sta Sprites1+MAX_ROWS-1
    lda #0
    sta SpeedX0+MAX_ROWS-1
    sta SpeedX1+MAX_ROWS-1
    sta PosX0+MAX_ROWS-1
    sta PosX1+MAX_ROWS-1

    ; spawn replacements
    lda FrameCtr
    and #$0f
    cmp #8
    bcs .Blank1
    lda #<FighterGfx
    sta Sprites0+MAX_ROWS-1
    lda ScreenPosY
    asl
    adc #50
    sta PosX0+MAX_ROWS-1
    lda #1
    sta SpeedX0+MAX_ROWS-1
.Blank1

    lda FrameCtr
    eor INTIM
    and #3
    tax
    lda Buildings,x
    sta Sprites1+MAX_ROWS-1
    bcc .Blank2
    lda FrameCtr
    and #%00011111
    adc #90
    sta PosX1+MAX_ROWS-1
.Blank2
    rts

SpawnBottom SUBROUTINE
    ; shift rows up
    ldy #MAX_ROWS-1
.ShiftUp
    lda Sprites0-1,y
    sta Sprites0,y
    lda Sprites1-1,y
    sta Sprites1,y
    lda SpeedX0-1,y
    sta SpeedX0,y
    lda SpeedX1-1,y
    sta SpeedX1,y
    lda PosX0-1,y
    sta PosX0,y
    lda PosX1-1,y
    sta PosX1,y

    dey
    cpy #1
    bne .ShiftUp

    lda #<BlankGfx
    sta Sprites0+1
    sta Sprites1+1
    lda #0
    sta SpeedX0+1
    sta SpeedX1+1
    sta PosX0+1
    sta PosX1+1

    ; spawn replacements
    lda FrameCtr
    and #$0f
    cmp #8
    bcs .Blank1
    lda #<FighterGfx
    sta Sprites0+1
    lda ScreenPosY
    asl
    adc #75
    sta PosX0+1
    lda #1
    sta SpeedX0+1
.Blank1

    lda FrameCtr
    eor INTIM
    and #3
    tax
    lda Buildings,x
    sta Sprites1+1
    beq .Blank2
    lda FrameCtr
    and #%00011111
    adc #90
    sta PosX1+1
.Blank2

    rts
; -----------------------------------------------------------------------------
; Data
; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $b00

    include "dat/title-planet.pf"
    include "dat/title-proton.pf"
    include "dat/title-battle.sp"
    include "dat/title-copy.sp"
    include "dat/title-name.sp"

LaserGfx0
    dc.b %00000000
    dc.b %10000010
    dc.b %01010100
    dc.b %00101000
    dc.b %11111110
    dc.b %00101000
    dc.b %01010100
    dc.b %10000010
LaserGfx1
    dc.b %00000000
    dc.b %00010000
    dc.b %01010100
    dc.b %00101000
    dc.b %00111000
    dc.b %00101000
    dc.b %01010100
    dc.b %00010000

    ORG ORG_ADDR + $c00
GFX_BEGIN SET *

; BlankGfx must be on the page's first byte
BlankGfx
ShipGfx
    ds.b 16, 0

.Begin
    dc.b %00000000
    dc.b %00000000
    dc.b %01111100
    dc.b %01111100
    dc.b %11010110
    dc.b %10111010
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11010110
    dc.b %10010010
    dc.b %00010000
    dc.b %00000000
SHIP_HEIGHT = * - .Begin

FighterGfx
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %10000001
    dc.b %01000010
    dc.b %10100101
    dc.b %11000011
    dc.b %11111111
    dc.b %11100111
    dc.b %11100111
    dc.b %01111110
    dc.b %00111100
    dc.b %01011010
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
FIGHTER_HEIGHT = * - FighterGfx

#if 1
ExplosionGfx
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %10000001
    dc.b %11001010
    dc.b %00101001
    dc.b %01000100
    dc.b %00111011
    dc.b %01010100
    dc.b %11001011
    dc.b %00111010
    dc.b %01001000
    dc.b %10010010
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
EXPLOSION_HEIGHT = * - ExplosionGfx
#endif

CondoGfx
    dc.b %00000000
    dc.b %00000000
    dc.b %01111111
    dc.b %01111111
    dc.b %01010101
    dc.b %01010101
    dc.b %01111111
    dc.b %01010101
    dc.b %01010101
    dc.b %01111111
    dc.b %01110111
    dc.b %01000001
    dc.b %00100010
    dc.b %00011100
    dc.b %00000000
    dc.b %00000000
Condo_HEIGHT = * - CondoGfx

BaseGfx
    dc.b %00000000
    dc.b %00000000
    dc.b %01111110
    dc.b %11111111
    dc.b %11000011
    dc.b %10111101
    dc.b %10100101
    dc.b %10111101
    dc.b %10101001
    dc.b %10111011
    dc.b %11000011
    dc.b %00111100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
BASE_HEIGHT = * - BaseGfx

FuelGfx
    dc.b %00000000
    dc.b %00000000
    dc.b %00111110
    dc.b %01111111
    dc.b %01100011
    dc.b %01011101
    dc.b %01111111
    dc.b %01100011
    dc.b %01011101
    dc.b %01111111
    dc.b %01100011
    dc.b %01000001
    dc.b %00111110
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
FUEL_HEIGHT = * - FuelGfx

; this pattern is generated by ./bin/playfield.exe
; the last byte must be repeated.
PFPattern
    dc.b $6d, $e5, $b6, $0e, $c0, $a0, $b6, $ec
    dc.b $0d, $83, $09, $3a, $a0, $7e, $49, $6d
PF_ROW_HEIGHT = * - PFPattern

Digits
Digit0
    dc.b %00000000
    dc.b %00111000
    dc.b %01101100
    dc.b %01100110
    dc.b %01100110
    dc.b %00110110
    dc.b %00111100
DIGIT_HEIGHT = * - Digit0
Digit1
    dc.b %00000000
    dc.b %00110000
    dc.b %00110000
    dc.b %00011000
    dc.b %00011000
    dc.b %00011100
    dc.b %00001100
Digit2
    dc.b %00000000
    dc.b %01111100
    dc.b %00110000
    dc.b %00011000
    dc.b %00001100
    dc.b %01100110
    dc.b %00111100
Digit3
    dc.b %00000000
    dc.b %01111000
    dc.b %11001100
    dc.b %00011100
    dc.b %00001110
    dc.b %00100110
    dc.b %00011100
Digit4
    dc.b %00000000
    dc.b %00011000
    dc.b %00011000
    dc.b %00001100
    dc.b %11111100
    dc.b %01100110
    dc.b %01100110
Digit5
    dc.b %00000000
    dc.b %01111000
    dc.b %11001100
    dc.b %00001100
    dc.b %01111000
    dc.b %01100000
    dc.b %00111110
Digit6
    dc.b %00000000
    dc.b %00111100
    dc.b %01100110
    dc.b %01111100
    dc.b %00110000
    dc.b %00011100
    dc.b %00000110
Digit7
    dc.b %00000000
    dc.b %00110000
    dc.b %00110000
    dc.b %00011000
    dc.b %00001100
    dc.b %00000110
    dc.b %01111110
Digit8
    dc.b %00000000
    dc.b %01111000
    dc.b %11001100
    dc.b %11001100
    dc.b %01111110
    dc.b %00100110
    dc.b %00111110
Digit9
    dc.b %00000000
    dc.b %00110000
    dc.b %00011000
    dc.b %00001100
    dc.b %00111110
    dc.b %01100110
    dc.b %00111100

    IF >GFX_BEGIN != >*
        ECHO "(1) Graphics crossed a page boundary!", (GFX_BEGIN&$ff00), (*&$ff00)
    ENDIF
    ECHO "Page", (GFX_BEGIN&$ff00 ), "has", (((GFX_BEGIN+$100)&$ff00)-*)d, "bytes remaining"

DigitTable
    dc.b <Digit0, <Digit1, <Digit2, <Digit3, <Digit4
    dc.b <Digit5, <Digit6, <Digit7, <Digit8, <Digit9

Buildings
    dc.b <BlankGfx, <CondoGfx, <BaseGfx, <FuelGfx

    include "lib/ntsc.asm"
    include "lib/pal.asm"

; -----------------------------------------------------------------------------
; Audio data
; -----------------------------------------------------------------------------
EngineVolume SUBROUTINE
.range  SET [MAX_SPEED_Y>>FPOINT_SCALE]+1
.val    SET 0
.max    SET 6
.min    SET 2
    REPEAT .range
        dc.b [.val * [.max - .min]] / .range + .min
.val    SET .val + 1
    REPEND

EngineFrequency SUBROUTINE
.range  SET [MAX_SPEED_Y>>FPOINT_SCALE]+1
.val    SET .range
.max    SET 31
.min    SET 7
    REPEAT .range
        dc.b [.val * [.max - .min]] / .range + .min
.val    SET .val - 1
    REPEND

LASER_AUDIO_RATE    = %00000001
LASER_AUDIO_FRAMES  = 9

LaserVol
    ds.b 0, 6, 8, 6, 8, 6, 8, 6, 0
LaserCon
    dc.b $8, $8, $8, $8, $8, $8, $8, $8, $8
LaserFreq
    dc.b 0, 1, 0, 1, 0, 1, 0, 1, 0

; Procedure tables
ModeVertBlank
    dc.w TitleVertBlank     ; MODE_TITLE
    dc.w GameVertBlank      ; MODE_GAME
ModeKernel
    dc.w TitleKernel        ; MODE_TITLE
    dc.w GameKernel         ; MODE_GAME
ModeOverscan
    dc.w TitleOverscan      ; MODE_TITLE
    dc.w GameOverscan       ; MODE_GAME

#if 0
Mult6
    dc.b   0,   6,  12,  18,  24,  30,  36,  42,  48,  54
    dc.b  60,  66,  72,  78,  84,  90,  96, 102, 108, 114
    dc.b 120, 126, 132, 138, 144, 150, 156, 162, 168, 174
    dc.b 180, 186, 192, 198, 204, 210, 216, 222, 228, 234
    dc.b 240, 246, 252
#endif

    ECHO "Page", *&$ff00, "has", (* - (*&$ff00))d, "bytes remaining"

    ORG ORG_ADDR + $f00
; -----------------------------------------------------------------------------
; Desc:     Draws a 48-bit wide sprite centered on the screen.
;           Position GRP0 to pixel 56 (TIA cycle 124).
;           Position GRP1 to pixel 64 (TIA cycle 132).
; Input:    Y register (height-1)
; Output:
; -----------------------------------------------------------------------------
KERNEL_BEGIN SET *
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

; positioned on pixel 4 (TIA 72) and 12 (TIA 80)
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

    IF >KERNEL_BEGIN != >*
        ECHO "(3) Kernels crossed a page boundary!", (KERNEL_BEGIN&$ff00), (*&$ff00)
    ENDIF

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

#if 0
    lda #<TitleCopy0
    sta SpritePtrs+2
    lda #<TitleCopy1
    sta SpritePtrs+4
    lda #<TitleCopy2
    sta SpritePtrs+6

    lda #>TitleCopy
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7

    lda #<BlankGfx
    sta SpritePtrs
    sta SpritePtrs+8
    sta SpritePtrs+10
    lda #>BlankGfx
    sta SpritePtrs+1
    sta SpritePtrs+9
    sta SpritePtrs+11
#endif
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

    ECHO "Page", (*&$ff00), "has", ($fffa - *)d, "bytes remaining"

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $ffa
Interrupts
    dc.w Reset              ; NMI
    dc.w Reset              ; RESET
    dc.w Reset              ; IRQ
