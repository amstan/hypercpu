MAKEFILE_PATH = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
TOOLCHAIN_PATH = $(MAKEFILE_PATH)
.SECONDARY:

AS = $(TOOLCHAIN_PATH)as.py

%.hs: %.hS
	cpp $< | sed "s/__NL__/\n/g" > $@

%.array.c: %.hs
	${AS} $< --output $@ --output_type c_array

%.verilog_trenary: %.hs
	${AS} $< --output $@ --output_type verilog_trenary

%.dat: %.hs
	${AS} $< --output $@ --output_type logisim

.PHONY: clean
clean:
	-rm -rf *.hs *.array.c *.verilog_trenary *.dat
