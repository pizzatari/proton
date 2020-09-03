GFX_BEGIN SET *

LaserGfx0
    dc.b %00000000
    dc.b %10000010
    dc.b %01010100
    dc.b %00101000
    dc.b %11111110
    dc.b %00101000
    dc.b %01010100
    dc.b %10000010
LASER_HEIGHT = * - LaserGfx0
LaserGfx1
    dc.b %00000000
    dc.b %00010000
    dc.b %01010100
    dc.b %00101000
    dc.b %00111000
    dc.b %00101000
    dc.b %01010100
    dc.b %00010000

    IF >GFX_BEGIN != >*
        ECHO "Title Gfx crossed a page boundary!", (GFX_BEGIN&$ff00), *
    ENDIF
