`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2025 14:13:04
// Design Name: 
// Module Name: alt_coordinates
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


module alt_coordinates(
    input [12:0] pixel_index,    
    output [6:0] x,
    output [5:0] y
);

    assign x = 95 -(pixel_index % 96);
    assign y = 63 - (pixel_index / 96);

endmodule
