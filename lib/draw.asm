; -----------------------------------------------------------------------------
; Desc:     Draws a 48-bit wide sprite centered on the screen using the
;           Dragster algorithm.
; Input:    Y register (height-1)
; Output:
; Notes:    Position GRP0 to TIA cycle 124 (on-screen pixel 56)
;           Position GRP1 to TIA cycle 132 (on-screen pixel 64)
; -----------------------------------------------------------------------------
DrawWideSprite56 SUBROUTINE ; 6 (6)
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
