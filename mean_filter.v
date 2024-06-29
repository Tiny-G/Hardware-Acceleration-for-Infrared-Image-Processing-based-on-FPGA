`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/08 16:20:18
// Design Name: 
// Module Name: mean_filter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 均值滤波核，输入的是二维图像数据,由于veilog无法直接输入二维，所以要输入的事flatten后的一维数据,输入的均值
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mean_filter
#(
    parameter          P_DATA_WIDTH       = 8   ,
    parameter          P_SLIDE_WINDOW     = 3   

)
(
    input                                                       i_clk    ,
    input                                                       i_rst_n  ,
    input                                                       i_h_sync ,
    input                                                       i_v_sync ,
    input   [P_DATA_WIDTH*P_SLIDE_WINDOW*P_SLIDE_WINDOW-1:0]    i_data   ,

    output                                                      o_h_sync ,
    output                                                      o_v_sync ,
    output  [P_DATA_WIDTH-1:0]                                  o_data   



);

localparam        P_SLIDE_WINDOW_SIZE  = P_SLIDE_WINDOW*P_SLIDE_WINDOW   ; // 窗口大小,即被除数大小

//input regiser
reg                                                     ri_h_sync   ;
reg                                                     ri_v_sync   ;
reg [P_DATA_WIDTH*P_SLIDE_WINDOW*P_SLIDE_WINDOW-1:0]    ri_data     ;

//output register
reg                                                     ro_h_sync   ;
reg                                                     ro_v_sync   ;
reg [P_DATA_WIDTH-1:0]                                  ro_data     ;

//tmep register
wire                                                    w_h_valid_sync;

assign o_h_sync = ro_h_sync ;
assign o_v_sync = ro_v_sync ;
assign o_data   = ro_data   ;
assign w_h_valid_sync = ri_v_sync && ri_h_sync ;

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ri_h_sync   <= 1'b0;
        ri_v_sync   <= 1'b0;
        ri_data     <=  'd0;
    end else begin
        ri_h_sync   <= i_h_sync ;
        ri_v_sync   <= i_v_sync ;
        ri_data     <= i_data   ;
    end
end

integer i,j;
always @(*) begin
    ro_data =  ri_data[P_DATA_WIDTH-1:0];
    for (i = 0; i < P_SLIDE_WINDOW; i = i + 1) begin
        for (j = 0; j < P_SLIDE_WINDOW; j = j + 1) begin
            if(ri_data[i*P_SLIDE_WINDOW+j*P_DATA_WIDTH +: P_DATA_WIDTH] > ro_data)
                ro_data = ri_data[i*P_SLIDE_WINDOW+j*P_DATA_WIDTH +: P_DATA_WIDTH];
            else
                ro_data = ro_data;
        end
    end
end


endmodule
