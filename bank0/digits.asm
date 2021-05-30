BANK0_GFX_BEGIN SET *

Bank0_Digits
Bank0_Digit0
    dc.b %00000000
    dc.b %00111000
    dc.b %01101100
    dc.b %01100110
    dc.b %01100110
    dc.b %00110110
    dc.b %00111100
DIGIT_HEIGHT = * - Bank0_Digit0
Bank0_Digit1
    dc.b %00000000
    dc.b %00110000
    dc.b %00110000
    dc.b %00011000
    dc.b %00011000
    dc.b %00011100
    dc.b %00001100
Bank0_Digit2
    dc.b %00000000
    dc.b %01111100
    dc.b %00110000
    dc.b %00011000
    dc.b %00001100
    dc.b %01100110
    dc.b %00111100
Bank0_Digit3
    dc.b %00000000
    dc.b %01111000
    dc.b %11001100
    dc.b %00011100
    dc.b %00001110
    dc.b %00100110
    dc.b %00011100
Bank0_Digit4
    dc.b %00000000
    dc.b %00011000
    dc.b %00011000
    dc.b %00001100
    dc.b %11111100
    dc.b %01100110
    dc.b %01100110
Bank0_Digit5
    dc.b %00000000
    dc.b %01111000
    dc.b %11001100
    dc.b %00001100
    dc.b %01111000
    dc.b %01100000
    dc.b %00111110
Bank0_Digit6
    dc.b %00000000
    dc.b %00111100
    dc.b %01100110
    dc.b %01111100
    dc.b %00110000
    dc.b %00011100
    dc.b %00000110
Bank0_Digit7
    dc.b %00000000
    dc.b %00110000
    dc.b %00110000
    dc.b %00011000
    dc.b %00001100
    dc.b %00000110
    dc.b %01111110
Bank0_Digit8
    dc.b %00000000
    dc.b %01111000
    dc.b %11001100
    dc.b %11001100
    dc.b %01111110
    dc.b %00100110
    dc.b %00111110
Bank0_Digit9
    dc.b %00000000
    dc.b %00110000
    dc.b %00011000
    dc.b %00001100
    dc.b %00111110
    dc.b %01100110
    dc.b %00111100

    IF >BANK0_GFX_BEGIN != >*
        ECHO "bank0/digits.asm crossed a page boundary!", (BANK0_GFX_BEGIN&$ff00), *
    ENDIF
