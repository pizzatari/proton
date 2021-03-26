    SEG rom
    ORG BANK0_ORG

Bank0_Reset
    sei
    CLEAN_START
    jsr Bank0_TitleInit

Bank0_FrameStart SUBROUTINE
    inc FrameCtr
    jsr Bank0_VerticalSync

    lda #PROC_VERT_BLANK
    jsr Bank0_CallProcedure
    
    lda #PROC_KERNEL
    jsr Bank0_CallProcedure
    
    lda #PROC_OVERSCAN
    jsr Bank0_CallProcedure

    jmp Bank0_FrameStart

Bank0_VerticalSync SUBROUTINE
    VERTICAL_SYNC
    rts

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
    lda #<BlankGfx
    sta SpritePtrs+8
    sta SpritePtrs+10
    lda #>BlankGfx
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
    jsr Bank0_DrawTitleSprite     ; 6 (65)    returns on cycle 18

    ; ------------------------------------------------------------------------
    ; 1 (19) line blank spacer
    ; ------------------------------------------------------------------------
    ldy #0                  ; 2 (21)
    sta GRP0                ; 3 (24)
    sta GRP1                ; 3 (27)

    ldx #P0_OBJ             ; 2 (29)
    lda #164                ; 2 (31)
    jsr Bank0_HorizPositionBG     ; 6 (37)

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
    lda TitleAuthorPalette,x  ; 4 (6)
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

    SLEEP_LINES 34

    ldx #1
    jsr Bank0_SetTitleGfx
    lda #<TitleCopy4
    sta SpritePtrs+8
    lda #>TitleCopy4
    sta SpritePtrs+9

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

    ldx #MODE_WAVE
    jsr Bank0_GeneralIO
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
    lda #JOY_DELAY
    sta Delay
    jsr Bank0_SpritePtrsClear
    lda #0
    sta GRP0
    sta GRP1
    sta GRP0
    rts

Bank0_WaveVertBlank SUBROUTINE
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

    lda #<Digit0
    sta SpritePtrs+8
    lda #<Digit1
    sta SpritePtrs+10

    lda #>Digits
    sta SpritePtrs+9
    sta SpritePtrs+11

    lda StatusPos0
    ldx #P0_OBJ
    jsr Bank0_HorizPosition
    lda StatusPos1
    ldx #P1_OBJ
    jsr Bank0_HorizPosition
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
    jsr Bank0_GeneralIO
.Delay

    TIMER_WAIT
    rts

; -----------------------------------------------------------------------------
; Game code
; -----------------------------------------------------------------------------
Bank0_GameInit SUBROUTINE
    jsr Bank0_InitScreen
    jsr Bank0_InitPlayer
    jsr Bank0_SpritePtrsClear
    jsr Bank0_SpawnGroundSprites

    lda #>RAND_SEED
    eor INTIM
    bne .Good
    lda #<RAND_SEED
.Good
    sta RandLFSR8
    lda #JOY_DELAY
    sta Delay
    rts

Bank0_GameVertBlank SUBROUTINE
    lda #VBLANK_HEIGHT*76/64
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

    jsr Bank0_ScreenScroll
    jsr Bank0_EnemyTurn

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
    jsr Bank0_HorizPosition
    ldx #P1_OBJ
    lda #76
    jsr Bank0_HorizPosition
    ldx #M0_OBJ
    lda PlyrPosX
    clc
    adc #4          ; adjust offset
    jsr Bank0_HorizPosition
    sta WSYNC
    sta HMOVE

    ; enable/disable laser
    lda Delay
    bne .Continue
    lda PlyrFire
    sta ENAM0
    beq .Continue
    stx LaserAudioFrame
    jsr Bank0_DetectPlayerHit
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

Bank0_GameOverscan SUBROUTINE
    ; -2 because ShrinkerRowKernel consumes an extra line
    lda #[OVERSCAN_HEIGHT-2]*76/64
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

    jsr Bank0_GameIO
    jsr Bank0_ShipUpdatePosition
    jsr Bank0_EnemiesUpdatePosition
    jsr Bank0_PlayAudio

.Delay
    TIMER_WAIT
    rts

Bank0_GameIO SUBROUTINE
    lda SWCHB
    and #SWITCH_RESET
    bne .Joystick
    jmp Bank0_Reset

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

