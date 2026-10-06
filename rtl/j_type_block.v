module j_type_block (
    // ===== INPUTS =====
    input  [31:0] pc,           // Program Counter từ FETCH
    input  [31:0] insn,         // Instruction từ IMEM
    
    // ===== OUTPUTS =====
    output reg [31:0] next_pc,      // Next PC (pc + offset)
    output reg [31:0] rdest_data,   // Return address (pc+4)
    output reg [4:0]  rdest_addr    // Destination register address
);

// ===== DECODE INSTRUCTION FIELDS =====
wire [31:0] imm = {{11{insn[31]}}, insn[31], insn[19:12], insn[20], insn[30:21], 1'b0};

// ===== EXECUTION LOGIC =====
always @(*) begin
    // Decode destination address
    rdest_addr = insn[11:7];
    
    // Jump
    next_pc = pc + imm;
    
    // Save return address
    rdest_data = pc + 4;
end

endmodule
