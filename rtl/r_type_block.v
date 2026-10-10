// Author: Thanh Truong
module r_type_block (
    input  [31:0] pc,
    input  [31:0] insn,
    input  [31:0] rs1_data,
    input  [31:0] rs2_data,

    output reg [31:0] next_pc,
    output reg [31:0] rdest_data,
    output reg [4:0]  rdest_addr,   // Destination register address
    output reg [4:0]  rs1_addr,     // Source register 1 address
    output reg [4:0]  rs2_addr      // Source register 2 address
);

wire [2:0] funct3 = insn[14:12];
wire [6:0] funct7 = insn[31:25];

always @(*) begin
    // Decode register addresses
    rdest_addr = insn[11:7];
    rs1_addr   = insn[19:15];
    rs2_addr   = insn[24:20];

    next_pc = pc + 4;

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
