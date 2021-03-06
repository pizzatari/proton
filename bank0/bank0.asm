    ORG BANK0_ORG
    RORG BANK0_RORG

Bank0_Reset
    nop     ; 3 bytes for bit instruction
    nop
    nop

    sei
    CLEAN_START
	cli
    jsr Bank0_TitleInit
    TIMER_WAIT

Bank0_TitleLoop SUBROUTINE
    inc FrameCtr
	jsr Bank0_TitleVertBlank
	jsr Bank0_TitleKernel
	jsr Bank0_TitleOverscan
	jmp Bank0_TitleLoop

Bank0_WaveLoop SUBROUTINE
    inc FrameCtr
	jsr Bank0_WaveVertBlank
	jsr Bank0_WaveKernel
	jsr Bank0_WaveOverscan
	jmp Bank0_WaveLoop

; -----------------------------------------------------------------------------
; Title code
; -----------------------------------------------------------------------------
Bank0_TitleInit
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

Bank0_TitleVertBlank SUBROUTINE
    VERTICAL_SYNC

    lda #VBLANK_HEIGHT*76/64
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

    ldx #0
    jsr Bank0_SetTitleGfx
    lda #<Bank0_BlankGfx
    sta SpritePtrs+8
    sta SpritePtrs+10
    lda #>Bank0_BlankGfx
    sta SpritePtrs+9
    sta SpritePtrs+11

    ldx #P0_OBJ
    lda #19
    jsr Bank0_HorizPosition
    ldx #P1_OBJ
    lda #19+8
    jsr Bank0_HorizPosition
    sta WSYNC
    sta HMOVE

    jsr Bank0_TitleAnimate

    TIMER_WAIT
    sta VBLANK      ; turn on the display
    sta CTRLPF
    rts

Bank0_TitleKernel SUBROUTINE
    sta WSYNC                   ; WSYNC for timing
    lda #COLOR_BLACK            ; 2 (2)
    sta COLUBK                  ; 3 (5)
    sta COLUPF                  ; 3 (8)

    ; ------------------------------------------------------------------------
    ; blank space
    ; ------------------------------------------------------------------------
    SLEEP_LINES 84              ; 84 (16)

    lda #3
    sta VDELP0                  ; 3 (19)
    sta VDELP1                  ; 3 (22)
    sta NUSIZ0                  ; 3 (25)
    sta NUSIZ1                  ; 3 (28)

    lda #COLOR_WHITE            ; 2 (30)
    sta COLUP0                  ; 2 (32)
    sta COLUP1                  ; 2 (34)

    lda #0                      ; 2 (36)
    sta GRP0                    ; 3 (39) 
    sta GRP1                    ; 3 (42) 
    sta GRP0                    ; 3 (45) 
    lda #$ff                    ; 2 (47)
    sta PF0                     ; 3 (50)

    ; ------------------------------------------------------------------------
    ; planet
    ; ------------------------------------------------------------------------
    clc                         ; 2 (52)
    ldy #TITLEPLANET_HEIGHT*4-1         ; 2 (54)
