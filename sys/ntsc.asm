; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.1 (beta)
; Game:     The Battle for Proton
; -----------------------------------------------------------------------------

#if VIDEO_MODE == VIDEO_NTSC

; total 262
LINES_VSYNC         = 3
LINES_VBLANK        = 37
LINES_OVERSCAN      = 30
SCREEN_WIDTH        = 160
SCREEN_HEIGHT       = 192

COLOR_BLACK         = $00
COLOR_WHITE         = $0e
COLOR_DGREEN        = $c0
COLOR_GREEN         = $c2
COLOR_LGREEN        = $c6
COLOR_DGRAY         = $02
COLOR_GRAY          = $06
COLOR_LGRAY         = $08
COLOR_RED           = $42
COLOR_YELLOW        = $1c
COLOR_BLUE          = $86
COLOR_ORANGE        = $3a

TitlePalette
    dc.b $c0
    dc.b $c0
    dc.b $c2
    dc.b $c2
    dc.b $c4
    dc.b $c4
    dc.b $c6
    dc.b $c6
    dc.b $c8
    dc.b $c8
    dc.b $ca
    dc.b $ca
    dc.b $cc
    dc.b $cc
    dc.b $ce
    dc.b $ce

TitleNamePalette
    dc.b $0a
    dc.b $0c
    dc.b $0e
    dc.b $00
    dc.b $8a
    dc.b $8c
    dc.b $8e
    dc.b 0

ShipPalette
    dc.b $00
    dc.b $08 ; *
    dc.b $08 ; *
    dc.b $06 ; *
    dc.b $04 ; *
    dc.b $84 ; *
    dc.b $86 ; *
    dc.b $88 ; *
    dc.b $8a ; *
    dc.b $08 ; *
    dc.b $08 ; *
    dc.b $0a ; *
    dc.b $0c ; *
    dc.b $08 ; *
    dc.b COLOR_LASER
    dc.b COLOR_LASER
    ds.b PF_ROW_HEIGHT, COLOR_LASER

EnemyPalette
    dc.b $00
    dc.b $08 ; *
    dc.b $08 ; *
    dc.b $06 ; *
    dc.b $04 ; *
    dc.b $44 ; *
    dc.b $46 ; *
    dc.b $48 ; *
    dc.b $4a ; *
    dc.b $08 ; *
    dc.b $08 ; *
    dc.b $0a ; *
    dc.b $0c ; *
    dc.b $08 ; *
    dc.b COLOR_LASER
    dc.b COLOR_LASER

HUDPalette
    dc.b $08, $00; , $80

;ShipPalette0
;    ;      1    2    3    4    5    6    7    8    9   10   11
;    ;                          v---v--- flames
;    dc.b $00, $00, $00, $2e, $2a, $22, $02, $04, $06, $08, $0e
;    dc.b $0a, $0e, $06, $08, $0a, $0c, $4e, $46, $0e, $08, $00
;    ;                       blinking ----^----^
;ShipPalette1
;    ;      1    2    3    4    5    6    7    8    9   10   11
;    ;      v---- missile color
;    dc.b $2e, $00, $00, $3a, $36, $32, $02, $04, $06, $08, $0e
;    dc.b $0a, $0e, $06, $08, $0a, $0c, $86, $8e, $0e, $08, $00
;ShipPalette2
;    ;      1    2    3    4    5    6    7    8    9   10   11
;    ;      v---- missile color
;    dc.b $2e, $00, $00, $46, $44, $42, $02, $04, $06, $08, $0e
;    dc.b $0a, $0e, $06, $08, $0a, $0c, $46, $86, $0e, $08, $00
;ShipPalette3
;    ;      v---- missile color
;    dc.b $2e


; -----------------------------------------------------------------------------
; Audio data
; -----------------------------------------------------------------------------
LASER_AUDIO_RATE    = %00000001
LASER_AUDIO_FRAMES  = 9

LaserVol
    ds.b 0, 6, 8, 6, 8, 6, 8, 6, 0
LaserCon
    dc.b $8, $8, $8, $8, $8, $8, $8, $8, $8
LaserFreq
    dc.b 0, 1, 0, 1, 0, 1, 0, 1, 0

EngineVolume SUBROUTINE
.range  SET [MAX_SPEED_Y>>FPOINT_SCALE]+1
.val    SET 0
.max    SET 6
.min    SET 2
    REPEAT .range
        dc.b [.val * [.max - .min]] / .range + .min
.val    SET .val + 1
    REPEND

EngineFrequency SUBROUTINE
.range  SET [MAX_SPEED_Y>>FPOINT_SCALE]+1
.val    SET .range
.max    SET 31
.min    SET 7
    REPEAT .range
        dc.b [.val * [.max - .min]] / .range + .min
.val    SET .val - 1
    REPEND

#endif
