/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by substituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you activate when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module cpu(
  // Control signals
  clock,                          // I: The master clock
  reset,                          // I: A reset signal

  // Imem
  address_imem,                   // O: The address of the data to get from imem
  q_imem,                         // I: The data from imem

  // Dmem
  address_dmem,                   // O: The address of the data to get or put from/to dmem
  data,                           // O: The data to write to dmem
  wren,                           // O: Write enable for dmem
  q_dmem,                         // I: The data from dmem

  // Regfile
  ctrl_writeEnable,               // O: Write enable for regfile
  ctrl_writeReg,                  // O: Register to write to in regfile
  ctrl_readRegA,                  // O: Register to read from port A of regfile
  ctrl_readRegB,                  // O: Register to read from port B of regfile
  data_writeReg,                  // O: Data to write to for regfile
  data_readRegA,                  // I: Data from port A of regfile
  data_readRegB                   // I: Data from port B of regfile
);
  // Control signals
  input clock, reset;

  // Imem
  output [11:0] address_imem;
  input [31:0] q_imem;

  // Dmem
  output [11:0] address_dmem;
  output [31:0] data;
  output wren;
  input [31:0] q_dmem;

  // Regfile
  output ctrl_writeEnable;
  output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
  output [31:0] data_writeReg;
  input [31:0] data_readRegA, data_readRegB;

  /* YOUR CODE STARTS HERE */
  wire [31:0] instruction;
  assign instruction = q_imem;

  // PC Logic
  wire [31:0] pc;
  wire [31:0] pc_next;

  wire [31:0] pc_plus_one;
  wire unused_overflow_pc_plus_one, unused_isNotEqual_pc_plus_one, unused_isLessThan_pc_plus_one;

  alu alu_pc_plus_one (
      .data_operandA(pc),
      .data_operandB(32'd1),
      .ctrl_ALUopcode(5'b00000), // Opcode for addition
      .ctrl_shiftamt(5'b00000),
      .data_result(pc_plus_one),
      .isNotEqual(unused_isNotEqual_pc_plus_one),
      .isLessThan(unused_isLessThan_pc_plus_one),
      .overflow(unused_overflow_pc_plus_one)
  );

  wire [31:0] jump_target;
  assign jump_target = {5'b0, instruction[26:0]};

    // ALU instance for branch_target
  wire [31:0] branch_offset;
  wire [31:0] branch_target;
  wire unused_overflow_branch_target, unused_isNotEqual_branch_target, unused_isLessThan_branch_target;

  // Sign-extend the immediate value
  assign branch_offset = {{15{instruction[16]}}, instruction[16:0]};

  alu alu_branch_target (
      .data_operandA(pc_plus_one),
      .data_operandB(branch_offset),
      .ctrl_ALUopcode(5'b00000), // Opcode for addition
      .ctrl_shiftamt(5'b00000),
      .data_result(branch_target),
      .isNotEqual(unused_isNotEqual_branch_target),
      .isLessThan(unused_isLessThan_branch_target),
      .overflow(unused_overflow_branch_target)
  );

  // PC Register
  genvar j;
  generate
    for (j = 0; j < 32; j = j + 1) begin: pc_register
      dffe_ref pc_dffe (
        .q(pc[j]),
        .d(pc_next[j]),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
      );
    end
  endgenerate

  // Instruction Fetch
  assign address_imem = pc[11:0];
  
  wire [4:0] opcode;
  wire [4:0] rd, rs, rt;
  wire [4:0] shamt, alu_op;
  wire [16:0] immediate;

  assign opcode = instruction[31:27];
  assign rd = instruction[26:22];
  assign rs = instruction[21:17];
  assign rt = instruction[16:12];
  assign shamt = instruction[11:7];
  assign alu_op = instruction[6:2];
  assign immediate = instruction[16:0];

  // For I-type instructions
  wire [31:0] imm_ext;
  assign imm_ext[16:0] = immediate;
  assign imm_ext[31:17] = {15{immediate[16]}};

  wire Rwe, Rdst, ALUinB, DMWe, Rwd, JP, BR, ALUop_ctl;
  wire is_R, is_addi, is_sw, is_lw, is_j, is_bne, is_jal, is_jr, is_blt, is_bex, is_setx;

  // Control Unit
  control control_unit (
    .opcode(opcode),
    .Rwe(Rwe),
    .Rdst(Rdst),
    .ALUinB(ALUinB),
    .ALUop_ctl(ALUop_ctl),
    .DMWe(DMWe),
    .Rwd(Rwd),
    .JP(JP),
    .BR(BR),
    .is_R(is_R),
    .is_addi(is_addi),
    .is_sw(is_sw),
    .is_lw(is_lw),
    .is_j(is_j),
    .is_bne(is_bne),
    .is_jal(is_jal),
    .is_jr(is_jr),
    .is_blt(is_blt),
    .is_bex(is_bex),
    .is_setx(is_setx)
  );

  // Identify R-type operations
  wire is_add, is_sub, is_and, is_or, is_sll, is_sra;
  assign is_add  = is_R & ~alu_op[4] & ~alu_op[3] & ~alu_op[2] & ~alu_op[1] & ~alu_op[0];
  assign is_sub  = is_R & ~alu_op[4] & ~alu_op[3] & ~alu_op[2] & ~alu_op[1] &  alu_op[0];
  assign is_and  = is_R & ~alu_op[4] & ~alu_op[3] & ~alu_op[2] &  alu_op[1] & ~alu_op[0];
  assign is_or   = is_R & ~alu_op[4] & ~alu_op[3] & ~alu_op[2] &  alu_op[1] &  alu_op[0];
  assign is_sll  = is_R & ~alu_op[4] & ~alu_op[3] &  alu_op[2] & ~alu_op[1] & ~alu_op[0];
  assign is_sra  = is_R & ~alu_op[4] & ~alu_op[3] &  alu_op[2] & ~alu_op[1] &  alu_op[0];

  wire is_overflow, is_not_equal, is_less_than;

  // ALU
  wire [31:0] alu_data_operandA, alu_data_operandB, alu_output;
  wire [4:0] ALUop;

  assign alu_data_operandA = data_readRegA;
  assign alu_data_operandB = ALUinB ? imm_ext : data_readRegB;

  assign ALUop = is_R ? alu_op :
                 (is_bne | is_blt) ? 5'b00001 : 
                 (is_addi | is_lw | is_sw) ? 5'b00000 :
                 5'b00000;

  alu alu_unit (
    .data_operandA(alu_data_operandA),
    .data_operandB(alu_data_operandB),
    .ctrl_ALUopcode(ALUop),
    .ctrl_shiftamt(shamt),
    .data_result(alu_output),
    .isNotEqual(is_not_equal),
    .isLessThan(is_less_than),
    .overflow(is_overflow)
  );

  // Regfile
  assign ctrl_readRegA = (is_bne | is_blt | is_jr) ? rd : (is_bex ? 5'b11110 : rs);
  assign ctrl_readRegB = (is_bne | is_blt) ? rs : (is_sw ? rd : rt);

  assign ctrl_writeReg = is_setx ? 5'b11110 : // $r30
                         is_jal ? 5'b11111 :  // $r31
                         (is_overflow ? 5'b11110 : rd);

  assign ctrl_writeEnable = Rwe;

  // DMEM
  assign address_dmem = alu_output[11:0];
  assign data = data_readRegB;
  assign wren = DMWe;

  assign data_writeReg = is_setx ? jump_target :
                         is_jal ? pc_plus_one :
                         is_lw ? q_dmem :
                         is_overflow ? (is_add ? 32'd1 :
                                        is_addi ? 32'd2 :
                                        is_sub ? 32'd3 : alu_output) :
                         alu_output;

    // ALU instance for data_readRegA comparison
  wire isNotEqual_zero;
  wire unused_overflow_compare_zero, unused_isLessThan_compare_zero;

  alu alu_compare_zero (
      .data_operandA(data_readRegA),
      .data_operandB(32'd0),
      .ctrl_ALUopcode(5'b00001), // Opcode for subtraction
      .ctrl_shiftamt(5'b00000),
      .data_result(), // We don't need the result
      .isNotEqual(isNotEqual_zero),
      .isLessThan(unused_isLessThan_compare_zero),
      .overflow(unused_overflow_compare_zero)
  );

  // Update branch_taken logic
  assign branch_taken = (is_bne & is_not_equal) |
                        (is_blt & is_less_than) |
                        (is_bex & isNotEqual_zero);

  // PC Update Logic
  assign pc_next = is_jr ? data_readRegA :
                   (is_j | is_jal | (is_bex & branch_taken)) ? jump_target :
                   (BR & branch_taken) ? branch_target :
                   pc_plus_one;

endmodule
