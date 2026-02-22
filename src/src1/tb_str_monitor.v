// tb_str_monitor.v — 监测每次 STR/LDR 的地址和数据
`timescale 1ns / 1ps
module tb_str_monitor;
    reg clk, rst;
    always #5 clk = ~clk;
    arm_pipeline dut (.clk(clk), .rst(rst));

    integer cycle;
    initial cycle = 0;

    // 监测 STR：在 EX 阶段（idex_mem_write && cond_met）
    // 地址 = ex_result[9:2]（word addr），数据 = ex_store_data
    // 监测 LDR 结果：在 WB 阶段 memwb_mem_to_reg=1 时
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;

            // STR 执行（在 EX 阶段）
            if (dut.idex_mem_write && dut.cond_met) begin
                $display("C%3d STR: dmem[word%0d=byte%0d] <= %0d (R3=%0d R0=%0d)",
                    cycle,
                    dut.ex_result[9:2],
                    {dut.ex_result[9:2], 2'b00},
                    $signed(dut.ex_store_data),
                    $signed(dut.regfile_inst.regs[3]),
                    $signed(dut.regfile_inst.regs[0]));
            end

            // LDR 结果到达 WB（读出数据有效）
            if (dut.memwb_reg_write && dut.memwb_cond_met && dut.memwb_mem_to_reg) begin
                $display("C%3d LDR: R%0d <= %0d (from dmem)",
                    cycle,
                    dut.memwb_rd_addr,
                    $signed(dut.memwb_mem_data));
            end
        end
    end

    initial begin
        clk = 0; rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0; #1;
        dut.regfile_inst.regs[13] = 32'd800;
        dut.regfile_inst.regs[14] = 32'hFFFF_FF00;

        $display("=== STR/LDR Monitor ===");
        // 运行到外循环第二遍（ip从8结束，约 cycle 110）
        repeat(180) @(posedge clk);

        $display("\n=== D-Mem after 180 cycles ===");
        begin : dump
            integer i;
            for (i = 0; i < 11; i = i + 1)
                $display("  dmem[%2d] = %5d", i, $signed(dut.dmem_inst.mem[i]));
        end
        $display("=== Done ==="); $finish;
    end
endmodule
