; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.1 (beta)
; Game:     The Battle for Proton
; -----------------------------------------------------------------------------
; Repeating kernel
;
;   virtual landscape
;   + . . . . . . . . . . . . +
;   .                         .
;   .                         .
;   .                         .
;   +-------------------------+
;   |                         | <--- section 0
;   | ----------------------- |
;   |                         | <--- section 1
;   | ----------------------- |
;   |                         | <--- section 2
;   | ----------------------- |
;   |                         | <--- section 3
;   | ----------------------- |
;   |                         | <--- section 4
;   | ----------------------- |
;   |          /_\            | <--- ShipY
;   +-------------------------+ <--- screen bottom
;   .                         .
;   .                         .
;   .                         .
;   + . . . . . . . . . . . . +
;

    processor 6502

    include "include/vcs.h"
    include "include/macro.h"
    include "include/video.h"
    include "include/time.h"
    include "include/io.h"
    include "include/position.h"

SEGMENTED = 1

; -----------------------------------------------------------------------------
; Definitions
; -----------------------------------------------------------------------------

ORG_ADDR            = $f000

COLOR_BG            = COLOR_DGREEN
COLOR_FG            = COLOR_GREEN
COLOR_HUD_SCORE     = COLOR_WHITE

FPOINT_SCALE        SET 1       ; fixed point integer bit format: 1111111.1

; bounds of the screen
MIN_POS_X           = 23 + 11
MAX_POS_X           = SCREEN_WIDTH - 11

; Max/min speed must be less than half the pattern height otherwise an
; optical illusion occurs giving the impression of reversing direction.
MAX_SPEED_Y         =  12 << FPOINT_SCALE
MIN_SPEED_Y         = -12 << FPOINT_SCALE
MAX_SPEED_X         =  3
MIN_SPEED_X         = -3
ACCEL_Y             =  1
ACCEL_X             =  1
FRICTION_X          =  1

MAX_NUM_SPRITES     = 13

; -----------------------------------------------------------------------------
; Variables
; -----------------------------------------------------------------------------
    SEG.U ram
    ORG $80

FrameCtr        ds.b 1
Score           ds.b 3

; sprites parameters (fixed point integers)
SpeedX          ds.b MAX_NUM_SPRITES
SpeedY          ds.b MAX_NUM_SPRITES
;Speed           ds.b MAX_NUM_SPRITES
PosX            ds.b MAX_NUM_SPRITES
PosY            ds.b MAX_NUM_SPRITES
Segment         ds.b MAX_NUM_SPRITES

SpritePtrs      ds.w 6

LocalVars       ds.b 14

PosYInt = LocalVars
PosXInt = LocalVars+1
PFTmp = LocalVars+2
PFTmp2  = LocalVars+3

Temp = LocalVars
HUDHeight = LocalVars+1

; -----------------------------------------------------------------------------
; Rom Begin
; -----------------------------------------------------------------------------
    SEG rom
    ORG ORG_ADDR

Reset
    sei
    CLEAN_START

Init
    ; load defaults
    lda #[SCREEN_WIDTH/2 - 4]
    sta PosX

    ; populate enemy 1
    ldy #1
    sta PosX,y
    lda #5
    sta PosY,y
    lda #1
    sta Segment,y
    sta SpeedX,y
    sta SpeedY,y

FrameStart
    jsr VerticalSync
    jsr VerticalBlank
    jsr Kernel
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

    ; update enemies
    jsr EnemyUpdate

    ; update score as a timer for now
    sed
;    lda FrameCtr
;    and #64-1
;    bne .SkipTime
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

    TIMER_WAIT
   
    lda #0
    sta VBLANK
    rts

    ALIGN 256
