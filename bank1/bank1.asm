    SEG rom
    ORG BANK1_ORG

Bank1_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

Bank1_GameInit
    jsr Bank1_InitScreen
    jsr Bank1_InitPlayer
    jsr Bank1_SpritePtrsClear
    jsr Bank1_SpawnGroundSprites

    lda #>RAND_SEED
    eor INTIM
    bne .Good
    lda #<RAND_SEED
.Good
    sta RandLFSR8
    lda #JOY_DELAY
    sta Delay

Bank1_GameFrame SUBROUTINE
    inc FrameCtr
    jsr Bank1_GameVertBlank
    jsr Bank1_GameKernel
    jsr Bank1_GameOverscan
    jmp Bank1_GameFrame

Bank1_VerticalSync SUBROUTINE
    VERTICAL_SYNC
    rts

; -----------------------------------------------------------------------------
; Game code
; -----------------------------------------------------------------------------

Bank1_GameVertBlank SUBROUTINE
    VERTICAL_SYNC

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

    jsr Bank1_ScreenScroll
    jsr Bank1_EnemyTurn

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
    jsr Bank1_HorizPosition
    ldx #P1_OBJ
    lda #76
    jsr Bank1_HorizPosition
    ldx #M0_OBJ
    lda PlyrPosX
    clc
    adc #4          ; adjust offset
    jsr Bank1_HorizPosition
    sta WSYNC
    sta HMOVE

    ; enable/disable laser
;    lda Delay
;    bne .Continue
    lda PlyrFire
    sta ENAM0
    beq .Continue
    stx LaserAudioFrame
    jsr Bank1_DetectPlayerHit
.Continue

    lda #>Bank1_BlankGfx
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
    lda #>Bank1_BlankGfx
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

Bank1_GameOverscan SUBROUTINE
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

    jsr Bank1_GameIO
    jsr Bank1_ShipUpdatePosition
    jsr Bank1_EnemiesUpdatePosition
;    jsr Bank0_PlayAudio

.Delay
    TIMER_WAIT
    rts

Bank1_GameIO SUBROUTINE
    lda SWCHB
    and #SWITCH_RESET
    bne .Joystick
    jmp Bank1_Reset

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

Bank1_InitScreen SUBROUTINE
    ; init screen
    lda #8
    sta ScreenPosY
    lda #0
    sta ScreenSpeedY
    rts

Bank1_InitPlayer SUBROUTINE
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

Bank1_SpawnGroundSprites SUBROUTINE
    ; populate sprites with some values
    ldy #MAX_ROWS-1
    sty Temp
.Loop
    jsr Bank1_SpritesShiftDown
    jsr Bank1_RowInc
    jsr Bank1_SpawnInTop
    dec Temp
    bne .Loop

.Return
    rts

Bank1_SpawnEnemies SUBROUTINE
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

Bank1_HUDSetup SUBROUTINE
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

Bank1_EnemyTurn SUBROUTINE
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
    jsr Bank1_HorizPosition

.Attack0
    

.Attack1
    lda #SPR_ATTACK1
    bit RandLFSR8
    bne .Return

    
.Return
    rts

Bank1_DetectCollision SUBROUTINE
    lda SprType0
    beq .Return
.Return
    rts

Bank1_DetectPlayerHit SUBROUTINE
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

    lda #<Bank1_BlankGfx
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

Bank1_SpritePtrsClear SUBROUTINE
    lda #<Bank1_BlankGfx
    sta SpritePtrs
    sta SpritePtrs+2
    sta SpritePtrs+4
    sta SpritePtrs+6
    sta SpritePtrs+8
    sta SpritePtrs+10
    lda #>Bank1_BlankGfx
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
    rts

Bank1_ShipUpdatePosition SUBROUTINE
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

Bank1_EnemiesUpdatePosition SUBROUTINE
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

Bank1_UpdateVerticalPositions SUBROUTINE
    rts

