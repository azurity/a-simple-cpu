`timescale 1ns / 1ps
module alu(
    input  [ 3:0]   opcode,        //操作码
    input  [31:0]   data0,         //输入数据A
    input  [31:0]   data1,         //输入数据B
    output [31:0]   out_data,      //输出结果
    output reg      ovf,           //溢出标志位
    output [ 3:0]   condition      //状态码      
    );   
    parameter   _OUT            = 1'h0;
    parameter   _ADD            = 1'h1;
    parameter   _SUB            = 1'h2;
    parameter   _AND            = 1'h3;
    parameter   _OR             = 1'h4;
    parameter   _NOR            = 1'h5;
    parameter   _XOR            = 1'h6;
    parameter   _SHITF_L_LOGIC  = 1'h7;
    parameter   _SHITF_R_LOGIC  = 1'h8;
    parameter   _SHITF_R_ARITH  = 1'h9;
    parameter  _MUL             = 1'ha;
    parameter  _DIV             = 1'hb;
    parameter  _MULU            = 1'hc;
    parameter  _DIVU            = 1'hd;
    parameter  _SLT             = 1'he;
    parameter  _SLTU            = 1'hf;
    wire [4:0]    shf;
    assign shf = data1[4:0];
    wire [31:0] shf_temp_1;
    wire [31:0] shf_temp_2;
    wire [31:0] shf_temp_3;
    wire [31:0] shf_temp_4;
    wire [31:0] shf_temp_5;
    wire EQ,NE,GT,LT;
    wire [32:0] tmp0;
    wire [32:0] tmp1;
    wire [32:0] tmp_out;
    assign tmp0 =  {data0[31],data0};
    assign tmp1 = {data1[31],data1};

    always@(*)
    begin
        case(opcode)
            _OUT:           
            begin
                outdata <= data0;
                ovf = 0;
            end
            _ADD:
            begin
                tmp_out <= tmp0 + tmp1;
                ovf <= tmp_out[32] ^ tmp_out[31];
                outdata <= tmp_out[31:0];
            end 
            _SUB:
            begin
                outdata <= data0 - data1;
                ovf <= tmp_out[32] ^ tmp_out[31];
                outdata <= tmp_out[31:0];
                EQ <= 1'b0;
                NE <= 1'b0;
                GT <= 1'b0;
                LT <= 1'b0;
                if(outdata == 32'b0)EQ <=1'b1;
                else if(outdata[31]==1'b0)
                begin
                    NE <= 1'b1;
                    GT <= 1'b1;
                end
                else 
                begin
                    NE <= 1'b1;
                    LT <= 1'b1;
                end
                condition <= {EQ,NE,GT,LT};
            end 
            _AND:
            begin
                outdata <= data0 & data1;
                ovf = 0;
            end
            _OR:
            begin
                outdata <= data0 | data1;
                ovf = 0;
            end
            _NOR:
            begin
                outdata <= ~(data0 ^ data1);
                ovf = 0;
            end
            _XOR:
            begin
                outdata <= data0 ^ data1;
                ovf = 0;
            end
            _SHITF_L_LOGIC:
            begin
               // outdata = data0 << data1;
                shf_tmp_1 <= shf[0]?{data0[30:0],1'b0}:data0;
                shf_tmp_2 <= shf[1]?{shf_tmp_1[29:0],2'b0}:shf_tmp_1;
                shf_tmp_3 <= shf[2]?{shf_tmp_2[27:0],4'b0}:shf_tmp_2;
                shf_tmp_4 <= shf[3]?{shf_tmp_3[23:0],8'b0}:shf_tmp_3;
                shf_tmp_5 <= shf[4]?{shf_tmp_4[15:0],16'b0}:shf_tmp_4;
                outdata <= shf_tmp_5;
                ovf = 0;
            end
            _SHITF_R_LOGIC:
            begin
                shf_tmp_1 <= shf[0]?{ 1'b0,data0[31:1]}:data0;
                shf_tmp_2 <= shf[1]?{ 2'b0,shf_tmp_1[31:2]}:shf_tmp_1;
                shf_tmp_3 <= shf[2]?{ 4'b0,shf_tmp_2[31:4]}:shf_tmp_2;
                shf_tmp_4 <= shf[3]?{ 8'b0,shf_tmp_3[31:8]}:shf_tmp_3;
                shf_tmp_5 <= shf[4]?{16'b0,shf_tmp_4[31:16]}:shf_tmp_4;
                outdata <= shf_tmp_5;
                ovf = 0;
            end
            _SHITF_R_ARITH:
            begin
               // outdata = ($signed(data0)) >>> data1;
                shf_tmp_1 <= shf[0]?{( 1{data0[31]}},data0    [31:1]}:data0;
                shf_tmp_2 <= shf[1]?{{ 2{data0[31]}},shf_tmp_1[31:2]}:shf_tmp_1;
                shf_tmp_3 <= shf[2]?{{ 4{data0[31]}},shf_tmp_2[31:4]}:shf_tmp_2;
                shf_tmp_4 <= shf[3]?{{ 8{data0[31]}},shf_tmp_3[31:8]}:shf_tmp_3;
                shf_tmp_5 <= shf[4]?{{16{data0[31]}},shf_tmp_4[31:16]}:shf_tmp_4;
                outdata <= shf_tmp_5;
                ovf = 0;
            end
            _MUL:
            begin

            end
            _DIV:
            begin

            end
            _SLT:
            begin

            end
            _SLT_signal:
            begin

            end
        endcase
    end
endmodule