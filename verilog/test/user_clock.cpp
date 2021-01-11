#include <stdio.h>
#include <stdlib.h>
#include "verilated.h"
#include "Vuser_clock.h"

int main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	Vuser_clock *tb = new Vuser_clock;

	tb->step = 0;
	tb->mode = 0b11;

	for (int i = 0; i < 30; i++) {
		for (int k = 0; k < 200000; k++) {
			tb->source_clock = k & 1;
			tb->eval();
		}

		printf("source_clock %x, step %x, mode 0x%x => out_clock %x\n", tb->source_clock, tb->step, tb->mode, tb->out_clock);
	}
}
