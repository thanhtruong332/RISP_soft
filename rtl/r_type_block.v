module r_type_block (
    // ===== INPUTS =====
    input  [31:0] pc,           // Program Counter từ FETCH
    input  [31:0] insn,         // Instruction từ IMEM
    input  [31:0] rs1_data,     // Register source 1 data từ RF
    input  [31:0] rs2_data,     // Register source 2 data từ RF
    
    // ===== OUTPUTS =====
    output reg [31:0] next_pc,      // Next PC (luôn là pc+4)
    output reg [31:0] rdest_data,   // Result data ghi vào RF
    output reg [4:0]  rdest_addr,   // Destination register address
    output reg [4:0]  rs1_addr,     // Source register 1 address
    output reg [4:0]  rs2_addr      // Source register 2 address
);

// ===== DECODE INSTRUCTION FIELDS =====
wire [2:0] funct3 = insn[14:12];
wire [6:0] funct7 = insn[31:25];

// ===== EXECUTION LOGIC =====
always @(*) begin
    // Decode register addresses
    rdest_addr = insn[11:7];
    rs1_addr   = insn[19:15];
    rs2_addr   = insn[24:20];
    
    // Next PC (R-type never branches)
    next_pc = pc + 4;
    
    // Execute ALU operation
    case (funct3)
        3'b000: begin // ADD/SUB
            if (funct7[5])
                rdest_data = rs1_data - rs2_data;  // SUB
            else
                rdest_data = rs1_data + rs2_data;  // ADD
        end
        
        3'b001: rdest_data = rs1_data << rs2_data[4:0];  // SLL
        
        3'b010: rdest_data = ($signed(rs1_data) < $signed(rs2_data)) ? 32'd1 : 32'd0;  // SLT
        
        3'b011: rdest_data = (rs1_data < rs2_data) ? 32'd1 : 32'd0;  // SLTU
        
        3'b100: rdest_data = rs1_data ^ rs2_data;  // XOR
        
        3'b101: begin // SRL/SRA
            if (funct7[5])
                rdest_data = $signed(rs1_data) >>> rs2_data[4:0];  // SRA
            else
                rdest_data = rs1_data >> rs2_data[4:0];  // SRL
        end
        
        3'b110: rdest_data = rs1_data | rs2_data;  // OR
        
        3'b111: rdest_data = rs1_data & rs2_data;  // AND
        
        default: rdest_data = 32'b0;
    endcase
end

endmodule