Bank1_ScreenScroll SUBROUTINE
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
    jsr Bank1_SpritesShiftDown
    jsr Bank1_RowInc
    jsr Bank1_SpawnInTop
    jmp .Return

.Reverse
    lda ScreenPosY
    bpl .Return
    clc
    adc #PF_ROW_HEIGHT
    sta ScreenPosY
    jsr Bank1_SpritesShiftUp
    jsr Bank1_RowDec
    jsr Bank1_SpawnInBottom

.Return
    rts

Bank1_SpritesShiftDown SUBROUTINE
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

Bank1_SpritesShiftUp SUBROUTINE
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

Bank1_RowInc SUBROUTINE
    clc
    lda RowNum
    adc #1
    sta RowNum
    lda RowNum+1
    adc #0
    sta RowNum+1
    rts

Bank1_RowDec SUBROUTINE
    sec
    lda RowNum
    sbc #1
    sta RowNum
    lda RowNum+1
    sbc #0
    sta RowNum+1
    rts

Bank1_SpawnInTop SUBROUTINE
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

Bank1_SpawnInBottom SUBROUTINE
    ; spawn ground structure
    lda RowNum
    jsr Jumble8
    and #7
    tax
    lda GroundSprites,x
    sta SprType1

#if 0
    ; spawn enemy
    lda #<Bank1_BlankGfx
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

    ; platform depedent data
    include "sys/bank1_palette.asm"
    ;include "sys/bank0_audio.asm"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK1_ORG + $a00
    PAGE_BOUNDARY_SET

Bank1_GameKernel SUBROUTINE ; executes between 1 and 16 lines
    ;ldy #11
    jsr Bank1_ExpanderRowKernel
                            ; 30 (30)
    dec CurrRow             ; 5 (35)
    ldy #10                 ; 2 (37) 
    jsr Bank1_RowKernel           ; 6 (43)
                            ; 30 (30)
    dec CurrRow             ; 5 (35)
    ldy #9                  ; 2 (37)
    jsr Bank1_RowKernel           ; 6 (43)

    dec CurrRow
    ldy #8
    jsr Bank1_RowKernel

    dec CurrRow
    ldy #7
    jsr Bank1_RowKernel

    dec CurrRow
    ldy #6
    jsr Bank1_RowKernel

    dec CurrRow
    ldy #5
    jsr Bank1_RowKernel

    dec CurrRow
    ldy #4
    jsr Bank1_RowKernel

    dec CurrRow
    ldy #3
    jsr Bank1_RowKernel

    dec CurrRow
    ldy #2
    jsr Bank1_RowKernel

    dec CurrRow
    ldy #1
    jsr Bank1_ShrinkerRowKernel

    jsr Bank1_HUDSetup
    jsr Bank1_HUDKernel
    rts

Bank1_ExpanderRowKernel SUBROUTINE
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

Bank1_RowKernel SUBROUTINE          ; 43 (43)
    lda SprLife0,y                  ; 4 (47)
    sta TempColor                   ; 3 (50)

    ldx #0                          ; 2 (52)
    lda SprPosX0,y                  ; 4 (56)
    jsr Bank1_HorizPosition         ; 6 (62)

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
Bank1_GeneralIO SUBROUTINE
    lda SWCHB
    and #SWITCH_RESET
    bne .Joystick
    jmp Bank1_Reset

.Joystick
    lda #JOY_FIRE
    bit INPT4
    bne .Return
    
    stx Mode
    ;lda #PROC_INIT
    ;jsr Bank1_CallProcedure
.Return
    rts

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK1_ORG + $b00
    PAGE_BOUNDARY_SET

Bank1_ShrinkerRowKernel SUBROUTINE        ; 43 (43)
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
    jsr Bank1_HorizPosition               ; 6 (69)

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