.TitleLoop
    tya                         ; 2 (58)
    lsr                         ; 2 (60)
    lsr                         ; 2 (62)
    sta WSYNC
    tax                         ; 2 (2)
    lda #$ff                    ; 2 (4)
    sta PF1                     ; 3 (7)
    sta PF2                     ; 3 (10)
    lda TitlePalette,x          ; 4 (14)
    sta COLUBK                  ; 3 (17)
    SLEEP 20                    ; 20 (37)
    lda TitlePlanet1,x          ; 4 (41)
    sta PF1                     ; 3 (44)
    lda TitlePlanet2,x          ; 4 (48)
    sta PF2                     ; 3 (51)
    dey                         ; 2 (53)
    cpy #4                      ; 2 (55) 
    bpl .TitleLoop              ; 2 (57)

    ldy #4-1                    ; 2 (59)
    jsr Bank0_DrawTitleSprite         ; 6 (65)    returns on cycle 18

    ; ------------------------------------------------------------------------
    ; 1 (19) line blank spacer
    ; ------------------------------------------------------------------------
    ldy #0                      ; 2 (21)
    sta GRP0                    ; 3 (24)
    sta GRP1                    ; 3 (27)

    ldx #P0_OBJ                 ; 2 (29)
    lda #164                    ; 2 (31)
    jsr Bank0_HorizPositionBG         ; 6 (37)

    lda #0                      ; 2 (20)
    sta NUSIZ0                  ; 3 (23)
    sta NUSIZ1                  ; 3 (26)
    sta VDELP0                  ; 3 (29)
    sta VDELP1                  ; 3 (32)
    ldx #COLOR_YELLOW           ; 2 (34)
    sta WSYNC
    sta HMOVE                   ; 3 (37) 
    sta PF0                     ; 3 (40)
    sta PF1                     ; 3 (43)
    sta PF2                     ; 3 (46)
    stx COLUPF                  ; 3 (49)

    ; ------------------------------------------------------------------------
    ; laser top
    ; ------------------------------------------------------------------------
    ldy #7                      ; 2 (51)
.Laser0
    lda (LaserPtr),y            ; 5 (5)
    sta GRP0                    ; 3 (3)
    sta WSYNC
    dey                         ; 2 (5)
    cpy #4                      ; 2 (7)
    bne .Laser0                 ; 2 (9)

    ; ------------------------------------------------------------------------
    ; laser middle line
    ; ------------------------------------------------------------------------
    lda (LaserPtr),y            ; 5 (14)
    ldy #0                      ; 2 (16)
    sta GRP0                    ; 3 (19)

    lda LaserPF                 ; 3 (22)
    ldx LaserPF+1               ; 3 (25)

    sta WSYNC
    sta PF0                     ; 3 (3)
    stx PF1                     ; 3 (6)
    lda LaserPF+2               ; 3 (9)
    sta PF2                     ; 3 (12)

    SLEEP_21                    ; 21 (33)
    lda LaserPF+3               ; 3 (36)
    sta PF0                     ; 3 (39)
    lda LaserPF+4               ; 3 (42)
    sta PF1                     ; 3 (45)
    lda LaserPF+5               ; 3 (48)
    sta PF2                     ; 3 (51)

    ; ------------------------------------------------------------------------
    ; laser bottom
    ; ------------------------------------------------------------------------
    ldx #0                      ; 2 (54)
    ldy #3                      ; 2 (56)
.Laser1
    lda LaserGfx0,y             ; 4 (21)
    lda (LaserPtr),y            ; 5 (26)
    sta WSYNC
    sta GRP0                    ; 3 (3)
    stx PF0                     ; 3 (6)
    stx PF1                     ; 3 (9)
    stx PF2                     ; 3 (12)
    dey                         ; 2 (14)
    bpl .Laser1                 ; 2 (16)

    lda #0                      ; 2 (18)
    sta GRP0                    ; 3 (21)

    ; ------------------------------------------------------------------------
    ; PROTON title
    ; ------------------------------------------------------------------------
    clc                         ; 2 (23)
    ldy #TITLEPROTON_HEIGHT-1    ; 2 (25)
