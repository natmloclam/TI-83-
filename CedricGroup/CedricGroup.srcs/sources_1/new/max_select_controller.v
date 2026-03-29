`timescale 1ns / 1ps

module max_select_controller(
    input clk,
    input mode,                // GRAPH mode = 1
    input [1:0] sw,            // toggle max-select mode
    input enable_integral,
    input btnC,                // confirm button
    input signed [15:0] cursor_x,
    output reg signed [15:0] x_left = 0, x_right = -10000,
    output reg show_line_left = 0, show_line_right = 0,
    output reg find_enable = 0, // to pass into max_finder
    output reg cursor_active = 1, // normal cursor enabled
    output wire selecting,   // NEW: indicates we're in selection mode
    output wire [1:0] selection_state  // NEW: which limit we're selecting
);
    // FSM states
    localparam IDLE         = 2'd0;
    localparam SELECT_LEFT  = 2'd1;
    localparam SELECT_RIGHT = 2'd2;
    localparam DONE         = 2'd3;
    
    reg sel;
    reg [1:0] state = IDLE;
    reg btnC_prev = 0;
    wire btnC_pressed = btnC && !btnC_prev;
    
    // Continuously update sel based on switches
    always @(*) begin
        sel = (sw == 2'b01 || sw == 2'b10 || enable_integral == 1);
    end
    
    // Output the current state for 7-segment display
    assign selection_state = state;
    assign selecting = (state == SELECT_LEFT || state == SELECT_RIGHT);
    
    always @(posedge clk) begin
        btnC_prev <= btnC;
        
        // Reset if not in GRAPH mode or max-select disabled
        if (mode != 1'b1 || !sel) begin
            state <= IDLE;
            find_enable <= 0;
            show_line_left <= 0;
            show_line_right <= 0;
            cursor_active <= 1;
            x_left <= 0; 
            x_right <= 0; // reset everytime i run this 
        end else begin
            cursor_active <= 0; // normal cursor disabled when sel=1
            
            case(state)
                IDLE: begin
                    find_enable <= 0;
                    show_line_left <= 0;
                    show_line_right <= 0;
                    if (sel) begin
                        state <= SELECT_LEFT;
                    end
                end
                
                SELECT_LEFT: begin
                    show_line_left <= 1;
                    x_left <= cursor_x;  // Continuously update while selecting
                    if (btnC_pressed) begin
                        state <= SELECT_RIGHT;
                    end
                end
                
                SELECT_RIGHT: begin
                    show_line_right <= 1;
                    x_right <= cursor_x;  // Continuously update while selecting
                    if (btnC_pressed) begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    show_line_left <= 1;
                    show_line_right <= 1;
                    find_enable <= 1;
                    cursor_active <= 1;
                    if (!sel) state <= IDLE;
                end
            endcase
        end
    end
endmodule