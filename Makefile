ASM			= dasm
M4			= m4
PERL		= perl
FIND		= find
MAKE_SPRITE = ./bin/make-sprite
MAKE_PFIELD = ./bin/make-playfield

ASM_FLAGS   = -v0 -f3 -l"$*.lst" -s"$*.sym" 

DEPS_ASM	= $(wildcard ./lib/*.asm) $(wildcard ./gfx/*.asm) \
				$(wildcard bank?/*.asm) $(wildcard bank?/gfx/*.asm)
DEPS_H		= $(wildcard ./include/*.h)

DEPS_M4		= $(wildcard ./lib/*.m4)
DEPS_S		= $(DEPS_M4:.m4=.s)

DEPS_MSP	= $(wildcard ./gen/*.msp) $(wildcard ./bank?/gen/*.msp)
DEPS_SP		= $(DEPS_MSP:.msp=.sp)

DEPS_MPF	= $(wildcard ./gen/*.mpf) $(wildcard ./bank?/gen/*.mpf)
DEPS_PF		= $(DEPS_MPF:.mpf=.pf)

TARGET		= proton.bin

.PHONY: all
all: $(TARGET) 

$(TARGET): $(DEPS_S) $(DEPS_SP) $(DEPS_PF) $(DEPS_ASM) $(DEPS_H)

%.bin: %.asm
	$(ASM) "$<" $(ASM_FLAGS) -o"$@"

%.sp: %.msp $<
	$(PERL) $(MAKE_SPRITE) "$<" -o"$@"

%.pf: %.mpf
	$(PERL) $(MAKE_PFIELD) "$<" > $@

%.s: %.m4 $<
	$(M4) "$<" > "$@"

%.bin: %.s $<
	$(ASM) "$<" $(ASM_FLAGS) -o"$@"

.PHONY: clean
clean:
	find . -iname '*.bin' -or -iname '*.lst' -or -iname '*.sym' -or -iname '*.pf' -or -iname '*.sp' \
		-exec rm -fv {} +
