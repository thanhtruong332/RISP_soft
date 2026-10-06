`timescale 1ns / 1ps
module rissp_top (
    input clk, rst_n,
    input [31:0] MEM_RDATA, input MEM_READY,
    output CPU_DATA, output CPU_PRIVILEGED, output [3:0] HPROT,
    output [31:0] MEM_ADDR, output [31:0] MEM_WDATA, 
    output MEM_WRITE, output MEM_READ,
    output [31:0] INST_ADDR, input [31:0] INST_DATA,
    
    // THÊM ĐÚNG CHÂN NÀY ĐỂ BẢO VỆ DỮ LIỆU AES
    output [3:0] MEM_WSTRB 
);
    wire [31:0] pc, next_pc, insn, rs1_data, rs2_data, rdest_data;
    wire [3:0]  dmem_wstrb;
    wire [4:0]  rs1_addr, rs2_addr, rdest_addr;
    wire        rf_wen, dmem_read_internal;

    assign CPU_DATA = 0; assign CPU_PRIVILEGED = 0; assign HPROT = 0;

    assign INST_ADDR = pc;
    assign MEM_WRITE = |dmem_wstrb;
    assign MEM_READ  = dmem_read_internal;
    assign MEM_WSTRB = dmem_wstrb; // Nối dây wstrb ra ngoài

    modular_ex mex (
        .pc(pc), .insn(insn), .rs1_data(rs1_data), .rs2_data(rs2_data), .dmem_rdata(MEM_RDATA),
        .next_pc(next_pc), .rdest_data(rdest_data), .rdest_addr(rdest_addr),
        .rf_wen(rf_wen), .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .dmem_addr(MEM_ADDR), .dmem_wdata(MEM_WDATA), .dmem_wstrb(dmem_wstrb), .dmem_read(dmem_read_internal)
    );

    fetch_stage fetch (
        .clk(clk), .rst_n(rst_n), .stall(1'b0), // Ép stall = 0
        .next_pc(next_pc), .imem_addr(), .imem_rdata(INST_DATA), .pc(pc), .insn(insn)
    );

    register_file rf (
        .clk(clk), .rst_n(rst_n), .wen(rf_wen),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .rdest_addr(rdest_addr), .rdest_data(rdest_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );
endmodule
