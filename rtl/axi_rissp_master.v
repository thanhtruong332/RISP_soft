`timescale 1ns / 1ps
module axi_rissp_master (
    input clk, rst_n,
    input [31:0] dmem_addr, dmem_wdata,
    input [3:0]  dmem_wstrb,
    input        dmem_read,
    output reg [31:0] dmem_rdata,
    output wire stall_cpu,

    output reg [31:0] m_axi_awaddr,
    output wire [2:0] m_axi_awprot,
    output reg        m_axi_awvalid,
    input             m_axi_awready,

    output reg [31:0] m_axi_wdata,
    output reg [3:0]  m_axi_wstrb,
    output reg        m_axi_wvalid,
    input             m_axi_wready,

    input [1:0] m_axi_bresp,
    input       m_axi_bvalid,
    output reg  m_axi_bready,

    output reg [31:0] m_axi_araddr,
    output wire [2:0] m_axi_arprot,
    output reg        m_axi_arvalid,
    input             m_axi_arready,

    input [31:0] m_axi_rdata,
    input [1:0]  m_axi_rresp,
    input        m_axi_rvalid,
    output reg   m_axi_rready
);
    assign m_axi_awprot = 3'b000;
    assign m_axi_arprot = 3'b000;

    localparam IDLE       = 3'b001;
    localparam WRITE_DATA = 3'b010;
    localparam READ_DATA  = 3'b100;

    reg [2:0] state;
    reg aw_done, w_done, b_done, ar_done, r_done;

    // BUG FIX 1: stall_cpu
    // TRƯỚC: stall = cpu_req khi IDLE → stall 1 cycle thừa
    //        khiến fetch_stage dùng pc_reg thay vì next_pc
    //        → BRAM fetch sai instruction
    // Stall while an AXI transaction is in progress.
    //        tức là transaction đang thật sự diễn ra
    wire cpu_req = (|dmem_wstrb) || dmem_read;
    assign stall_cpu = (state != IDLE);

    // BUG FIX 2: write_complete / read_complete
    // TRƯỚC: dùng combinational check (bvalid && bready)
    //        → write_complete=1 cùng cycle bvalid lên
    //        → state về IDLE ngay, b_done chưa kịp set
    //        → cycle sau: IDLE + cpu_req=1 → stall lại
    //        → CPU execute lại sw instruction → AXI double-write
    // Complete only after all required channel handshakes finish.
    //        (registered, tức là handshake đã xong cycle trước)
    wire write_complete = (state == WRITE_DATA) &&
                          aw_done && w_done && b_done;

    wire read_complete  = (state == READ_DATA) &&
                          ar_done && r_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            m_axi_awaddr  <= 32'h0;
            m_axi_awvalid <= 0;
            m_axi_wdata   <= 32'h0;
            m_axi_wstrb   <= 4'h0;
            m_axi_wvalid  <= 0;
            m_axi_bready  <= 0;
            m_axi_araddr  <= 32'h0;
            m_axi_arvalid <= 0;
            m_axi_rready  <= 0;
            dmem_rdata    <= 32'h0;
            aw_done <= 0; w_done <= 0; b_done <= 0;
            ar_done <= 0; r_done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    aw_done <= 0; w_done <= 0; b_done <= 0;
                    ar_done <= 0; r_done <= 0;

                    if (cpu_req) begin
                        if (|dmem_wstrb) begin
                            state         <= WRITE_DATA;
                            m_axi_awaddr  <= dmem_addr;
                            m_axi_awvalid <= 1;
                            m_axi_wdata   <= dmem_wdata;
                            m_axi_wstrb   <= dmem_wstrb;
                            m_axi_wvalid  <= 1;
                            m_axi_bready  <= 1;
                        end else if (dmem_read) begin
                            state         <= READ_DATA;
                            m_axi_araddr  <= dmem_addr;
                            m_axi_arvalid <= 1;
                            m_axi_rready  <= 1;
                        end
                    end else begin
                        m_axi_awvalid <= 0;
                        m_axi_wvalid  <= 0;
                        m_axi_arvalid <= 0;
                    end
                end

                WRITE_DATA: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 0;
                        aw_done       <= 1;
                    end
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid <= 0;
                        w_done       <= 1;
                    end
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 0;
                        b_done       <= 1;
                    end
                    // Chỉ về IDLE sau khi tất cả done flags đã set
                    if (write_complete) state <= IDLE;
                end

                READ_DATA: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 0;
                        ar_done       <= 1;
                    end
                    if (m_axi_rvalid && m_axi_rready) begin
                        dmem_rdata   <= m_axi_rdata;
                        m_axi_rready <= 0;
                        r_done       <= 1;
                    end
                    if (read_complete) state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
