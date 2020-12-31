#include <stdio.h>
#include <stdlib.h>
#include "verilated.h"
#include "Vhypercpu.h"

#define REG_COUNT 16
#define SP_ADDR (REG_COUNT - 2)
#define PC_ADDR (REG_COUNT - 1)

void print_registers(Vhypercpu *tb, bool header = 1, const char *prefix = "", const char *header_prefix = "") {
	if (header) {
		printf("%s", header_prefix);
		for (int r = 0; r < REG_COUNT; r++) {
			const char *name = "";
			if (r == SP_ADDR) name = "SP-";
			if (r == PC_ADDR) name = "PC-";
			printf("    %3s%x ", name, r);
		}
		printf("\n");
	}

	printf("%s", prefix);
	for (int r = 0; r < REG_COUNT; r++) {
		printf("% 8x ", tb->hypercpu__DOT__hypercpu_registers__DOT__registers[r]);
	}
	printf("\n");
}

void tick(Vhypercpu *tb) {
	tb->eval(); // This might look redundant, but it's safer to keep it
	tb->mclk = 1;
	tb->eval();
	tb->mclk = 0;
	tb->eval();
}

void status(Vhypercpu *tb, char clk_instruction_or_mem) {
	printf("%c ", clk_instruction_or_mem);
	printf("%08x %8x %08x ", tb->mem_addr, tb->mem_read, tb->hypercpu__DOT__instruction);
	print_registers(tb, /*header=*/ 0);
}

int main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	Vhypercpu *tb = new Vhypercpu;

	tb->reset = 0;
	tb->eval();
	tb->reset = 1;
	tb->eval();

	print_registers(tb, /*header=*/ 1,
	           /*prefix=*/ "                    CAabiiii ",
	    /*header_prefix=*/ "C mem_addr mem_data instruct ");
	for(int i = 0; i < 20; i++) {
		tb->eval();
		tb->mclk = 0;
		tb->eval();
		status(tb, 'i');

		tb->eval();
		tb->mclk = 1;
		tb->eval();
		status(tb, 'm');
	}
}
