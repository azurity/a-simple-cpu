`timescale 1ns / 1ps

module FETCH(
    input reset,
    input clk,
    input [29:0] input_pc,
    input [31:0] data,
    output [61:0] IF_ID_BUS,
    input next_valid,
    output valid,
    output finish
);
    parameter FETCH_NOP = 62'b0;
    reg [29:0] PC;
    always @(posedge clk)
    begin
        PC = input_pc;
    end
    assign finish = 1; // jump 锁死?
    assign valid = (next_valid & finish) | reset;
    assign IF_ID_BUS = reset? FETCH_NOP : {PC,data};
endmodule
