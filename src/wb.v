`timescale 1ns / 1ps

module WB(
    input [42:0] MEM_WB_BUS,
    output reg_en,
    output lo_en,
    output hi_en,
    output cp0_en,
    output [4:0] rd,
    output [2:0] sel,
    output [31:0] w_data,
    output valid,
    output finish
);
    wire en;
    wire [1:0] aim;
    assign {en,aim,rd,sel,w_data} = MEM_WB_BUS; // PC?
    assign reg_en = en & ~aim[1] & ~aim[0];
    assign lo_en = en & ~aim[1] & aim[0];
    assign hi_en = en & aim[1] & ~aim[0];
    assign cp0_en = en & aim[1] & aim[0];
    assign valid = 1;
    assign finish = 1;
endmodule
