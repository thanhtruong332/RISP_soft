`timescale 1ns / 1ps
module tb_expG_scale_rissp_16b_ecb;
    localparam [31:0] START_ADDR = 32'h0000ff00;
    localparam [31:0] STOP_ADDR = 32'h0000ff04;
    localparam [31:0] ERRORS_ADDR = 32'h0000ff08;
    localparam [31:0] STATUS_ADDR = 32'h0000ff0c;
    localparam integer OUTPUT_INDEX = 720;
    localparam integer BLOCKS = 1;
    localparam integer PAYLOAD_BYTES = 16;

    reg clk = 0;
    reg rst_n = 0;
    reg [31:0] MEM_RDATA = 0;
    reg MEM_READY = 1;
    wire [31:0] MEM_ADDR, MEM_WDATA, INST_ADDR, INST_DATA;
    wire MEM_WRITE, MEM_READ, CPU_DATA, CPU_PRIVILEGED;
    wire [3:0] HPROT;
    wire [3:0] MEM_WSTRB;

    reg [31:0] unified_mem [0:16383];
    reg [7:0] expected_byte [0:PAYLOAD_BYTES-1];
    integer i;
    integer mem_index;
    integer repeat_id = 0;
    integer firmware_errors = -1;
    integer observed_errors = 0;
    integer cycle_count = 0;
    integer start_cycle = 0;
    integer raw_cycles = 0;
    integer retired = 0;
    integer alu_count = 0;
    integer load_count = 0;
    integer store_count = 0;
    integer branch_count = 0;
    integer taken_branch_count = 0;
    integer branch_penalty_cycles = 0;
    integer jump_count = 0;
    integer m_count = 0;
    integer b_count = 0;
    integer total_stalls = 0;
    integer control_stalls = 0;
    integer load_use_stalls = 0;
    integer memory_stalls = 0;
    integer derived_total_stalls = 0;
    integer counter_errors = 0;
    reg profile_active = 0;
    reg profile_complete = 0;

    rissp_top DUT (
        .clk(clk), .rst_n(rst_n), .MEM_RDATA(MEM_RDATA), .MEM_READY(MEM_READY),
        .CPU_DATA(CPU_DATA), .CPU_PRIVILEGED(CPU_PRIVILEGED), .HPROT(HPROT),
        .MEM_ADDR(MEM_ADDR), .MEM_WDATA(MEM_WDATA), .MEM_WRITE(MEM_WRITE),
        .MEM_READ(MEM_READ), .INST_ADDR(INST_ADDR), .INST_DATA(INST_DATA),
        .MEM_WSTRB(MEM_WSTRB)
    );

    always #12.5 clk = ~clk;
    assign INST_DATA = (^INST_ADDR === 1'bx) ? 32'h00000013 : unified_mem[(INST_ADDR & 32'h0000ffff) >> 2];

    always @(*) begin
        if (MEM_READ && (^MEM_ADDR !== 1'bx))
            MEM_RDATA = unified_mem[(MEM_ADDR & 32'h0000ffff) >> 2];
        else
            MEM_RDATA = 32'h0;
    end

    
    task count_instruction;
        input [31:0] instruction;
        reg [6:0] opcode;
        reg [6:0] funct7;
        begin
            opcode = instruction[6:0];
            funct7 = instruction[31:25];
            retired <= retired + 1;
            case (opcode)
                7'b0000011: load_count <= load_count + 1;
                7'b0100011: store_count <= store_count + 1;
                7'b1100011: begin
                    branch_count <= branch_count + 1;
                    // RISSP resolves the branch in its single-instruction datapath.
                    // A non-sequential next_pc is therefore a directly observed taken branch.
                    if (DUT.next_pc != (DUT.pc + 32'd4))
                        taken_branch_count <= taken_branch_count + 1;
                end
                7'b1101111, 7'b1100111: jump_count <= jump_count + 1;
                default: alu_count <= alu_count + 1;
            endcase
            if (opcode == 7'b0110011 && funct7 == 7'b0000001)
                m_count <= m_count + 1;
            if ((opcode == 7'b0110011 || opcode == 7'b0010011) && funct7 == 7'b0110000)
                b_count <= b_count + 1;
        end
    endtask

    always @(posedge clk) begin
        if (!rst_n) begin
            cycle_count <= 0;
            profile_active <= 0;
            profile_complete <= 0;
            start_cycle <= 0;
            raw_cycles <= 0;
            retired <= 0;
            alu_count <= 0;
            load_count <= 0;
            store_count <= 0;
            branch_count <= 0;
            taken_branch_count <= 0;
            branch_penalty_cycles <= 0;
            jump_count <= 0;
            m_count <= 0;
            b_count <= 0;
            total_stalls <= 0;
            control_stalls <= 0;
            load_use_stalls <= 0;
            memory_stalls <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (MEM_WRITE && MEM_READY && MEM_ADDR == START_ADDR) begin
                profile_active <= 1;
                profile_complete <= 0;
                start_cycle <= cycle_count;
                retired <= 0;
                alu_count <= 0;
                load_count <= 0;
                store_count <= 0;
                branch_count <= 0;
                taken_branch_count <= 0;
                branch_penalty_cycles <= 0;
                jump_count <= 0;
                m_count <= 0;
                b_count <= 0;
                total_stalls <= 0;
                control_stalls <= 0;
                load_use_stalls <= 0;
                memory_stalls <= 0;
            end else begin
                if (MEM_WRITE && MEM_READY && MEM_ADDR == STOP_ADDR) begin
                    profile_active <= 0;
                    profile_complete <= 1;
                    raw_cycles <= cycle_count - start_cycle;
                end
                if (profile_active && rst_n && !(MEM_WRITE && MEM_READY && MEM_ADDR == STOP_ADDR))
                    count_instruction(DUT.insn);
            end
            // RISSP is a one-instruction-at-a-time core in this project.
            // With MEM_READY held high, it has no separately observable memory stall cycle.
        end
    end




    always @(posedge clk) begin
        if (rst_n && MEM_WRITE && MEM_READY && (^MEM_ADDR !== 1'bx)) begin
            mem_index = (MEM_ADDR & 32'h0000ffff) >> 2;
            if (MEM_WSTRB[0]) unified_mem[mem_index][7:0]   <= MEM_WDATA[7:0];
            if (MEM_WSTRB[1]) unified_mem[mem_index][15:8]  <= MEM_WDATA[15:8];
            if (MEM_WSTRB[2]) unified_mem[mem_index][23:16] <= MEM_WDATA[23:16];
            if (MEM_WSTRB[3]) unified_mem[mem_index][31:24] <= MEM_WDATA[31:24];
            if (MEM_ADDR == ERRORS_ADDR)
                firmware_errors = MEM_WDATA;
            if (MEM_ADDR == STATUS_ADDR) begin
                observed_errors = 0;
                counter_errors = 0;
                derived_total_stalls = raw_cycles - retired - 1;
                for (i = 0; i < PAYLOAD_BYTES; i = i + 1)
                    if (unified_mem[OUTPUT_INDEX+i][7:0] !== expected_byte[i])
                        observed_errors = observed_errors + 1;
                if (retired != alu_count + load_count + store_count + branch_count + jump_count)
                    counter_errors = counter_errors + 1;
                if (taken_branch_count > branch_count)
                    counter_errors = counter_errors + 1;
                if (derived_total_stalls < 0)
                    counter_errors = counter_errors + 1;
                if (derived_total_stalls != control_stalls + load_use_stalls + memory_stalls)
                    counter_errors = counter_errors + 1;
                $display("[EXP_G] CORE=RISSP MODE=ECB REPEAT=%0d PAYLOAD_BYTES=%0d BLOCKS=%0d", repeat_id, PAYLOAD_BYTES, BLOCKS);
                $display("[EXP_G] START=%0d STOP=%0d RAW_CYCLES=%0d CYCLES_PER_BLOCK=%0f", start_cycle, start_cycle+raw_cycles, raw_cycles, raw_cycles/(BLOCKS*1.0));
                $display("[EXP_G] RETIRED=%0d CPI=%0f ALU=%0d LOAD=%0d STORE=%0d BRANCH=%0d JUMP=%0d M=%0d B=%0d", retired, raw_cycles/(retired*1.0), alu_count, load_count, store_count, branch_count, jump_count, m_count, b_count);
                $display("[EXP_G] TAKEN_BRANCH=%0d BRANCH_PENALTY_CYCLES=%0d", taken_branch_count, branch_penalty_cycles);
                $display("[EXP_G] TOTAL_STALLS=%0d CONTROL_STALLS=%0d LOAD_USE_STALLS=%0d MEMORY_STALLS=%0d OTHER_STALLS=%0d", derived_total_stalls, control_stalls, load_use_stalls, memory_stalls, derived_total_stalls-control_stalls-load_use_stalls-memory_stalls);
                $display("[EXP_G] COUNTER_ERRORS=%0d COUNTER_CHECK=%s", counter_errors, counter_errors==0 ? "PASS" : "FAIL");
                $display("[EXP_G] FW_ERRORS=%0d TB_ERRORS=%0d STATUS=%08x RESULT=%s", firmware_errors, observed_errors, MEM_WDATA, (MEM_WDATA==32'h50415353 && firmware_errors==0 && observed_errors==0 && counter_errors==0 && profile_complete) ? "PASS" : "FAIL");
                $display("[EXP_G] BLOCKS_CHECKED=%0d BYTES_CHECKED=%0d", BLOCKS, PAYLOAD_BYTES);
                for (i = 0; i < BLOCKS; i = i + 1) begin
                    $write("[EXP_G_BLOCK] BLOCK=%0d OBSERVED=", i+1);
                    $write("%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x ",
                        unified_mem[OUTPUT_INDEX+i*16+0][7:0], unified_mem[OUTPUT_INDEX+i*16+1][7:0],
                        unified_mem[OUTPUT_INDEX+i*16+2][7:0], unified_mem[OUTPUT_INDEX+i*16+3][7:0],
                        unified_mem[OUTPUT_INDEX+i*16+4][7:0], unified_mem[OUTPUT_INDEX+i*16+5][7:0],
                        unified_mem[OUTPUT_INDEX+i*16+6][7:0], unified_mem[OUTPUT_INDEX+i*16+7][7:0],
                        unified_mem[OUTPUT_INDEX+i*16+8][7:0], unified_mem[OUTPUT_INDEX+i*16+9][7:0],
                        unified_mem[OUTPUT_INDEX+i*16+10][7:0], unified_mem[OUTPUT_INDEX+i*16+11][7:0],
                        unified_mem[OUTPUT_INDEX+i*16+12][7:0], unified_mem[OUTPUT_INDEX+i*16+13][7:0],
                        unified_mem[OUTPUT_INDEX+i*16+14][7:0], unified_mem[OUTPUT_INDEX+i*16+15][7:0]);
                    $write("EXPECTED=");
                    $write("%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x\n",
                        expected_byte[i*16+0], expected_byte[i*16+1], expected_byte[i*16+2], expected_byte[i*16+3],
                        expected_byte[i*16+4], expected_byte[i*16+5], expected_byte[i*16+6], expected_byte[i*16+7],
                        expected_byte[i*16+8], expected_byte[i*16+9], expected_byte[i*16+10], expected_byte[i*16+11],
                        expected_byte[i*16+12], expected_byte[i*16+13], expected_byte[i*16+14], expected_byte[i*16+15]);
                end
                #100;
                $finish;
            end
        end
    end

`ifdef EXP_G_DEBUG
    always @(posedge clk) begin
        if (rst_n && (cycle_count < 60 || (cycle_count % 100000) == 0))
            $display("[EXP_G_DEBUG] CYCLE=%0d PC=%08x INSN=%08x MEMR=%b MEMW=%b ADDR=%08x WDATA=%08x PROFILE=%b", cycle_count, INST_ADDR, INST_DATA, MEM_READ, MEM_WRITE, MEM_ADDR, MEM_WDATA, profile_active);
    end