Bank1_PlayAudio SUBROUTINE
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
    ORG BANK1_ORG + $c0f

    PAGE_BOUNDARY_SET
Bank1_HUDKernel SUBROUTINE             ; 24 (24)
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
    lda Bank1_StatusPos0,y                ; 4
    ldy HUDPalette                  ; 3 (35)
    jsr Bank1_HorizPositionBG             ; 6 (41)

    ldy Status                      ; 3
    lda Bank1_StatusPos1,y                ; 4
    ldx #1                          ; 2 (4)
    ldy HUDPalette+1                ; 3 (7)
    jsr Bank1_HorizPositionBG             ; 6 (13)

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
    lda Bank1_StatusColors,x              ; 4 (23)
    sta COLUBK                      ; 3 (26)

    ; text color
    lda #COLOR_WHITE                ; 2 (28)
    sta COLUP0                      ; 3 (31)
    sta COLUP1                      ; 3 (34)

    ; nusize positioning
    ldx Status                      ; 3 (37)
    lda Bank1_StatusNusiz,x               ; 4 (41)
    sta NUSIZ0                      ; 3 (44)
    sta NUSIZ1                      ; 3 (47)

    ldy #DIGIT_HEIGHT-1             ; 2 (49)
    jsr Bank1_DrawWideSprite56      ; 6 (55)

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

;NusizPattern
;    dc.b 3, 1, 6, 3, 4, 2, 0, 3

AirSprites
    dc.b <Bank1_BlankGfx, <FighterGfx
GroundSprites
    dc.b <Bank1_BlankGfx, <CondoGfx, <HouseGfx, <IndustryGfx
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
Bank1_DrawWideSprite56 SUBROUTINE ; 6 (6)
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
Bank1_DrawTitleSprite SUBROUTINE
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
    PAGE_BOUNDARY_CHECK "(4) Kernels"
    PAGE_BYTES_REMAINING

    PAGE_BOUNDARY_SET
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
Bank1_HorizPosition SUBROUTINE
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
Bank1_HorizPositionBG SUBROUTINE  ; 6 (6)
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
Bank1_HorizPositionPF SUBROUTINE
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

    PAGE_BOUNDARY_CHECK "Horiz Positioning"
    PAGE_BYTES_REMAINING

	INCLUDE_BANKSWITCH_SUBS 1
Bank1_ProcTableHi
Bank1_ProcTableLo

; -----------------------------------------------------------------------------
    ORG BANK1_ORG + $e00
    PAGE_BOUNDARY_SET
    include "gfx/hud.asm"
    include "gfx/playfield.asm"
    PAGE_BOUNDARY_CHECK "Graphics data"
    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK1_ORG + $f00 
    include "bank1/sprites.asm"

Bank1_StatusColors
    ; Bit:  0 (mode)
    ; Bit:  1 (ctr)
    ;    00         01
    dc.b COLOR_BLUE, COLOR_BLUE
    ;    10         11
    dc.b COLOR_BLUE, COLOR_RED

Bank1_StatusNusiz
    dc.b 3      ; ST_NORM
    dc.b 6      ; ST_ALERT

Bank1_StatusPos0
    dc.b 71     ; ST_NORM
    dc.b 55     ; ST_ALERT
Bank1_StatusPos1
    dc.b 79     ; ST_NORM
    dc.b 63     ; ST_ALERT

Bank1_Mult7
    dc.b   0,   7,  14,  21,  28,  35,  42,  49,  56,  63
    ;dc.b  70,  77,  84,  91,  98, 105, 112, 119, 126, 133
    ;dc.b 140, 147, 154, 161, 168, 175, 182, 189, 196, 203
    ;dc.b 210, 217, 224, 231, 238, 245, 252

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG BANK1_ORG + $ffa
Bank1_Interrupts
    dc.w Bank1_Reset           ; NMI
    dc.w Bank1_Reset           ; RESET
    dc.w Bank1_Reset           ; IRQ
