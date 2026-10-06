module u_type_block (
    // ===== INPUTS =====
    input  [31:0] pc,           // Program Counter từ FETCH
    input  [31:0] insn,         // Instruction từ IMEM
    
    // ===== OUTPUTS =====
    output reg [31:0] next_pc,      // Next PC (luôn pc+4)
    output reg [31:0] rdest_data,   // Result data ghi vào RF
    output reg [4:0]  rdest_addr    // Destination register address
);

// ===== DECODE INSTRUCTION FIELDS =====
wire [6:0]  opcode = insn[6:0];
wire [31:0] imm = {insn[31:12], 12'b0};  // Upper 20 bits

// ===== EXECUTION LOGIC =====
always @(*) begin
    // Decode destination address
    rdest_addr = insn[11:7];
    
    // Next PC
    next_pc = pc + 4;
    
    // Execute
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
