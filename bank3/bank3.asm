    SEG rom
    ORG BANK3_ORG

Bank3_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $ffa
Bank3_Interrupts
    dc.w Bank3_Reset           ; NMI
    dc.w Bank3_Reset           ; RESET
    dc.w Bank3_Reset           ; IRQ
