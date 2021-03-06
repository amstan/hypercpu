#!/usr/bin/env python3
"""
HyperCPU Assembler
"""

import argparse
import re
import sys

class AssemblyError(Exception):
	pass

class ArchitectureLimitation(AssemblyError):
	pass

class AssemblyValueError(AssemblyError, ValueError):
	pass

LINE_RE = re.compile(r"""^
	(?:(?P<label>[^=]*?) \s* :)? \s*
	(?P<instruction>.*?)? \s*
	(?P<comment>\#.*)?
$""", re.X)

WORD_RE = re.compile("^\.word (?P<value>.*)$")

ALU_OPS = {
	'~':  0x0,
	'&':  0x1,
	'|':  0x2,
	'^':  0x3,

	'<':  0x4,
	'>':  0x5,
	'==': 0x6,
	'!=': 0x7,

	'<<': 0x8,
	'>>': 0x9,
	     #0xa,
	     #0xb,

	'+':  0xc,
	'-':  0xd,
	'*':  0xe,
	'/':  0xf,
}
SINGLE_TERM_ALUOPS = ["~"]

def reg_re(name="b"):
	"""Outputs regex for a register or named register only. Most likely for b."""
	return rf"(?P<{name}>\$?\w+?)"
def term_re(name, register_only=False):
	"""Outputs regex for a register, named register or immediate value."""
	return rf"(?P<{name}>.+?)"

ALU_OPS_GROUP = (
	rf"(?P<alu_op>" +
	'|'.join(f"{re.escape(op)}"
		for op in ALU_OPS.keys()
			if op not in SINGLE_TERM_ALUOPS)
	+ ")"
)
ALU_OPS_GROUP_RE = re.compile(ALU_OPS_GROUP, re.X)
ALU_OPS_SINGLE_GROUP = rf"(?P<single_alu_op>{'|'.join(re.escape(op) for op in SINGLE_TERM_ALUOPS)})"
ALU_EXPRESSION = rf"""\s* (?P<alu_expression>
	{term_re('a')}? \s* {ALU_OPS_GROUP} \s* {term_re('alu_b')} # a `alu_op` b
	|{ALU_OPS_SINGLE_GROUP}? \s* {term_re('single')}           # `alu_op`?single
) \s*"""

LOAD_RE = re.compile(fr"^{reg_re()} \s* = \s* mem\[{ALU_EXPRESSION}\]$", re.X)
STORE_RE = re.compile(fr"^mem\[{ALU_EXPRESSION}\] \s* = \s* {reg_re()}$", re.X)

ALU_RE = re.compile(fr"^{reg_re()} \s* = \s* {ALU_EXPRESSION}$", re.X)

BR_RE = re.compile(fr"""^
	if (?:\s+|\()
			(?P<br_negate>!|not)? \s*
			{reg_re()} \s*
		\)?
	\s* (?:
		  goto|
		  {term_re("br_pc")} \s* =
		) \s*
	{ALU_EXPRESSION}
$""", re.X)

INSTRUCTIONS_RE = {i:eval(i + "_RE") for i in [
	"BR",
	"WORD",
	"LOAD",
	"STORE",
	"ALU",
]}

OPCODES = {       #ccci ALU-
	"BRZ":       0b0100_0000,
	"BRNZ":      0b0110_0000,
	"LOAD":      0b1000_0000,
	"STORE":     0b1010_0000,
	"CALL":      0b1100_0000,
	"ALU":       0b1110_0000,
	"mask":      0b1110_0000,
	"immediate": 0b0001_0000,
	"alutype":   0b1110_0000,
	"alu_op":    0b0000_1111,
}

def eval_typed(s, expected_type, vars=None):
	evalled = eval(s, vars)
	if not isinstance(evalled, expected_type):
		raise TypeError(f"type({s}=={evalled!r})!={expected_type}")
	return evalled

class Register():
	all_aliases = {}
	number = None
	SPECIAL_NAMES = {
		"sp": 0xe,
		"pc": 0xf,
	}

	def __init__(self, r):
		if isinstance(r, int):
			self.number = r
		elif r.startswith("$"):
			r_ = r[1:]
			if r_.isdigit():
				self.number = int(r_)
			elif r_ in "abcdef":
				self.number = int(r_, 16)
			elif (lowered := r_.lower()) in self.SPECIAL_NAMES:
				self.number = self.SPECIAL_NAMES[lowered]
		if self.number is None:
			raise AssemblyValueError(f"Unknown register {r!r}.")

		if not (0 <= self.number < 16):
			raise AssemblyValueError(f"Do not have a register {self.number:#x}.")

	def __repr__(self):
		try:
			special_name = next(name for name, number in Register.SPECIAL_NAMES.items() if number == self.number)
			return f"${special_name}"
		except StopIteration:
			return f"${self.number:x}"

	def __eq__(self, other):
		return self.number == other.number

