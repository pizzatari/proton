VIDEO_NTSC                  = 1
VIDEO_PAL                   = 2
VIDEO_PAL60                 = 3
VIDEO_SECAM                 = 4
VIDEO_MODE                  = VIDEO_NTSC

#if VIDEO_MODE == VIDEO_NTSC
; total 262
VBLANK_HEIGHT               = 37        ; 40 including vsync
OVERSCAN_HEIGHT             = 30
SCREEN_WIDTH                = 160
SCREEN_HEIGHT               = 192
#endif

#if VIDEO_MODE == VIDEO_PAL || VIDEO_MODE == VIDEO_PAL60 || VIDEO_MODE == VIDEO_SECAM
; total 312
VBLANK_HEIGHT               = 45        ; 48 including vysnc
OVERSCAN_HEIGHT             = 36
SCREEN_WIDTH                = 160
SCREEN_HEIGHT               = 228
#endif

; Colors
#if VIDEO_MODE == VIDEO_NTSC
COLOR_BLACK                 = $00
COLOR_WHITE                 = $0E
COLOR_BROWN                 = $C0
COLOR_DGRAY                 = $02
COLOR_GRAY                  = $06
COLOR_LGRAY                 = $08
COLOR_LLGREEN               = $CE
COLOR_LGREEN                = $C8
COLOR_MGREEN                = $C6
COLOR_GREEN                 = $C4
COLOR_DGREEN                = $C2
COLOR_RED                   = $44
COLOR_DRED                  = $40
COLOR_PINK                  = $3E
COLOR_YELLOW                = $EE
COLOR_VIOLET                = $66
COLOR_BLUE                  = $86
COLOR_ORANGE                = $38
#endif

; Colors
#if VIDEO_MODE == VIDEO_PAL
#endif

