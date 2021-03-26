; -----------------------------------------------------------------------------
; Desc:     Executes a procedure in a fixed time period.
; Inputs:   procedure address, timer intervals, timer
; Outputs:
; Notes:
;   TIMED_JSR Subroutine, 20, TIM8T
;   TIMED_JSR Subroutine, 10, TIM64T
; -----------------------------------------------------------------------------
    MAC TIMED_JSR
.PROC   SET {1}
.TIME   SET {2}
.TIMER  SET {3}
        lda #.TIME
        sta .TIMER
        jsr .PROC
.Loop
        lda INTIM
        bne .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:    Sleeps until the timer goes to zero.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
    MAC TIMER_WAIT
.Loop
        lda INTIM
        bne .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sleeps until the timer goes negative.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
    MAC TIMER_WAIT_NEGATIVE
.Loop
        lda INTIM
        bpl .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sleeps for a specified number of scan lines.
; Inputs:   number of scan lines
; Outputs:
; -----------------------------------------------------------------------------
    MAC SLEEP_LINES
.LINES   SET {1}
        ldy #.LINES
.Loop
        sty WSYNC
        dey
        bne .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sleeps for a specified number of cycles using a loop to minimize
;           code size.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
    MAC SLEEP_14
        bit $1000                   ; +4 (4)
        bit $1000                   ; +4 (8)
        bit $1000                   ; +4 (12)
        nop                         ; +2 (14)
    ENDM

    MAC SLEEP_17
        ldy #1                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    2 * 5 - 1 = 9 cycles
        nop                         ; +2
        nop                         ; +2
        nop                         ; +2
    ENDM

    MAC SLEEP_21
        ldy #3                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    4 * 5 - 1 = 19 cycles
    ENDM

    MAC SLEEP_23
        ldy #3                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    4 * 5 - 1 = 19 cycles
        nop                         ; +2
    ENDM

    MAC SLEEP_24
        ldy #3                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    4 * 5 - 1 = 19 cycles
        bit $0                      ; +3
    ENDM

    MAC SLEEP_26
        ldy #4                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    5 * 5 - 1 = 24 cycles
    ENDM

    MAC SLEEP_26
        ldy #4                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    5 * 5 - 1 = 24 cycles
    ENDM

    MAC SLEEP_28
        ldy #4                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    5 * 5 - 1 = 24 cycles
        nop                         ; +2
    ENDM

    MAC SLEEP_30
        ldy #4                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    5 * 5 - 1 = 24 cycles
        nop                         ; +2
        nop                         ; +2
    ENDM

    MAC SLEEP_33
        ldy #5                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    6 * 5 - 1 = 29 cycles
        nop                         ; +2
    ENDM

    MAC SLEEP_34
        ldy #5                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    6 * 5 - 1 = 29 cycles
        bit $0                      ; +3
    ENDM

    MAC SLEEP_36
        ldy #6                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    7 * 5 - 1 = 34 cycles
    ENDM

    MAC SLEEP_37
        ldy #5                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    6 * 5 - 1 = 29 cycles
        nop                         ; +2
        nop                         ; +2
        nop                         ; +2
    ENDM

    MAC SLEEP_38
        ldy #6                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    7 * 5 - 1 = 34 cycles
        nop                         ; +2
    ENDM

    MAC SLEEP_43
        ldy #7                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    8 * 5 - 1 = 39 cycles
        nop                         ; +2
    ENDM

    MAC SLEEP_45
        ldy #7                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    8 * 5 - 1 = 39 cycles
        nop                         ; +2
        nop                         ; +2
    ENDM

    MAC SLEEP_48
        ldy #8                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    9 * 5 - 1 = 44 cycles
        nop                         ; +2
    ENDM

    MAC SLEEP_49
        ldy #8                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    9 * 5 - 1 = 44 cycles 
        bit $0                      ; +3
    ENDM

    MAC SLEEP_50
        ldy #8                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    9 * 5 - 1 = 44 cycles 
        nop                         ; +2
        nop                         ; +2
    ENDM

    MAC SLEEP_51
        ldy #9                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    10 * 5 - 1 = 49 cycles 
    ENDM

    MAC SLEEP_52
        ldy #8                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    9 * 5 - 1 = 44 cycles 
        bit $0                      ; +3
        bit $0                      ; +3
    ENDM

    MAC SLEEP_54
        ldy #9                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    10 * 5 - 1 = 49 cycles 
        bit $0                      ; +3
    ENDM

    MAC SLEEP_55
        ldy #9                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    10 * 5 - 1 = 49 cycles 
        nop                         ; +2
        nop                         ; +2
    ENDM

    MAC SLEEP_56
        ldy #10                     ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    11 * 5 - 1 = 54 cycles 
    ENDM

    MAC SLEEP_61
        ldy #11                     ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    12 * 5 - 1 = 59 cycles 
    ENDM
