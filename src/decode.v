`timescale 1ns / 1ps
module decode(
        input  [ 61:0]   IF_ID_BUS,
        input  [ 31:0]   r_data0,
        input  [ 31:0]   r_data1,
        output [4:0]     rs,
        output [4:0]     rt,
        output [183:0]   ID_EXE_BUS,
        output _break,
        output _syscall,
        output _error_throw
    );
    wire [31:0]  ins;
    wire [29:0]  pc;
    wire rs,rt,rd,imm;
    wire [ 4:0]  sa;
    wire [ 5:0]  opcode;
    wire [ 5:0]  funct;
    wire [15:6]  rdsa;
    assign ins = IF_ID_BUS[61:30];
    assign  pc = IF_ID_BUS[29:0];
    assign rs  = ins[25:21];
    assign rt  = ins[20:16];
    assign rd  = ins[15:11];
    assign imm = ins[15: 0];
    assign sa  = ins[10: 6];
    assign opcode = ins[31:26];
    assign funct = ins[5:0];

    wire inst_OUT;
    wire inst_ADD,inst_ADDI,inst_ADDU,inst_ADDIU;
    wire inst_SUB,inst_SUBU;
    wire inst_SLT,inst_SLTU,inst_SLTI,inst_SLTIU;
    wire inst_MULT,inst_DIV,inst_MULTU,inst_DIVU;
    wire inst_AND,inst_ANDI,inst_LUI,inst_OR,inst_ORI,inst_NOR,inst_XOR,inst_XORI;
    wire inst_SLLV,inst_SLL,inst_SRAV,inst_SRA,inst_SRLV,inst_SRL;
    wire inst_BEQ,  inst_BNE, inst_BGEZ , inst_BGTZ, inst_BLEZ, inst_BLTZ, inst_J, inst_JAL, inst_JR, inst_JALR;    
    wire inst_BGEZAL,inst_BLTZAL;
    wire inst_MFHI,inst_MFLO,inst_MTHI,inst_MTLO;
    wire inst_BREAK,inst_SYSCALL;
    wire int_LB,inst_LBU,inst_LH,inst_LHU,inst_LW,inst_SB,inst_SH,inst_SW;
    wire inst_ERET,inst_MFC0,MTFC0;

    wire arithmetic_op,logic_op,shift_op,jump_op,datamov_op,trap_op,fetch_op,privilege_op;

    wire op_zero;  // 操作码全0
    wire sa_zero;  // sa域全0
    wire rdsa_zero;
    assign op_zero = ~(|opcode);
    assign sa_zero = ~(|sa);
    assign rdsa_zero = ~(|rdsa);

    assign inst_ADD   = op_zero & sa_zero & (funct == 6'b100000);
    assign inst_ADDU  = op_zero & sa_zero & (funct == 6'b100001);
    assign inst_ADDI  = (opcode == 6'b001000);
    assign inst_ADDIU = (opcode == 6'b001001);
    assign inst_SUB   = op_zero & sa_zero & (funct == 6'b100010);
    assign inst_SUBU  = op_zero & sa_zero & (funct == 6'b100011);
    
    assign inst_SLT   = op_zero & sa_zero & (funct == 6'b101010);
    assign inst_SLTU  = op_zero & sa_zero & (funct == 6'b101011);
    assign inst_SLTI  = (opcode == 6'b001010);
    assign inst_SLTIU = (opcode == 6'b001011);
    
    assign inst_DIV   = op_zero & rdsa_zero & (funct == 6'b011010);
    assign inst_DIVU  = op_zero & rdsa_zero & (funct == 6'b011011);
    assign inst_MULT  = op_zero & rdsa_zero & (funct == 6'b011000);
    assign inst_MULTU = op_zero & rdsa_zero & (funct == 6'b011001);
    
    assign arithmetic_op = inst_ADD | inst_ADDU | inst_ADDI | inst_ADDIU | inst_SUB | inst_SUBU |
                           inst_SLT | inst_SLTU | inst_SLTI | inst_SLTIU |
                           inst_DIV | inst_DIVU | inst_MULT | inst_MULTU;

    assign inst_AND   = op_zero & sa_zero & (funct == 6'b100100);
    assign inst_ANDI  = (opcode == 6'b001100);
    assign inst_LUI   = (opcode == 6'b001111) & (rs == 5'b0);
    assign inst_NOR   = op_zero & sa_zero & (funct == 6'b100111); 
    assign inst_OR    = op_zero & sa_zero & (funct == 6'b100101);
    assign inst_ORI   = (opcode == 6'b001101);
    assign inst_XOR   = op_zero & sa_zero & (funct == 6'b100110);
    assign inst_XORI  = (opcode == 6'b001110); 

    assign logic_op   = inst_AND | inst_ANDI | inst_LUI | inst_NOR | inst_OR | inst_ORI | inst_XOR | inst_XORI;
    
    assign inst_SLLV  = op_zero & sa_zero & (funct == 6'b000100);
    assign inst_SLL   = op_zero & (rs == 5'b0) & (funct == 6'b0);
    assign inst_SRAV  = op_zero & sa_zero & (funct == 6'b000111;
    assign inst_SRA   = op_zero & (rs == 5'b0) & (funct == 6'b000011);
    assign inst_SRLV  = op_zero & sa_zero & (funct == 6'b000110);
    assign inst_SRL   = opzero & (rs == 5'b0) & (funct == 6'b000010);

    assign shift_op   = inst_SLLV | inst_SLL | inst_SRAV | inst_SRA | inst_SRLV | inst_SRL;

    assign inst_BEQ   = (opcode == 6'b000100);              //判断相等跳转
    assign inst_BGEZ  = (opcode == 6'b000001) & (rt==5'd1); //大于等于0跳转
    assign inst_BGTZ  = (opcode == 6'b000111) & (rt==5'd0); //大于0跳转
    assign inst_BLEZ  = (opcode == 6'b000110) & (rt==5'd0); //小于等于0跳转
    assign inst_BLTZ  = (opcode == 6'b000001) & (rt==5'd0); //小于0跳转
    assign inst_BNE   = (opcode == 6'b000101);              //判断不等跳转
    assign inst_J     = (opcode == 6'b000010);              //跳转
    assign inst_JAL   = (opcode == 6'b000011);              //跳转和链接
    assign inst_JALR  = op_zero & (rt==5'd0) & (rd==5'd31) & sa_zero & (funct == 6'b001001);          //跳转寄存器并链接 
    assign inst_JR    = op_zero & (rt==5'd0) & (rd==5'd0 ) & sa_zero & (funct == 6'b001000);             //跳转寄存器
    assign inst_BGEZAL= (opcode == 6'b000001) & (rt == 5'b10001);
    assign inst_BTLZAL= (opcode == 6'b000001) & (rt == 5'b10000);

    assign jump_op    = inst_BEQ | inst_BGEZ | inst_BGTZ | inst_BLEZ | inst_BLTZ | inst_BNE | 
                        inst_J   | inst_JAL  | inst_JALR | inst_JR   | inst_BGEZAL | inst_BTLZAL;

    assign inst_MFHI  = op_zero & (rs == 5'b0) & (rt == 5'b0) & sa_zero & (funct == 6'b010000);
    assign inst_MFLO  = op_zero & (rs == 5'b0) & (rt == 5'b0) & sa_zero & (funct == 6'b010010);
    assign inst_MTHI  = op_zero & (rt == 5'b0) & rdsa_zero & (funct == 6'b010001);
    assign inst_MTLO  = op_zero & (rt == 5'b0) & rdsa_zero & (funct == 6'b010011);

    assign datamov_op = inst_MFHI | inst_MFLO | inst_MTHI | inst_MTLO;

    assign inst_BREAK = op_zero & (funct == 6'b001101);
    assign inst_SYSCALL = op_zero & (funct == 6'b001100);

    assign trap_op = inst_BREAK | inst_SYSCALL;

    assign inst_LB = (opcode == 6'b100000);
    assign inst_LBU = (opcode == 6'b100100);
    assign inst_LH = (opcode == 6'b100001);
    assign inst_LHU = (opcode == 6'b100101);
    assign inst_LW = (opcode == 6'b100011);
    assign inst_SB = (opcode == 6'b101000);
    assign inst_SH = (opcode == 6'b101001);
    assign inst_SW = (opcode == 6'b101011);

    assign fetch_op = inst_LB | inst_LBU | inst_LH | inst_LHU | inst_LW | inst_SB | inst_SH | inst_SW;

    assign inst_REST = (ins == 32'b010000 1 000 0000 0000 0000 0000 011000);
    assign inst_MFC0 = (opcode == 6'b010000) & (rs == 5'b0) & (ins[10:3] == 8'b0);
    assign inst_MTC0 = (opcode == 6'b010000) & (rs == 5'b00100) & (ins[10:3] == 8'b0);

    assign privilege_op = inst_REST | inst_MFC0 | inst_MTC0;

    assign _error_throw = ~(arithmetic_op | logic_op | shift_op | jump_op | datamov_op | trap_op | fetch_op | privilege_op);
    //alu操作分类
    wire alu_add, alu_sub, alu_slt,alu_sltu;
    wire alu_and, alu_nor, alu_or, alu_xor;
    wire alu_sll, alu_srl, alu_sra;
    assign alu_add = inst_ADD | inst_ADDI | inst_ADDU | inst_ADDIU;    // 做加法
    assign alu_sub = inst_SUB | inst_SUBU;                            // 减法
    assign alu_slt = inst_SLT | inst_SLTI;                 // 有符号小于置位
    assign alu_sltu= inst_SLTIU | inst_SLTU;               // 无符号小于置位
    assign alu_and = inst_AND | inst_ANDI;                 // 逻辑与
    assign alu_nor = inst_NOR;                             // 逻辑或非
    assign alu_or  = inst_OR  | inst_ORI;                  // 逻辑或
    assign alu_xor = inst_XOR | inst_XORI;                 // 逻辑异或
    assign alu_sll = inst_SLL | inst_SLLV;                 // 逻辑左移
    assign alu_srl = inst_SRL | inst_SRLV;                 // 逻辑右移
    assign alu_sra = inst_SRA | inst_SRAV;                 // 算术右移
    
endmodule