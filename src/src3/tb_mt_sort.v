// tb_sw_verify.v ? ????????GCC -O0 ????
//
// ???? C ???? arm-none-eabi-gcc -O0 ???
//   T0 (PC=0  ): bubble_sort  ? ?? [323,123,-455,2,98,125,10,65,-56,0]
//   T1 (PC=48 ): array_sum    ? ?? [10,20,30,40,50,60,70,80,90,100] = 550
//   T2 (PC=96 ): find_max     ? ??? [-9,-3,-7,-1,-5,-8,-2,-4,-6,0] = 0
//   T3 (PC=144): count_neg    ? ???? [5,4,3,2,1,-1,-2,-3,-4,-5] = 5
//
// ??? imem ? 48 words?dmem ? 12 words?? result?
`timescale 1ns / 1ps
module tb_mt_sort;
    reg clk, rst;
    always #5 clk = ~clk;
    arm_pipeline dut (.clk(clk), .rst(rst));

    integer i, cycle;
    initial cycle = 0;
    always @(posedge clk) if (!rst) cycle = cycle + 1;

    always @(posedge clk) begin
        if (!rst && cycle <= 24)
            $display("C%2d T%0d pc=%0d | ex=%0d | WBrd%0d=%0d",
                cycle, dut.idex_thread, dut.idex_pc,
                $signed(dut.ex_result),
                dut.memwb_rd_addr, $signed(dut.wb_wdata));
    end

    initial begin
        clk = 0; rst = 1;
        repeat(3) @(posedge clk); #1;
        rst = 0; #1;

        // SP/LR ?????? reg ?? = thread*16 + reg?
        // GCC -O0 ? frame pointer(R11)?????????
        // ???? 900+ ???????????dmem[0..11/64..75/128..139/192..203]?
        dut.regfile_inst.regs[13] = 32'd900;        // T0 SP
        dut.regfile_inst.regs[14] = 32'hFFFFFF00;   // T0 LR
        dut.regfile_inst.regs[29] = 32'd920;        // T1 SP
        dut.regfile_inst.regs[30] = 32'hFFFFFF00;   // T1 LR
        dut.regfile_inst.regs[45] = 32'd940;        // T2 SP
        dut.regfile_inst.regs[46] = 32'hFFFFFF00;   // T2 LR
        dut.regfile_inst.regs[61] = 32'd960;        // T3 SP
        dut.regfile_inst.regs[62] = 32'hFFFFFF00;   // T3 LR

        $display("=== 4-Thread Software Verification (GCC -O0) ===");
        $display("T0 bubble_sort: [323,123,-455,2,98,125,10,65,-56,0]");
        $display("T1 array_sum:   [10,20,30,40,50,60,70,80,90,100]");
        $display("T2 find_max:    [-9,-3,-7,-1,-5,-8,-2,-4,-6,0]");
        $display("T3 count_neg:   [5,4,3,2,1,-1,-2,-3,-4,-5]");

        // GCC -O0 ? frame pointer + ????????? 6000 ?
        repeat(6000) @(posedge clk);

        $display("\n--- T0: bubble_sort result ---");
        for (i = 0; i < 10; i = i + 1)
            $display("  array[%0d] = %0d", i, $signed(dut.dmem_inst.mem[i+1]));

        $display("\n--- T1: array_sum result ---");
        $display("  result = %0d  (expected 550)", $signed(dut.dmem_inst.mem[75]));

        $display("\n--- T2: find_max result ---");
        $display("  result = %0d  (expected 0)", $signed(dut.dmem_inst.mem[139]));

        $display("\n--- T3: count_neg result ---");
        $display("  result = %0d  (expected 5)", $signed(dut.dmem_inst.mem[203]));

        $display("\n=== Self Check ===");

        if ($signed(dut.dmem_inst.mem[1])==-455 && $signed(dut.dmem_inst.mem[2])==-56  &&
            $signed(dut.dmem_inst.mem[3])==0    && $signed(dut.dmem_inst.mem[4])==2    &&
            $signed(dut.dmem_inst.mem[5])==10   && $signed(dut.dmem_inst.mem[6])==65   &&
            $signed(dut.dmem_inst.mem[7])==98   && $signed(dut.dmem_inst.mem[8])==123  &&
            $signed(dut.dmem_inst.mem[9])==125  && $signed(dut.dmem_inst.mem[10])==323)
            $display("  T0 bubble_sort: PASS");
        else $display("  T0 bubble_sort: FAIL");

        if ($signed(dut.dmem_inst.mem[75]) == 550)
            $display("  T1 array_sum:   PASS (result=550)");
        else $display("  T1 array_sum:   FAIL (got %0d)", $signed(dut.dmem_inst.mem[75]));

        if ($signed(dut.dmem_inst.mem[139]) == 0)
            $display("  T2 find_max:    PASS (result=0)");
        else $display("  T2 find_max:    FAIL (got %0d)", $signed(dut.dmem_inst.mem[139]));

        if ($signed(dut.dmem_inst.mem[203]) == 5)
            $display("  T3 count_neg:   PASS (result=5)");
        else $display("  T3 count_neg:   FAIL (got %0d)", $signed(dut.dmem_inst.mem[203]));

        $display("=== Done ===");
        $finish;
    end
endmodule