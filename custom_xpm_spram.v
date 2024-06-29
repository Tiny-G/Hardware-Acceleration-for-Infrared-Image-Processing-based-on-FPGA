`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/09 20:50:26
// Design Name: 
// Module Name: custom_xpm_spram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 简单单端口RAM
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module custom_xpm_spram#(
    parameter           P_WRITE_DATA_WIDTH_A = 32 ,
    parameter           P_WRITE_DATA_DEPTH_A = 64 ,
    parameter           P_READ_DATA_WIDTH_A  = 32 ,
    parameter           P_ADDR_WIDTH_A       = 6   
)
(
    //port A
    input                                   clka    ,
    input                                   rsta_n  ,
    input   [P_ADDR_WIDTH_A-1:0]            addra   ,
    input                                   wea     ,
    input   [P_WRITE_DATA_WIDTH_A-1:0]      dina    ,
    output  [P_READ_DATA_WIDTH_A-1:0]       douta   ,
    input                                   ena          
);

localparam  P_MEMORY_SIZE = P_WRITE_DATA_WIDTH_A*P_WRITE_DATA_DEPTH_A;

xpm_memory_spram #(
    .ADDR_WIDTH_A       (P_ADDR_WIDTH_A     )   ,// DECIMAL
    .AUTO_SLEEP_TIME    (0                  )   ,// DECIMAL
    .BYTE_WRITE_WIDTH_A (P_WRITE_DATA_WIDTH_A)  ,// DECIMAL
    .ECC_MODE           ("no_ecc"           )   ,// String
    .MEMORY_INIT_FILE   ("none"             )   ,// String
    .MEMORY_INIT_PARAM  ("0"                )   ,// String
    .MEMORY_OPTIMIZATION("true"             )   ,// String
    .MEMORY_PRIMITIVE   ("auto"             )   ,// String
    .MEMORY_SIZE        (P_MEMORY_SIZE      )   ,// DECIMAL
    .MESSAGE_CONTROL    (0                  )   ,// DECIMAL
    .READ_DATA_WIDTH_A  (P_READ_DATA_WIDTH_A)   ,// DECIMAL
    .READ_LATENCY_A     (2                  )   ,// DECIMAL
    .READ_RESET_VALUE_A ("0"                )   ,// String
    .RST_MODE_A         ("SYNC"             )   ,// String
    .USE_MEM_INIT       (1                  )   ,// DECIMAL
    .WAKEUP_TIME        ("disable_sleep"    )   ,// String
    .WRITE_DATA_WIDTH_A (P_WRITE_DATA_DEPTH_A)  ,// DECIMAL
    .WRITE_MODE_A       ("read_first"       )    // String
)
xpm_memory_spram_inst 
(
    .dbiterra           (                   )   ,            
    .douta              (douta              )   ,                  
    .sbiterra           (                   )   ,            
    .addra              (addra              )   ,                  
    .clka               (clka               )   ,                    
    .dina               (dina               )   ,                    
    .ena                (ena                )   ,                      
    .injectdbiterra     (                   )   ,
    .injectsbiterra     (                   )   ,
    .rsta               (!rsta_n            )   ,                    
    .sleep              (                   )   ,                  
    .wea                (wea                )                          

);
endmodule
