; -----------------------------------------------------------------------------
; These procedures depend on 2 bytes of RAM, so allocate 2 bytes for RandLFSR.
; RandLFSR is in little endian format.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Desc:     8-bit Galois LFSR with a $b8 as the tap.
; Input:    A register (current number)
; Output:   A register (next number)
; Notes:    Zero is an invalid state. Only numbers in the range 1-255 are
;           produced.
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

; -----------------------------------------------------------------------------
; Desc:     16-bit Galois LFSR with a $b400 as the tap.
; Input:    X register (selects which LFSR)
;           RandLFSR (current number)
; Output:   RandLFSR (next number)
; Notes:    Zero is an invalid state. Only numbers in the range 1-65535 are
;           produced.
; -----------------------------------------------------------------------------
RandGalois16 SUBROUTINE
    lsr RandLFSR+1,x    ; lfsr >>= 1
    ror RandLFSR,x
    bcc .Skip
    lda #$b4
    eor RandLFSR+1,x    ; lfsr ^= 0xb400
    sta RandLFSR+1,x
.Skip
    rts

; -----------------------------------------------------------------------------
; Desc:     Same as RandGalois16 but generates the sequence in reverse and
;           uses $6801 as the tap.
; Input:    X register (selects which LFSR)
;           RandLFSR (current number)
; Output:   RandLFSR (previous number)
; Notes:    Zero is an invalid state. Only numbers in the range 1-255 are
;           produced.
; -----------------------------------------------------------------------------
RandGaloisRev16 SUBROUTINE
    asl RandLFSR,x      ; lfsr >>= 1
    rol RandLFSR+1,x
    bcc .Skip
    lda #$68
    eor RandLFSR+1,x    ; lfsr ^= 0x6801
    sta RandLFSR+1,x
    lda #$01
    eor RandLFSR,x
    sta RandLFSR,x
.Skip
    rts

