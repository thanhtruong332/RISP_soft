// Author: Thanh Truong
`timescale 1ns / 1ps

module i_type_block (
    input  [31:0] pc,
    input  [31:0] insn,
    input  [31:0] rs1_data,
    input  [31:0] dmem_rdata,
    output [31:0] next_pc,
    output reg [31:0] rdest_data,
    output reg [4:0]  rdest_addr,
    output [31:0] dmem_addr,
    output reg    dmem_read
);
    wire [6:0]  opcode = insn[6:0];
    wire [2:0]  funct3 = insn[14:12];
    wire [31:0] imm    = {{20{insn[31]}}, insn[31:20]};
    wire [4:0]  shamt  = insn[24:20];
    wire [31:0] addr   = rs1_data + imm;

    assign next_pc   = (opcode == 7'b1100111) ? (addr & ~32'h1) : (pc + 4);
    assign dmem_addr = addr;

    always @(*) begin
        dmem_read = 1'b0;
        rdest_data = 32'b0;

        rdest_addr = insn[11:7];

        case (opcode)
            7'b0010011: begin // ALU Immediate
                case (funct3)
                    3'b000: rdest_data = rs1_data + imm;            // ADDI
                    3'b010: rdest_data = ($signed(rs1_data) < $signed(imm)) ? 32'd1 : 32'd0; // SLTI
                    3'b011: rdest_data = (rs1_data < imm) ? 32'd1 : 32'd0; // SLTIU
                    3'b100: rdest_data = rs1_data ^ imm;            // XORI
                    3'b110: rdest_data = rs1_data | imm;            // ORI
                    3'b111: rdest_data = rs1_data & imm;            // ANDI
                    3'b001: rdest_data = rs1_data << shamt;         // SLLI
                    3'b101: rdest_data = insn[30] ? ($signed(rs1_data) >>> shamt) : (rs1_data >> shamt); // SRAI/SRLI
                endcase
            end
            7'b0000011: begin // LOAD
                dmem_read = 1'b1;
                case (funct3)
                    3'b000: begin // LB
                        case (addr[1:0])
                            2'b00: rdest_data = {{24{dmem_rdata[7]}},  dmem_rdata[7:0]};
                            2'b01: rdest_data = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                            2'b10: rdest_data = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                            2'b11: rdest_data = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
                        endcase
                    end
                    3'b100: begin // LBU
                        case (addr[1:0])
                            2'b00: rdest_data = {24'b0, dmem_rdata[7:0]};
                            2'b01: rdest_data = {24'b0, dmem_rdata[15:8]};
                            2'b10: rdest_data = {24'b0, dmem_rdata[23:16]};
                            2'b11: rdest_data = {24'b0, dmem_rdata[31:24]};
                        endcase
                    end
                    3'b010: rdest_data = dmem_rdata; // LW
                    default: rdest_data = 32'b0;
                endcase
            end
            7'b1100111: rdest_data = pc + 4; // JALR
        endcase
    end
endmodule
