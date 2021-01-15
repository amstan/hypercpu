# HyperCPU
Here is a toy cpu architecture I made.

The plan is to go pretty far with it as a learning exercise:
* Started as a logisim design
* Implementation in hardware using Verilog and FPGAs
* Compiler toolchain

## Cycle

Rising - load registers, do things with them(alu, load, display)
Falling - save to memory, write registers, increment pc, load new instruction, decode

## Instructions
```
.... .... ........ ........ ........
oooo oooo AAAABBBB ±iiiiiii iiiiiiii
ccci ALU- opcode subparts(sometimes applicable)

o - opcode
A - address for register A
B - address for register B
±i - misc immediate data (this is sign extended from 16 bit to 32 bit)
```

### Following subparts of the opcode sometimes applicable:

* i - replace B with immediate data for ALU input (remember the sign extension)
* ccc, rest of the code:
	* 0b00x - reserved
	*
	* 0b010 - branch on not zero
	* 0b011 - branch on zero

	* 0b100 - load(usually when i=1)
	* 0b101 - save(usually when i=1)

	* 0b110 - call
	* 0b111 - store alu to register B
* ALU op - ALU operation

```
opcode name   misc     side effect
==========================================
0b00000000 - NOP
0b00000001 - SYNC, for multiprocessing support, stop unless last to execute this command, if last then make others start as well

0b00000010 - POP,   B=memory[--sp];
0b00000011 - PUSH,  memory[sp++]=B;

0b00000100 - Load word immediate(skips over next instruction and considers it as data), B=memory[++pc];

0b00100000 - SET,   set_bit(B,A);
0b00100001 - CLEAR, clear_bit(B,A);
0b00100000 - TOGGLE,toggle_bit(B,A);
0b00100001 - TEST,  B=test_bit(B,A);

0b010iALUO - BRNZ,  if(B)  pc=A `ALUO` x;
0b011iALUO - BRZ,   if(!B) pc=A `ALUO` x;

0b100iALUO - LOAD,  B=memory[A`ALUO`x];
0b101iALUO - STORE, memory[A`ALUO`x]=B;

0b110iALUO - CALL,  push(pc); pc=A `ALUO` x;
0b111iALUO - ALU,   B=A `ALUO` x
```

### Aliases
* Load immediate(B=i) -> ALUi:B=A+i where A is a register with 0 in it
* Move(B=A) -> ALUi:B=A+i|i=0
* Return(opposite of call) -> POP:B=pc
* ALU immediate -> ALUi:B=A+i|&B=&A

### ALU op
* 0 - not B
* 1 - A and B
* 2 - A or B
* 3 - A xor B

* 4 - A < B(unsigned)
* 5 - A > B(unsigned)
* 6 - A == B
* 7 - A != B

* 8 - A << B(bitshift)
* 9 - A >> B(bitshift)
* A -
* B -

* C - A + B
* D - A - B
* E - A * B
* F - A / B

## Memory Map

```
0x00000000 - 0x00ffffff - ROM
0x01000000 - 0x01ffffff - RAM
0x80000000 - 0x8fffffff - Peripherals
	* 0x80000000 - Random number generator
0x90000000 - 0x9fffffff - Input
	* 0x90000000 - Keyboard
	* 0x9000001X - Joystick
		* 0 - X
		* 1 - Y
		* 2 - L
		* 3 - R
		* 4 - A
		* 5 - B
		* 6 - C
		* 7 - D
0xA0000000 - 0xAfffffff - Output
	* 0xA0000000 - TTY
	* 0xA0000001 - 4 Byte Hex Display
0xB0000000 - 0xBfffffff - Display
```
