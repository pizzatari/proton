; -----------------------------------------------------------------------------
; These procedures depend on 2 bytes of RAM, so allocate 2 bytes for RandLFSR16.
; RandLFSR16 is in little endian format.
; -----------------------------------------------------------------------------

    IFCONST RAND_GALOIS8
    IF RAND_GALOIS8 > 0
; -----------------------------------------------------------------------------
; Desc:     8-bit Galois LFSR with a $b8 as the tap.
; Input:    A register (current number)
; Output:   A register (next number)
; Notes:    Zero is an invalid state. Only numbers in the range 1-255 are
;           produced.
; -----------------------------------------------------------------------------
RandGalois8 SUBROUTINE
    lsr
    bcc .SkipEor
    eor #$b8
.SkipEor
    rts
    ENDIF
    ENDIF

    IFCONST RAND_GALOIS16
    IF RAND_GALOIS16 > 0
; -----------------------------------------------------------------------------
; Desc:     16-bit Galois LFSR with a $b400 as the tap.
; Input:    X register (selects which LFSR)
;           RandLFSR16 (current number)
; Output:   RandLFSR16 (next number)
; Notes:    Zero is an invalid state. Only numbers in the range 1-65535 are
;           produced. Numbers are little endian.
; -----------------------------------------------------------------------------
RandGalois16 SUBROUTINE
    lsr RandLFSR16+1,x      ; lfsr >>= 1
    ror RandLFSR16,x
    bcc .Skip
    lda #$b4
    eor RandLFSR16+1,x      ; lfsr ^= 0xb400
    sta RandLFSR16+1,x
.Skip
    rts

; -----------------------------------------------------------------------------
; Desc:     Same as RandGalois16 but generates the sequence in reverse and
;           uses $6801 as the tap.
; Input:    X register (selects which LFSR)
;           RandLFSR16 (current number)
; Output:   RandLFSR16 (previous number)
; Notes:    Zero is an invalid state. Only numbers in the range 1-255 are
;           produced. Numbers are little endian.
; -----------------------------------------------------------------------------
RandGaloisRev16 SUBROUTINE
    asl RandLFSR16,x        ; lfsr >>= 1
    rol RandLFSR16+1,x
    bcc .Skip
    lda #$68
    eor RandLFSR16+1,x      ; lfsr ^= 0x6801
    sta RandLFSR16+1,x
    lda #$01
    eor RandLFSR16,x
    sta RandLFSR16,x
.Skip
    rts
    ENDIF
    ENDIF

    IFCONST RAND_JUMBLE
    IF RAND_JUMBLE > 0
; -----------------------------------------------------------------------------
; Desc:     Returns a jumbled version of the number given.
; Input:    A register (row num)
; Output:   A register (jumbled)
; -----------------------------------------------------------------------------
Jumble8 SUBROUTINE
    lsr
    and #$0f
    tax
    lda Reverse4,x
    rts

Reverse4
    dc.b %00000000, %00001000, %00000100, %00001100
    dc.b %00000010, %00001010, %00000110, %00001100
    dc.b %00000001, %00001001, %00000101, %00001101
    dc.b %00000011, %00001011, %00000111, %00001111
    ENDIF
    ENDIF
