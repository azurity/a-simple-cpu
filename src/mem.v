`timescale 1ns / 1ps

module MEM(
    input [?:0] EXE_MEM_BUS,
    output [?:0] MEM_WB_BUS,
    output [3:0] w_mem,
    output [7:0] addr_mem,
    input [31:0] load_data,
    output [31:0] store_data
);
    wire [9:0] addr;
    wire [31:0] store_data;
    reg [31:0] load_data;
    wire [31:0] exe_result;
    wire [31:0] mem_result;
    wire [31:0] result;
    wire read;
    wire write;
    wire [1:0] len;
    wire un;
    wire [10:0] wb_through;
    assign {read,write,len,un,wb_through,addr,exe_result} = EXE_MEM_BUS;
    assign addr_mem = addr[9:2];
    // 写逻辑
    /*assign w_mem = wirte ? {len[0]&addr[1]&add[0],len[0]&addr[1]&~addr[0],len[0]&~addr[1]&~addr[0],len[0]&~addr[1]&~addr[0]}
        |{{2{len[1]&addr[1]}},{2{len[1]&~addr[1]}}}
        |{4{len[2]}} : 4'b0;*/
    assign store_data = exe_result;
    always @(*)
    begin
        case(len)
            2'b00:
                w_mem <= addr[1:0];
            2'b01:
                begin
                    w_mem <= addr[1] ? 4'b0011 : 4'b1100;
                end
            2'b10:
                w_mem <= 4'b1111;
        endcase
    end
    // 读逻辑
    always @(*)
    begin
        case(len)
            2'b00:
                begin
                    case(addr[1:0])
                        2'b00:
                            mem_result <= {{24{~un & load_data[7]}},load_data[7:0]};
                        2'b01:
                            mem_result <= {{24{~un & load_data[15]}},load_data[15:8]};
                        2'b10:
                            mem_result <= {{24{~un & load_data[23]}},load_data[23:16]};
                        2'b11:
                            mem_result <= {{24{~un & load_data[31]}},load_data[31:24]};
                    endcase
                end
            2'b01:
                begin
                    case(addr[1]):
                        1'b0:
                            mem_result <= {{16{~un & load_data[15]}},load_data[15:0]};
                        1'b1:
                            mem_result <= {{16{~un & load_data[31]}},load_data[31:16]};
                    endcase
                end
            2'b10:
                mem_result <= load_data;
        endcase
    end
    assign result = read ? mem_result : exe_result;
    assign {wb_through,result} = MEM_WB_BUS;
endmodule