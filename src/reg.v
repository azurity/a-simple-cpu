`timesacle 1ns / 1ps

module Reg(
    input clk,
    input [31:0] w_data,
    input [4:0] rs,
    input [4:0] rt,
    input [4:0] rd,
    output [31:0] r_data0,
    output [31:0] r_data1
);
    reg[31:0] data[31:0];
    always @(posedge clk)
    begin
        if(rd!=5'b00000)
            data[rd] <= w_data;
    end
    always @(*)
    begin
        r_data0 <= data[rs];
    end
    always @(*)
    begin
        r_data1 <= data[rt];
    end
endmodule