Kernel SUBROUTINE
    ; convert to integer and modulo 32
    lda PosY
    lsr
    and #PF_PATTERN_HEIGHT-1
    sta PosYInt

    ; preload the first two playfield lines to display during
    ; horizontal positioning
    tax
    lda PFPattern+PF_PATTERN_HEIGHT,x
    sta PFTmp
    lda PFPattern+PF_PATTERN_HEIGHT-1,x
    sta PFTmp2

    ; play field kernel
    ldy #PF_PATTERN_HEIGHT
.Row0
    clc                         ; 2 (31)
    tya                         ; 2 (33)
    adc PosYInt                 ; 3 (36)
    tax                         ; 2 (38)
    lda PFPattern,x             ; 4 (42)
    tax                         ; 2 (44)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs),y          ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    cpy #PF_PATTERN_HEIGHT/2    ; 2 (27)
    bne .Row0                   ; 2 (29)

    ; play field kernel
.Row1
    clc                         ; 2 (29)
    tya                         ; 2 (31)
    adc PosYInt                 ; 3 (34)
    tax                         ; 2 (36)
    lda PFPattern,x             ; 4 (40)
    tax                         ; 2 (42)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+2),y        ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    bne .Row1                   ; 2 (27)

    ; play field kernel
    ldy #PF_PATTERN_HEIGHT
.Row2
    clc                         ; 2 (31)
    tya                         ; 2 (33)
    adc PosYInt                 ; 3 (36)
    tax                         ; 2 (38)
    lda PFPattern,x             ; 4 (42)
    tax                         ; 2 (44)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+4),y        ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    cpy #PF_PATTERN_HEIGHT/2    ; 2 (27)
    bne .Row2                   ; 2 (29)

    ; play field kernel
.Row3
    clc                         ; 2 (29)
    tya                         ; 2 (31)
    adc PosYInt                 ; 3 (34)
    tax                         ; 2 (36)
    lda PFPattern,x             ; 4 (40)
    tax                         ; 2 (42)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+6),y        ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    bne .Row3                   ; 2 (27)

    ; play field kernel
    ldy #PF_PATTERN_HEIGHT
.Row4
    clc                         ; 2 (31)
    tya                         ; 2 (33)
    adc PosYInt                 ; 3 (36)
    tax                         ; 2 (38)
    lda PFPattern,x             ; 4 (42)
    tax                         ; 2 (44)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+8),y        ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    cpy #PF_PATTERN_HEIGHT/2    ; 2 (27)
    bne .Row4                   ; 2 (29)

    ; play field kernel
.Row5
    clc                         ; 2 (29)
    tya                         ; 2 (31)
    adc PosYInt                 ; 3 (34)
    tax                         ; 2 (36)
    lda PFPattern,x             ; 4 (40)
    tax                         ; 2 (42)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+10),y       ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    bne .Row5                   ; 2 (27)

    ; play field kernel
    ldy #PF_PATTERN_HEIGHT
.Row6
    clc                         ; 2 (31)
    tya                         ; 2 (33)
    adc PosYInt                 ; 3 (36)
    tax                         ; 2 (38)
    lda PFPattern,x             ; 4 (42)
    tax                         ; 2 (44)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+12),y       ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    cpy #PF_PATTERN_HEIGHT/2    ; 2 (27)
    bne .Row6                   ; 2 (29)

    ; play field kernel
.Row7
    clc                         ; 2 (29)
    tya                         ; 2 (31)
    adc PosYInt                 ; 3 (34)
    tax                         ; 2 (36)
    lda PFPattern,x             ; 4 (40)
    tax                         ; 2 (42)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+14),y       ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    bne .Row7                   ; 2 (27)

    ; play field kernel
    ldy #PF_PATTERN_HEIGHT
.Row8
    clc                         ; 2 (31)
    tya                         ; 2 (33)
    adc PosYInt                 ; 3 (36)
    tax                         ; 2 (38)
    lda PFPattern,x             ; 4 (42)
    tax                         ; 2 (44)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+16),y       ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    cpy #PF_PATTERN_HEIGHT/2    ; 2 (27)
    bne .Row8                   ; 2 (29)

    ; play field kernel