Bank0_InitScreen SUBROUTINE
    ; init screen
    lda #8
    sta ScreenPosY
    lda #0
    sta ScreenSpeedY
    rts

Bank0_InitPlayer SUBROUTINE
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

Bank0_SpawnGroundSprites SUBROUTINE
    ; populate sprites with some values
    ldy #MAX_ROWS-1
    sty Temp
.Loop
    jsr Bank0_SpritesShiftDown
    jsr Bank0_RowInc
    jsr Bank0_SpawnInTop
    dec Temp
    bne .Loop

.Return
    rts

Bank0_SpawnEnemies SUBROUTINE
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

Bank0_HUDSetup SUBROUTINE
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

Bank0_EnemyTurn SUBROUTINE
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
    jsr Bank0_HorizPosition

.Attack0
    

.Attack1
    lda #SPR_ATTACK1
    bit RandLFSR8
    bne .Return

    
.Return
    rts

Bank0_DetectCollision SUBROUTINE
    lda SprType0
    beq .Return
.Return
    rts

Bank0_DetectPlayerHit SUBROUTINE
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

Bank0_SpritePtrsClear SUBROUTINE
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

Bank0_ShipUpdatePosition SUBROUTINE
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

Bank0_EnemiesUpdatePosition SUBROUTINE
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

Bank0_UpdateVerticalPositions SUBROUTINE
    rts

Bank0_ScreenScroll SUBROUTINE
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
    jsr Bank0_SpritesShiftDown
    jsr Bank0_RowInc
    jsr Bank0_SpawnInTop
    jmp .Return

.Reverse
    lda ScreenPosY
    bpl .Return
    clc
    adc #PF_ROW_HEIGHT
    sta ScreenPosY
    jsr Bank0_SpritesShiftUp
    jsr Bank0_RowDec
    jsr Bank0_SpawnInBottom

.Return
    rts

Bank0_SpritesShiftDown SUBROUTINE
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

Bank0_SpritesShiftUp SUBROUTINE
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

Bank0_RowInc SUBROUTINE
    clc
    lda RowNum
    adc #1
    sta RowNum
    lda RowNum+1
    adc #0
    sta RowNum+1
    rts

Bank0_RowDec SUBROUTINE
    sec
    lda RowNum
    sbc #1
    sta RowNum
    lda RowNum+1
    sbc #0
    sta RowNum+1
    rts

Bank0_SpawnInTop SUBROUTINE
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

Bank0_SpawnInBottom SUBROUTINE
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

    ALIGN $ea
    PAGE_BOUNDARY_SET
TitleGfx
    include "gen/title-battle.sp"
    include "gen/title-author.sp"
    include "gen/title-copy.sp"
    PAGE_BOUNDARY_CHECK "TitleCopy"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $a00
    PAGE_BOUNDARY_SET

Bank0_GameKernel SUBROUTINE
    ; executes between 1 and 16 lines
    ;ldy #11
    jsr Bank0_ExpanderRowKernel
                            ; 30 (30)
    dec CurrRow             ; 5 (35)
    ldy #10                 ; 2 (37) 
    jsr Bank0_RowKernel           ; 6 (43)
                            ; 30 (30)
    dec CurrRow             ; 5 (35)
    ldy #9                  ; 2 (37)
    jsr Bank0_RowKernel           ; 6 (43)

    dec CurrRow
    ldy #8
    jsr Bank0_RowKernel

    dec CurrRow
    ldy #7
    jsr Bank0_RowKernel

    dec CurrRow
    ldy #6
    jsr Bank0_RowKernel

    dec CurrRow
    ldy #5
    jsr Bank0_RowKernel

    dec CurrRow
    ldy #4
    jsr Bank0_RowKernel

    dec CurrRow
    ldy #3
    jsr Bank0_RowKernel

    dec CurrRow
    ldy #2
    jsr Bank0_RowKernel

    dec CurrRow
    ldy #1
    jsr Bank0_ShrinkerRowKernel

    jsr Bank0_HUDSetup
    jsr Bank0_HUDKernel
    rts

Bank0_ExpanderRowKernel SUBROUTINE
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

