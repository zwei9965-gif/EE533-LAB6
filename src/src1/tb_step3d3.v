// tb_step3d3.v ? Step 3d-3 ????
`timescale 1ns / 1ps
module tb_step3d3;
    reg clk, rst;
    always #5 clk = ~clk;
    arm_pipeline dut (.clk(clk), .rst(rst));

    initial begin
        clk = 0; rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        $display("=== Step 3d-3: Pre/Post-Index Writeback Test ===");
        repeat(28) @(posedge clk);

        $display("\n=== Register File ===");
        $display("  R0  = %0d  (expected  10)", dut.regfile_inst.regs[0]);
        $display("  R1  = %0d  (expected  20)", dut.regfile_inst.regs[1]);
        $display("  R2  = %0d  (expected  20)", dut.regfile_inst.regs[2]);
        $display("  R3  = %0d  (expected  10)", dut.regfile_inst.regs[3]);
        $display("  SP  = %0d  (expected 100)", dut.regfile_inst.regs[13]);
        $display("\n=== D-Mem ===");
        $display("  D-Mem[23] = %0d  (expected 20)", dut.dmem_inst.mem[23]);
        $display("  D-Mem[24] = %0d  (expected 10)", dut.dmem_inst.mem[24]);

        $display("\n=== Self Check ===");
        if (dut.regfile_inst.regs[2]  === 32'd20)  $display("  PASS  R2 = 20");
        else $display("  FAIL  R2 = %0d (expected 20)", dut.regfile_inst.regs[2]);
        if (dut.regfile_inst.regs[3]  === 32'd10)  $display("  PASS  R3 = 10");
        else $display("  FAIL  R3 = %0d (expected 10)", dut.regfile_inst.regs[3]);
        if (dut.regfile_inst.regs[13] === 32'd100) $display("  PASS  SP = 100");
        else $display("  FAIL  SP = %0d (expected 100)", dut.regfile_inst.regs[13]);
        if (dut.dmem_inst.mem[23] === 32'd20) $display("  PASS  D-Mem[23] = 20");
        else $display("  FAIL  D-Mem[23] = %0d (expected 20)", dut.dmem_inst.mem[23]);
        if (dut.dmem_inst.mem[24] === 32'd10) $display("  PASS  D-Mem[24] = 10");
        else $display("  FAIL  D-Mem[24] = %0d (expected 10)", dut.dmem_inst.mem[24]);

        $display("\n=== Done ===");
        $finish;
    end
endmodule