.NameLoop
    tya                         ; 2 (60)
    sta WSYNC
    tax                         ; 2 (2)
    lda TitleAuthorPalette,x      ; 4 (6)
    sta COLUPF                  ; 3 (9)
    lda TitleProton0,x          ; 4 (13)
    sta PF0                     ; 3 (16)
    lda TitleProton1,x          ; 4 (20)
    sta PF1                     ; 3 (23)
    lda TitleProton2,x          ; 4 (27)
    sta PF2                     ; 3 (30)
    nop                         ; 2 (32)
    lda TitleProton3,x          ; 4 (36)
    sta PF0                     ; 3 (39)
    lda TitleProton4,x          ; 4 (43)
    sta PF1                     ; 3 (46)
    lda TitleProton5,x          ; 4 (50)
    sta PF2                     ; 3 (53)
    dey                         ; 2 (55)
    bpl .NameLoop               ; 2 (57)

    ; ------------------------------------------------------------------------
    ; blank space
    ; ------------------------------------------------------------------------
    lda #0                      ; 2 (59)
    sta WSYNC
    sta PF0                     ; 3 (3)
    sta PF1                     ; 3 (6) 
    sta PF2                     ; 3 (9)

    ; ------------------------------------------------------------------------
    ; copyright
    ; ------------------------------------------------------------------------
    ldx #P0_OBJ
    lda #71
    jsr Bank0_HorizPosition
    ldx #P1_OBJ
    lda #71+8
    jsr Bank0_HorizPosition
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

    SLEEP_LINES 35

    ldx #1
    jsr Bank0_SetTitleGfx
    lda #<TitleCopy4
    sta SpritePtrs+8
    lda #>TitleCopy4
    sta SpritePtrs+9

	lda #<Bank0_BlankGfx
	sta SpritePtrs+10
	lda #>Bank0_BlankGfx
	sta SpritePtrs+11

    ldy #7-1
    jsr Bank0_DrawWideSprite56

    ldx #2
    jsr Bank0_SetTitleGfx
    lda #<TitleAuthor4
    sta SpritePtrs+8
    lda #<TitleAuthor5
    sta SpritePtrs+10
    lda #>TitleAuthor5
    sta SpritePtrs+11

    ldy #5-1
    jsr Bank0_DrawWideSprite56

    lda #0
    sta VDELP0
    sta VDELP1
    sta GRP0
    sta GRP1
    sta NUSIZ0
    sta NUSIZ1

    SLEEP_LINES 2
    rts

Bank0_TitleOverscan SUBROUTINE
    sta WSYNC
    lda #2
    sta VBLANK

    lda #[OVERSCAN_HEIGHT-1]*76/64
    sta TIM64T

    lda #COLOR_BLACK
    sta COLUBK
    sta COLUPF

	; check fire button
    lda #JOY_FIRE
    bit INPT4
    bne .Continue
	jsr Bank0_WaveInit
	pla				; remove current subroutine from stack
	pla
	TIMER_WAIT
	jmp Bank0_WaveLoop

.Continue
    TIMER_WAIT
    rts

Bank0_TitleAnimate SUBROUTINE
    lda FrameCtr
    cmp #255
    bne .Anim
    jsr Bank0_TitleInit
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
Bank0_WaveInit SUBROUTINE
    lda #MODE_WAVE
    sta Mode
    lda #JOY_DELAY
    sta Delay
    jsr Bank0_SpritePtrsClear
    lda #0
    sta GRP0
    sta GRP1
    sta GRP0
	sta PF0
	sta PF1
	sta PF2
    lda #3
    sta VDELP0              ; 3 (19)
    sta VDELP1              ; 3 (22)
    sta NUSIZ0              ; 3 (25)
    sta NUSIZ1              ; 3 (28)
	rts

	;TIMER_WAIT				; wait for overscan to finish

Bank0_WaveVertBlank SUBROUTINE
    VERTICAL_SYNC

    lda #VBLANK_HEIGHT*76/64
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

    lda #<Bank0_Digit0
    sta SpritePtrs+8
    lda #<Bank0_Digit1
    sta SpritePtrs+10

    lda #>Bank0_Digits
    sta SpritePtrs+9
    sta SpritePtrs+11

    lda #71
    ldx #P0_OBJ
    jsr Bank0_HorizPosition
    lda #71+8
    ldx #P1_OBJ
    jsr Bank0_HorizPosition
    sta WSYNC
    sta HMOVE

    TIMER_WAIT
    sta VBLANK      ; turn on the display
    sta CTRLPF
    rts

