
; -----------------------------------------------------------------------------
; Desc:     Galois LFSR: 8 bit, $b8
; Input:    A register (current random number)
; Output:   A register (next random number)
; -----------------------------------------------------------------------------
RandGalois8 SUBROUTINE
    bne .SkipInx
    inx             ; prevent zeros
.SkipInx
    lsr
    bcc .SkipEor
    eor #$b8
.SkipEor
    rts

