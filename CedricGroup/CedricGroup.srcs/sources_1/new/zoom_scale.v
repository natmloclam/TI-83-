`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.10.2025 16:43:38
// Design Name: 
// Module Name: zoom_scale
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


module zoom_scale(
    input clk,
    input mode, pan_toggle,
    input btnU, 
    input btnD, 
    output reg [15:0] scale = 2
);
    parameter MIN_ZOOM = 4; 
    parameter MAX_ZOOM = 1; 
    parameter DEFAULT = 2;
    
    reg btnU_prev, btnD_prev;
    
    always @(posedge clk) begin
        // Store previous button states
        btnU_prev <= btnU;
        btnD_prev <= btnD;
        
        if (mode == 1 && pan_toggle == 0) 
            begin
            // Detect rising edge of btnU (button just pressed)
            if (btnU && !btnU_prev) begin
                if (scale > MAX_ZOOM)
                    scale <= scale - 1;  // zoom in
            end
            
            // Detect rising edge of btnD (button just pressed)
            if (btnD && !btnD_prev) begin
                if (scale < MIN_ZOOM)
                    scale <= scale + 1;  // zoom out
            end 
        end
    end
    
endmodule