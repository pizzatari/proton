    MAC SET_LEFT_DIGIT
.NUM    SET {1}
.PTR    SET {2}
        lda .NUM
        and #$f0
        lsr
        lsr
        lsr
        lsr
        tay
        lda Multiply6,y
        clc
        adc #<Digit0
        sta .PTR
        lda #>Digit0
        sta .PTR+1
    ENDM

    MAC SET_RIGHT_DIGIT
.NUM    SET {1}
.PTR    SET {2}
        lda .NUM
        and #$0f
        tay
        lda Multiply6,y
        clc
        adc #<Digit0
        sta .PTR
        lda #>Digit0
        sta .PTR+1
    ENDM

DebugKernel SUBROUTINE
    lda #$0e
    sta COLUP0
    lda #0
    sta PF0
    sta PF1
    sta PF2
    sta GRP0

    ; viewport debug
    SET_LEFT_DIGIT ViewportTop, TempPtr
    ;SET_LEFT_DIGIT ShipX, TempPtr
    ldy #DIGIT_HEIGHT
.DrawDebug3
    dey
    lda (TempPtr),y                 ; 4, (15)
    sta GRP0                        ; 3, (18)
    sta WSYNC
    bne .DrawDebug3

    lda #0
    sta GRP0
    sta WSYNC

    SET_RIGHT_DIGIT ViewportTop, TempPtr
    ;SET_RIGHT_DIGIT ShipX, TempPtr
    ldy #DIGIT_HEIGHT
.DrawDebug4
    dey
    lda (TempPtr),y                 ; 4, (15)
    sta GRP0                        ; 3, (18)
    sta WSYNC
    bne .DrawDebug4


    lda #0
    sta GRP0
    sta WSYNC

    SET_LEFT_DIGIT MissileY, TempPtr
    ;SET_LEFT_DIGIT ShipY, TempPtr
    ldy #DIGIT_HEIGHT
.DrawDebug
    dey
    lda (TempPtr),y                 ; 4, (15)
    sta GRP0                        ; 3, (18)
    sta WSYNC
    bne .DrawDebug

    lda #0
    sta GRP0
    sta WSYNC

    SET_RIGHT_DIGIT MissileY, TempPtr
    ;SET_RIGHT_DIGIT ShipY, TempPtr
    ldy #DIGIT_HEIGHT
.DrawDebug2
    dey
    lda (TempPtr),y                 ; 4, (15)
    sta GRP0                        ; 3, (18)
    sta WSYNC
    bne .DrawDebug2

    lda #0
    sta GRP0
    sta WSYNC

    rts
