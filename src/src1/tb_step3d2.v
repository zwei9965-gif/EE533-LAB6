// tb_step3d2.v — BL + BX 测试
// 流程：MOV→BL my_func→[ADD R1,#42; BX LR]→ADD R0,#1→B done
// 期望：R0=1, R1=42, R14=24
`timescale 1ns / 1ps
module tb_step3d2;
    reg clk, rst;
    always #5 clk = ~clk;
    arm_pipeline dut (.clk(clk), .rst(rst));

    integer cycle;
    initial cycle = 0;
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            $display("Cyc%3d | pc=%2d | IF=%h | br=%b | WB_R%0d=%0d",
                cycle, dut.pc, dut.if_instr, dut.branch_taken,
                dut.memwb_is_bl ? 14 : dut.memwb_rd_addr,
                dut.memwb_is_bl ? dut.memwb_bl_ret :
                    (dut.memwb_mem_to_reg ? dut.memwb_mem_data
                                          : dut.memwb_alu_result));
        end
    end

    initial begin
        clk = 0; rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        $display("=== Step 3d-2: BL + BX Test ===");
        repeat(45) @(posedge clk);

        $display("\n=== Register File ===");
        $display("  R0  = %0d  (expected  1)", dut.regfile_inst.regs[0]);
        $display("  R1  = %0d  (expected 42)", dut.regfile_inst.regs[1]);
        $display("  R14 = %0d  (expected 24)", dut.regfile_inst.regs[14]);

        $display("\n=== Self Check ===");
        if (dut.regfile_inst.regs[0] === 32'd1)
            $display("  PASS  R0 = 1   (returned to main, ADD R0 executed)");
        else
            $display("  FAIL  R0 = %0d (expected 1)", dut.regfile_inst.regs[0]);
        if (dut.regfile_inst.regs[1] === 32'd42)
            $display("  PASS  R1 = 42  (func body executed once)");
        else
            $display("  FAIL  R1 = %0d (expected 42)", dut.regfile_inst.regs[1]);
        if (dut.regfile_inst.regs[14] === 32'd24)
            $display("  PASS  R14 = 24 (BL saved return addr)");
        else
            $display("  FAIL  R14 = %0d (expected 24)", dut.regfile_inst.regs[14]);

        $display("\n=== Done ===");
        $finish;
    end
endmodule
