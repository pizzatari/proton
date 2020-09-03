; -----------------------------------------------------------------------------
; Call procedure in bank 0.
;   Inputs:     procedure
;   Outputs:
; -----------------------------------------------------------------------------
    MAC CALL_PROC 
.PROC   SET {1}

        lda #<.PROC
        sta TempPtr
        lda #>.PROC
        sta TempPtr+1

        jsr CallProc
    ENDM

; -----------------------------------------------------------------------------
; Sleeps until the timer goes to zero. This does not work correctly if the timer
; passes zero before we get here.
;    Inputs:
;    Outputs:
; -----------------------------------------------------------------------------
    MAC TIMER_WAIT_ZERO
.Loop
        lda INTIM
        bne .Loop
    ENDM

; -----------------------------------------------------------------------------
; Sleeps for a specified number of lines.
;    Inputs:        NumberOfLines
;    Outputs:
; -----------------------------------------------------------------------------
    MAC SLEEP_LINES
.LINES   SET {1}
        ldy #.LINES
.Loop
        sty WSYNC
        dey
        bne .Loop
    ENDM

; -----------------------------------------------------------------------------
; Erases player sprite graphics.
;    Inputs:
;    Outputs:
; -----------------------------------------------------------------------------
    MAC CLEAR_SPRITE_GRAPHICS
        lda #0
        sta VDELP0
        sta VDELP1
        sta GRP0
        sta GRP1
    ENDM

; -----------------------------------------------------------------------------
; Sets the sprite pointers to the same sprite character given by the 16 bit
; address.
;   Inputs:     SpritePtrs, SpriteAddr
;   Outputs:
; -----------------------------------------------------------------------------
    MAC SET_SPRITE_PTR
.PTRS   SET {1}
.ADDR   SET {2}
        lda #<.ADDR
        ldx #>.ADDR
        ldy #[NUM_VISIBLE_CARDS*2-2]
.Loop
        sta .PTRS,y
        stx .PTRS+1,y
        dey
        dey
        bpl .Loop
    ENDM

; -----------------------------------------------------------------------------
; Sets the 6 sprites to sprite pointers.
;   Inputs:    SpritePtrs, Sprite1, Sprite2, Sprite3, Sprite4, Sprite5, Sprite6
;   Outputs:
; -----------------------------------------------------------------------------
    MAC SET_SPRITE_PTRS
.PTRS   SET {1}
.SPRITE1  SET {2}
.SPRITE2  SET {3}
.SPRITE3  SET {4}
.SPRITE4  SET {5}
.SPRITE5  SET {6}
.SPRITE6  SET {7}
        ; lsb
        lda #<.SPRITE1
        sta .PTRS
        lda #<.SPRITE2
        sta .PTRS+2
        lda #<.SPRITE3
        sta .PTRS+4
        lda #<.SPRITE4
        sta .PTRS+6
        lda #<.SPRITE5
        sta .PTRS+8
        lda #<.SPRITE6
        sta .PTRS+10
        ; msb
        lda #>.SPRITE1
        sta .PTRS+1
        lda #>.SPRITE2
        sta .PTRS+3
        lda #>.SPRITE3
        sta .PTRS+5
        lda #>.SPRITE4
        sta .PTRS+7
        lda #>.SPRITE5
        sta .PTRS+9
        lda #>.SPRITE6
        sta .PTRS+11
    ENDM

; -----------------------------------------------------------------------------
; Sets the sprite pointers to the same characters from the same page.
;   Inputs:    SpritePtrs, Sprite1, Sprite2, Sprite3, Sprite4, Sprite5, Sprite6
;   Outputs:
; -----------------------------------------------------------------------------
    MAC SET_SPRITE_PAGE_PTRS
.PTRS   SET {1}
.SPRITE1  SET {2}
.SPRITE2  SET {3}
.SPRITE3  SET {4}
.SPRITE4  SET {5}
.SPRITE5  SET {6}
.SPRITE6  SET {7}
        lda #<.SPRITE1
        sta .PTRS
        lda #<.SPRITE2
        sta .PTRS+2
        lda #<.SPRITE3
        sta .PTRS+4
        lda #<.SPRITE4
        sta .PTRS+6
        lda #<.SPRITE5
        sta .PTRS+8
        lda #<.SPRITE6
        sta .PTRS+10
        lda #>.SPRITE1
        sta .PTRS+1
        sta .PTRS+3
        sta .PTRS+5
        sta .PTRS+7
        sta .PTRS+9
        sta .PTRS+11
    ENDM
