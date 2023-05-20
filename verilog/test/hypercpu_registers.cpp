#include <stdio.h>
#include <stdlib.h>
#include "verilated.h"
#include "Vhypercpu_registers.h"
#include "Vhypercpu_registers_hypercpu_registers.h"

#define REG_COUNT 16
#define SP_ADDR (REG_COUNT - 2)
#define PC_ADDR (REG_COUNT - 1)

void print_registers(Vhypercpu_registers *tb, bool header = 1, const char *prefix = "", const char *header_prefix = "") {
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
		printf("% 8x ", tb->hypercpu_registers->registers[r]);
	}
	printf("\n");
}

void tick(Vhypercpu_registers *tb) {
	tb->eval(); // This might look redundant, but it's safer to keep it
	tb->mclk = 1;
	tb->eval();
	tb->mclk = 0;
	tb->eval();
}

int main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	Vhypercpu_registers *tb = new Vhypercpu_registers;

	tb->reset = 1;
	tb->next_sp = 0xeeee0000;
	tb->next_pc = 0xffff0000;
	tick(tb);

	// Write test
	print_registers(tb, /*header=*/ 1, /*prefix=*/ " _    ", /*header_prefix=*/ "reg   ");
	for(int i = 0; i < REG_COUNT * 2; i++) {
		int reg = i/2;

		tb->write_addr = reg;
		tb->write_data = 0x11000000 + reg;
		tb->write_enable = i % 2;

		tb->next_sp = 0xee000000 + i;
		tb->next_pc = 0xff000000 + i;

		tick(tb);
		printf("%2d %c  ", reg, " w"[tb->write_enable]);
		print_registers(tb, /*header=*/ 0);
	}
	print_registers(tb, /*header=*/ 0, /*prefix=*/ " _    ");

	tb->write_addr = 0;
	tb->write_data = 0;
	tb->write_enable = 0;

	// Read test
	printf("ReadA ");
	for(tb->read_a_addr = 0; tb->read_a_addr < REG_COUNT; tb->read_a_addr++) {
		tb->next_sp = tb->read_sp + 1;
		tb->next_pc = tb->read_pc + 1;
		tick(tb);
		printf("% 8x ", tb->read_a_data);
	}
	printf("\n");

	printf("ReadB ");
	for(tb->read_b_addr = 0; tb->read_b_addr < REG_COUNT; tb->read_b_addr++) {
		tb->next_sp = tb->read_sp + 1;
		tb->next_pc = tb->read_pc + 1;
		tick(tb);
		printf("% 8x ", tb->read_b_data);
	}
	printf("\n");

	// Erase test
	tb->eval();
	tb->reset = 0;
	tb->eval();
	tb->reset = 1;
	tb->eval();
	print_registers(tb, /*header=*/ 0, /*prefix=*/ "Erase ");
}
