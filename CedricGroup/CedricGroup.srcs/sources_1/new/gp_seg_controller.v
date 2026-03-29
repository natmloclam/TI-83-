`timescale 1ns / 1ps

module gp_seg_controller(
    input clk,                  // e.g. 1 kHz refresh clock
    input mode,                 // 0 = MENU, 1 = GRAPH
    input signed [15:0] cursor_x,
    input signed [15:0] cursor_y,
    
    input signed [31:0] integral_value, 
    input integral_done,
    
    // New inputs for showing limits during selection
    input integral_selecting,        // High during limit selection
    input [1:0] selection_state,     // Which state: 0=IDLE, 1=LEFT, 2=RIGHT, 3=DONE
    input enable_integral_mode,      // NEW: indicates we're in integral mode at all
    
    output reg [3:0] an = 4'b1111,
    output reg [6:0] seg = 7'b1111111
);
    parameter MENU  = 0;
    parameter GRAPH = 1;
    
    // Selection states
    localparam IDLE         = 2'd0;
    localparam SELECT_LEFT  = 2'd1;
    localparam SELECT_RIGHT = 2'd2;
    localparam DONE         = 2'd3;

    reg [1:0] count = 0;

    // 2-second toggle for X/Y display (only when not selecting limits and not integral mode)
    reg [10:0] sec_count = 0;
    reg show_x = 1;

    always @(posedge clk) begin
        if (!integral_done && !integral_selecting && !enable_integral_mode) begin
            sec_count <= sec_count + 1;
            if (sec_count >= 2000) begin // 2 seconds @ 1kHz
                sec_count <= 0;
                show_x <= ~show_x;
            end
        end else begin
            sec_count <= 0;
            show_x <= 1; 
        end
    end
    
    // Convert integral value to 1 decimal place
    wire signed [31:0] int_scaled = integral_value >>> 4;  // Divide by 16 for integer part
    wire signed [31:0] int_abs_raw = (int_scaled < 0) ? -int_scaled : int_scaled;
    wire signed [31:0] int_remainder = (integral_value < 0) ? -(integral_value - (int_scaled <<< 4)) : (integral_value - (int_scaled <<< 4));
    wire signed [31:0] decimal_digit_raw = (int_remainder * 10) >>> 4;
    
    wire int_negative = int_scaled < 0;
    wire [15:0] int_abs = int_abs_raw[15:0];
    wire [3:0] dec_abs = (decimal_digit_raw < 0) ? -decimal_digit_raw[3:0] : decimal_digit_raw[3:0];
    
    wire [3:0] int_hundreds = (int_abs / 100) % 10;
    wire [3:0] int_tens = (int_abs / 10) % 10;
    wire [3:0] int_ones = int_abs % 10;

    // Round and scale cursor coordinates to nearest integer
    wire signed [15:0] x_int = (cursor_x >= 0) ? ((cursor_x + 8) >>> 4) : ((cursor_x - 8) >>> 4);
    wire signed [15:0] y_int = (cursor_y >= 0) ? ((cursor_y + 8) >>> 4) : ((cursor_y - 8) >>> 4);

    // Choose displayed value
    reg signed [15:0] disp_val;
    reg [7:0] prefix;  // ASCII for X, Y, or L

    // sign detection 
    wire is_negative = disp_val < 0;
    wire [15:0] abs_val = is_negative ? -disp_val : disp_val;

    always @(*) begin
        if (mode == GRAPH && enable_integral_mode && integral_selecting && selection_state == SELECT_LEFT) begin
            // During LEFT limit selection, show "L=xx" (left limit x coordinate)
            disp_val = x_int;
            prefix = "L";
        end else if (mode == GRAPH && enable_integral_mode && integral_selecting && selection_state == SELECT_RIGHT) begin
            // During RIGHT limit selection, show "R=xx" (right limit x coordinate)
            disp_val = x_int;
            prefix = "R";
        end else if (mode == GRAPH && enable_integral_mode && integral_done && selection_state == DONE) begin
            // Show integral result
            disp_val = 0;
            prefix = " ";
        end else if (mode == GRAPH && !enable_integral_mode) begin
            // Normal graph mode - alternate X/Y
            if (show_x) begin
                disp_val = x_int;
                prefix = "X";
            end else begin
                disp_val = y_int;
                prefix = "Y";
            end
        end else begin
            disp_val = 0;
            prefix = " ";
        end
    end

    // Extract decimal digits (two least significant)
    wire [3:0] tens = (abs_val / 10) % 10;
    wire [3:0] ones = abs_val % 10;

    // 7-segment decoder (common anode)
    function [6:0] seg_decode;
        input [3:0] num;
        begin
            case(num)
                4'd0: seg_decode = 7'b1000000;
                4'd1: seg_decode = 7'b1111001;
                4'd2: seg_decode = 7'b0100100;
                4'd3: seg_decode = 7'b0110000;
                4'd4: seg_decode = 7'b0011001;
                4'd5: seg_decode = 7'b0010010;
                4'd6: seg_decode = 7'b0000010;
                4'd7: seg_decode = 7'b1111000;
                4'd8: seg_decode = 7'b0000000;
                4'd9: seg_decode = 7'b0010000;
                default: seg_decode = 7'b1111111;
            endcase
        end
    endfunction

    function [6:0] seg_letter;
        input [7:0] ch;
        begin
            case (ch)
                "X": seg_letter = 7'b0001001; // custom X
                "Y": seg_letter = 7'b0010001; // custom Y
                "L": seg_letter = 7'b1000111; // custom L
                "R": seg_letter = 7'b0101111; // custom r
                "-": seg_letter = 7'b0111111; // negative sign "-"
                default: seg_letter = 7'b1111111;
            endcase
        end
    endfunction

    // Display logic
    always @(posedge clk) begin
        count <= count + 1;

        if (mode == MENU) begin
            // MENU MODE: show "GrPH"
            case (count)
                2'd0: begin an <= 4'b0111; seg <= 7'b100_0010; end // G
                2'd1: begin an <= 4'b1011; seg <= 7'b010_1111; end // r
                2'd2: begin an <= 4'b1101; seg <= 7'b000_1100; end // P
                2'd3: begin an <= 4'b1110; seg <= 7'b000_1001; end // H
            endcase
        
        end else if (mode == GRAPH && enable_integral_mode && integral_done && selection_state == DONE) begin
            // INTEGRAL MODE: show value with 1 decimal place
            // Format: [sign/hundreds] [tens] [ones] [decimal]
                        
            if (int_abs < 1000) begin  // Can fit in display
                case (count)
                    2'd0: begin 
                        an <= 4'b0111;
                        // Leftmost digit: show negative sign, hundreds, or blank
                        if (int_negative && int_hundreds == 0) begin
                            seg <= seg_letter("-");
                        end else if (int_hundreds != 0) begin
                            seg <= seg_decode(int_hundreds);
                        end else begin
                            seg <= 7'b1111111;  // Blank leading zero
                        end
                    end
                    2'd1: begin 
                        an <= 4'b1011;
                        // Second digit: show tens (suppress only if both hundreds and tens are zero)
                        if (int_hundreds == 0 && int_tens == 0) begin
                            seg <= 7'b1111111;
                        end else begin
                            seg <= seg_decode(int_tens);
                        end
                    end
                    2'd2: begin 
                        an <= 4'b1101;
                        // Third digit: ones (always show)
                        seg <= seg_decode(int_ones);
                    end
                    2'd3: begin 
                        an <= 4'b1110; 
                        // Fourth digit: decimal place
                        seg <= seg_decode(dec_abs);
                    end
                endcase
            end else begin
                // Number too large (>= 1000), show "Err"
                case (count)
                    2'd0: begin an <= 4'b0111; seg <= 7'b1111111; end // blank
                    2'd1: begin an <= 4'b1011; seg <= 7'b0000110; end // E
                    2'd2: begin an <= 4'b1101; seg <= 7'b0101111; end // r
                    2'd3: begin an <= 4'b1110; seg <= 7'b0101111; end // r
                endcase
            end

        end else if (mode == GRAPH) begin
            // GRAPH MODE or LIMIT SELECTION: show "X=##", "Y=##", "L=##", or "R=##"
            case (count)
                2'd0: begin an <= 4'b0111; seg <= seg_letter(prefix); end  // X, Y, L, or R
                2'd1: begin an <= 4'b1011; seg <= is_negative ? seg_letter("-") : 7'b1111111; end // show '-' or blank
                2'd2: begin an <= 4'b1101; seg <= seg_decode(tens); end   // tens
                2'd3: begin an <= 4'b1110; seg <= seg_decode(ones); end   // ones
            endcase

        end else begin
            an <= 4'b1111;
            seg <= 7'b1111111;
        end
    end
endmodule