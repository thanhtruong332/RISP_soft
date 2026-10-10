// Author: Thanh Truong
module j_type_block (
    input  [31:0] pc,
    input  [31:0] insn,

    output reg [31:0] next_pc,      // Next PC (pc + offset)
    output reg [31:0] rdest_data,   // Return address (pc+4)
    output reg [4:0]  rdest_addr    // Destination register address
);

wire [31:0] imm = {{11{insn[31]}}, insn[31], insn[19:12], insn[20], insn[30:21], 1'b0};

always @(*) begin
    rdest_addr = insn[11:7];

    // Jump
    next_pc = pc + imm;

    // Save return address
    rdest_data = pc + 4;
end

endmodule
