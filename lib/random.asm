; Galois LFSR: 8 bit, $b8
RandGalois8 SUBROUTINE
    lda RandNum
    bne .SkipInx
    inx             ; prevent zeros
.SkipInx
    lsr
    bcc .SkipEor
    eor #$b8
.SkipEor
    sta RandNum
    rts
