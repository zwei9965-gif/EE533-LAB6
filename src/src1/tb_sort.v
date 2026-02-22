// tb_sort.v ? Bubble Sort ???????
// ???LR ?????????? bx lr ????
`timescale 1ns / 1ps
module tb_sort;
    reg clk, rst;
    always #5 clk = ~clk;
    arm_pipeline dut (.clk(clk), .rst(rst));

    integer cycle;
    initial cycle = 0;
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            if (cycle <= 40 || dut.branch_taken)
                $display("C%3d pc=%2d(%h) | A=%0d B=%0d ex=%0d | WBR%0d=%0d SP=%0d",
                    cycle, dut.pc, dut.if_instr,
                    $signed(dut.ex_alu_A), $signed(dut.ex_alu_B),
                    $signed(dut.ex_result),
                    dut.memwb_rd_addr,
                    $signed(dut.memwb_mem_to_reg?dut.memwb_mem_data:dut.memwb_alu_result),
                    $signed(dut.regfile_inst.regs[13]));
        end
    end

    initial begin
        clk = 0; rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0; #1;
        dut.regfile_inst.regs[13] = 32'd800;          // SP
        dut.regfile_inst.regs[14] = 32'hFFFF_FF00;    // LR ???bx lr ??? imem[0x3FFFFC]=NOP
        $display("=== Bubble Sort (gcc) ? Forwarding Test ===");
        $display("Input: [323, 123, -455, 2, 98, 125, 10, 65, -56, 0]");
        $display("LR??=0xFFFFFF00?bx lr ???????sort ??????");

        repeat(570) @(posedge clk); // sort~C535???C604 wrap???570??

        $display("\n=== D-Mem after sort ===");
        begin : show
            integer i;
            $display("  N=%0d", $signed(dut.dmem_inst.mem[0]));
            for (i = 0; i < 10; i = i + 1)
                $display("  array[%0d] = %5d", i, $signed(dut.dmem_inst.mem[i+1]));
        end

        $display("\n=== Registers ===");
        $display("  R0=%0d R3=%0d ip=%0d SP=%0d LR=%0d",
            $signed(dut.regfile_inst.regs[0]),
            $signed(dut.regfile_inst.regs[3]),
            $signed(dut.regfile_inst.regs[12]),
            $signed(dut.regfile_inst.regs[13]),
            $signed(dut.regfile_inst.regs[14]));

        $display("\n=== Self Check ===");
        begin : chk
            reg pass; integer exp[0:9]; integer i;
            pass = 1;
            exp[0]=-455; exp[1]=-56; exp[2]=0;   exp[3]=2;
            exp[4]=10;   exp[5]=65;  exp[6]=98;  exp[7]=123;
            exp[8]=125;  exp[9]=323;
            for (i = 0; i < 10; i = i + 1)
                if ($signed(dut.dmem_inst.mem[i+1]) !== exp[i]) begin
                    $display("  FAIL array[%0d]=%0d (exp %0d)",
                        i, $signed(dut.dmem_inst.mem[i+1]), exp[i]);
                    pass = 0;
                end
            if (pass) $display("  PASS  All 10 elements sorted correctly!");
        end
        $display("=== Done ==="); $finish;
    end
endmodule