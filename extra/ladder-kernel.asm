; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.1 (beta)
; Game:     The Battle for Proton
; -----------------------------------------------------------------------------
;
; Each row is stationary. The background moves within the row. Sprites cannot
; cross row boundaries without dropping scanlines.
;
;   +-------------------------+
;   |                         | <--- row 10
;   | ----------------------- |
;   |                         | <--- row 9
;   | ----------------------- |
;   |                         | <--- row 8
;   | ----------------------- |
;   |                         | <--- row 7
;   | ----------------------- |
;   |                         | <--- row 6
;   | ----------------------- |
;   |                         | <--- row 5
;   | ----------------------- |
;   |                         | <--- row 4
;   | ----------------------- |
;   |                         | <--- row 3
;   | ----------------------- |
;   |                         | <--- row 2
;   | ----------------------- |
;   |                         | <--- row 1
;   | ----------------------- |
;   |          /_\            | <--- row 0
;   +-------------------------+
;        |               |      <--- HUD row
;        +---------------+

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

MAX_NUM_SPRITES     = 11
MAX_NUM_PTRS        = 6

PLAYER_ROW          = 0

; -----------------------------------------------------------------------------
; Variables
; -----------------------------------------------------------------------------
    SEG.U ram
    ORG $80

FrameCtr        ds.b 1
Score           ds.b 3

; sprite data
Sprites0        ds.b MAX_NUM_SPRITES        ; gfx low byte = sprite type
Sprites1        ds.b MAX_NUM_SPRITES        ; gfx low byte = sprite type
SpeedX0         ds.b MAX_NUM_SPRITES
SpeedX1         ds.b MAX_NUM_SPRITES
PosX0           ds.b MAX_NUM_SPRITES
PosX1           ds.b MAX_NUM_SPRITES

; player motion
SpeedY          ds.b 1
PosY            ds.b 1

JoyFire         ds.b 1
LaserAudioFrame ds.b 1

; graphics data
SpritePtrs      ds.w MAX_NUM_PTRS
PfLine01        dc.b 1
PfLine02        dc.b 1
PfLine11        dc.b 1
PfLine12        dc.b 1

LocalVars       ds.b 14

Temp            = LocalVars+4
HUDHeight       = LocalVars+1

    ECHO "RAM used =", (* - $80)d, "bytes"
    ECHO "RAM free =", (128 - (* - $80))d, "bytes" 

; -----------------------------------------------------------------------------
; Rom Begin
; -----------------------------------------------------------------------------
    SEG rom
    ORG ORG_ADDR

Reset
    sei
    CLEAN_START

Init
    jsr SpawnBuildings
    jsr SpawnEnemies
    ; try to maintain stable line count if we got here from a reset

    jsr InitPlayer

    TIMER_WAIT

FrameStart
    jsr VerticalSync
    jsr VerticalBlank

    ; align the cycles for the first row
    sta WSYNC
    SLEEP_34

    ldy #10
    jsr EvenRowKernel
    ldy #9
    jsr OddRowKernel
    ldy #8
    jsr EvenRowKernel
    ldy #7
    jsr OddRowKernel
    ldy #6
    jsr EvenRowKernel
    ldy #5
    jsr OddRowKernel
    ldy #4
    jsr EvenRowKernel
    ldy #3
    jsr OddRowKernel
    ldy #2
    jsr EvenRowKernel
    ldy #1
    jsr OddRowKernel
    ldy #0
    jsr PlayerRowKernel

    jsr HUDSetup
    jsr HUDKernel

    jsr Overscan
    jmp FrameStart

; -----------------------------------------------------------------------------
; Desc:     Performs the vertical syncing.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
VerticalSync SUBROUTINE
    VERTICAL_SYNC
    rts

; -----------------------------------------------------------------------------
; Desc:     Performs the vertical blanking.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
VerticalBlank SUBROUTINE
    lda #[LINES_VBLANK-1]*76/64
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

#if 0
    ; update score as a timer for now
    sed
    lda FrameCtr
    and #32-1
    bne .SkipTime
.Time
    clc
    lda Score+2
    adc #1
    sta Score+2
    lda Score+1
    adc #0
    sta Score+1
    lda Score
    adc #0
    sta Score
.SkipTime
    cld
