; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.1 (beta)
; Game:     The Battle for Proton
; -----------------------------------------------------------------------------

#if VIDEO_MODE == VIDEO_NTSC

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

#endif
