#include <stdio.h>
#include <stdlib.h>
#include "verilated.h"
#include "Vhypercpu_alu.h"

// #define DO_SINGLE(num, c_op)
// #define DO(num, c_op)

#define DO_OP_0 DO_SINGLE(0x0, ~)
#define DO_OP_1 DO(0x1, &)
#define DO_OP_2 DO(0x2, |)
#define DO_OP_3 DO(0x3, ^)

#define DO_OP_4 DO(0x4, <)
#define DO_OP_5 DO(0x5, >)
#define DO_OP_6 DO(0x6, ==)
#define DO_OP_7 DO(0x7, !=)

#define DO_OP_8 DO(0x8, <<)
#define DO_OP_9 DO(0x9, >>)

#define DO_OP_c DO(0xc, +)
#define DO_OP_d DO(0xd, -)
#define DO_OP_e DO(0xe, *)
#define DO_OP_f DO(0xf, /)


// #define DO_OP_a UNDEF
// #define DO_OP_b UNDEF

#define DO_ALL_OPS() \
	DO_OP_0 DO_OP_1 DO_OP_2 DO_OP_3 \
	DO_OP_4 DO_OP_5 DO_OP_6 DO_OP_7 \
	DO_OP_8 DO_OP_9 \
	DO_OP_c DO_OP_d DO_OP_e DO_OP_f


void print_output(Vhypercpu_alu *tb, bool header = 1) {
	if (header) {
		printf("       a        b ");
		#define DO_SINGLE(num, c_op) printf("%*c%sb ", 8-1-strlen(#c_op),' ', #c_op);
		#define DO(num, c_op) printf("%*ca%sb ", 8-2-strlen(#c_op),' ', #c_op);
		DO_ALL_OPS();
		#undef DO_SINGLE
		#undef DO
		printf("\n");
	}

	printf("%8x %8x ", tb->a, tb->b);

	#define PRINT_ALU_CALCULATION(num, c_op) tb->op = num; tb->eval(); printf("%8x ", tb->r);
	#define DO_SINGLE PRINT_ALU_CALCULATION
	#define DO PRINT_ALU_CALCULATION
	DO_ALL_OPS();
	#undef PRINT_ALU_CALCULATION
	#undef DO_SINGLE
	#undef DO
	printf("\n");
}

int check_against_c(Vhypercpu_alu *tb) {
	unsigned int c_result;
	#define ALU(num, c_op) tb->op = num; tb->eval();
	#define DO_SINGLE(num, c_op) ALU(num, c_op); c_result = c_op tb->b; CHECK(num, c_op);
	#define DO(num, c_op) ALU(num, c_op); c_result = tb->a c_op tb->b; CHECK(num, c_op);
	#define CHECK(num, c_op) if (tb->r != c_result) {printf("Result for %s op#%d, a=%x, b=%x differs: C=%x Verilog=%x\n", #c_op, num, tb->a, tb->b, c_result, tb->r); return 1;}
	DO_ALL_OPS();
	#undef ALU
	#undef DO_SINGLE
	#undef DO

	return 0;
}

int main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	Vhypercpu_alu *tb = new Vhypercpu_alu;

	//TODO: Fix div by 0 testing

	for(tb->a = 1; tb->a < 10; tb->a++) {
		for(tb->b = 1; tb->b < 10; tb->b++) {
			print_output(tb, /*header=*/ tb->b==1);
			if (check_against_c(tb)) return 1;
		}
	}

	return 0;
}
