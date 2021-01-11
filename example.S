#define WORD_INTO_REG(reg, value) \
	reg = mem[$pc + 2] __NL__\
	$pc = $pc + 2 __NL__\
	.word value

#define reading $0
#define accumulator $1
#define register_with_0 $2
#define pRAM $8
#define pInput $9
#define pDisplay $a

0x0 start:
accumulator = register_with_0 + 0x00
WORD_INTO_REG(pRAM,     RAM)
WORD_INTO_REG(pInput,   Input)
WORD_INTO_REG(pDisplay, Display)
loop:
reading = mem[pInput + 0x11] # Input.Joystick.Y
accumulator = reading + accumulator
mem[pDisplay + 1] = accumulator # Display.Hex
mem[pRAM + accumulator] = accumulator # fills RAM with its own address depending on accumulator
$pc = register_with_0 + loop # goto loop

0x01000000 RAM:
0x90000000 Input:
0xa0000000 Display:
