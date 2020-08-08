; -----------------------------------------------------------------------------
; Desc:     Positions an object horizontally using the divide by 15 method with a table
;           lookup for fine adjustments.
; Input:    Bank?.fineAdjustTable
;           A register (horizontal position)
;           X register (sprite to position : 0 to 4)
; Output:   A = fine adjustment value
;           Y = the remainder minus an additional 15
; Notes:
;   0 = Player 0
;   1 = Player 1
;   2 = Missile 0
;   3 = Missile 1
;   4 = Ball
;
;    Scanlines: If control comes on or before cycle 73, then 1 scanline is consumed.
;               If control comes after cycle 73, then 2 scanlines are consumed.
;    Control is returned on cycle 6 of the next scanline.
; -----------------------------------------------------------------------------
    ; battlezone position object
    MAC HORIZ_POSITION
        sec             ; 2 (2)
        sta WSYNC       ; 3 (5)
.Div15
        sbc #15         ; 2 (7)     each time thru this loop takes 5 cycles, which is 
        bcs .Div15      ; 3 (10)    the same amount of time it takes to draw 15 pixels

        eor #7          ; 2 (11)   The EOR & ASL statements convert the remainder
        asl             ; 2 (13)   of position/15 to the value needed to fine tune
        asl             ; 2 (15)    the X position
        asl             ; 2 (17)
        asl             ; 2 (19)
        sta RESP0,X     ; 4 (23)    set coarse X position of object
        sta HMP0,X      ; 4 (27)    store fine tuning of X
    ENDM
