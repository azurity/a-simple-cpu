`timescale 1ns / 1ps

module CPU(
    input clk,
    input reset
);
reg [61:0] IF_ID_BUS_REG;
reg [183:0] ID_EXE_BUS_REG;
reg [79:0] EXE_MEM_BUS_REG;
reg [42:0] MEM_WB_BUS_REG;
wire [61:0] IF_ID_BUS_REG;
wire [183:0] ID_EXE_BUS;
wire [79:0] EXE_MEM_BUS;
wire [42:0] MEM_WB_BUS;
wire [29:0] PC;
wire [29:0] nextPC;
wire [31:0] ins;
wire [29:0] jump_addr;
wire jump;
//
wire [3:0] ram_en;
wire [7:0] ram_addr;
wire [31:0] ram_load;
wire [31:0] ram_store;
wire mres;
wire mreq;
//
wire lo_en;
wire hi_en;
wire cp0_en;
wire reg_en;
wire [4:0] rs;
wire [4:0] rt;
wire [4:0] rd;
wire [2:0] sel;
wire [31:0] reg_0;
wire [31:0] reg_1;
wire [31:0] wb_data;
//
wire of_exception;
//
//
FETCH fetch(
    .clk(clk),
    .reset(reset),
    .data(ins),
    .IF_ID_BUS(IF_ID_BUS),
    .nextPC(nextPC)
);

// TODO: decode

EXE exe(
    .ID_EXE_BUS(ID_EXE_BUS),
    .EXE_MEM_BUS(EXE_MEM_BUS),
    .addr(jump_addr),
    .jump(jump),
    .of(of_exception)
);

MEM mem(
    .EXE_MEM_BUS(EXE_MEM_BUS),
    .MEM_WB_BUS(MEM_WB_BUS),
    .w_mem(ram_en),
    .addr_mem(ram_addr),
    .load_data(ram_load),
    .store_data(ram_store),
    .mres(mres),
    .mreq(mreq)
);

WB wb(
    .MEM_WB_BUS(MEM_WB_BUS),
    .reg_en(reg_en),
    .lo_en(lo_en),
    .hi_en(hi_en),
    .cp0_en(cp0_en),
    .rd(rd),
    .sel(sel),
    .w_data(wb_data)
);

Reg reg(
    .clk(clk & reg_en),
    .w_data(wb_data),
    .rs(rs),
    .rt(rt),
    rd(rd),
    .r_data0(reg_0),
    .r_data1(reg_1)
);

blk_mem_gen_0 RAM(
    .clka(clk),
    .addra(ram_addr),
    .dina(ram_store),
    .douta(ram_load),
    .wea(ram_en)
);

blk_mem_gen_1 ROM(
    .clka(clk),
    .addra(PC[7:0]),
    .douta(ins)
);
endmodule
