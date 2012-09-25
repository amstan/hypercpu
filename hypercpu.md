Cycle:
Rising - load registers, do things with them(alu, load, display)
Falling - save to memory, write registers, increment pc, load new instruction, decode

Instructions:
........ ........ ........ ........ 
oooooooo fAAAfBBB iiiiiiii iiiiiiii

o - opcode
f - unused(flags maybe?)
A - address for register A
B - address for register B
i - misc immediate data

opcode name   misc     side effect  
==========================================
0x00 - NOP
0x01 - LOADI,          B=i
0x02 - DEBUG,          hex display=A
0x8~ - LOADM, aluop=~, B=memory[A`aluop`i]
0x9~ - SAVEM, aluop=~, memory[A`aluop`i]=B
0xf~ - ALU,   aluop=~, B=A `aluop` B

aluop:
0 - not B
1 - A and B
2 - A or B
3 - A xor B

4 - A < B(unsigned)
5 - A > B(unsigned)
6 - A == B
7 - A != B

8 - A << B(bitshift)
9 - A >> B(bitshift)
A -
B -

C - A + B
D - A - B
E - A * B
F - A / B