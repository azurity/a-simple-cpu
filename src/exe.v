`timescale 1ns / 1ps

module EXE(
    input [183:0] ID_EXE_BUS,
    output [109:0] EXE_MEM_BUS,
    input [29:0] PC_ADD_8,
    output [29:0] addr,
    output jump,
    output of,
    output [31:0] epc,
    //lo,hi
    input next_valid,
    output valid,
    output finish
);
    wire [4:0] cond;
    wire [3:0] opcode;
    wire of_allow;
    wire [1:0] data_switch;
    wire [15:0] through;
    wire [29:0] pc;
    wire [29:0] offset;
    wire [31:0] data0;
    wire [31:0] data1;
    wire [31:0] data2;
    assign {cond,opcode,of_allow,data_switch,thorugh,pc,offset,data0,data1,data2} = ID_EXE_BUS;
    assign epc = {pc,2'b0};
    wire [31:0] alu_data;
    wire ovf;
    wire [3:0] condition;
    wire [31:0] out_data;
    //
    assign addr = pc + offset;
    alu ALU(
        .opcode(opcode),
        .data0(data0),
        .data1(data1),
        .out_data(alu_data),
        .ovf(ovf),
        condition(condition),
        finish(finish)
    );
    assign of = ovf & of_allow;
    assign jump = (|(cond & {1'b1,condition}));
    always @(*)
    begin
        case(data_switch)
            2'b00:
                out_data <= alu_data;
            2'b01:
                out_data <= {PC_ADD_8,2'b0};
            default:
                out_data <= data2;
        endcase
    end
    //
    assign valid = finish & next_valid;
    assign EXE_MEM_BUS = {through,alu_data,out_data,pc};
endmodule