#endif

    ; preload the first two playfield lines to display during
    ; horizontal positioning

    lda #PF_ROW_HEIGHT                      ; 2 (2)
    clc                                     ; 2 (2)
    adc PosY                                ; 3 (3)
    and #PF_PATTERN_HEIGHT-1                ; 2 (2)
    tax
    lda PFPattern+PF_ROW_HEIGHT,x           ; 4 (4)
    sta PfLine01                            ; 3 (55)
    lda PFPattern+PF_ROW_HEIGHT-1,x         ; 4 (52)
    sta PfLine02                            ; 3 (55)

    lda #PF_ROW_HEIGHT                      ; 2 (2)
    clc                                     ; 2 (2)
    adc PosY                                ; 3 (3)
    and #PF_PATTERN_HEIGHT-1                ; 2 (2)
    tax
    lda PFPattern,x                         ; 4 (4)
    sta PfLine11                            ; 3 (55)
    lda PFPattern-1,x                       ; 4 (52)
    sta PfLine12                            ; 3 (55)

    ; clear sprite pointers
    jsr SpritePtrsClear
    jsr LaserCollision

    ; positon building sprites
    ldx #1
    lda #100
    jsr HorizPosition
    
    ; position the player missile
    ldx #3
    lda PosX1+PLAYER_ROW
    clc
    adc #4          ; adjust offset
    jsr HorizPosition

    sta WSYNC
    sta HMOVE

    lda #COLOR_LASER
    sta COLUP1

    ; enable/disable fire graphics
    ldx JoyFire
    stx ENAM1
    cpx #0
    bne .NoSound
    stx LaserAudioFrame
.NoSound

    TIMER_WAIT
   
    ; turn on the display
    lda #0
    sta VBLANK

    ; clear fine motion for subseuent HMOVEs
    sta HMM1
    sta HMP1

    rts

; -----------------------------------------------------------------------------
; Desc:     Blanks the screen and waits for the duration of the overscan time.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
Overscan SUBROUTINE
    sta WSYNC
    lda #2
    sta VBLANK
    lda #COLOR_BLACK
    sta COLUBK
    sta COLUPF

    lda #[LINES_OVERSCAN-1]*76/64
    sta TIM64T

    inc FrameCtr

    jsr ReadSwitches
    jsr ReadJoystick0
    jsr ShipUpdatePosition
    jsr EnemiesUpdatePosition2
    jsr PlayAudio

    jsr SpawnEnemies

    TIMER_WAIT
    rts

InitPlayer SUBROUTINE
    ; init player's sprite
    lda #<ShipGfx
    sta Sprites1,y
    lda #[SCREEN_WIDTH/2 - 4]
    sta PosX1,y
    lda #0
    sta PosY
    rts

InitTestSprites1 SUBROUTINE
    ; populate sprites with some values
    ldx #<FighterGfx
    ldy #MAX_NUM_SPRITES-1
.Pop
    ; init sprite
    stx Sprites0,y
    ; init horizontal position
    tya
    asl
    asl
    clc
    adc #30
    sta PosX0,y
    ; init speed
    lda #1
    sta SpeedX0,y
    dey
    bne .Pop

    rts

InitTestSprites2 SUBROUTINE
    ; populate sprites with some values
    ldy #MAX_NUM_SPRITES-1
    ldx #<FighterGfx
    stx Sprites0,y
    ; init horizontal position
    tya
    asl
    asl
    clc
    adc #30
    sta PosX0,y
    ; init speed
    lda #1
    sta SpeedX0,y

    ldy #0
    ; init player's sprite
    lda #<ShipGfx
    sta Sprites1,y
    lda #[SCREEN_WIDTH/2 - 4]
    sta PosX0,y
    lda #0
    sta PosY
    rts

SpawnBuildings SUBROUTINE
    lda #0
    ldy #MAX_NUM_SPRITES-1
.Loop
    ora Sprites1,y
    dey
    bne .Loop

    cmp #0
    bne .Return

    ; populate sprites with some values
    ;ldx #<BaseGfx
    ldx #<FuelGfx
    ldy #MAX_NUM_SPRITES-1
.Pop
    ; init sprite
    stx Sprites1,y

    lda #0
    sta SpeedX1,y

    dey
    bne .Pop

.Return
    rts
SpawnEnemies SUBROUTINE
    lda #0
    ldy #MAX_NUM_SPRITES-1
