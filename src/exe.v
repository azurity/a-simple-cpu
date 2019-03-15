`timescale 1ns / 1ps

module EXE(
    input [183:0] ID_EXE_BUS,
    output [79:0] EXE_MEM_BUS,
    output [29:0] addr,
    output jump,
    output of
    //lo,hi
);
    wire [4:0] cond;
    wire [3:0] opcode;
    wire of_shield;
    wire [1:0] data_switch;
    wire [15:0] through;
    wire [29:0] pc;
    wire [29:0] offset;
    wire [31:0] data0;
    wire [31:0] data1;
    wire [31:0] data2;
    assign {cond,opcode,of_shield,data_switch,thorugh,pc,offset,data0,data1,data2} = ID_EXE_BUS;
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
        condition(condition)
    );
    assign of = ovf & ~of_shield;
    assign jump = (|(cond & {1'b1,condition}));
    always @(*)
    begin
        case(data_switch)
            2'b00:
                out_data <= alu_data;
            2'b01:
                out_data <= {addr,2'b0};
            default:
                out_data <= data2;
        endcase
    end
    //
    assign EXE_MEM_BUS = {through,alu_data,out_data};
endmodule
