`timescale 1ns / 1ps

module FETCH(
    input clk,
    input reset,
    input [31:0] data,
    output [61:0] IF_ID_BUS,
    output reg [29:0] nextPC
);
    reg [29:0] PC;
    always @(posedge clk)
    begin
        if (reset)
        begin
            PC = 0;
            nextPC = 0;
        end
        else 
        begin
            PC = nextPC;
            nextPC = nextPC + 1;
        end
    end
    assign IF_ID_BUS = {PC,data};
endmodule