.Row9
    clc                         ; 2 (29)
    tya                         ; 2 (31)
    adc PosYInt                 ; 3 (34)
    tax                         ; 2 (36)
    lda PFPattern,x             ; 4 (40)
    tax                         ; 2 (42)
    sta WSYNC
    lda ShipPalette0,y          ; 4 (4)
    sta COLUP0                  ; 3 (7)
    lda (SpritePtrs+18),y       ; 4 (11)
    sta GRP0                    ; 3 (14)
    stx PF0                     ; 3 (17)
    stx PF1                     ; 3 (20)
    stx PF2                     ; 3 (23)
    dey                         ; 2 (25)
    bne .Row9                   ; 2 (27)

    ; the playfield needs to be written out during the horizontal positioning
    ldx #0                      ; 2 (29)
    lda PosX                    ; 3 (32)
    ldy PFTmp                   ; 3 (35)
    jsr HorizPositionPF         ; 6 (41)

    sta WSYNC
    sta HMOVE                   ; 3 (3)
    lda PFTmp2                  ; 3 (6)
    sta PF0                     ; 3 (9)
    sta PF1                     ; 3 (12)
    sta PF2                     ; 3 (15)

    ; ship's kernel
    ldy #PF_PATTERN_HEIGHT-2    ; 2 (19)
.ShipRow
    clc                         ; 2 (17)
    tya                         ; 2 (25)
    adc PosYInt                 ; 2 (27)
    tax                         ; 2 (29)
    lda PFPattern,x             ; 4 (33)
    ldx ShipGfx,y               ; 4 (37)

    sta WSYNC
    sta PF0                     ; 3 (3)
    sta PF1                     ; 3 (6)
    sta PF2                     ; 3 (9)
    stx GRP0                    ; 3 (12)
    lda ShipPalette0,y          ; 4 (16)
    sta COLUP0                  ; 3 (19)

    dey                         ; 2 (21)
    cpy #PF_PATTERN_HEIGHT/2    ; 2 (27)
    bne .ShipRow                ; 2 (23)
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
    ;lda #88                     ; 2 (20)
    lda #72                     ; 2 (20)
    ldy HUDPalette              ; 3 (23)
    jsr HorizPositionBG

    ;lda #96                     ; 2 (2)
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

    lda #LINES_OVERSCAN*76/64
    sta TIM64T

    inc FrameCtr
    jsr ReadJoystick0
    jsr ShipUpdatePosition

    TIMER_WAIT
    rts

; -----------------------------------------------------------------------------
; Physics
; -----------------------------------------------------------------------------

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
    lda SpeedX
    bpl .Dec1           ; instant decceleration on change of direction
    lda #0
.Dec1
    clc
    adc #ACCEL_X
    cmp #MAX_SPEED_X+1
    bpl .CheckLeft
    sta SpeedX

.CheckLeft
    tya
    and #JOY0_LEFT
    bne .CheckDown
    lda SpeedX
    bmi .Dec2           ; instant decceleration on change of direction
    lda #0
.Dec2
    sec
    sbc #ACCEL_X
    cmp #MIN_SPEED_X
    bmi .CheckDown
    sta SpeedX

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
    bne .Return

    ; deccelerate horizontal motion when there's no input
    tya 
    and #JOY0_LEFT | JOY0_RIGHT
    cmp #JOY0_LEFT | JOY0_RIGHT
    bne .Return
    lda SpeedX
    beq .Return
    bpl .Pos
    clc
    adc #FRICTION_X
    sta SpeedX
    jmp .Return
.Pos
    sec
    sbc #FRICTION_X
    sta SpeedX

.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Updates the ship's position and speed by the fixed point
;           integer values.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
EnemyUpdate SUBROUTINE
    lda #<BlankGfx
    ldx #>BlankGfx
    ldy #MAX_NUM_SPRITES*2-2
