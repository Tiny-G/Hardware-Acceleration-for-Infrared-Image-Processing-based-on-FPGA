`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/23 15:49:37
// Design Name: 
// Module Name: multi_hight_feature_rows
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module multi_hight_feature_rows
#(
    parameter          P_IMAGE_HEIGHT = 256 
)
(
    input              i_clk                ,
    input              i_rst_n              ,
    input              i_h_aync_m           ,
    input              i_v_aync_m           ,
    input   [23:0]     i_data_m             ,
    input              i_remainder_signal_m ,
    input              i_h_aync_s           ,
    input              i_v_aync_s           ,
    input   [23:0]     i_data_s             ,
    input              i_remainder_signal_s ,

    output             o_h_aync             ,
    output             o_v_aync             ,
    output  [59:0]     o_data               ,
    output             o_remainder_signal   
);

//input register
reg                 ri_h_aync_m             ;
reg                 ri_v_aync_m             ;
reg     [23:0]      ri_data_m               ;
reg                 ri_remainder_signal_m   ;
reg                 ri_h_aync_s             ;
reg                 ri_v_aync_s             ;
reg     [23:0]      ri_data_s               ;
reg                 ri_remainder_signal_s   ;

//output register
reg                 r_remainder_signal_1d   ;
reg                 r_remainder_signal_2d   ;
reg                 r_remainder_signal      ;

//temp regisers
reg                 r_h_aync_m_1d           ;
reg                 r_v_aync_m_1d           ;
reg     [23:0]      r_data_m_1d             ;
reg                 r_remainder_signal_m_1d ;
reg                 r_h_aync_s_1d           ;
reg                 r_v_aync_s_1d           ;
reg     [23:0]      r_data_s_1d             ;
reg                 r_remainder_signal_s_1d ;

reg     [7:0]       r_get_remainders        ;
reg     [15:0]      r_rows_cnt              ;
reg                 r_h_valid_aync_1d       ;

wire                w_h_valid_aync          ;
wire                w_h_valid_aync_posedge  ;

wire                w_h_aync1               ;
wire                w_v_aync1               ;
wire    [7:0]       w_res_data1             ;
wire                w_h_aync2               ;
wire                w_v_aync2               ;
wire    [7:0]       w_res_data2             ;
wire                w_h_aync3               ;
wire                w_v_aync3               ;
wire    [7:0]       w_res_data3             ;

assign  o_h_aync            = w_h_aync1&&w_h_aync2&&w_h_aync3;
assign  o_v_aync            = w_v_aync1&&w_v_aync2&&w_v_aync3;
assign  o_data              = {w_res_data1,w_res_data2,w_res_data3};
assign  o_remainder_signal  = r_remainder_signal;

assign  w_h_valid_aync      = ri_h_aync_m && ri_h_aync_s ;
assign  w_h_valid_aync_posedge = w_h_valid_aync && !r_h_valid_aync_1d;


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_aync_m           <= 1'd0 ;
        ri_v_aync_m           <= 1'd0 ;
        ri_data_m             <= 24'd0;
        ri_remainder_signal_m <= 1'd0 ;
        ri_h_aync_s           <= 1'd0 ;
        ri_v_aync_s           <= 1'd0 ;
        ri_data_s             <= 24'd0;
        ri_remainder_signal_s <= 1'd0 ;
    end else begin
        ri_h_aync_m           <= i_h_aync_m           ;
        ri_v_aync_m           <= i_v_aync_m           ;
        ri_data_m             <= i_data_m             ;
        ri_remainder_signal_m <= i_remainder_signal_m ;
        ri_h_aync_s           <= i_h_aync_s           ;
        ri_v_aync_s           <= i_v_aync_s           ;
        ri_data_s             <= i_data_s             ;
        ri_remainder_signal_s <= i_remainder_signal_s ;
    end
end
//delay signals
always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) begin
        r_h_valid_aync_1d <= 1'd0 ;
        r_h_aync_m_1d     <= 1'd0 ;
        r_v_aync_m_1d     <= 1'd0 ;
        r_h_aync_s_1d     <= 1'd0 ;
        r_v_aync_s_1d     <= 1'd0 ;
        r_remainder_signal_1d <= 1'b0;
        r_remainder_signal_2d <= 1'b0;
    end else begin
        r_h_valid_aync_1d <= w_h_valid_aync ;
        r_h_aync_m_1d    <= ri_h_aync_m ;
        r_v_aync_m_1d    <= ri_v_aync_m ;
        r_h_aync_s_1d    <= ri_h_aync_s ;
        r_v_aync_s_1d    <= ri_v_aync_s ;
        r_remainder_signal_1d <= r_remainder_signal_m_1d;
        r_remainder_signal_2d <= r_remainder_signal_1d;
    end
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_rows_cnt <= 16'd0;
    else if(w_h_valid_aync_posedge)
        r_rows_cnt <= r_rows_cnt + 16'd1;
    else if(r_rows_cnt == P_IMAGE_HEIGHT)
        r_rows_cnt <= 16'd0;
    else
        r_rows_cnt <= r_rows_cnt;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_get_remainders <= 8'd0;
    else if(r_rows_cnt == P_IMAGE_HEIGHT-1 && w_h_valid_aync_posedge && ri_remainder_signal_m)
        r_get_remainders <= ri_data_m[7:0];
    else if(!ri_v_aync_m )
        r_get_remainders <= 8'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) begin
        r_data_m_1d <= 24'd0 ;
        r_data_s_1d <= 24'd0 ;
    end else if(ri_h_aync_m && !ri_remainder_signal_m)begin
        r_data_m_1d <= ri_data_s ;
        r_data_s_1d <= ri_data_m ;
    end else if(ri_h_aync_m && ri_remainder_signal_m)begin
        case (r_get_remainders)
                1: begin
                    r_data_m_1d <= {ri_data_s[23:16],16'd0} ;
                    r_data_s_1d <= {ri_data_m[23:16],16'd0} ;
                end
                2: begin
                    r_data_m_1d <= {ri_data_s[23:8],8'd0} ;
                    r_data_s_1d <= {ri_data_m[23:8],8'd0} ;
                end
            default :begin
                r_data_m_1d <= ri_data_s;
                r_data_s_1d <= ri_data_m;
            end
        endcase
    end else begin
        r_data_m_1d <= 24'd0 ;
        r_data_s_1d <= 24'd0 ;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)  r_remainder_signal <= 1'b0;
    else  r_remainder_signal <= r_remainder_signal_2d;
end


multi_hight_feature multi_hight_feature_U0
(
    .i_clk       (i_clk             ),
    .i_rst_n     (i_rst_n           ),
    .i_h_aync_m  (r_h_aync_m_1d     ),
    .i_v_aync_m  (r_v_aync_m_1d     ),
    .i_data_m    (r_data_m_1d[23:16]),
    .i_v_aync_s  (r_v_aync_s_1d     ),
    .i_h_aync_s  (r_h_aync_s_1d     ),
    .i_data_s    (r_data_s_1d[23:16]),
    .o_h_aync    (w_h_aync1         ),
    .o_v_aync    (w_v_aync1         ),
    .o_res_data  (w_res_data1       )
);
multi_hight_feature multi_hight_feature_U1
(
    .i_clk       ( i_clk            ),
    .i_rst_n     ( i_rst_n          ),
    .i_h_aync_m  (r_h_aync_m_1d     ),
    .i_v_aync_m  (r_v_aync_m_1d     ),
    .i_data_m    (r_data_m_1d[16:8] ),
    .i_v_aync_s  (r_v_aync_s_1d     ),
    .i_h_aync_s  (r_h_aync_s_1d     ),
    .i_data_s    (r_data_s_1d[16:8] ),
    .o_h_aync    (w_h_aync2         ),
    .o_v_aync    (w_v_aync2         ),
    .o_res_data  (w_res_data2       )
);
multi_hight_feature multi_hight_feature_U2
(
    .i_clk       ( i_clk            ),
    .i_rst_n     ( i_rst_n          ),
    .i_h_aync_m  (r_h_aync_m_1d     ),
    .i_v_aync_m  (r_v_aync_m_1d     ),
    .i_data_m    (r_data_m_1d[7:0]  ),
    .i_v_aync_s  (r_v_aync_s_1d     ),
    .i_h_aync_s  (r_h_aync_s_1d     ),
    .i_data_s    (r_data_s_1d[7:0]  ),
    .o_h_aync    (w_h_aync3         ),
    .o_v_aync    (w_v_aync3         ),
    .o_res_data  (w_res_data3       )
);
endmodule