class Line():
	def __init__(self, line_number, line_str, file):
		self.number = line_number
		self.str = line_str.strip() # there's newlines usually
		self.file = file

		self.match = LINE_RE.match(self.str)
		for k, v in self.match.groupdict().items():
			setattr(self, k, v)
		self.instruction = self.instruction
		self._parse_label()

	def _parse_label(self):
		self.new_address = None
		self.label_name = None

		if not self.label:
			return
		parts = self.label.split(" ")

		if len(parts) == 1:
			try:
				self.new_address = eval_typed(parts[0], int)
			except Exception:
				self.label_name = parts[0]
		elif len(parts) == 2:
			self.new_address = eval_typed(parts[0], int)
			self.label_name = parts[1]
		else:
			raise SyntaxError(f"Cannot parse label {self.label!r}")

	def __str__(self):
		return self.str

def generate_assembler_words(files, args):
	labels = {}

	all_lines = []
	for f in files:
		#Register.all_aliases = {} # TODO: fix this so register aliases are not global
		for i, line_str in enumerate(f.readlines()):
			all_lines.append(Line(i, line_str, f))

	address = args.output_offset
	# Gather all labels and register aliases
	for line in all_lines:
		if line.new_address is not None:
			address = line.new_address
		if line.label_name:
			labels[line.label_name] = address
		if line.instruction:
			address += 1

	address = args.output_offset
	for line in all_lines:
		ow = None # output word
		output_comment = ""

		if line.new_address is not None:
			address = line.new_address

		try:
			for i_type, i_re in INSTRUCTIONS_RE.items():
				if i_match := i_re.match(line.instruction):
					i_dict = i_match.groupdict()
					if i_type == "WORD":
						ow = eval_typed(i_dict["value"], int, vars=labels)
						output_comment = "from .word"

					if i_type in ["ALU", "LOAD", "STORE", "BR"]:
						if i_dict["single"]:
							if i_dict["single_alu_op"]: # `alu_op`b
								i_dict["a"] = 0 # unused since it's single term
								i_dict["alu_op"] = i_dict["single_alu_op"]
								i_dict["alu_b"] = i_dict["single"]
							else: # just a, with an implied + immediate 0
								i_dict["a"] = i_dict["single"]
								i_dict["alu_op"] = "+"
								i_dict["alu_b"] = "0"
							try:
								Register(i_dict["single"])
							except ValueError:
								# the user might have wanted the alu expression to return just the immediate (as i_dict["single"])
								# we have no such alu operation
								# but hack this by using ~alu_b operation with immediate
								immediate = eval_typed(i_dict["single"], int, vars=labels)
								if not (0 <= immediate < 0x10000):
									raise AssemblyValueError(f"Immediate of {immediate:#x} cannot be stored in 16 bits of assignment")
								immediate = immediate ^ 0xffff # invert it at compile time, the alu will invert it back using ~
								i_dict["alu_op"] = "~"
								i_dict["alu_b"] = str(immediate)
								i_dict["a"] = 0 # unused since it's single term

						#print(line, i_type, i_dict)
						a = Register(i_dict["a"])
						b = Register(i_dict["b"])
						alu_op = i_dict["alu_op"]

						try:
							alu_b = Register(i_dict["alu_b"])
						except ValueError:
							is_immediate = True
							immediate = i_dict["alu_b"]
							#if immediate[0]!="(" and ALU_OPS_GROUP_RE.findall(immediate):
								#raise AssemblyError(f"Evaluated {immediate=!r} should have () around it to not confuse order of operations with alu_op={i_dict['alu_op']!r}")
							immediate = eval_typed(immediate, int, vars=labels)
							if not (0 <= immediate < 0x10000):
								raise AssemblyValueError(f"Immediate of {immediate:#x} cannot be stored in 16 bits")
						else:
							is_immediate = False
							immediate = 0

							if b != alu_b:
								raise ArchitectureLimitation(f"{b=} has to be {alu_b=}")
							del alu_b

						if i_type == "BR":
							if not i_dict["br_negate"]:
								i_type = "BRNZ"
							else:
								i_type = "BRZ"
							if i_dict["br_pc"] not in [None, "$pc"]:
								raise ArchitectureLimitation(f"When doing a branch LHS of ALU expression must be '$pc', not '{i_dict['br_pc']}'.")

						alu_op_number = ALU_OPS[alu_op]
						op_code = (
							OPCODES[i_type] |
							(OPCODES["immediate"] * is_immediate) |
							alu_op_number
						)
						ow = (
							op_code << 24 |

							a.number << 20 |
							b.number << 16 |

							immediate
						)

						output_comment = f"{i_type}\t{a=} {b=} {alu_op=}({alu_op_number:x}) immediate:{is_immediate} {immediate:#x}"

					assert (ow is not None), f"Unhandled {i_type}, did not set ow"
					break
			else:
				if line.instruction:
					raise AssemblyError(f"Did not recognize instruction.")
		except AssemblyError as e:
			print("Assembly Error")
			print(f"  File {line.file.name!r}, line {line.number}")
			print(f"    {line}")
			print(f"  {e.__class__.__name__}: {e}")
			sys.exit(1)

		if args.comment_type == "original_line":
			output_comment = line

		if line.instruction:
			assert (ow is not None), f"Instruction not null{line.instruction!r} should mean we have an ow"
			yield (address, ow, output_comment)
			address += 1