.Gfx
    sta SpritePtrs,y
    stx SpritePtrs+1,y
    dey
    dey
    bpl .Gfx

    lda #<FighterGfx
    sta SpritePtrs
    lda #>FighterGfx
    sta SpritePtrs+1

    rts

; -----------------------------------------------------------------------------
; Desc:     Updates the ship's position and speed by the fixed point
;           integer values.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
ShipUpdatePosition SUBROUTINE
;    lda FrameCtr
;    and #%00000111
;    bne .Return

    ; update vertical position
    lda PosY
    clc
    adc SpeedY
    sta PosY

    lda PosX
    clc
    adc SpeedX
    cmp #MAX_POS_X
    bcs .HaltShip
    cmp #MIN_POS_X
    bcc .HaltShip
    sta PosX
    rts
.HaltShip
    lda #0
    sta SpeedX
.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Positions an object horizontally using the Battlezone algorithm.
;           lookup for fine adjustments.
; Input:    A register (screen pixel position)
;           X register (object index: 0 to 4)
; Output:
; Notes:    Object indexes:
;               0 = Player 0
;               1 = Player 1
;               2 = Missile 0
;               3 = Missile 1
;               4 = Ball
;           Follow up with: sta WSYNC; sta HMOVE
; -----------------------------------------------------------------------------
HorizPosition SUBROUTINE               ; 6 (6)  
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

; sets a background color for the line consumed by positioning
HorizPositionBG SUBROUTINE ; 6 (6)  
    sec             ; 2 (8)
    sta WSYNC       ; 3 (11)
    sty COLUBK      ; 3 (3)
    sbc #15         ; 2 (5)

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

HorizPositionPF SUBROUTINE              ; 6 (6)  
    SLEEP 6         ; 6 (53)
    sty PF0         ; 3 (56)
    SLEEP 8         ; 8 (64)
    sec             ; 2 (66)
    sty PF1         ; 3 (69)
    sty PF2         ; 3 (72)
    sta WSYNC

    ; coarse position timing
.Div15
    sbc #15         ; 4 (7)
    bcs .Div15      ; 5 (12)

    ; computing fine positioning value
    eor #7          ; 2 (14)            ; 4 bit signed subtraction
    asl             ; 2 (16)
    asl             ; 2 (18)
    asl             ; 2 (20)
    asl             ; 2 (22)

    ; position
    sta RESP0,X     ; 4 (26)            ; coarse position
    sta HMP0,X      ; 4 (30)            ; fine position
    rts

HorizPosition4 SUBROUTINE               ; 6 (6)  
    sec             ; 2 (8)

    ; coarse position timing
.Div15
    sbc #15<<3      ; 2 (10)
    bcs .Div15      ; 2/3 (12)

    ; computing fine positioning value
    eor #%00111000  ; 2 (14)            ; 4 bit signed subtraction
    asl             ; 2 (16)

    ; position
    sta HMP0        ; 3 (19)            ; fine position
    sta RESP0,X     ; 4 (23)            ; coarse position

    rts             ; 6 (29)

; -----------------------------------------------------------------------------
; Graphics data
; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $d00

SHIP_NUM_FRAMES = 3

ShipGfx
    ds.b 16, 0
ShipStart
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %10000010
    dc.b %11000110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %10111010
    dc.b %11000110
    dc.b %01111100
    dc.b %01111100
    dc.b %00000000
SHIP_HEIGHT = * - ShipStart

FighterGfx
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
    dc.b %00000000
FIGHTER_HEIGHT = * - FighterGfx
    ds.b 16, 0

BaseGfx
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %01111111
    dc.b %01111111
    dc.b %01010101
    dc.b %01010101
    dc.b %01111111
    dc.b %01111111
    dc.b %01010101
    dc.b %01010101
    dc.b %00111110
    dc.b %00111110
    dc.b %00001000
    dc.b %00000000

BlankGfx
    ds.c 33, 0

