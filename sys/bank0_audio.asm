; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Jan 21, 2019
; Version:  0.1 (beta)
; Game:     The Battle for Proton
; -----------------------------------------------------------------------------

#if VIDEO_MODE == VIDEO_NTSC

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
