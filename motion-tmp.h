
    MAC MOVE_VIEWPORT_BACKWARD
.SPEED  SET {1}
        sta Temp
        ; advance viewport
        lda ViewportTop
        clc
        adc #.SPEED
        sta ViewportTop

        ; check viewport wraparound
        cmp #SCREEN_HEIGHT-1
        bcs .NoWrapAround
        clc
        adc #SCREEN_HEIGHT      ; 3 (80)
        sta ViewportTop         ; 4 (84)
.NoWrapAround

        ; update the ship's position
        sec                     ; 2 (86)
        sbc #SHIP_Y             ; 3 (93)
        sta ShipY               ; 4 (97)
        lda Temp
    ENDM

    MAC MOVE_VIEWPORT_FOREWARD
.SPEED  SET {1}
        sta Temp
        ; advance viewport
        sec
        lda ViewportTop
        sbc #.SPEED
        sta ViewportTop

        ; check viewport wraparound
        cmp #SCREEN_HEIGHT-1
        bcs .NoWrapAround
        sec
        sbc #SCREEN_HEIGHT      ; 3 (80)
        sta ViewportTop         ; 4 (84)
.NoWrapAround

        ; update the ship's position
        sec                     ; 2 (86)
        sbc #SHIP_Y             ; 3 (93)
        sta ShipY               ; 4 (97)
        lda Temp
    ENDM

