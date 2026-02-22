// tb_mt_sort.v ? ??????????
//
// ???????????????????
//   T0 (PC=0 ):  dmem[0..10]    [323,123,-455,2,98,125,10,65,-56,0]
//   T1 (PC=32):  dmem[64..74]   [50,30,80,10,70,20,90,40,60,100]
//   T2 (PC=64):  dmem[128..138] [-9,-3,-7,-1,-5,-8,-2,-4,-6,0]
//   T3 (PC=96):  dmem[192..202] [5,4,3,2,1,-1,-2,-3,-4,-5]
//
// ??????????????????
//   T0: SP=840 ? push?word[209]
//   T1: SP=844 ? push?word[210]
//   T2: SP=848 ? push?word[211]
//   T3: SP=852 ? push?word[212]
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

        // ?? ??????????? = thread*16 + reg?????????????
        // Thread 0: regs[0..15]  SP=R13[13], LR=R14[14]
        dut.regfile_inst.regs[13] = 32'd840;
        dut.regfile_inst.regs[14] = 32'hFFFFFF00;
        // Thread 1: regs[16..31] SP=R13[29], LR=R14[30]
        dut.regfile_inst.regs[29] = 32'd844;
        dut.regfile_inst.regs[30] = 32'hFFFFFF00;
        // Thread 2: regs[32..47] SP=R13[45], LR=R14[46]
        dut.regfile_inst.regs[45] = 32'd848;
        dut.regfile_inst.regs[46] = 32'hFFFFFF00;
        // Thread 3: regs[48..63] SP=R13[61], LR=R14[62]
        dut.regfile_inst.regs[61] = 32'd852;
        dut.regfile_inst.regs[62] = 32'hFFFFFF00;

        $display("=== 4-Thread Independent Bubble Sort ===");
        $display("T0 input: [323,123,-455,2,98,125,10,65,-56,0]");
        $display("T1 input: [50,30,80,10,70,20,90,40,60,100]");
        $display("T2 input: [-9,-3,-7,-1,-5,-8,-2,-4,-6,0]");
        $display("T3 input: [5,4,3,2,1,-1,-2,-3,-4,-5]");

        repeat(2600) @(posedge clk);

        $display("\n=== Thread 0 result (dmem[0..10]) ===");
        $display("  N=%0d", $signed(dut.dmem_inst.mem[0]));
        for (i = 0; i < 10; i = i + 1)
            $display("  array[%0d] = %0d", i, $signed(dut.dmem_inst.mem[i+1]));

        $display("\n=== Thread 1 result (dmem[64..74]) ===");
        $display("  N=%0d", $signed(dut.dmem_inst.mem[64]));
        for (i = 0; i < 10; i = i + 1)
            $display("  array[%0d] = %0d", i, $signed(dut.dmem_inst.mem[64+i+1]));

        $display("\n=== Thread 2 result (dmem[128..138]) ===");
        $display("  N=%0d", $signed(dut.dmem_inst.mem[128]));
        for (i = 0; i < 10; i = i + 1)
            $display("  array[%0d] = %0d", i, $signed(dut.dmem_inst.mem[128+i+1]));

        $display("\n=== Thread 3 result (dmem[192..202]) ===");
        $display("  N=%0d", $signed(dut.dmem_inst.mem[192]));
        for (i = 0; i < 10; i = i + 1)
            $display("  array[%0d] = %0d", i, $signed(dut.dmem_inst.mem[192+i+1]));

        $display("\n=== Self Check ===");

        if ($signed(dut.dmem_inst.mem[1])==-455 && $signed(dut.dmem_inst.mem[2])==-56  &&
            $signed(dut.dmem_inst.mem[3])==0    && $signed(dut.dmem_inst.mem[4])==2    &&
            $signed(dut.dmem_inst.mem[5])==10   && $signed(dut.dmem_inst.mem[6])==65   &&
            $signed(dut.dmem_inst.mem[7])==98   && $signed(dut.dmem_inst.mem[8])==123  &&
            $signed(dut.dmem_inst.mem[9])==125  && $signed(dut.dmem_inst.mem[10])==323)
            $display("  T0: PASS");
        else $display("  T0: FAIL");

        if ($signed(dut.dmem_inst.mem[65])==10  && $signed(dut.dmem_inst.mem[66])==20  &&
            $signed(dut.dmem_inst.mem[67])==30  && $signed(dut.dmem_inst.mem[68])==40  &&
            $signed(dut.dmem_inst.mem[69])==50  && $signed(dut.dmem_inst.mem[70])==60  &&
            $signed(dut.dmem_inst.mem[71])==70  && $signed(dut.dmem_inst.mem[72])==80  &&
            $signed(dut.dmem_inst.mem[73])==90  && $signed(dut.dmem_inst.mem[74])==100)
            $display("  T1: PASS");
        else $display("  T1: FAIL");

        if ($signed(dut.dmem_inst.mem[129])==-9 && $signed(dut.dmem_inst.mem[130])==-8 &&
            $signed(dut.dmem_inst.mem[131])==-7 && $signed(dut.dmem_inst.mem[132])==-6 &&
            $signed(dut.dmem_inst.mem[133])==-5 && $signed(dut.dmem_inst.mem[134])==-4 &&
            $signed(dut.dmem_inst.mem[135])==-3 && $signed(dut.dmem_inst.mem[136])==-2 &&
            $signed(dut.dmem_inst.mem[137])==-1 && $signed(dut.dmem_inst.mem[138])==0)
            $display("  T2: PASS");
        else $display("  T2: FAIL");

        if ($signed(dut.dmem_inst.mem[193])==-5 && $signed(dut.dmem_inst.mem[194])==-4 &&
            $signed(dut.dmem_inst.mem[195])==-3 && $signed(dut.dmem_inst.mem[196])==-2 &&
            $signed(dut.dmem_inst.mem[197])==-1 && $signed(dut.dmem_inst.mem[198])==1  &&
            $signed(dut.dmem_inst.mem[199])==2  && $signed(dut.dmem_inst.mem[200])==3  &&
            $signed(dut.dmem_inst.mem[201])==4  && $signed(dut.dmem_inst.mem[202])==5)
            $display("  T3: PASS");
        else $display("  T3: FAIL");

        $display("=== Done ===");
        $finish;
    end
endmodule