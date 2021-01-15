#define WORD_INTO_REG(reg, value) \
	reg = mem[$pc + 2] __NL__\
	$pc = $pc + 2 __NL__\
	.word value

#define reading $0
#define accumulator $1
#define pRAM $8
#define pInput $9
#define pDisplay $a
#define compare $2

0x0 start:
accumulator = 0x00
WORD_INTO_REG(pRAM,     RAM)
WORD_INTO_REG(pInput,   Input)
WORD_INTO_REG(pDisplay, Display)

loop:
	reading = mem[pInput + 0x11] # Input.Joystick.Y
	accumulator = reading + accumulator

	mem[pDisplay + 1] = accumulator # Display.Hex
	mem[pRAM + accumulator] = accumulator # fills RAM with its own address depending on accumulator

	WORD_INTO_REG(compare, 0x20000000)
	compare = accumulator > compare
	if compare $pc = endloop
$pc = loop
endloop:

0x01000000 RAM:
0x90000000 Input:
0xa0000000 Display:
