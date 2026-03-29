`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.10.2025 17:48:02
// Design Name: 
// Module Name: input_scaler
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


module input_scaler(input signed [15:0] a, b, c, d, output signed [15:0] out_a, out_b, out_c, out_d);

    parameter SCALE = 16;
    
    assign out_a = a * SCALE;
    assign out_b = b * SCALE;
    assign out_c = c * SCALE;
    assign out_d = d * SCALE;

endmodule