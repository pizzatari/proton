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
HorizPosition SUBROUTINE
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
HorizPositionBG SUBROUTINE  ; 6 (6)
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
HorizPositionPF SUBROUTINE
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