Bank0_WaveKernel SUBROUTINE
    ldy #96+1
.Top
    sty WSYNC
    dey
    bne .Top

    ldy #DIGIT_HEIGHT-1
    jsr Bank0_DrawWideSprite56

    ldy #96-DIGIT_HEIGHT
.Bot
    sty WSYNC
    dey
    bne .Bot
	
    rts

Bank0_WaveOverscan SUBROUTINE
    sta WSYNC
    lda #2
    sta VBLANK

    lda #[OVERSCAN_HEIGHT-1]*76/64
    sta TIM64T

	; joystick input with delay
    lda Delay
    bne .Decrement
    lda #JOY_FIRE
    bit INPT4
    bne .CheckReset
Debug
	pla						; remove current subroutine from stack
	pla
    JUMP_BANK PROC_GAME_INIT, 1, 0
.Decrement
	dec Delay
	
	; check for reset button
.CheckReset
    lda SWCHB
    and #SWITCH_RESET
    bne .Continue
    jmp Bank0_Reset
.Continue

    TIMER_WAIT
    rts

Bank0_GameIO SUBROUTINE
    lda SWCHB
    and #SWITCH_RESET
    bne .Joystick
    jmp Bank0_Reset

.Joystick
;    lda Delay
;    beq .Continue
;    rts

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
    eor #$ff
    and #JOY_FIRE
    clc
    rol
    rol
    rol
    sta PlyrFire

.Return
    rts

Bank0_InitScreen SUBROUTINE
    ; init screen
    lda #8
    sta ScreenPosY
    lda #0
    sta ScreenSpeedY
    rts

Bank0_SpritePtrsClear SUBROUTINE
    lda #<Bank0_BlankGfx
    sta SpritePtrs
    sta SpritePtrs+2
    sta SpritePtrs+4
    sta SpritePtrs+6
    sta SpritePtrs+8
    sta SpritePtrs+10
    lda #>Bank0_BlankGfx
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
    rts

; -----------------------------------------------------------------------------
; Desc:     Assigns first 4 pointers. The 5th and 6th pointers may or may not
;           be blanks.
; Input:    X register (0=battle title, 1=copyright, 2=author)
; Param:    
; Output:
; Notes:    
; -----------------------------------------------------------------------------
Bank0_SetTitleGfx SUBROUTINE
    lda TitleGfxLo0,x
    sta SpritePtrs

    lda TitleGfxLo1,x
    sta SpritePtrs+2

    lda TitleGfxLo2,x
    sta SpritePtrs+4

    lda TitleGfxLo3,x
    sta SpritePtrs+6

    lda #>TitleGfx
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    rts

TitleGfxLo0
    dc.b <TitleBattle0, <TitleCopy0, <TitleAuthor0
TitleGfxLo1
    dc.b <TitleBattle1, <TitleCopy1, <TitleAuthor1
TitleGfxLo2
    dc.b <TitleBattle2, <TitleCopy2, <TitleAuthor2
TitleGfxLo3
    dc.b <TitleBattle3, <TitleCopy3, <TitleAuthor3

    ; platform depedent data
    include "sys/bank0_palette.asm"
    include "sys/bank0_audio.asm"
    PAGE_BYTES_REMAINING

    ALIGN 256, $ea
    PAGE_BOUNDARY_SET
TitleGfx
    include "gen/title-battle.sp"
    include "gen/title-author.sp"
    include "gen/title-copy.sp"
    PAGE_BOUNDARY_CHECK "TitleCopy"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
; Desc:     Basic joystick handler. Advances the mode on joystick press.
; Input:    X register (next mode)
; Output:
; -----------------------------------------------------------------------------
Bank0_GeneralIO SUBROUTINE
    lda SWCHB
    and #SWITCH_RESET
    bne .Joystick
    jmp Bank0_Reset

.Joystick
    lda #JOY_FIRE
    bit INPT4
    bne .Return
    
    stx Mode
    ;lda #PROC_INIT
    ;jsr Bank0_CallProcedure