; doubled up for optimization (removes a modulo 32 inside the kernel)
; this is generated by ./bin/playfield.exe
PFPattern
    dc.b $6d, $e5, $b6, $0e, $c0, $a0, $b6, $ec
    dc.b $0d, $83, $09, $3a, $a0, $7e, $49, $7f
    dc.b $34, $86, $a0, $88, $82, $3d, $9b, $18
    dc.b $82, $d2, $a0, $62, $10, $c8, $db, $12
PF_PATTERN_HEIGHT = * - PFPattern
    dc.b $6d, $e5, $b6, $0e, $c0, $a0, $b6, $ec
    dc.b $0d, $83, $09, $3a, $a0, $7e, $49, $7f
    dc.b $34, $86, $a0, $88, $82, $3d, $9b, $18
    dc.b $82, $d2, $a0, $62, $10, $c8, $db, $12

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

#if VIDEO_MODE == VIDEO_NTSC

;ShipPalette0
;    ;      1    2    3    4    5    6    7    8    9   10   11
;    ;                          v---v--- flames
;    dc.b $00, $00, $00, $2e, $2a, $22, $02, $04, $06, $08, $0e
;    dc.b $0a, $0e, $06, $08, $0a, $0c, $4e, $46, $0e, $08, $00
;    ;                       blinking ----^----^
;ShipPalette1
;    ;      1    2    3    4    5    6    7    8    9   10   11
;    ;      v---- missile color
;    dc.b $2e, $00, $00, $3a, $36, $32, $02, $04, $06, $08, $0e
;    dc.b $0a, $0e, $06, $08, $0a, $0c, $86, $8e, $0e, $08, $00
;ShipPalette2
;    ;      1    2    3    4    5    6    7    8    9   10   11
;    ;      v---- missile color
;    dc.b $2e, $00, $00, $46, $44, $42, $02, $04, $06, $08, $0e
;    dc.b $0a, $0e, $06, $08, $0a, $0c, $46, $86, $0e, $08, $00
;ShipPalette3
;    ;      v---- missile color
;    dc.b $2e

ShipPalette0
    ds.b 16, 0
    dc.b $00
    dc.b $00
    dc.b $00
    dc.b $08
    dc.b $06 ; *
    dc.b $04 ; *
    dc.b $84 ; *
    dc.b $86 ; *
    dc.b $88 ; *
    dc.b $8a ; *
    dc.b $08 ; *
    dc.b $08 ; *
    dc.b $0a ; *
    dc.b $0c ; *
    dc.b $08 ; *
    dc.b $00

HUDPalette
    dc.b $08, $00, $80

#endif

#if VIDEO_MODE == VIDEO_PAL
ShipPalette0
    ;      1    2    3    4    5    6    7    8    9   10   11
    ;                          v---v--- flames
    dc.b $00, $00, $00, $2e, $2a, $22, $02, $04, $06, $08, $0e
    dc.b $0a, $0e, $06, $08, $0a, $0c, $4e, $46, $0e, $08, $00
    ;                       blinking ----^----^
ShipPalette1
    ;      1    2    3    4    5    6    7    8    9   10   11
    ;      v---- missile color
    dc.b $2e, $00, $00, $3a, $36, $32, $02, $04, $06, $08, $0e
    dc.b $0a, $0e, $06, $08, $0a, $0c, $86, $8e, $0e, $08, $00
ShipPalette2
    ;      1    2    3    4    5    6    7    8    9   10   11
    ;      v---- missile color
    dc.b $2e, $00, $00, $46, $44, $42, $02, $04, $06, $08, $0e
    dc.b $0a, $0e, $06, $08, $0a, $0c, $46, $86, $0e, $08, $00
ShipPalette3
    ;      v---- missile color
    dc.b $2e

HUDPalette
    dc.b $08, $00, $80
#endif

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG ORG_ADDR + $ffa
Interrupts
    dc.w Reset  ; NMI    $fffa, $fffb
    dc.w Reset  ; RESET  $fffc, $fffd
    dc.w Reset  ; IRQ    $fffe, $ffff