Bank0_RowKernel SUBROUTINE                ; 43 (43)
    lda SprLife0,y                  ; 4 (47)
    sta TempColor                   ; 3 (50)

    ldx #0                          ; 2 (52)
    lda SprPosX0,y                  ; 4 (56)
    jsr Bank0_HorizPosition               ; 6 (62)

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

    ;lda SprFire0+9                  ; 3
    ;sta ENAM1                       ; 3

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
    lda #PROC_INIT
    jsr Bank0_CallProcedure
.Return
    rts

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $b00
    PAGE_BOUNDARY_SET

Bank0_ShrinkerRowKernel SUBROUTINE        ; 43 (43)
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
    jsr Bank0_HorizPosition               ; 6 (69)

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

    include "lib/random.asm"

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $c0f

; Procedure table indexes
PROC_INIT                   = %00
PROC_VERT_BLANK             = %01
PROC_KERNEL                 = %10
PROC_OVERSCAN               = %11

; Procedure table:
; Bit 2-3:  mode
; Bit 0-1:  procedure
ProceduresLo
    ; 0000
    dc.b <Bank0_TitleInit      ; MODE_TITLE
    dc.b <Bank0_TitleVertBlank ; MODE_TITLE
    dc.b <Bank0_TitleKernel    ; MODE_TITLE
    dc.b <Bank0_TitleOverscan  ; MODE_TITLE
    ; 0100
    dc.b <Bank0_WaveInit       ; MODE_WAVE
    dc.b <Bank0_WaveVertBlank  ; MODE_WAVE
    dc.b <Bank0_WaveKernel     ; MODE_WAVE
    dc.b <Bank0_WaveOverscan   ; MODE_WAVE
    ; 1000
    dc.b <Bank0_GameInit       ; MODE_GAME
    dc.b <Bank0_GameVertBlank  ; MODE_GAME
    dc.b <Bank0_GameKernel     ; MODE_GAME
    dc.b <Bank0_GameOverscan   ; MODE_GAME
ProceduresHi
    ; 0000
    dc.b >Bank0_TitleInit      ; MODE_TITLE
    dc.b >Bank0_TitleVertBlank ; MODE_TITLE
    dc.b >Bank0_TitleKernel    ; MODE_TITLE
    dc.b >Bank0_TitleOverscan  ; MODE_TITLE
    ; 0100
    dc.b >Bank0_WaveInit       ; MODE_WAVE
    dc.b >Bank0_WaveVertBlank  ; MODE_WAVE
    dc.b >Bank0_WaveKernel     ; MODE_WAVE
    dc.b >Bank0_WaveOverscan   ; MODE_WAVE
    ; 1000
    dc.b >Bank0_GameInit       ; MODE_GAME
    dc.b >Bank0_GameVertBlank  ; MODE_GAME
    dc.b >Bank0_GameKernel     ; MODE_GAME
    dc.b >Bank0_GameOverscan   ; MODE_GAME

    PAGE_BOUNDARY_SET
Bank0_HUDKernel SUBROUTINE             ; 24 (24)
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
    jsr Bank0_HorizPositionBG             ; 6 (41)

    ldy Status                      ; 3
    lda StatusPos1,y                ; 4
    ldx #1                          ; 2 (4)
    ldy HUDPalette+1                ; 3 (7)
    jsr Bank0_HorizPositionBG             ; 6 (13)

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
    jsr Bank0_DrawWideSprite56         ; 6 (55)

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
    rts                     ; 6 (67)

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
; Param:
; Output:
; -----------------------------------------------------------------------------
Bank0_CallProcedure SUBROUTINE
    clc
    ror
    ror
    ora Mode
    rol
    rol
    tay
    lda ProceduresLo,y
    sta Ptr
    lda ProceduresHi,y
    sta Ptr+1

    lda #>[.Return-1]
    pha
    lda #<[.Return-1]
    pha
    jmp (Ptr)
.Return
    rts
    
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $e00
    PAGE_BOUNDARY_SET
    include "gen/title-planet.pf"
    include "gen/title-proton.pf"
    include "gen/wave-text.sp"
    include "gfx/hud.asm"
    include "gfx/playfield.asm"
    PAGE_BOUNDARY_CHECK "Graphics data"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $f00 
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

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $ffa
Interrupts
    dc.w Bank0_Reset           ; NMI
    dc.w Bank0_Reset           ; RESET
    dc.w Bank0_Reset           ; IRQ
