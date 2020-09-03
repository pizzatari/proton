; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.1 (beta)
; Game:     The Battle for Proton
; -----------------------------------------------------------------------------
    MAC ACCELERATE
.CURR   SET {1}         ; current velocity
.ACCEL  SET {2}         ; acceleration rate
.MAX    SET {3}         ; maximum velocity
        sta Temp
        clc
        lda .CURR
        adc #.ACCEL
        sta .CURR
        ; signed comparison if A >= velocity then A = MAX
        sec
        sbc #.MAX
        bvc .Compare
        eor #$80
.Compare
        bmi .Return
        lda #.MAX
        sta .CURR
.Return
        lda Temp
    ENDM

    MAC DECELERATE
.CURR   SET {1}         ; current velocity
.ACCEL  SET {2}         ; acceleration rate
.MIN    SET {3}         ; minimum velocity
        sta Temp
        sec
        lda .CURR
        sbc #.ACCEL
        sta .CURR
        ; signed comparison if A < velocity then A = MIN
        sec
        sbc #.MIN
        bvc .Compare
        eor #$80
.Compare
        bpl .Return
        lda #.MIN
        sta .CURR
.Return
        lda Temp
    ENDM

    ; The result is stored in Temp
    MAC CALCULATE_MOTION
.VELOC  SET {1}         ; velocity
#if 0
        ; This rounding is incorrect for negative numbers (and not really necessary).
        ; Truncating the fraction works fine.
        ; calculate rounding value
        lda .VELOC
        and #MOTION_SCALE_MASK
        tay
        lda RoundVelocity,y
        sta Temp
#else
        lda #0
        sta Temp
#endif

        ; convert fixed point to native
        lda .VELOC
        bmi .Negative
        REPEAT MOTION_SCALE
        lsr
        REPEND
        clc
        adc Temp
        jmp .Continue
.Negative
        REPEAT MOTION_SCALE
        lsr
        REPEND
        clc
        ora #<[MOTION_SCALE_MASK << [8 - MOTION_SCALE]]
        adc Temp
.Continue
        sta Temp
    ENDM

    MAC UPDATE_SHIP_Y
.VIEWPORT   SET {1}
        lda .VIEWPORT
        ; update the ship's position
        sec
        sbc #SHIP_Y
        sta ShipY
    ENDM

    MAC UPDATE_MISSILE_Y
        lda MissileY
        beq .Return

        ; update the missile's position
        lda MissileVelocity
        REPEAT MOTION_SCALE
        lsr
        REPEND

        clc
        adc MissileY
        sta MissileY

        ; check if missile has travelled off the screen
        cmp ViewportTop
        bcc .Return

        lda #0
        sta MissileY
        sta MissileOn
.Return
    ENDM 
