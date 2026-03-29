`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2025 12:43:00
// Design Name: 
// Module Name: led_controller
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


module led_controller(input mode, input [15:0] scale, output reg [3:0] led);

    always @(*)
    begin
        if (mode == 1) 
        begin 
            case (scale)
                1 : led <= 4'b0001;
                2 : led <= 4'b0011;
                3 : led <= 4'b0111;
                4 : led <= 4'b1111;
                default : led <= 4'b0000;
            endcase 
        end
        else led <= 0; 
    end
    
endmodule

