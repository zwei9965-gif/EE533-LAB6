// tb_step3d4.v — LDR [PC, #off] 字面量池测试
// LDR R0,[PC,#8]  from addr0 → 访问 word4 = 0xDEADBEEF
// LDR R1,[PC,#4]  from addr5 → 访问 word8 = 0xCAFEF00D
`timescale 1ns / 1ps
module tb_step3d4;
    reg clk, rst;
    always #5 clk = ~clk;
    arm_pipeline dut (.clk(clk), .rst(rst));

    integer cycle;
    initial cycle = 0;
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            $display("Cyc%2d | pc=%2d | IF=%h | idex_rn=%8h op2=%3d ex=%8h | WB_R%0d=%8h",
                cycle, dut.pc, dut.if_instr,
                dut.idex_rn, dut.idex_op2, dut.ex_result,
                dut.memwb_rd_addr,
                dut.memwb_mem_to_reg ? dut.memwb_mem_data : dut.memwb_alu_result);
        end
    end

    initial begin
        clk = 0; rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        $display("=== Step 3d-4: LDR [PC, #off] Test ===");
        repeat(20) @(posedge clk);

        $display("\n=== Register File ===");
        $display("  R0 = %h  (expected deadbeef)", dut.regfile_inst.regs[0]);
        $display("  R1 = %h  (expected cafef00d)", dut.regfile_inst.regs[1]);

        $display("\n=== Self Check ===");
        if (dut.regfile_inst.regs[0] === 32'hDEADBEEF)
            $display("  PASS  R0 = deadbeef");
        else
            $display("  FAIL  R0 = %h (expected deadbeef)", dut.regfile_inst.regs[0]);
        if (dut.regfile_inst.regs[1] === 32'hCAFEF00D)
            $display("  PASS  R1 = cafef00d");
        else
            $display("  FAIL  R1 = %h (expected cafef00d)", dut.regfile_inst.regs[1]);

        $display("\n=== Done ===");
        $finish;
    end
endmodule
