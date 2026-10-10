// Author: Thanh Truong
`timescale 1ns / 1ps

module modular_ex (
    input  [31:0] pc, insn, rs1_data, rs2_data, dmem_rdata,
    output reg [31:0] next_pc, rdest_data,
    output reg [4:0]  rdest_addr,
    output reg        rf_wen,
    output reg [31:0] dmem_addr, dmem_wdata,
    output reg [3:0]  dmem_wstrb,
    output reg        dmem_read,
    output wire [4:0] rs1_addr, rs2_addr
);
    assign rs1_addr = insn[19:15];
    assign rs2_addr = insn[24:20];
    wire [6:0] opcode = insn[6:0];

    wire [31:0] imm_s = {{20{insn[31]}}, insn[31:25], insn[11:7]};
    wire [31:0] imm_i = {{20{insn[31]}}, insn[31:20]};

    wire [31:0] b_next_pc, j_next_pc, i_next_pc_jalr, r_rdest, i_rdest, u_rdest;
    r_type_block r_blk (
        .pc(pc),
        .insn(insn),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rdest_data(r_rdest)
    );
    i_type_block i_blk (
        .pc(pc),
        .insn(insn),
        .rs1_data(rs1_data),
        .dmem_rdata(dmem_rdata),
        .next_pc(i_next_pc_jalr),
        .rdest_data(i_rdest)
    );
    b_type_block b_blk (
        .pc(pc),
        .insn(insn),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .next_pc(b_next_pc)
    );
    j_type_block j_blk (
        .pc(pc),
        .insn(insn),
        .next_pc(j_next_pc),
        .rdest_data(j_rdest)
    );
    u_type_block u_blk (
        .pc(pc),
        .insn(insn),
        .rdest_data(u_rdest)
    );

    always @(*) begin

        next_pc    = pc + 4;
        rdest_data = 32'b0;
        rdest_addr = insn[11:7];
        rf_wen     = 1'b0;
        dmem_addr  = 32'b0;
        dmem_wdata = 32'b0;
        dmem_wstrb = 4'b0000;
        dmem_read  = 1'b0;

        case (opcode)
            7'b0110111: begin // LUI
                rdest_data = {insn[31:12], 12'b0}; rf_wen = 1'b1;
            end
            7'b0010011: begin // I-type ALU
                rdest_data = i_rdest; rf_wen = 1'b1;
            end
            7'b0000011: begin // LOAD (lw)
                dmem_addr  = rs1_data + imm_i;
                dmem_read  = 1'b1;
                rdest_data = dmem_rdata; rf_wen = 1'b1;
            end
            7'b0100011: begin
                dmem_addr  = rs1_data + imm_s;
                dmem_wdata = rs2_data;
                dmem_wstrb = 4'b1111;
                rf_wen     = 1'b0;
            end
            7'b1100011: next_pc = b_next_pc;
            7'b1101111, 7'b1100111: begin // JAL, JALR
                next_pc = (opcode == 7'b1101111) ? j_next_pc : i_next_pc_jalr;
                rdest_data = pc + 4; rf_wen = 1'b1;
            end
            7'b0110011: begin rdest_data = r_rdest; rf_wen = 1'b1; end
            default: ;
        endcase
    end
endmodule