.Loop
    ora Sprites0,y
    dey
    bne .Loop

    cmp #0
    bne .Return

    ; populate sprites with some values
    ldx #<FighterGfx
    ldy #MAX_NUM_SPRITES-1
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

    ALIGN 256
EvenRowKernel SUBROUTINE
    tya                             ; 2 (44)
    pha                             ; 3 (47)

    ; Entering on cycle 34 + 8 = 42.
    ; Two lines of the playfield need to be written out during
    ; the horizontal positioning.

    ldx #0                          ; 2 (49)
    lda PosX0,y                     ; 4 (53)
    ldy PfLine01                    ; 3 (56)
    jsr HorizPositionPF             ; 6 (62)

    ; invoke fine horizontal positioning
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    lda PfLine02                    ; 3 (6)
    sta PF0                         ; 3 (9)
    sta PF1                         ; 3 (12)
    sta PF2                         ; 3 (15)

    ; setup sprite graphics pointer
    pla                             ; 4 (19)
    tay                             ; 2 (21)
    lda Sprites0,y                  ; 4 (25)
    sta SpritePtrs                  ; 3 (28)
    ;lda Sprites1,y                  ; 4 (32)
    ;sta SpritePtrs+2                ; 3 (35)

    ; draw the row using the top half of the playfield pattern
    ldy #PF_ROW_HEIGHT-2            ; 2 (30)
.Row
    tya                             ; 2 (41)
    clc                             ; 2 (43)
    adc PosY                        ; 3 (46)
    sta Temp                        ; 3 (49)
#if 0
    and #BASE_HEIGHT-1              ; 2 (51)
    adc Sprites1,y                  ; 4 (55)
    sta SpritePtrs+2                ; 3 (58)
#endif

    lda Temp                        ; 3 (61)
    and #PF_PATTERN_HEIGHT-1        ; 2 (63)
    tax                             ; 2 (65)
    lda PFPattern+PF_ROW_HEIGHT,x   ; 4 (69)
    tax                             ; 2 (71)
    lda #$08                        ; 2 (73)

    sta WSYNC                       ; 3 (0)

    stx PF0                         ; 3 (3)
    sta COLUP1                      ; 3 (6)
    lda ShipPalette0,y              ; 4 (10)
    sta COLUP0                      ; 3 (13)
    lda (SpritePtrs),y              ; 5 (18)
    sta GRP0                        ; 3 (21)
    stx PF1                         ; 3 (24)
    stx PF2                         ; 3 (27)
    lda (SpritePtrs+2),y            ; 5 (32)
    sta GRP1                        ; 3 (35)

    dey                             ; 2 (37)
    bne .Row                        ; 2 (39)

    rts                             ; 6 (34)

OddRowKernel SUBROUTINE
    tya                             ; 2 (44)
    pha                             ; 3 (47)

    ; Entering on cycle 34 + 8 = 42.
    ; Two lines of the playfield need to be written out during
    ; the horizontal positioning.

    ldx #0                          ; 2 (49)
    lda PosX0,y                     ; 4 (53)
    ldy PfLine11                    ; 3 (56)
    jsr HorizPositionPF             ; 6 (62)

    ; invoke fine horizontal positioning
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    lda PfLine12                    ; 3 (6)
    sta PF0                         ; 3 (9)
    sta PF1                         ; 3 (12)
    sta PF2                         ; 3 (15)

    ; setup sprite graphics pointer
    pla                             ; 4 (19)
    tay                             ; 2 (21)
    lda Sprites0,y                  ; 4 (25)
    sta SpritePtrs                  ; 3 (28)
    lda Sprites1,y                  ; 4 (32)
    sta SpritePtrs+2                ; 3 (35)

    ; draw the row using the bottom half of the playfield pattern
    ldy #PF_ROW_HEIGHT-2            ; 2 (30)
.Row
    clc                             ; 2 (41)
    tya                             ; 2 (43)
    adc PosY                        ; 3 (46)
    and #PF_PATTERN_HEIGHT-1        ; 2 (48)
    tax                             ; 2 (50)
    lda PFPattern,x                 ; 4 (54)
    tax                             ; 2 (56)
    lda #$08                        ; 2 (58)

    sta WSYNC
    sta COLUP1                      ; 3 (3)
    lda ShipPalette0,y              ; 4 (7)
    sta COLUP0                      ; 3 (10)
    lda (SpritePtrs+2),y            ; 5 (15)
    sta GRP1                        ; 3 (18)
    stx PF0                         ; 3 (21)
    stx PF1                         ; 3 (24)
    lda (SpritePtrs),y              ; 5 (29)
    sta GRP0                        ; 3 (32)
    stx PF2                         ; 3 (35)

    dey                             ; 2 (37)
    bne .Row                        ; 2 (39)
    rts                             ; 6 (34)

