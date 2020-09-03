; -----------------------------------------------------------------------------
; Positions an object horizontally using the divide by 15 method with a table
; lookup for fine adjustments.
;    Inputs:    Bank?.fineAdjustTable
;               A register (horizontal position)
;               X register (sprite to position : 0 to 4)
;               
;    Outputs:   A = fine adjustment value
;               Y = the remainder minus an additional 15
; Notes:
;    Scanlines: If control comes on or before cycle 73, then 1 scanline is consumed.
;               If control comes after cycle 73, then 2 scanlines are consumed.
;    Control is returned on cycle 6 of the next scanline.
; -----------------------------------------------------------------------------
    ; this version moves the sec before the WSYNC and the RESP0 write before HMP0
    MAC POS_OBJECT
.TABLE  SET {1}

        sec             ; 02     Set the carry flag so no borrow will be applied during the division.
        sta WSYNC       ; 00     Sync to start of scanline.
.divideby15 sbc #15     ; 04     Waste the necessary amount of time dividing X-pos by 15!
        bcs .divideby15 ; 06/07  11/16/21/26/31/36/41/46/51/56/61/66
        tay
        nop
        nop
        nop
        sta RESP0,x     ; 21/ 26/31/36/41/46/51/56/61/66/71 - Set the rough position.
        lda .TABLE,y    ; 13 -> Consume 5 cycles by guaranteeing we cross a page boundary
        sta HMP0,x
    ENDM

#if 0
    MAC POS_OBJECT
.TABLE  SET {1}
        sta WSYNC       ; 00     Sync to start of scanline.
        sec             ; 02     Set the carry flag so no borrow will be applied during the division.
.divideby15
        sbc #15         ; 04     Waste the necessary amount of time dividing X-pos by 15!
        bcs .divideby15 ; 06/07  11/16/21/26/31/36/41/46/51/56/61/66
        tay
        lda .TABLE,y    ; 13 -> Consume 5 cycles by guaranteeing we cross a page boundary
        sta HMP0,x
        sta RESP0,x     ; 21/ 26/31/36/41/46/51/56/61/66/71
                        ; Set the rough position.
    ENDM
#endif

; Fine adjustment lookup table for horizontal positioning.
;
; This table converts the remainder of the division by 15 (-1 to -15) to the correct
; fine adjustment value. This table is on a page boundary to guarantee the processor
; will cross a page boundary and waste a cycle in order to be at the precise position
; for a RESP0,x write.
;
    MAC FINE_ADJUST_DATA
{1}.fineAdjustBegin
    dc.b %01110000; Left 7
    dc.b %01100000; Left 6
    dc.b %01010000; Left 5
    dc.b %01000000; Left 4
    dc.b %00110000; Left 3
    dc.b %00100000; Left 2
    dc.b %00010000; Left 1
    dc.b %00000000; No movement.
    dc.b %11110000; Right 1
    dc.b %11100000; Right 2
    dc.b %11010000; Right 3
    dc.b %11000000; Right 4
    dc.b %10110000; Right 5
    dc.b %10100000; Right 6
    dc.b %10010000; Right 7
{1}.fineAdjustTable EQU {1}.fineAdjustBegin - %11110001; NOTE: %11110001 = -15
    ENDM
