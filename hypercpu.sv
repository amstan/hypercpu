localparam MCLK_MEM_INSTRUCTION = 1'b0;
localparam MCLK_MEM_LOADSTORE   = 1'b1;

module hypercpu(
	// Memory
	output wire[31:0] mem_addr,
	inout tri[31:0] mem_read,
	output wire[31:0] mem_write,
	output wire mem_write_enable,

	// Meta
	input mclk,
	input reset
);

// Instruction decoding
reg[31:0] instruction;
wire[7:0] opcode = instruction[31:24];
wire[3:0] a_addr = instruction[23:20];
wire[3:0] b_addr = instruction[19:16];
wire[15:0] immediate = instruction[15:0]; // TODO: this should be signed, and later on extended to 32 bit when it goes into the ALU

// Registers
// The values of the 2 registers that the instruction pertains to
wire[31:0] a;
wire[31:0] b;
// Writing
tri[31:0] reg_write_data;
wire reg_write_enable;
// Special
// verilator lint_save
// verilator lint_off UNUSED
// verilator lint_off UNDRIVEN
wire[31:0] sp, next_sp;
// verilator lint_restore
wire[31:0] pc, next_pc;

hypercpu_registers hypercpu_registers(
	.read_a_addr(a_addr),
	.read_b_addr(b_addr),
	.read_a_data(a),
	.read_b_data(b),

	.write_addr(b_addr),
	.write_data(reg_write_data),
	.write_enable(reg_write_enable),

	.next_sp(next_sp),
	.next_pc(next_pc),
	.read_sp(sp),
	.read_pc(pc),

	.mclk(mclk), .reset(reset)
);

// ALU
// verilator lint_save
// verilator lint_off UNOPTFLAT
// There is no loop here, it's gated by the difference between the 2 MCLK_MEM_'s
wire[31:0] alu_result;
// verilator lint_restore

hypercpu_alu hypercpu_alu(.a(a), .b(opcode[4] ? immediate : b), .op(opcode[3:0]), .r(alu_result));
// Maybe this is it and we just want to put it in a register:
wire alu_result_to_reg = opcode[7:5] == 3'b111;
assign reg_write_data = alu_result_to_reg ? alu_result : 32'bZ;
//assign reg_write_enable = alu_result_to_reg;

// Program flow
assign next_pc = pc + 1;
// verilator lint_save
// verilator lint_off UNUSED
wire is_br = opcode[7:6] == 2'b01;
wire br_on_true = opcode[5]; // 0 == BRNZ, 1 = BRZ
// TODO: Implement BR
// verilator lint_restore

// Memory
// Multiplexing to do both instruction loading and memory reads into registers
assign mem_addr = (mclk == MCLK_MEM_INSTRUCTION) ? pc : alu_result;
// Latch so we can still read the contents off cycle
// reg[31:0] instruction; is declared up high ^^^^^^^^
reg[31:0] data_from_mem_to_be_loaded;
always @ (mclk or mem_read) begin
	if (mclk == MCLK_MEM_INSTRUCTION)
		instruction = mem_read;
	else
		data_from_mem_to_be_loaded = mem_read;
end

// Memory LOAD
wire is_load = opcode[7:5] == 3'b100;
assign reg_write_data = is_load ? data_from_mem_to_be_loaded : 32'bZ;
//assign reg_write_enable = is_load;

assign reg_write_enable = alu_result_to_reg | is_load;

// Memory STORE
wire is_store = opcode[7:5] == 3'b101;
assign mem_write = b;
assign mem_write_enable = is_store;

// Attachments to the memory bus
hypercpu_rom hypercpu_rom(.mem_addr(mem_addr[23:0]), .mem_read(mem_read), .mem_read_enabled(mem_addr[31:24] == 8'h00));

endmodule
