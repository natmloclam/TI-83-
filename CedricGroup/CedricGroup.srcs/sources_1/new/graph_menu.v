`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2025 12:48:07
// Design Name: 
// Module Name: graph_menu
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


module graph_menu #(
    parameter W   = 96,
    parameter H   = 64,
    parameter BG  = 16'h0000,   // black
    parameter FG  = 16'hFFFF,   // white
    parameter SEL = 16'h07FF    // cyan
)(
    input  wire        clk,
    input [6:0] x, input [5:0] y,
    input  wire [4:0]  sw,     // which of a,b,c,d selected
    input  wire signed [31:0] a_val,
    input  wire signed [31:0] b_val,
    input  wire signed [31:0] c_val,
    input  wire signed [31:0] d_val,
    output reg  [15:0] pixel_data
);

    // --- layout constants ---
    localparam ITEM_H  = 12;   // spacing per line
    localparam X0      = 4;
    localparam CELL_W  = 6;
    localparam CELL_H  = 8;
    localparam Y_INSET = 2;

    
//    localparam ENT_W      = 18;       // width in pixels (text + padding)
//    localparam ENT_H      = 9;       // height in pixels
//    localparam ENT_X      = W - ENT_W - 2; // box position from right
//    localparam ENT_Y      = H - ENT_H - 2;
//    localparam ENT_PAD_X  = 1;        // left padding for text inside box
//    localparam ENT_PAD_Y  = 1;
    
    // which of the 5 lines are we in? (line 0: equation, 1-4: a-d)
    wire [3:0] sel_index;
    assign sel_index = (sw[0]) ? 4'd6 :       // just to avoid highlighting over ENT  
                       (sw[1]) ? 4'd3 :       // D selected
                       (sw[2]) ? 4'd2 :       // C selected
                       (sw[3]) ? 4'd1 :       // B selected
                       (sw[4]) ? 4'd0 :       // A selected
                       4'd6;                  // default disappear

    
    wire [2:0] item_idx = y / ITEM_H;
    wire in_any_item    = (y < 6*ITEM_H);
    wire is_sel         = (item_idx == (sel_index + 1)); // highlight a-d lines
            
    wire is_sel_line = (item_idx == (sel_index + 1)); 
    wire [3:0] y_in_item = y % ITEM_H;
    wire in_highlight = in_any_item && is_sel_line &&
                        (y_in_item >= 1) && (y_in_item <= ITEM_H-2);
                        
//    // ===== ENT box logic ========== // 
//    wire in_ent_box = (x >= ENT_X) && (x < ENT_X + ENT_W) &&
//                      (y >= ENT_Y) && (y < ENT_Y + ENT_H);
//    wire ent_active = sw[0];
    
//    // relative coordinates inside ENT box - ONLY compute when inside
//    wire [4:0] ex = x - ENT_X - ENT_PAD_X; 
//    wire [3:0] ey = y - ENT_Y - ENT_PAD_Y;             
    
//    wire in_ent_text_area = in_ent_box && 
//                            (x >= ENT_X + ENT_PAD_X) && 
//                            (y >= ENT_Y + ENT_PAD_Y);
//    // which letter
//    wire [1:0] ent_col = ex / CELL_W;      
//    wire [2:0] ent_fx  = ex % CELL_W;      
//    wire [2:0] ent_fy  = ey[2:0]; 
    
//    // only draw if inside glyph bounds AND inside box
//    wire ent_valid = in_ent_box && (ent_fx < 5) && (ent_fy < 7) && (ent_col < 3);
    
    
    // --- 5×7 font ---
    function [34:0] glyph_bitmap;
        input [7:0] ch;
        begin
            case (ch)
                "A": glyph_bitmap = 35'b01110_10001_11111_10001_10001_10001_10001;
                "B": glyph_bitmap = 35'b11110_10001_10001_11110_10001_10001_11110;
                "C": glyph_bitmap = 35'b01111_10000_10000_10000_10000_10000_01111;
                "D": glyph_bitmap = 35'b11110_10001_10001_10001_10001_10001_11110;
                "E": glyph_bitmap = 35'b11111_10000_11111_10000_10000_10000_11111;
                "G": glyph_bitmap = 35'b01111_10000_10000_10011_10001_10001_01110;
                "H": glyph_bitmap = 35'b10001_10001_11111_10001_10001_10001_10001;
                "I": glyph_bitmap = 35'b01110_00100_00100_00100_00100_00100_01110;
                "L": glyph_bitmap = 35'b10000_10000_10000_10000_10000_10000_11111;
                "N": glyph_bitmap = 35'b10001_11001_10101_10011_10001_10001_10001;
                "P": glyph_bitmap = 35'b11110_10001_10001_11110_10000_10000_10000;
                "R": glyph_bitmap = 35'b11110_10001_10001_11110_10100_10010_10001;
                "S": glyph_bitmap = 35'b01110_10001_10000_01110_00001_10001_01110;
                "T": glyph_bitmap = 35'b11111_00100_00100_00100_00100_00100_00100;
                "V": glyph_bitmap = 35'b10001_10001_10001_10001_01010_01010_00100;
                "Y": glyph_bitmap = 35'b10001_10001_01010_00100_00100_00100_00100;
                "X": glyph_bitmap = 35'b10001_10001_01010_00100_01010_10001_10001;
                "W": glyph_bitmap = 35'b10001_10001_10001_10101_10101_10101_01010;
                "3": glyph_bitmap = 35'b11111_00001_00110_00001_00001_00001_11111;
                "+": glyph_bitmap = 35'b00000_00100_00100_11111_00100_00100_00000;
                "-": glyph_bitmap = 35'b00000_00000_00000_11111_00000_00000_00000;
                "=": glyph_bitmap = 35'b00000_00000_11111_00000_11111_00000_00000;
                "^": glyph_bitmap = 35'b00100_01010_10001_00000_00000_00000_00000;
                " ": glyph_bitmap = 35'b00000_00000_00000_00000_00000_00000_00000;
                "0": glyph_bitmap = 35'b01110_10001_10011_10101_11001_10001_01110;
                "1": glyph_bitmap = 35'b00100_01100_00100_00100_00100_00100_01110;
                "2": glyph_bitmap = 35'b01110_10001_00010_00100_01000_10000_11111;
                "4": glyph_bitmap = 35'b10001_10001_11111_00001_00001_00001_00001;
                "5": glyph_bitmap = 35'b11111_10000_11110_00001_00001_00001_11111;
                "6": glyph_bitmap = 35'b01110_10000_11110_10001_10001_10001_01110;
                "7": glyph_bitmap = 35'b11111_00010_00100_01000_01000_01000_01000;
                "8": glyph_bitmap = 35'b01110_10001_01110_10001_10001_10001_01110;
                "9": glyph_bitmap = 35'b01110_10001_10001_01111_00001_00001_01110;
                "[": glyph_bitmap = 35'b11100_00100_11100_00100_11100_00000_00000;
                "]": glyph_bitmap = 35'b11100_00100_11100_10000_11100_00000_00000;
                default: glyph_bitmap = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction

    function glyph_on;
        input [7:0] ch;
        input [2:0] fx, fy;
        reg [34:0] bits;
        integer idx;
        begin
            bits = glyph_bitmap(ch);
            idx  = fy*5 + fx;
            glyph_on = bits[34-idx];
        end
    endfunction

    // --- helper: convert signed 8-bit to two chars ---
    function [15:0] num_to_chars;
        input signed [7:0] num;
        reg signed [7:0] absval;
        reg [3:0] tens, ones;
        begin
            absval = (num < 0) ? -num : num;
            tens = absval / 10;
            ones = absval % 10;
            num_to_chars[15:8] = (num < 0) ? "-" : (tens ? ("0" + tens) : " ");
            num_to_chars[7:0]  = "0" + ones;
        end
    endfunction

    // --- line text generator ---
    function [7:0] char_at;
        input [2:0] idx;
        input [5:0] col;
        reg [15:0] numch;
        begin
            case (idx)
                // Line 0: "y = ax^3 + bx^2 + cx + d"
                3'd0: begin
                    case (col)
                        0: char_at = "Y";
                        1: char_at = "=";
                        2: char_at = "A";
                        3: char_at = "X";
                        4: char_at = "[";
                        5: char_at = "+";
                        6: char_at = "B";
                        7: char_at = "X";
                        8: char_at = "]";
                        9: char_at = "+";
                        10: char_at = "C";
                        11: char_at = "X";
                        12: char_at = "+";
                        13: char_at = "D";
                        default: char_at = " ";
                    endcase
                end
                // Lines 1-4: coefficients
                3'd1: begin 
                    numch = num_to_chars(a_val); 
                    case(col)
                        0 : char_at = "A";
                        1 : char_at = " ";
                        2 : char_at = "=";
                        3 : char_at = " ";
                        4 : char_at = numch[15:8];
                        5 : char_at = numch[7:0]; 
                        default : char_at = " "; 
                    endcase 
                end
                3'd2: begin 
                    numch = num_to_chars(b_val); 
                    case(col)
                        0 : char_at = "B";
                        1 : char_at = " ";
                        2 : char_at = "=";
                        3 : char_at = " ";
                        4 : char_at = numch[15:8];
                        5 : char_at = numch[7:0]; 
                        default : char_at = " "; 
                    endcase 
                end
                3'd3: begin 
                    numch = num_to_chars(c_val); 
                    case(col)
                        0 : char_at = "C"; 
                        1 : char_at = " ";
                        2 : char_at = "=";
                        3 : char_at = " ";
                        4 : char_at = numch[15:8];
                        5 : char_at = numch[7:0]; 
                        default : char_at = " "; 
                    endcase 
                end
                3'd4: begin 
                    numch = num_to_chars(d_val); 
                    case(col)
                        0 : char_at = "D";
                        1 : char_at = " ";
                        2 : char_at = "=";
                        3 : char_at = " ";
                        4 : char_at = numch[15:8];
                        5 : char_at = numch[7:0];
                        default : char_at = " "; 
                    endcase 
                end
                default: char_at = " ";
            endcase
        end
    endfunction

    // --- text rendering ---
    wire in_text_box = (x >= X0) && (x < W-8) &&
                       (y_in_item >= Y_INSET) && (y_in_item < Y_INSET + CELL_H);
    wire [5:0] col = (x - X0) / CELL_W;
    wire [2:0] fx  = (x - X0) % CELL_W;
    wire [2:0] fy  = (y_in_item - Y_INSET);
    wire in_font_core = (fx < 5) && (fy < 7);

    reg [7:0] ch;
    always @(*) begin
        if (in_text_box)
            ch = char_at(item_idx, col);
        else
            ch = " ";
    end

//    reg [7:0] ent_ch;
//    always @(*) begin
//        if (in_ent_text_area) begin  // ADD THIS CHECK
//            case(ent_col)
//                0: ent_ch = "E";
//                1: ent_ch = "N";
//                2: ent_ch = "T";
//                default: ent_ch = " ";
//            endcase
//        end else begin
//            ent_ch = " ";  // Default when outside box
//        end
//    end
    
    wire pix_txt = in_text_box && in_font_core && glyph_on(ch, fx, fy);
//    wire in_ent_box_bg = in_ent_box && sw[0];
    
    // Use ent_valid which already includes in_ent_box check
//    wire pix_ent = ent_valid && glyph_on(ent_ch, ent_fx, ent_fy);
    
    
    always @(*) begin
        if (pix_txt)
            pixel_data = FG;           // main text
//        else if (pix_ent)
//            pixel_data = FG;           // ENT letters
//        else if (in_ent_box_bg)
//            pixel_data = SEL;          // ENT box background
        else if (in_highlight)
            pixel_data = SEL;          // highlight selected line
        else
            pixel_data = BG;
    end

endmodule