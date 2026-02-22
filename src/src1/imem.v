`timescale 1ns/1ps
module imem (
    input  wire [8:0]  addr,
    output wire [31:0] dout,
    input  wire [8:0]  data_addr,
    output wire [31:0] data_dout,
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] din
);
    reg [31:0] mem [0:511];
    integer i;
    initial begin
        for (i = 0; i < 512; i = i + 1)
            mem[i] = 32'hE1A0B00B;  // NOP
        $readmemh("imem_sort.hex", mem);
    end
    assign dout      = mem[addr];
    assign data_dout = mem[data_addr];
    always @(posedge clk) begin
        if (we) mem[addr] <= din;
    end
endmodule