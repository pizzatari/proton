SHIP_WIDTH      = 8
SHIP_NUM_FRAMES = 3

ShipSprite
    dc.b %00000000
    dc.b %11011011
    dc.b %11111111
    dc.b %11111111
    dc.b %11111111
    dc.b %11111111
    dc.b %11111111
    dc.b %01111110
    dc.b %01111110
    dc.b %00111100
    dc.b %00111100
    dc.b %00111100
    dc.b %00111100
    dc.b %00100100
    dc.b %00100100
    dc.b %00011000
SHIP_HEIGHT = * - ShipSprite

EnemyFighter
    dc.b %00000000
    dc.b %00000000
    dc.b %01000010
    dc.b %01011010
    dc.b %01011010
    dc.b %00111100
    dc.b %01111110
    dc.b %11100111
    dc.b %11100111
    dc.b %11111111
    dc.b %11000011
    dc.b %10100101
    dc.b %00011000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

ProtonBase
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %01111111
    dc.b %01111111
    dc.b %01010101
    dc.b %01010101
    dc.b %01111111
    dc.b %01111111
    dc.b %01010101
    dc.b %01010101
    dc.b %00111110
    dc.b %00111110
    dc.b %00001000
    dc.b %00000000

GroundPattern0
    dc.b %11001101
    dc.b %10101010
    dc.b %00011001
    dc.b %10101011
    dc.b %11010110
    dc.b %01101101
    dc.b %10110110
    dc.b %01010101
    dc.b %11001100
    dc.b %00101010
    dc.b %11011001
    dc.b %10110010
    dc.b %01001010
    dc.b %01101101
    dc.b %10101010
    dc.b %01011101
    dc.b %11011001

GroundPattern1
    dc.b %01001100
    dc.b %10101010
    dc.b %10011001
    dc.b %10101010
    dc.b %01100111
    dc.b %01101100
    dc.b %10110111
    dc.b %01010100
    dc.b %01001101
    dc.b %10101010
    dc.b %01011001
    dc.b %10101011
    dc.b %01000110
    dc.b %01101101
    dc.b %10110110
    dc.b %01010101

GroundPattern2
    dc.b %01001100
    dc.b %00101010
    dc.b %11011001
    dc.b %10101011
    dc.b %01010110
    dc.b %01101100
    dc.b %10110111
    dc.b %01010101
    dc.b %01001100
    dc.b %10101010
    dc.b %11011001
    dc.b %00101010
    dc.b %11010110
    dc.b %11101101
    dc.b %10111000
    dc.b %01010101
    dc.b %11010110

#if 0
GroundPattern0
    dc.b #01010101
    dc.b #11001100
    dc.b #10101010
    dc.b #00011001
    dc.b #10101011
    dc.b #11010110
    dc.b #01101100
    dc.b #00110111
    dc.b #01010101
    dc.b #11001100
    dc.b #00101010
    dc.b #11011001
    dc.b #10101010
    dc.b #00100110
    dc.b #01101101
    dc.b #10110100
GroundPattern1
    dc.b #10101010
    dc.b #00110010
    dc.b #01010101
    dc.b #10011000
    dc.b #01010101
    dc.b #11100111
    dc.b #00110110
    dc.b #01101101
    dc.b #10101010
    dc.b #00110010
    dc.b #01010101
    dc.b #10011010
    dc.b #01010101
    dc.b #01100110
    dc.b #10110110
    dc.b #00101101
#endif

PaletteOffset
VAL SET 0
    REPEAT SHIP_NUM_FRAMES
    dc.b VAL
VAL SET VAL + SHIP_HEIGHT
    REPEND

ShipPalette0
    ;      1    2    3    4    5    6    7    8    9   10   11
    ;                          v---v--- flames
    dc.b $00, $00, $00, $2e, $2a, $22, $02, $04, $06, $08, $0e
    dc.b $0a, $0e, $06, $08, $0a, $0c, $4e, $46, $0e, $08, $00
    ;                       blinking ----^----^
ShipPalette1
    ;      1    2    3    4    5    6    7    8    9   10   11
    ;      v---- missile color
    dc.b $2e, $00, $00, $3a, $36, $32, $02, $04, $06, $08, $0e
    dc.b $0a, $0e, $06, $08, $0a, $0c, $86, $8e, $0e, $08, $00
ShipPalette2
    ;      1    2    3    4    5    6    7    8    9   10   11
    ;      v---- missile color
    dc.b $2e, $00, $00, $46, $44, $42, $02, $04, $06, $08, $0e
    dc.b $0a, $0e, $06, $08, $0a, $0c, $46, $86, $0e, $08, $00
ShipPalette3
    ;      v---- missile color
    dc.b $2e

#if 0
ShipPalette0
    ;       1   2    3    4    5    6    7    8    9   10   11
    dc.b $1e, $1e, $2a, $0e, $3a, $36, $04, $06, $04, $06, $08
    dc.b $0a, $08, $0a, $0c, $0a, $0c, $0e, $82, $0c, $0e, $00, $00, $00

ShipPalette1
    dc.b $16, $16, $1e, $3e, $44, $3a, $04, $06, $04, $06, $08
    dc.b $0a, $08, $0a, $0c, $0a, $0c, $0e, $96, $0c, $0e, $00, $00, $00

ShipPalette2
    dc.b $18, $18, $10, $4e, $36, $44, $04, $06, $04, $06, $08
    dc.b $0a, $08, $0a, $0c, $0a, $0c, $0e, $42, $0c, $0e, $00, $00, $00
#endif

