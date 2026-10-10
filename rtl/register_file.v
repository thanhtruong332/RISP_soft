// Author: Thanh Truong
`timescale 1ns / 1ps
module register_file (
    input         clk,
    input         rst_n,
    input         wen,
    input  [4:0]  rs1_addr,
    input  [4:0]  rs2_addr,
    input  [4:0]  rdest_addr,
    input  [31:0] rdest_data,
    output [31:0] rs1_data,
    output [31:0] rs2_data
);
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) regs[i] <= 32'h0;
        end
        else if (wen && (rdest_addr != 5'b00000)) begin
            regs[rdest_addr] <= rdest_data;
        end
    end

    // Read directly from the register array without write-through bypass.
    assign rs1_data = (rs1_addr == 5'b00000) ? 32'b0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b00000) ? 32'b0 : regs[rs2_addr];

endmodule
