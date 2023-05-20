# VFLAGS ?= -Wall

# These are inane, something as simple as (var == 25) ? : will warn with this on
VFLAGS += -Wno-WIDTH

VFLAGS += -Wno-LATCH # please excuse my noobiness, that's how I originally implemented this processor in college

build/V%__ALL.o build/V%.h: %.sv
	verilator $(VFLAGS) -cc $*.sv --Mdir build/ --build

build/verilated%o: /usr/share/verilator/include/verilated%cpp
	g++ $^ -c -o $@

build/test_%.o: test/%.cpp build/V%.h
	g++ -I /usr/share/verilator/include -I /usr/share/verilator/include/vltstd -I build $< -c -o $@

VERILATOR_DEPS = build/verilated.o build/verilated_threads.o

build/test_%: build/V%__ALL.o build/test_%.o $(VERILATOR_DEPS)
	g++ $? -o build/test_$*

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

build/test_hypercpu.o: build/hypercpu_example_program.array.c
build/hypercpu_example_program.array.c: ../programs/example.S
	make -f ../toolchain/Makefile ../programs/example.array.c
	-mkdir build
	cp ../programs/example.array.c $@

# TODO: whenever building for hardware happens in the makefile this target needs to change:
#build/Vhypercpu__ALL.a: build/rom.verilog_trenary
build/rom.verilog_trenary:
	make -f ../toolchain/Makefile ../programs/example.verilog_trenary
	-mkdir build
	cp ../programs/example.verilog_trenary $@

.PHONY: clean
clean:
	rm -rf build/*
