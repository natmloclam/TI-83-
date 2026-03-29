`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2025 12:44:06
// Design Name: 
// Module Name: pan_controller
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


module pan_controller(
    input clk, mode, pan_toggle,       // connect pan_toggle to sw[0]
    input btnL, btnR, btnD, btnU, btnC,
    input [15:0] scale,
    output reg signed [15:0] pan_x = 0,
    output reg signed [15:0] pan_y = 0
);
    parameter GRAPH = 1;

    // --- Timing parameters (for 1 kHz clock) ---
    parameter BASE_DELAY = 20'd250;    // slow start (~4 Hz)
    parameter MIN_DELAY  = 20'd10;     // max speed (~66 Hz)
    parameter ACCEL_STEP = 20'd3;      // how quickly to accelerate
    parameter DECEL_STEP = 20'd8;      // how quickly to slow down

    reg [19:0] counter = 0;
    reg [19:0] delay = BASE_DELAY;
    reg [19:0] target_delay = BASE_DELAY;
    wire any_btn = btnL | btnR | btnU | btnD;

    always @(posedge clk) begin
        if (mode == GRAPH && pan_toggle) begin
            // Set target delay depending on whether a button is pressed
            if (any_btn)
                target_delay <= MIN_DELAY;   // accelerate toward fast
            else
                target_delay <= BASE_DELAY;  // decelerate toward slow

            // Gradually approach target delay (smooth accel/decel)
            if (delay > target_delay)
                delay <= delay - ACCEL_STEP;
            else if (delay < target_delay)
                delay <= delay + DECEL_STEP;

            // Main tick counter
            if (counter >= delay) begin
                counter <= 0;

                // Update pan positions
                if (btnL)      pan_x <= pan_x - scale;
                else if (btnR) pan_x <= pan_x + scale;
                else if (btnU) pan_y <= pan_y + scale;
                else if (btnD) pan_y <= pan_y - scale;
                else if (btnC) begin pan_x <= 0; pan_y <= 0; end

            end else begin
                counter <= counter + 1;
            end

        end else begin
            // reset when not panning
            counter <= 0;
            delay <= BASE_DELAY;
            target_delay <= BASE_DELAY;
        end
    end
endmodule