.Return
    rts

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $b00
    RORG BANK0_RORG + $b00

    PAGE_BOUNDARY_SET
Bank0_PlayAudio SUBROUTINE
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

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $c00
    RORG BANK0_RORG + $c00

    PAGE_BOUNDARY_SET
; -----------------------------------------------------------------------------
; Desc:     Draws a 48-bit wide sprite centered on the screen using the
;           Dragster algorithm.
; Input:    Y register (height-1)
; Output:
; Notes:    Position GRP0 to TIA cycle 124 (on-screen pixel 56)
;           Position GRP1 to TIA cycle 132 (on-screen pixel 64)
; -----------------------------------------------------------------------------
Bank0_DrawWideSprite56 SUBROUTINE ; 6 (6)
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

	lda #0					; 2 (63)
	sta GRP0				; 3 (66)
	sta GRP1				; 3 (69)
	sta GRP0				; 3 (72)

    rts                     ; 6 (2)

; positioned on TIA cycle 72 and 80 (on-screen pixel 4 and 12)
Bank0_DrawTitleSprite SUBROUTINE
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
Bank0_HorizPosition SUBROUTINE
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
Bank0_HorizPositionBG SUBROUTINE  ; 6 (6)
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
Bank0_HorizPositionPF SUBROUTINE
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

; -----------------------------------------------------------------------------
; Desc:     Calls the named procedure for the game mode.
; Input:    A register (procedure index)
;			Mode
; Param:
; Output:
; -----------------------------------------------------------------------------
#if 0
Bank0_CallProcedure SUBROUTINE
    clc
    ror
    ror
    ora Mode
    rol
    rol
    tay
    lda ProceduresLo,y
    sta TempPtr
    lda ProceduresHi,y
    sta TempPtr+1

    lda #>[.Return-1]
    pha
    lda #<[.Return-1]
    pha
    jmp (TempPtr)
.Return
    rts
#endif

    include "bank0/digits.asm"

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $e00
    RORG BANK0_RORG + $e00

    PAGE_BOUNDARY_SET
    include "gen/title-planet.pf"
    include "gen/title-proton.pf"
    include "gen/wave-text.sp"
    PAGE_BOUNDARY_CHECK "Graphics data"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $f00 
    RORG BANK0_RORG + $f00 

	INCLUDE_BANKSWITCH_SUBS 0
PROC_GAME_INIT = 0
Bank0_ProcTableHi
	dc.b >Bank1_GameInit
Bank0_ProcTableLo
	dc.b <Bank1_GameInit
    
    include "bank0/sprites.asm"
    include "gfx/title.asm"

Bank0_StatusColors
    ; Bit:  0 (mode)
    ; Bit:  1 (ctr)
    ;    00         01
    dc.b COLOR_BLUE, COLOR_BLUE
    ;    10         11
    dc.b COLOR_BLUE, COLOR_RED

Bank0_StatusNusiz
    dc.b 3      ; ST_NORM
    dc.b 6      ; ST_ALERT

Bank0_StatusPos0
    dc.b 71     ; ST_NORM
    dc.b 55     ; ST_ALERT
Bank0_StatusPos1
    dc.b 79     ; ST_NORM
    dc.b 63     ; ST_ALERT

Bank0_Mult7
    dc.b   0,   7,  14,  21,  28,  35,  42,  49,  56,  63
    ;dc.b  70,  77,  84,  91,  98, 105, 112, 119, 126, 133
    ;dc.b 140, 147, 154, 161, 168, 175, 182, 189, 196, 203
    ;dc.b 210, 217, 224, 231, 238, 245, 252

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $ffa
    RORG BANK0_RORG + $ffa

Bank0_Interrupts
    dc.w Bank0_Reset           ; NMI
    dc.w Bank0_Reset           ; RESET
    dc.w Bank0_Reset           ; IRQ
