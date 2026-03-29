`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.10.2025 15:11:22
// Design Name: 
// Module Name: axis_ticks
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


module axis_ticks(input signed [15:0] x, y, scale,
                  output tick_on);

    wire on_grid_x, on_grid_y;
    
    assign on_grid_x = (scale == 3) ? (x % 15 == 0) : ((x & 16'h000F) == 0);
    assign on_grid_y = (scale == 3) ? (y % 15 == 0) : ((y & 16'h000F) == 0);
    assign tick_on   = on_grid_x || on_grid_y;

endmodule 
