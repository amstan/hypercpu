VFLAGS ?= -Wall

 # These are inane, something as simple as (var == 25) ? : will warn with this on
VFLAGS += -Wno-WIDTH

build/V%__ALL.a: %.sv
	# Generate the verilator makefile + cpp then compile it
	verilator $(VFLAGS) -cc $*.sv --Mdir build/ --build

build/test_%: build/V%__ALL.a test/%.cpp
	# Compile the testbench together with the verilog object
	g++ -I /usr/share/verilator/include -I build /usr/share/verilator/include/verilated.cpp test/$*.cpp build/V$*__ALL.a -o build/test_$*

## More direct way of invoking
# build/test_%: %.sv test/%.cpp
# 	verilator $(VFLAGS) -cc $*.sv --Mdir build/ --exe --build test/$*.cpp --exe -o test_$*

.SECONDARY:
# Need .SECONDARY otherwise dependencies for the test,
# including the test will get deleted after executing the following rule:
.PHONY: test_%
test_%: build/test_%
	# Run test
	./$<

.DEFAULT: all
.PHONY: all
all: tests

.PHONY: tests
tests: $(patsubst test/%.cpp,test_%,$(wildcard test/*.cpp))

.PHONY: clean
clean:
	-rm -rf build/
