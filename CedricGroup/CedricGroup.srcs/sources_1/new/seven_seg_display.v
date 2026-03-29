`timescale 1ns / 1ps

module seven_seg_display(
    input clk,                           // Changed from CLK to clk (lowercase)
    input tangent_active,
    input signed [15:0] tangent_x0,
    input signed [15:0] tangent_y0,
    input signed [15:0] tangent_slope,
    output reg [6:0] seg,
    output reg [3:0] an
);
    reg [1:0] digit_sel = 0;
    reg [16:0] counter = 0;
    reg [27:0] mode_counter = 0;
    reg show_c = 0;
    
    wire [6:0] seg_patterns[3:0];
    
    // Clock divider for digit refresh
    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter == 0) begin
            digit_sel <= digit_sel + 1;
        end
    end
    
    // Alternation between m and c
    always @(posedge clk) begin
        if (tangent_active) begin
            mode_counter <= mode_counter + 1;
            if (mode_counter == 200_000_000) begin
                show_c <= ~show_c;
                mode_counter <= 0;
            end
        end else begin
            show_c <= 0;
            mode_counter <= 0;
        end
    end
    
    // Calculate y-intercept: c = y0 - m*x0
    wire signed [31:0] m_times_x0 = tangent_slope * tangent_x0;
    wire signed [31:0] m_times_x0_scaled = m_times_x0 >>> 6;
    wire signed [15:0] y_intercept_scaled = tangent_y0 - m_times_x0_scaled[15:0];
    
    wire signed [15:0] slope_display = tangent_slope >>> 4;
    wire signed [15:0] y_intercept_display = y_intercept_scaled >>> 4;
    
    wire signed [15:0] display_value = show_c ? y_intercept_display : slope_display;
    wire is_negative = display_value[15];
    wire [15:0] abs_value = is_negative ? -display_value : display_value;
    
    wire [3:0] digit_0 = abs_value % 10;
    wire [3:0] digit_1 = (abs_value / 10) % 10;
    wire [3:0] digit_2 = (abs_value / 100) % 10;
    
    wire [4:0] display_codes [3:0];
    
    assign display_codes[0] = tangent_active ? {1'b0, digit_0} : 5'b00011;
    assign display_codes[1] = tangent_active ? {1'b0, digit_1} : 5'b00010;
    assign display_codes[2] = tangent_active ? ((abs_value >= 100) ? {1'b0, digit_2} : 
                              (is_negative ? 5'b10000 : 5'b11111)) : 5'b00001;
    assign display_codes[3] = tangent_active ? (show_c ? 5'b10011 : 5'b10100) : 5'b00000;
    
    seven_seg_decoder dec0(.value(display_codes[0]), .tangent_active(tangent_active), .seg(seg_patterns[0]));
    seven_seg_decoder dec1(.value(display_codes[1]), .tangent_active(tangent_active), .seg(seg_patterns[1]));
    seven_seg_decoder dec2(.value(display_codes[2]), .tangent_active(tangent_active), .seg(seg_patterns[2]));
    seven_seg_decoder dec3(.value(display_codes[3]), .tangent_active(tangent_active), .seg(seg_patterns[3]));
    
    always @(*) begin
        seg = seg_patterns[digit_sel];
        an = ~(1 << digit_sel);
    end
endmodule

module seven_seg_decoder(
    input [4:0] value,
    input tangent_active,
    output reg [6:0] seg
);
    always @(*) begin
        if (!tangent_active) begin
            case(value[3:0])
                4'd0: seg = 7'b0100001; // D
                4'd1: seg = 7'b1001111; // I
                4'd2: seg = 7'b0001110; // F
                4'd3: seg = 7'b0001110; // F
                default: seg = 7'b1111111;
            endcase
        end else begin
            if (value[4]) begin
                case(value[3:0])
                    4'd0: seg = 7'b0111111; // minus
                    4'd1: seg = 7'b1110110; // X
                    4'd2: seg = 7'b0110111; // Y
                    4'd3: seg = 7'b1000110; // C
                    4'd4: seg = 7'b1001000; // M
                    default: seg = 7'b1111111;
                endcase
            end else begin
                case(value[3:0])
                    4'd0: seg = 7'b1000000;
                    4'd1: seg = 7'b1111001;
                    4'd2: seg = 7'b0100100;
                    4'd3: seg = 7'b0110000;
                    4'd4: seg = 7'b0011001;
                    4'd5: seg = 7'b0010010;
                    4'd6: seg = 7'b0000010;
                    4'd7: seg = 7'b1111000;
                    4'd8: seg = 7'b0000000;
                    4'd9: seg = 7'b0010000;
                    default: seg = 7'b1111111;
                endcase
            end
        end
    end
endmodule