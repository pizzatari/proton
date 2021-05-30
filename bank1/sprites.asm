GFX_BEGIN SET *

; BlankGfx must be on the first byte of the page
Bank1_BlankGfx
MaskTop
    ds.b PF_ROW_HEIGHT, 0
MaskTable
    ds.b PF_ROW_HEIGHT, $ff
    ds.b PF_ROW_HEIGHT, 0

SPRITE_HEIGHT = 16
ShipGfx
    dc.b %00000000
    dc.b %10010010
    dc.b %11010110
    dc.b %11010110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %11111110
    dc.b %10111010
    dc.b %11010110
    dc.b %01111100
    dc.b %01111100
FighterGfx
    dc.b %00000000
    dc.b %00000000
SHIP_HEIGHT = * - ShipGfx
    ds.b 2, 0
    dc.b %10000001
    dc.b %01000010
    dc.b %10100101
    dc.b %11000011
    dc.b %11111111
    dc.b %11100111
    dc.b %11100111
    dc.b %01111110
    dc.b %00111100
    dc.b %01011010
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
    ; Two extra zero bytes are needed because the kernel indexes a pixel
    ; offset from 0 to 18
CondoGfx
    ds.b 2, 0
    dc.b %11111110
    dc.b %11111110
    dc.b %10101010
    dc.b %10101010
    dc.b %11111110
    dc.b %10101010
    dc.b %10101010
    dc.b %11111110
    dc.b %11101110
    dc.b %10000010
    dc.b %01000100
    dc.b %00111000
    dc.b %00000000
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
HouseGfx
    ds.b 2, 0
    dc.b %11001110
    dc.b %11001110
    dc.b %11111110
    dc.b %11110110
    dc.b %11011110
    dc.b %01111100
    dc.b %00111000
    dc.b %00010000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
IndustryGfx
    ds.b 2, 0
    dc.b %11110111
    dc.b %11111111
    dc.b %11011011
    dc.b %11111111
    dc.b %11111111
    dc.b %01100110
    dc.b %01100000
    dc.b %01100000
    dc.b %00000000
    dc.b %00100000
    dc.b %00001010
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
CropsGfx
    ds.b 2, 0
    dc.b %10101010
    dc.b %00000000
    dc.b %10101010
    dc.b %00000000
    dc.b %10101010
    dc.b %00000000
    dc.b %10101010
    dc.b %00000000
    dc.b %10101010
    dc.b %00000000
    dc.b %10101010
    dc.b %00000000
    dc.b %10101010
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
FuelGfx
    ds.b 2, 0
    dc.b %01111100
    dc.b %11111110
    dc.b %11000110
    dc.b %10111010
    dc.b %11111110
    dc.b %11000110
    dc.b %10111010
    dc.b %11111110
    dc.b %11000110
    dc.b %10000010
    dc.b %01111100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
DishGfx
    ds.b 2, 0
    dc.b %11111100
    dc.b %11111100
    dc.b %01111000
    dc.b %00110000
    dc.b %00110000
    dc.b %00100000
    dc.b %00011100
    dc.b %01111000
    dc.b %01110000
    dc.b %11100000
    dc.b %11000000
    dc.b %10000000
    dc.b %10000000
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
PumpGfx
    ds.b 2, 0
    dc.b %11111110
    dc.b %01010100
    dc.b %00111000
    dc.b %00101000
    dc.b %00111000
    dc.b %00101000
    dc.b %00111000
    dc.b %00101000
    dc.b %00010000
    dc.b %00000001
    dc.b %10011111
    dc.b %11111001
    dc.b %10000000
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
ExplosionGfx
    ds.b 2, 0
    dc.b %00000000
    dc.b %10000001
    dc.b %11001010
    dc.b %00101001
    dc.b %01000100
    dc.b %00111011
    dc.b %01010100
    dc.b %11001011
    dc.b %00111010
    dc.b %01001000
    dc.b %10010010
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
#if 0
BaseGfx
    ds.b 2, 0
    dc.b %01111110
    dc.b %11111111
    dc.b %11000011
    dc.b %10111101
    dc.b %10100101
    dc.b %10111101
    dc.b %10101001
    dc.b %10111011
    dc.b %11000011
    dc.b %00111100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    ;dc.b %00000000
    ;dc.b %00000000
TankGfx
    ds.b 2, 0
    dc.b %01111110
    dc.b %11010101
    dc.b %10101011
    dc.b %11000011
    dc.b %01111110
    dc.b %00111100
    dc.b %00011111
    dc.b %00111100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
#endif

    IF >GFX_BEGIN != >*
        ECHO "Sprite Gfx crossed a page boundary!", (GFX_BEGIN&$ff00), *
    ENDIF