PlayerRowKernel SUBROUTINE
    tya                             ; 2 (44)
    pha                             ; 3 (47)

    ; Entering on cycle 34 + 8 = 42.
    ; Two lines of the playfield need to be written out during
    ; the horizontal positioning.

    ldx #0                          ; 2 (49)
    lda PosX1,y                     ; 4 (53)
    ldy PfLine01                    ; 3 (56)
    jsr HorizPositionPF             ; 6 (62)

    ; invoke fine horizontal positioning
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    lda PfLine02                    ; 3 (6)
    sta PF0                         ; 3 (9)
    sta PF1                         ; 3 (12)
    sta PF2                         ; 3 (15)

    ; setup sprite graphics pointer
    pla                             ; 4 (19)
    tay                             ; 2 (21)
    lda Sprites1,y                   ; 4 (25)
    sta SpritePtrs                  ; 3 (28)

    ; draw the row using the top half of the playfield pattern
    ldy #PF_ROW_HEIGHT-2            ; 2 (30)

.Row
    clc                             ; 2 (31)
    tya                             ; 2 (33)
    adc PosY                        ; 3 (36)
    and #PF_PATTERN_HEIGHT-1        ; 2 (2)
    tax                             ; 2 (38)
    lda PFPattern+PF_ROW_HEIGHT,x   ; 4 (42)
    tax                             ; 2 (45)

    sta WSYNC
    lda ShipPalette0,y              ; 4 (4)
    sta COLUP0                      ; 3 (7)
    lda (SpritePtrs),y              ; 5 (12)
    sta GRP0                        ; 3 (15)
    stx PF0                         ; 3 (18)
    stx PF1                         ; 3 (21)
    stx PF2                         ; 3 (24)
    dey                             ; 2 (26)
    bne .Row                        ; 2 (28)

    sty ENAM1                       ; 2 (30)
    rts                             ; 6 (36)

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

HUDKernel SUBROUTINE
    lda #$ff                    ; 2 (8)
    ldx #0                      ; 2 (10)
    ldy #1                      ; 2 (12)

    ; top border (3 lines)
    sta WSYNC
    stx COLUBK                  ; 3 (3)
    stx COLUPF                  ; 3 (6)
    sta PF0                     ; 3 (9)
    stx PF1                     ; 3 (12)
    stx PF2                     ; 3 (15)
    ; reflect playfield
    sty CTRLPF                  ; 3 (18)
    sty VDELP0
    sty VDELP1

    ; status panel (X = 0 from above)
    lda #72                     ; 2 (20)
    ldy HUDPalette              ; 3 (23)
    jsr HorizPositionBG

    lda #72+8                   ; 2 (2)
    ldx #1                      ; 2 (4)
    ldy HUDPalette+1            ; 3 (7)
    jsr HorizPositionBG

    lda HUDPalette+2            ; 3 (3)
    sta WSYNC
    sta HMOVE                   ; 3 (3)
    sta COLUBK                  ; 3 (6)

    ; 3 copies, medium spaced
    lda #%011                   ; 2 (8)
    sta NUSIZ0                  ; 3 (11)
    sta NUSIZ1                  ; 3 (14)

    lda #COLOR_WHITE            ; 2 (16)
    sta COLUP0                  ; 3 (19)
    sta COLUP1                  ; 3 (22)

    ldy #DIGIT_HEIGHT-1         ; 2 (24)
    sty HUDHeight               ; 3 (27)
