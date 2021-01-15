MAKEFILE_PATH = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
TOOLCHAIN_PATH = $(MAKEFILE_PATH)
.SECONDARY:

AS = $(TOOLCHAIN_PATH)as.py

%.s: %.S
	cpp $< | sed "s/__NL__/\n/g" > $@

%.array.c: %.s
	${AS} $< --output $@ --output_type c_array --output_variable program

%.verilog_trenary: %.s
	${AS} $< --output $@ --output_type verilog_trenary

%.dat: %.s
	${AS} $< --output $@ --output_type logisim

.PHONY: clean
clean:
	-rm -rf *.s *.array.c *.verilog_trenary *.dat
