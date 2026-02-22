// dmem_32.v ? ????????
// 256 x 32-bit?????
// ?????
//   T0: dmem[0..10]    N=10, array[0..9]
//   T1: dmem[64..74]   N=10, array[0..9]
//   T2: dmem[128..138] N=10, array[0..9]
//   T3: dmem[192..202] N=10, array[0..9]
`timescale 1ns / 1ps
module dmem_32 (
    input  wire        clka,
    input  wire        wea,
    input  wire [7:0]  addra,
    input  wire [31:0] dina,
    output reg  [31:0] douta,
    input  wire        clkb,
    input  wire [7:0]  addrb,
    output reg  [31:0] doutb
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
        $readmemh("sw2_dmem.hex", mem);
    end
    always @(posedge clka) begin
        if (wea) mem[addra] <= dina;
        douta <= mem[addra];
    end
    always @(posedge clkb) begin
        doutb <= mem[addrb];
    end
endmodule