.Loop
    ;                         Cycles  Pixel  GRP0  GRP0A    GRP1  GRP1A
    ; --------------------------------------------------------------------
    ldy HUDHeight           ; 3 (64)  (192)
    lda (SpritePtrs),y      ; 5 (69)  (207)
    sta GRP0                ; 3 (72)  (216)    D1     --      --     --
    sta WSYNC               ; 3 (75)  (225)
     ; --------------------------------------------------------------------
    lda (SpritePtrs+2),y    ; 5  (5)   (15)
    sta GRP1                ; 3  (8)   (24)    D1     D1      D2     --
    lda (SpritePtrs+4),y    ; 5 (13)   (39)
    sta GRP0                ; 3 (16)   (48)    D3     D1      D2     D2
    lda (SpritePtrs+6),y    ; 5 (21)   (63)
    sta Temp                ; 3 (24)   (72)
    lda (SpritePtrs+8),y    ; 5 (29)   (87)
    tax                     ; 2 (31)   (93)
    lda (SpritePtrs+10),y   ; 5 (36)  (108)
    tay                     ; 2 (38)  (114)
    lda Temp                ; 3 (41)  (123)             !
    sta GRP1                ; 3 (44)  (132)    D3     D3      D4     D2!
    stx GRP0                ; 3 (47)  (141)    D5     D3!     D4     D4
    sty GRP1                ; 3 (50)  (150)    D5     D5      D6     D4!
    sta GRP0                ; 3 (53)  (159)    D4*    D5!     D6     D6
    dec HUDHeight           ; 5 (58)  (174)                            !
    bpl .Loop               ; 3 (61)  (183)

    sta WSYNC
    lda HUDPalette+1
    sta COLUBK

    sta WSYNC
    lda HUDPalette
    sta COLUBK
    lda #0

    ; restore playfield
    sta WSYNC
    sta PF0
    sta COLUBK
    sta CTRLPF
    sta PF1
    sta PF2
    sta NUSIZ0
    sta NUSIZ1
    sta WSYNC
    sta VDELP0
    sta VDELP1

    rts

; -----------------------------------------------------------------------------
; Player input
; -----------------------------------------------------------------------------

ReadSwitches SUBROUTINE
    lda SWCHB
    and #SWITCH_RESET
    bne .Return
    jmp Reset
.Return
    rts

ReadJoystick0 SUBROUTINE
    ; update every even frame
    lda FrameCtr
    and #1
    bne .CheckMovement

    ; read joystick
    ldy SWCHA
    tya
    and #JOY0_RIGHT
    bne .CheckLeft
    lda SpeedX1+PLAYER_ROW
    bpl .Dec1           ; instant decceleration on change of direction
    lda #0
.Dec1
    clc
    adc #ACCEL_X
    cmp #MAX_SPEED_X+1
    bpl .CheckLeft
    sta SpeedX1+PLAYER_ROW

.CheckLeft
    tya
    and #JOY0_LEFT
    bne .CheckDown
    lda SpeedX1+PLAYER_ROW
    bmi .Dec2           ; instant decceleration on change of direction
    lda #0
.Dec2
    sec
    sbc #ACCEL_X
    cmp #MIN_SPEED_X
    bmi .CheckDown
    sta SpeedX1+PLAYER_ROW

.CheckDown
    tya
    and #JOY0_DOWN
    bne .CheckUp

    lda SpeedY
    sec
    sbc #ACCEL_Y
    cmp #MIN_SPEED_Y
    bmi .CheckUp
    sta SpeedY

.CheckUp
    tya
    and #JOY0_UP
    bne .CheckMovement

    lda SpeedY
    clc
    adc #ACCEL_Y
    cmp #MAX_SPEED_Y+1
    bpl .CheckMovement
    sta SpeedY

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
    lda SpeedX1+PLAYER_ROW
    beq .CheckFire
    bpl .Pos
    clc
    adc #FRICTION_X
    sta SpeedX1+PLAYER_ROW
    jmp .CheckFire
.Pos
    sec
    sbc #FRICTION_X
    sta SpeedX1+PLAYER_ROW

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

; -----------------------------------------------------------------------------
; Desc:     Detect collision between laser and enemies.
; Inputs:   A register (missile position)
; Outputs:
; -----------------------------------------------------------------------------
LaserCollision SUBROUTINE
    lda JoyFire
    beq .Return

    lda #0
    sta Temp
    
    ldy #MAX_NUM_SPRITES-1
.Loop
    lda Sprites0,y
    beq .Continue

    ; detect if laser > enemy left edge
    lda PosX0,y
    sec
    sbc #4      ; -4 adjust offset
    cmp PosX1+PLAYER_ROW
    bcs .Continue

    ; detect if laser < enemy right edge
    clc
    adc #8      ; +8 enemy width
    cmp PosX1+PLAYER_ROW
    bcc .Continue
    
    ; hit
    lda #<BlankGfx
    sta Sprites0,y
    inc Temp
    
