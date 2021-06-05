    ORG BANK2_ORG
	RORG BANK2_RORG

Bank2_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

; -----------------------------------------------------------------------------
    ORG BANK2_ORG + $f00 
    RORG BANK1_RORG + $c00

	INCLUDE_BANKSWITCH_SUBS 2
Bank2_ProcTableHi
Bank2_ProcTableLo

; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG BANK2_ORG + $ffa
    RORG BANK2_RORG + $ffa

Bank2_Interrupts
    dc.w Bank2_Reset           ; NMI
    dc.w Bank2_Reset           ; RESET
    dc.w Bank2_Reset           ; IRQ
