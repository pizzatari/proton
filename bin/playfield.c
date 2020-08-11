/*-----------------------------------------------------------------------------
  Author:   Edward Gilmour
  Date:     July 28, 2020
  Version:  0.1 (beta)
  Game:     The Battle for Proton
  Desc:     This program generates the playfield pattern data used in the game.
            Originally implemented as dasm pre-processing logic.

            playfield [num-bytes]

            The argument expects a multiple of 8.

  Notes: 	The original code no longer worked in dasm. I'm not sure why.
            Rather than debug it I reimplemented it in C.

	; Original implementation
	; Generate a pseudo-random textured playfield using this calculation:
	;   bit hack for reversing bits: [idx reversed bits] * ~idx] / DIVISOR
	;
		SUBROUTINE
	.idx SET 1
	REPEAT PF_PATTERN_HEIGHT
	   dc.b [[[.idx*$0802&$22110]|[.idx*$8020&$88440]]*$10101>>16]*~.idx]/7
	.idx SET .idx + 1
	REPEND
	; One more is needed since the kernel goes one record past the end.
	   dc.b [[[1*$0802&$22110]|[1*$8020&$88440]]*$10101>>16]*~1]/7
*/

#include <stdio.h>
#include <stdlib.h>

#define EOL_RECORD "\r\n"

int main(int argc, char *argv[]) {
    int precision = 0xff;
    int num_per_line = 8;
    int bytes = 16;
    int cnt = 1;
    int val;
    int first = 0;

    if (argc >= 2)
        bytes = atoi(argv[1]);

    if (bytes <= 0)
        return 0;

    printf("    dc.b ");
    for (cnt=1; cnt <= bytes; cnt++) {

        /* this incorporates a bit twiddling hack for reversing bits */
        val = (((cnt * 0x0802 & 0x22110) | (cnt * 0x8020 & 0x88440)) * 0x10101>>16) * ~cnt / 7;

        if (cnt == 1)
            first = val;

        if (cnt % num_per_line == 0) {
            /* the last byte needs to repeat the first byte */
            if (cnt == bytes)
                val = first;
            printf("$%.2x" EOL_RECORD, val & precision);
            if (cnt < bytes)
                printf("    dc.b ");
        } else {
            printf("$%.2x, ", val & precision);
        }
    }

    /* finish the line for non-multiples */
    if ((cnt-1) % num_per_line != 0)
        printf("$00" EOL_RECORD);

    return 0;
}
