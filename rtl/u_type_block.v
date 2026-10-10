// Author: Thanh Truong
module u_type_block (
    input  [31:0] pc,
    input  [31:0] insn,

    output reg [31:0] next_pc,
    output reg [31:0] rdest_data,
    output reg [4:0]  rdest_addr    // Destination register address
);

wire [6:0]  opcode = insn[6:0];
wire [31:0] imm = {insn[31:12], 12'b0};  // Upper 20 bits

always @(*) begin
    rdest_addr = insn[11:7];

    next_pc = pc + 4;

    if (opcode == 7'b0110111) begin
        // LUI - Load Upper Immediate
        rdest_data = imm;
    end
    else begin
        // AUIPC - Add Upper Immediate to PC
        rdest_data = pc + imm;
    end
end

endmodule
