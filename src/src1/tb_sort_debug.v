// tb_sort_debug.v — 详细追踪每一拍，前150周期全打印
// 同时每次 subs ip,ip,#1 (addr21) 进入 WB 时 dump D-Mem
`timescale 1ns / 1ps
module tb_sort_debug;
    reg clk, rst;
    always #5 clk = ~clk;
    arm_pipeline dut (.clk(clk), .rst(rst));

    integer cycle;
    initial cycle = 0;

    // 追踪 subs ip,ip,#1 进 WB 的时机
    // imem[21]=E25CC001, 当 memwb_instr == E25CC001 时 dump
    // 用更简单方法：当 pc 从 21 回到 9 时（branch from 23→9）
    
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            // 前150周期全打印
            if (cycle <= 150) begin
                $display("C%3d pc=%2d IF=%h | A=%08h B=%08h EX=%08h | WE=%b WEA=%b dmA=%3d | WBR%0d=%08h SP=%0d LR=%0d",
                    cycle,
                    dut.pc,
                    dut.if_instr,
                    dut.ex_alu_A,
                    dut.ex_alu_B,
                    dut.ex_result,
                    (dut.idex_mem_write && dut.cond_met),
                    dut.dmem_addr,
                    (dut.idex_mem_write && dut.cond_met),
                    dut.dmem_addr,
                    dut.memwb_rd_addr,
                    (dut.memwb_mem_to_reg ? dut.memwb_mem_data : dut.memwb_alu_result),
                    $signed(dut.regfile_inst.regs[13]),
                    $signed(dut.regfile_inst.regs[14]));
            end
            // 每次分支发生时打印寄存器快照
            if (dut.branch_taken && cycle > 150) begin
                $display("C%3d BRANCH pc=%2d→%2d | R0=%0d R3=%0d R12(ip)=%0d R14(LR)=%0d SP=%0d",
                    cycle, dut.pc,
                    dut.idex_is_bx ? dut.idex_bx_target[10:2] : dut.idex_branch_target,
                    $signed(dut.regfile_inst.regs[0]),
                    $signed(dut.regfile_inst.regs[3]),
                    $signed(dut.regfile_inst.regs[12]),
                    $signed(dut.regfile_inst.regs[14]),
                    $signed(dut.regfile_inst.regs[13]));
            end
        end
    end

    task dump_dmem;
        integer i;
        begin
            $display("  === D-Mem[0..10] ===");
            for (i = 0; i <= 10; i = i + 1)
                $display("  D[%2d]=%0d", i, $signed(dut.dmem_inst.mem[i]));
        end
    endtask

    task dump_regs;
        $display("  R0=%0d R1=%0d R2=%0d R3=%0d R12=%0d R13=%0d R14=%0d",
            $signed(dut.regfile_inst.regs[0]),
            $signed(dut.regfile_inst.regs[1]),
            $signed(dut.regfile_inst.regs[2]),
            $signed(dut.regfile_inst.regs[3]),
            $signed(dut.regfile_inst.regs[12]),
            $signed(dut.regfile_inst.regs[13]),
            $signed(dut.regfile_inst.regs[14]));
    endtask

    initial begin
        clk = 0; rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0; #1;
        dut.regfile_inst.regs[13] = 32'd800;  // SP
        dut.regfile_inst.regs[14] = 32'hDEAD_0000;  // LR = 哨兵（防止意外 bx lr）

        $display("=== Sort Debug: 前150周期全追踪 ===");

        // 等 150 周期后打印第一次 D-Mem 快照
        @(posedge clk); repeat(149) @(posedge clk);
        $display("\n=== Cycle 150 Snapshot ===");
        dump_regs;
        dump_dmem;

        // 再等到周期 400
        repeat(250) @(posedge clk);
        $display("\n=== Cycle 400 Snapshot ===");
        dump_regs;
        dump_dmem;

        // 再等到周期 700
        repeat(300) @(posedge clk);
        $display("\n=== Cycle 700 Snapshot ===");
        dump_regs;
        dump_dmem;

        $display("=== Done ==="); $finish;
    end
endmodule
