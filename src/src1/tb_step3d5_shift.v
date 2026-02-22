// tb_step3d5_shift.v — 移位操作数测试
// ADD R0,R0,R3,LSL#2 : R0=3, R3=5 → R0 = 3 + (5<<2) = 23
`timescale 1ns / 1ps
module tb_step3d5;
    reg clk, rst;
    always #5 clk = ~clk;
    arm_pipeline dut (.clk(clk), .rst(rst));

    integer cycle;
    initial cycle = 0;
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            $display("Cyc%2d | IF=%h | idex_rn=%2d op2=%2d ex=%2d | WB_R%0d=%0d",
                cycle, dut.if_instr,
                dut.idex_rn, dut.idex_op2, dut.ex_result,
                dut.memwb_rd_addr,
                dut.memwb_mem_to_reg ? dut.memwb_mem_data : dut.memwb_alu_result);
        end
    end

    initial begin
        clk = 0; rst = 1;
        @(posedge clk); #1; @(posedge clk); #1; @(posedge clk); #1;
        rst = 0;
        $display("=== Step 3d-5 shift test: ADD R0,R0,R3,LSL#2 ===");
        repeat(15) @(posedge clk);
        $display("\n=== Registers ===");
        $display("  R0 = %0d  (expected 23)", dut.regfile_inst.regs[0]);
        $display("  R3 = %0d  (expected  5)", dut.regfile_inst.regs[3]);
        if (dut.regfile_inst.regs[0] === 32'd23)
            $display("  PASS  R0 = 23");
        else
            $display("  FAIL  R0 = %0d", dut.regfile_inst.regs[0]);
        $display("=== Done ===");
        $finish;
    end
endmodule
