`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.10.2025 10:08:27
// Design Name: 
// Module Name: graph_coord
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


module graph_coord(input [6:0] x_raw, input [5:0] y_raw, input [15:0] scale,
                    output [15:0] x_out, y_out);
    
    assign x_out = ($signed({9'b0, x_raw}) - 48) * scale; 
    assign y_out = (32 - $signed({10'b0, y_raw})) * scale;
    
endmodule
