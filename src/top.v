`timescale 1ns / 1ps

module CPU(
    input clk,
    input reset
);
// 全局线
reg [61:0] IF_ID_BUS_REG;
reg [183:0] ID_EXE_BUS_REG;
reg [79:0] EXE_MEM_BUS_REG;
reg [42:0] MEM_WB_BUS_REG;
reg [29:0] PC_ADD_8_REG;
wire [61:0] IF_ID_BUS;
wire [183:0] ID_EXE_BUS;
wire [79:0] EXE_MEM_BUS;
wire [42:0] MEM_WB_BUS;
wire [29:0] PC;
wire [29:0] nextPC;
wire [31:0] ins;
wire [29:0] jump_addr;
wire jump;
// 内存
wire [3:0] ram_en;
wire [7:0] ram_addr;
wire [31:0] ram_load;
wire [31:0] ram_store;
wire mres;
wire mreq;
// 寄存器
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
// 异常
reg interrupt; // 中断例外
wire jump_exception; // 取指例外，仅会在跳转时发生
wire ri_exception; // 保留指令例外
wire syscall_exception; // 系统调用例外
wire break_exception; // 断点例外
wire [31:0] id_epc;
wire of_exception; // 溢出例外
wire [31:0] exe_epc;
wire m_el_exception; // load例外
wire m_es_exception; // store例外
wire [31:0] m_epc;
wire [31:0] m_bva;
wire execption;
// 互锁
wire if_valid,if_finish;
wire id_valid,id_finish;
wire exe_valid,exe_finish;
wire mem_valid,mem_finish;
wire wb_valid,wb_finish;
// CP0寄存器
reg [31:0] badVAddr;
reg [31:0] status;
reg [31:0] cause;
reg [31:0] epc;
//
assign execption = jump_exception | ri_exception | syscall_exception | break_exception | of_exception | m_el_exception | m_es_exception;
//
always @(posedge clk)
begin
    if(status[0])
    begin
        //
    end
    if(execption | interrupt) // TODO: 需要保证一次处理一条异常
    begin
        if(if_finish & id_valid)
        begin
            IF_ID_BUS_REG = IF_ID_BUS;
        end
        if(id_finish & exe_valid)
        begin
            ID_EXE_BUS_REG = ID_EXE_BUS;
            PC_ADD_8_REG = nextPC; // 需要保证瞬间赋值
        end
        if(exe_finish & mem_valid)
        begin
            EXE_MEM_BUS_REG = EXE_MEM_BUS;
        end
        if(mem_finish & wb_valid)
        begin
            MEM_WB_BUS_REG = MEM_WB_BUS;
        end
    end
    else
    begin
        if(interrupt)
        begin
            cause[6:2] = 5'b00000;
            //epc = ?;
        end
        else if(jump_exception)
        begin
            cause[6:2] = 5'b00100;
            badVAddr = {jump_addr,2'b0};
            epc = exe_epc;
        end
        else if(ri_exception)
            cause[6:2] = 5'b01010;
            epc = id_epc;
        begin
        end
        else if(of_exception | syscall_exception | break_exception)
        begin
            if(of_exception)
            begin
                casue[6:2] = 5'b01100;
                epc = exe_epc;
            end
            if(syscall_exception)
            begin
                cause[6:2] = 5'b01000;
                epc = id_epc;
            end
            if(break_exception)
            begin
                cause[6:2] = 5'b01001;
                epc = id_epc;
            end
        end
        else if(m_el_exception | m_es_exception)
        begin
            if(m_el_exception) cause[6:2] = 5'b00100;
            if(m_es_exception) cause[6:2] = 5'b00101;
            badVAddr = m_bva;
            epc = m_epc;
        end
        // TODO:
    end
end
//
FETCH fetch(
    .clk(clk),
    .reset(reset),
    .data(ins),
    .IF_ID_BUS(IF_ID_BUS),
    .nextPC(nextPC),
    .next_valid(id_valid),
    .valid(if_valid),
    .finish(if_finish)
);

DECODE decode(
    .IF_ID_BUS(IF_ID_BUS_REG),
    .r_data0(reg_0),
    .r_data1(reg_1),
    .rs(rs),
    .rt(rt),
    .ID_EXE_BUS(ID_EXE_BUS),
    ._break(break_exception),
    ._syscall(syscall_exception),
    ._error_throw(ri_exception),
    .epc(id_epc)
);

EXE exe(
    .ID_EXE_BUS(ID_EXE_BUS_REG),
    .EXE_MEM_BUS(EXE_MEM_BUS),
    .addr(jump_addr),
    .jump(jump),
    .of(of_exception),
    .epc(exe_epc),
    .next_valid(mem_valid),
    .valid(exe_valid),
    .finish(exe_finish)
);

MEM mem(
    .EXE_MEM_BUS(EXE_MEM_BUS_REG),
    .MEM_WB_BUS(MEM_WB_BUS),
    .w_mem(ram_en),
    .addr_mem(ram_addr),
    .load_data(ram_load),
    .store_data(ram_store),
    .mres(mres),
    .mreq(mreq),
    .adel(m_el_exception),
    .ades(m_es_exception),
    .epc(m_epc),
    .bva(m_bva),
    next_valid(wb_valid),
    .valid(mem_valid),
    .finish(mem_finish)
);

WB wb(
    .MEM_WB_BUS(MEM_WB_BUS_REG),
    .reg_en(reg_en),
    .lo_en(lo_en),
    .hi_en(hi_en),
    .cp0_en(cp0_en),
    .rd(rd),
    .sel(sel),
    .w_data(wb_data),
    .valid(wb_valid),
    .finish(wb_finish)
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