`endif

    initial begin
        if (!$value$plusargs("REPEAT=%d", repeat_id)) repeat_id = 1;
        for (i = 0; i < 16384; i = i + 1) unified_mem[i] = 0;
        expected_byte[0] = 8'h3a;
        expected_byte[1] = 8'hd7;
        expected_byte[2] = 8'h7b;
        expected_byte[3] = 8'hb4;
        expected_byte[4] = 8'h0d;
        expected_byte[5] = 8'h7a;
        expected_byte[6] = 8'h36;
        expected_byte[7] = 8'h60;
        expected_byte[8] = 8'ha8;
        expected_byte[9] = 8'h9e;
        expected_byte[10] = 8'hca;
        expected_byte[11] = 8'hf3;
        expected_byte[12] = 8'h24;
        expected_byte[13] = 8'h66;
        expected_byte[14] = 8'hef;
        expected_byte[15] = 8'h97;
        $readmemh("expG_16B_ECB.mem", unified_mem);
        #200;
        rst_n = 1;
    end

    initial begin
        #100000000;
        $display("[EXP_G] CORE=RISSP MODE=ECB REPEAT=%0d RESULT=TIMEOUT PC=%08x INSN=%08x CYCLE=%0d MEM_ADDR=%08x", repeat_id, INST_ADDR, INST_DATA, cycle_count, MEM_ADDR);
        $finish;
    end
endmodule
