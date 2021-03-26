    MAC RAM_BYTES_USAGE
        ECHO "RAM used =", (* - $80)d, "bytes"
        ECHO "RAM free =", (128 - (* - $80))d, "bytes"
    ENDM

    MAC PAGE_BYTES_REMAINING
        IFCONST PAGE_CURR_BANK
            ECHO "Bank", (PAGE_CURR_BANK)d, "Page", *&$f00, "has", ((*|$ff)&$fff - *&$fff)d, "bytes remaining"
        ELSE
            ECHO "Page", *&$f00, "has", ((*|$ff)&$fff - *&$fff)d, "bytes remaining"
        ENDIF
    ENDM

    MAC PAGE_BYTES_REMAINING_FROM
.FromAddr SET {1}

        IFCONST PAGE_CURR_BANK
            ECHO "Bank", (PAGE_CURR_BANK)d, "Page", *&$f00, "has", ((.FromAddr&$fff) - (*&$fff))d, "bytes remaining"
        ELSE
            ECHO "Page", *&$f00, "has", ((.FromAddr&$ff) - (*&$fff))d, "bytes remaining"
        ENDIF
    ENDM

    MAC PAGE_BOUNDARY_SET
BOUNDARY_BEGIN SET *
    ENDM

    MAC PAGE_BOUNDARY_CHECK
.Label SET {1}
        IF >BOUNDARY_BEGIN != >*
            ECHO .Label, "crossed a page boundary!", (BOUNDARY_BEGIN&$ff00), *
        ENDIF
    ENDM