.Continue
    dey
    bne .Loop

#if 1
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
#endif

.Return
    cld
    rts

; -----------------------------------------------------------------------------
; Desc:     Update SpritePtrs with blank sprite graphics.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
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
    lda PosY
    clc
    adc SpeedY
    sta PosY

    ; update player's horizontal position
    lda PosX1+PLAYER_ROW
    clc
    adc SpeedX1+PLAYER_ROW
    cmp #MAX_POS_X
    bcs .HaltShip
    cmp #MIN_POS_X
    bcc .HaltShip
    sta PosX1+PLAYER_ROW
    jmp .Return
.HaltShip
    lda #0
    sta SpeedX1+PLAYER_ROW

.Return
    rts

EnemiesUpdatePosition1 SUBROUTINE
    ; update enemies horizontal position
    ldy #MAX_NUM_SPRITES-1
.Enemies
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

EnemiesUpdatePosition2 SUBROUTINE
    ldy #MAX_NUM_SPRITES-1
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

; -----------------------------------------------------------------------------
; Desc:     Positions an object horizontally using the Battlezone algorithm.
;           lookup for fine adjustments.
; Input:    A register (screen pixel position)
;           X register (object index: 0 to 4)
; Output:   A register (fine positioning value)
; Notes:    Object indexes:
;               0 = Player 0
;               1 = Player 1
;               2 = Missile 0
;               3 = Missile 1
;               4 = Ball
;           Follow up with: sta WSYNC; sta HMOVE
; -----------------------------------------------------------------------------
HorizPosition SUBROUTINE
    sec             ; 2 (2)
    sta WSYNC

    ; coarse position timing
.Div15
    sbc #15         ; 2 (2)
    bcs .Div15      ; 3 (5)
    ; minimum cyles (2 loops): 5 + 4 = 9

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
; this must enter on cycle 57
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
    lda SpeedY
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

; -----------------------------------------------------------------------------
; Graphics data
; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $d00

SHIP_NUM_FRAMES = 3

GfxMSB = >*

BlankGfx
    ds.b 16, 0

ShipGfx
    dc.b %00000000
    dc.b %00000000
    dc.b %00010000
    dc.b %10010010
    dc.b %11010110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %10111010
    dc.b %11010110
    dc.b %01111100
    dc.b %01111100
    dc.b %00000000
SHIP_HEIGHT = * - ShipGfx

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


; doubled up for optimization (removes a modulo 32 inside the kernel)
; this is generated by ./bin/playfield.exe
PFPattern   ; 32 pixels
    dc.b $6d, $e5, $b6, $0e, $c0, $a0, $b6, $ec
    dc.b $0d, $83, $09, $3a, $a0, $7e, $49, $7f
    dc.b $34, $86, $a0, $88, $82, $3d, $9b, $18
    dc.b $82, $d2, $a0, $62, $10, $c8, $db, $12
PF_PATTERN_HEIGHT = * - PFPattern
    dc.b $6d, $e5, $b6, $0e, $c0, $a0, $b6, $ec
    dc.b $0d, $83, $09, $3a, $a0, $7e, $49, $7f
    dc.b $34, $86, $a0, $88, $82, $3d, $9b, $18
    dc.b $82, $d2, $a0, $62, $10, $c8, $db, $12
PF_ROW_HEIGHT = PF_PATTERN_HEIGHT/2

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
#if 0
    dc.b %00000000
    dc.b %01111000
    dc.b %11001100
    dc.b %11001100
    dc.b %01111110
    dc.b %00100110
    dc.b %00011100
#else
    dc.b %00000000
    dc.b %01111000
    dc.b %11001100
    dc.b %11001100
    dc.b %01111110
    dc.b %00100110
    dc.b %00111110
#endif

Digit9
    dc.b %00000000
    dc.b %00110000
    dc.b %00011000
    dc.b %00001100
    dc.b %00111110
    dc.b %01100110
    dc.b %00111100

DigitTable
    dc.b <Digit0, <Digit1, <Digit2, <Digit3, <Digit4
    dc.b <Digit5, <Digit6, <Digit7, <Digit8, <Digit9

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

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $ffa
Interrupts
    dc.w Reset  ; NMI    $fffa, $fffb
    dc.w Reset  ; RESET  $fffc, $fffd
    dc.w Reset  ; IRQ    $fffe, $ffff
