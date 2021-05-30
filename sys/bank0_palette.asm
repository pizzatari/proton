; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.1 (beta)
; Game:     The Battle for Proton
; -----------------------------------------------------------------------------

#if VIDEO_MODE == VIDEO_NTSC

#if 0
BG_COLOR                    = COLOR_GREEN
PF_COLOR                    = COLOR_DGREEN
CHIP_COLOR                  = COLOR_YELLOW
CARD_COLOR                  = COLOR_WHITE
CARD_INACTIVE_COLOR         = COLOR_LGRAY
#endif

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

TitleAuthorPalette
    dc.b $0a
    dc.b $0c
    dc.b $0e
    dc.b $00
    dc.b $8a
    dc.b $8c
    dc.b $8e
    dc.b 0

#endif
