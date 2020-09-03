    MAC RAM_BYTES_USAGE
        ECHO "RAM used =", (* - $80)d, "bytes"
        ECHO "RAM free =", (128 - (* - $80))d, "bytes"
    ENDM

    MAC PAGE_BYTES_REMAINING
        ECHO "Page", *&$f00, "has", ((*|$ff)&$fff - *&$fff)d, "bytes remaining"
    ENDM

    MAC PAGE_LAST_REMAINING
        ECHO "Page", *&$f00, "has", ($ffa - *&$fff)d, "bytes remaining"
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