def sign_extend(x, from_bits=16, to_bits=32):
	x &= (1 << from_bits) - 1 # make sure we're cropped to from bits
	from_sign_bit_mask = (1<<(from_bits-1))
	sign_bit = bool(x & from_sign_bit_mask)
	leftover_bits_mask = from_sign_bit_mask - 1
	new_sign_mask = ((1 << to_bits) - 1) - (leftover_bits_mask - 1)
	return x | (sign_bit * new_sign_mask)

def disassemble(word):
	disassembled = f".word {word:#010x}"

	try:
		opcode = word >> 24
		a = Register((word >> 20) & 0xf)
		b = Register((word >> 16) & 0xf)
		immediate = sign_extend(word & 0xffff)
		is_immediate = bool(opcode & OPCODES["immediate"])

		if alu_type := opcode & OPCODES["mask"]:
			opcode_type = next(name for name, bits in OPCODES.items() if bits == alu_type)

			alu_op_number = opcode & OPCODES["alu_op"]
			alu_op = next(name for name, bits in ALU_OPS.items() if bits == alu_op_number)
			alu_b = f"{immediate:#04x}" if is_immediate else b
			alu_expression = f"{a} {alu_op} {alu_b}"
			if alu_op in SINGLE_TERM_ALUOPS:
				alu_expression = f"{alu_op}{alu_b}"
				if is_immediate and alu_op == "~":
					# we can clean this up, no need to make the user calculate this
					immediate = sign_extend(immediate ^ 0xffff) # invert
					alu_expression = f"{immediate:#04x}"

			disassembled = f"{opcode_type} {alu_expression}"
			if opcode_type == "ALU":
				disassembled = f"{b} = {alu_expression}"
			if opcode_type == "LOAD":
				disassembled = f"{b} = mem[{alu_expression}]"
			if opcode_type == "STORE":
				disassembled = f"mem[{alu_expression}] = {b}"
			if opcode_type.startswith("BR"):
				negate = "!" if opcode_type == "BRZ" else ""
				disassembled = f"if ({negate}{b}) $pc = {alu_expression}"
	except StopIteration:
		# we probably couldn't find something
		pass
	return disassembled


def main(args):
	def output(*args_, **kwargs):
		print(*args_, **kwargs, file=args.output)
	output_words = [0] * args.output_min_size
	output_comments = {} # address: comment

	for address, ow, output_comment in generate_assembler_words(args.input_files, args):
		# sparse outputs
		if args.output_type == "asm":
			asm_line = f"{address:#010x}: .word {ow:#010x} # {output_comment}"
			if args.disassemble:
				asm_line = f"{address:#010x}: {disassemble(ow):30}# {output_comment}"
			output(asm_line)
		if args.output_type == "verilog_trenary":
			output(f"(mem_addr == 32'h_{address:08x}) ? 32'h_{ow:08x} : // {output_comment}")

		# array type outputs
		address -= args.output_offset
		assert address >= 0, "We're trying to write before the start of the file"
		if address == len(output_words):
			output_words.append(ow)
		elif address < len(output_words):
			output_words[address - args.output_offset] = ow
		else:
			assert address > len(output_words)
		output_comments[address] = output_comment

	if args.output_type == "logisim":
		output("v2.0 raw")
		for addr, word in enumerate(output_words):
			output(f"{word:x}", end=" \n"[addr%8==7])
		output("1")
	if args.output_type == "c_array":
		if args.output_variable_name is None:
			args.output_variable_name = args.input_files[0].name.split("/")[-1].split(".")[0]
		output(f"const unsigned int {args.output_variable_name}[{len(output_words)}] = {{")
		for address, word in enumerate(output_words):
			output(f"\t{word:#010x},", end="")
			if output_comments[address]:
				output(f" // {output_comments[address]}", end="")
			output()
		output("};")

		pass

	globals().update(locals()) #TODO: This is for output_commentging only, remove

if __name__=="__main__":
	p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)

	p.add_argument("input_files", nargs='+', type=argparse.FileType('r'), help="input .hs assembly files")
	p.add_argument("--output", type=argparse.FileType('w'), help="output files", default="/dev/stdout")
	p.add_argument("--output_type", choices=["asm", "verilog_trenary", "logisim", "c_array"], default="asm")
	p.add_argument("--output_offset", type=eval, default=0, help="the starting address of the output")
	p.add_argument("--output_min_size", type=eval, default=0)
	p.add_argument("--output_variable_name")
	p.add_argument("--comment_type", choices=["internal_state", "original_line"], default="original_line")
	p.add_argument('--disassemble', action='store_true', help="Try to come up with original source for input .words")

	args = p.parse_args()

	if args.output_type == "logisim" and args.output_min_size < 256:
		args.output_min_size = 256

	main(args)
