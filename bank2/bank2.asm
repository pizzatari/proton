    SEG rom
    ORG BANK2_ORG

Bank2_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG BANK2_ORG + $ffa
Bank2_Interrupts
    dc.w Bank2_Reset           ; NMI
    dc.w Bank2_Reset           ; RESET
    dc.w Bank2_Reset           ; IRQ
