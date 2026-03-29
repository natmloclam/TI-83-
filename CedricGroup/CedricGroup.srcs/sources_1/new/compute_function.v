`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.10.2025 19:38:54
// Design Name: 
// Module Name: compute_function
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


module compute_function(input  signed [15:0] x,
                        input  signed [15:0] a, b, c, d,
                        output signed [31:0] y_func);

    wire signed [31:0] x2, x3; 
    
    assign x2 = (x * x) >>> 4; 
    assign x3 = (x2 * x) >>> 4;
    assign y_func = ((a * x3) >>> 4) + ((b * x2) >>> 4) + ((c * x) >>> 4) + d; 

endmodule
