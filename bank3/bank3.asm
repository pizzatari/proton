    ORG BANK3_ORG
	RORG BANK3_RORG

Bank3_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $f00 
    RORG BANK3_RORG + $f00 

	INCLUDE_BANKSWITCH_SUBS 3
Bank3_ProcTableHi
Bank3_ProcTableLo
    
; -----------------------------------------------------------------------------
; Interrupts
; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $ffa
    RORG BANK3_RORG + $ffa

Bank3_Interrupts
    dc.w Bank3_Reset           ; NMI
    dc.w Bank3_Reset           ; RESET
    dc.w Bank3_Reset           ; IRQ
