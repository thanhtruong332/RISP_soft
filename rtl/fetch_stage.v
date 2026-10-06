`timescale 1ns / 1ps
module fetch_stage (
    input clk, rst_n, stall,
    input [31:0] next_pc,
    output [31:0] imem_addr,
    input [31:0] imem_rdata,
    output [31:0] pc,
    output [31:0] insn
);
    reg [31:0] pc_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      pc_reg <= 32'h0;
        else if (!stall) pc_reg <= next_pc;
    end

    // DÙNG pc_reg ĐỂ MÔ PHỎNG KHÔNG BỊ TREO CỨNG
    assign imem_addr = pc_reg; 
    assign pc        = pc_reg;
    assign insn      = (!rst_n) ? 32'h00000013 : imem_rdata;
endmodule
