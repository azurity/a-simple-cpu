`timescale 1ns / 1ps

module CPU(
    input clk,
    input reset,
    input [5:0] hw
);
// explain: 同时只能触发一个异常，（多个算一个）
parameter EXCEPT_ADDR = 30'b0; // TODO:
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
reg [29:0] PC;
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
reg [31:0] lock_wire;
wire [4:0] lock_rd;
wire [2:0] lock_sel;
wire rs_allow;
wire rt_allow;
reg [5:0] lock_wire_sp;
wire [2:0] lockreq;
wire [2:0] lockres;
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
wire eret;
// 互锁
wire if_valid,if_finish;
wire id_valid,id_finish;
wire exe_valid,exe_finish;
wire mem_valid,mem_finish;
wire wb_valid,wb_finish;
// 特殊寄存器
reg [31:0] HI;
reg [31:0] LO;
reg [31:0] badVAddr;
reg [31:0] status;
reg [31:0] cause;
reg [31:0] epc;
wire cp0;
//
reg [3:0] exptyp = 4'b1111; // 控制异常时期流水 & 控制reset
//
assign execption = jump_exception | ri_exception | syscall_exception | break_exception | of_exception | m_el_exception | m_es_exception;
assign interrupt = (|(cause[15:8] & status[15:8])) & status[0];
//
always @(posedge clk)
begin
    if(eret)
    begin
        status[1] = 0;
    end
    if((execption | interrupt) & ~status[1]) // 需要保证一次处理一条异常 finish
    begin
        status[1] = 1;
        if(interrupt)
        begin
            cause[6:2] = 5'b00000;
            epc = PC;
        end
        else if(jump_exception)
        begin
            cause[6:2] = 5'b00100;
            badVAddr = {jump_addr,2'b0};
            epc = exe_epc;
            exptyp = 4'b1100;
        end
        else if(ri_exception)
            cause[6:2] = 5'b01010;
            epc = id_epc;
            exptyp = 4'b1100;
        begin
        end
        else if(of_exception | syscall_exception | break_exception)
        begin
            if(of_exception)
            begin
                cause[6:2] = 5'b01100;
                epc = exe_epc;
                exptyp = 4'b1000;
            end
            if(syscall_exception)
            begin
                cause[6:2] = 5'b01000;
                epc = id_epc;
                exptyp = 4'b1100;
            end
            if(break_exception)
            begin
                cause[6:2] = 5'b01001;
                epc = id_epc;
                exptyp = 4'b1100;
            end
        end
        else if(m_el_exception | m_es_exception)
        begin
            if(m_el_exception) cause[6:2] = 5'b00100;
            if(m_es_exception) cause[6:2] = 5'b00101;
            badVAddr = m_bva;
            epc = m_epc;
            exptyp = 4'b0000;
        end
        // 跳转 finish
    end
    // else
    begin
        if(if_valid)
        begin
            PC = nextPC+1;
        end
        if(if_finish & id_valid & exptyp[0])
        begin
            if(jump)
            begin
                IF_ID_BUS_REG = {IF_ID_BUS[61:32],32'b0};
            end
            else
            begin
                IF_ID_BUS_REG = IF_ID_BUS;// 如果exe为jump,此处为nop finish
            end
        end
        if(id_finish & exe_valid & exptyp[1])
        begin
            ID_EXE_BUS_REG = ID_EXE_BUS;
            PC_ADD_8_REG = nextPC; // 需要保证瞬间赋值
        end
        if(exe_finish & mem_valid & exptyp[2])
        begin
            EXE_MEM_BUS_REG = EXE_MEM_BUS;
        end
        if(mem_finish & wb_valid & exptyp[3])
        begin
            MEM_WB_BUS_REG = MEM_WB_BUS;
        end
    end
end
//decode填值
always @(*)
begin
    if(sel == 3'b0)
    begin
        if(lock_rd == 8) cp0 <= badVAddr;
        else if（lock_rd == 12) cp0 <= status;
        else if（lock_rd == 13) cp0 <= cause;
        else if（lock_rd == 14) cp0 <= epc;
        else cp0 <= 31'b0;
    end
    else cp0 <= 31'b0;
end
//寄存器锁
always @(posedge clk)
begin
    if(lock_rd != 5'b0) lock_wire[lock_rd] = 1;
    if(reg_en) lock_wire[rd] = 0;
    lock_wire_sp[1:0] |= lockreq[1:0];
    if(lockreq[2])
    begin
        if(lock_sel == 3'b0)
        begin
            if(lock_rd == 8) lock_wire_sp[2] = 1;
            else if（lock_rd == 12) lock_wire_sp[3] = 1;
            else if（lock_rd == 13) lock_wire_sp[4] = 1;
            else if（lock_rd == 14) lock_wire_sp[5] = 1;
        end
    end
    if(cp0_en)
    begin
        if(sel == 3'b0)
        begin
            if(rd == 8) lock_wire_sp[2] = 0;
            else if（rd == 12) lock_wire_sp[3] = 0;
            else if（rd == 13) lock_wire_sp[4] = 0;
            else if（rd == 14) lock_wire_sp[5] = 0;
        end
    end
    if(hi_en) lockreq[1] = 0;
    if(lo_en) lockreq[0] = 0;
end
assign rs_allow = ~lock_wire[rs];
assign rt_allow = ~lock_wire[rt];
assign lockres[1:0] = ~lock_wire_sp[1:0];
always @(*)
begin
    if(sel == 3'b0)
    begin
        if(rd == 8)  lockres[2]=lock_wire_sp[2];
        else if（rd == 12) lockres[2]=lock_wire_sp[3];
        else if（rd == 13) lockres[2]=lock_wire_sp[4];
        else if（rd == 14) lockres[2]=lock_wire_sp[5];
        else lockres[2] = 0;
    end
    else lockres[2] = 0;
end
//跳转逻辑
// assign nextPC = jump? jump_addr : PC;
always @(*)
begin
    if(reset)
    begin
        nextPC = 30'b0;
    end
    else if((execption | interrupt) & ~status[1])
    begin
        nextPC <= EXCEPT_ADDR;
    end
    else if(eret)
    begin
        nextPC <= epc;
    else
    begin
        nextPC <= jump? jump_addr : PC;
    end
end
//中断
always @(hw)
begin
    if(~status[1]) cause[15:10] = hw[5:0];
    //if(status[0] & ~status[1])
    //begin
    //    cause[15:10] = hw[5:0] & status[15:10];
    //end
end
//写特殊寄存器
always @(posedge clk)
begin
    if(hi_en) HI = wb_data;
    if(lo_en) LO = wb_data;
    if(cp0_en)
    begin
        if(sel == 3'b0)
        begin
            //if(rd == 8) badVAddr = wb_data; 只读
            if（rd == 12)
            begin
                status = {16'b0,wb_data[15:8],6'b0,wb_data[1:0]};
            end
            else if（rd == 13 && ~status[1])
            begin
                cause = {cause[31],15'b0,cause[15:10],wb_data[9:8],1'b0,cause[6:2],2'b0};
            end
            else if（rd == 14 && ~status[1]) epc = wb_data;
        end
    end
end
//
FETCH fetch(
    .reset(exptyp[0] | reset),
    .clk(clk),
    .input_pc(nextPC),
    .data(ins),
    .IF_ID_BUS(IF_ID_BUS),
    .next_valid(id_valid),
    .valid(if_valid),
    .finish(if_finish)
);

DECODE decode(
    .reset(exptyp[1] | reset),
    .IF_ID_BUS(IF_ID_BUS_REG),
    .r_data0(reg_0),
    .r_data1(reg_1),
    .output_rs(rs),
    .output_rt(rt),
    //.output_rd(),
    .ID_EXE_BUS(ID_EXE_BUS),
    .cp0(cp0),
    .LO(LO),
    .HI(HI),
    ._break(break_exception),
    ._syscall(syscall_exception),
    ._eret(eret),
    ._error_throw(ri_exception),
    .j_exp(jump_exception),
    .lockreq(lockreq),
    .lockres(lockres),
    .epc(id_epc),
    .rs_allow(rs_allow),
    .rt_allow(rt_allow),
    .lock_rd(lock_rd),
    .lock_sel(lock_sel),
    .next_valid(exe_valid),
    .valid(id_valid),
    .finish(id_finish)
);

EXE exe(
    .reset(exptyp[2] | reset),
    .ID_EXE_BUS(ID_EXE_BUS_REG),
    .EXE_MEM_BUS(EXE_MEM_BUS),
    .PC_ADD_8(PC_ADD_8_REG),
    .addr(jump_addr),
    .jump(jump),
    .of(of_exception),
    .epc(exe_epc),
    .next_valid(mem_valid),
    .valid(exe_valid),
    .finish(exe_finish)
);

MEM mem(
    .reset(exptyp[3] | reset),
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
    .addra(nextPC[7:0]),
    .douta(ins)
);
endmodule
