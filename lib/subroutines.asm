; -----------------------------------------------------------------------------
; Sleeps until the timer goes to zero. This does not work correctly if the timer
; passes zero before we get here.
;    Inputs:
;    Outputs:
; -----------------------------------------------------------------------------
SleepTimeZero SUBROUTINE
    TIMER_WAIT
    rts

; -----------------------------------------------------------------------------
; Sleeps for a specified number of lines.
;    Inputs:        Y (the number of lines to wait)
;    Outputs:
; -----------------------------------------------------------------------------
SleepLines SUBROUTINE
.Loop
    sty WSYNC
    dey
    bne .Loop
    rts
