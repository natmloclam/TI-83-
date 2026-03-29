// oled_keypad_ui.v
module oled_keypad_ui #(
    parameter integer W       = 96,
    parameter integer H       = 64,
    parameter integer CELL_W  = 18,
    parameter integer CELL_H  = 16,
    parameter [15:0] C_WHITE  = 16'hFFFF,
    parameter [15:0] C_GREY   = 16'h39E7,
    parameter [15:0] C_CYAN   = 16'h07FF,
    parameter [15:0] C_BLACK  = 16'h0000
)(
    input  wire                clk,              // not used (combinational), keep for uniformity
    input  wire [12:0]         pixel_index,      // 0..6143 for 96×64
    input  wire [2:0]          cur_row,          // 0..3
    input  wire [2:0]          cur_col,          // 0..4
    output reg  [15:0]         pixel_data
);

    // -------------------------
    // Helpers: XY from index
    // -------------------------
    wire [6:0] x = pixel_index % W;
    wire [6:0] y = pixel_index / W;

    // Grid origin and inner padding for text
    localparam integer GX0 = 3;   // left margin
    localparam integer GY0 = 0;   // top margin
    localparam integer PAD_X = 6; // text left pad inside cell
    localparam integer PAD_Y = 4; // text top pad inside cell

    // Which cell (col,row) are we in?
    wire [2:0] col = (x >= GX0) ? ((x - GX0) / CELL_W) : 3'd7;  // 0..4 valid, else 7=invalid
    wire [2:0] row = (y >= GY0) ? ((y - GY0) / CELL_H) : 3'd7;  // 0..3 valid, else 7=invalid

    // Inside-cell coords
    wire [5:0] cx = (x >= GX0) ? ((x - GX0) % CELL_W) : 6'd63;
    wire [5:0] cy = (y >= GY0) ? ((y - GY0) % CELL_H) : 6'd63;

    // -------------------------
    // Which key ASCII at (row,col)
    // -------------------------
    function [7:0] key_ascii;
        input [2:0] r, c;
        begin
            case ({r,c})
                {3'd0,3'd0}: key_ascii = "7";
                {3'd0,3'd1}: key_ascii = "8";
                {3'd0,3'd2}: key_ascii = "9";
                {3'd0,3'd3}: key_ascii = "/";   // divide
                {3'd0,3'd4}: key_ascii = "B";   // backspace
                {3'd1,3'd0}: key_ascii = "4";
                {3'd1,3'd1}: key_ascii = "5";
                {3'd1,3'd2}: key_ascii = "6";
                {3'd1,3'd3}: key_ascii = "*";
                {3'd1,3'd4}: key_ascii = "C";   // clear
                {3'd2,3'd0}: key_ascii = "1";
                {3'd2,3'd1}: key_ascii = "2";
                {3'd2,3'd2}: key_ascii = "3";
                {3'd2,3'd3}: key_ascii = "-";
                {3'd2,3'd4}: key_ascii = "^";
                {3'd3,3'd0}: key_ascii = "0";
                {3'd3,3'd1}: key_ascii = "X";   // store X
                {3'd3,3'd2}: key_ascii = "Y";   // store Y
                {3'd3,3'd3}: key_ascii = "+";
                {3'd3,3'd4}: key_ascii = "=";
                default:     key_ascii = " ";
            endcase
        end
    endfunction

    // -------------------------
    // 5×7 font (rowbits for a small subset)
    // returns 5 bits for the given ascii+row (row 0..6)
    // bit[4] is leftmost pixel of the glyph row
    // -------------------------
    function [4:0] glyph_rowbits;
        input [7:0] ascii;
        input [2:0] r;  // 0..6
        begin
            glyph_rowbits = 5'b00000; // default
            case (ascii)
                "0": begin
                    case (r)
                        0: glyph_rowbits = 5'b01110;
                        1: glyph_rowbits = 5'b10001;
                        2: glyph_rowbits = 5'b10011;
                        3: glyph_rowbits = 5'b10101;
                        4: glyph_rowbits = 5'b11001;
                        5: glyph_rowbits = 5'b10001;
                        6: glyph_rowbits = 5'b01110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "1": begin
                    case (r)
                        0: glyph_rowbits = 5'b00100;
                        1: glyph_rowbits = 5'b01100;
                        2: glyph_rowbits = 5'b00100;
                        3: glyph_rowbits = 5'b00100;
                        4: glyph_rowbits = 5'b00100;
                        5: glyph_rowbits = 5'b00100;
                        6: glyph_rowbits = 5'b01110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "2": begin
                    case (r)
                        0: glyph_rowbits = 5'b01110;
                        1: glyph_rowbits = 5'b10001;
                        2: glyph_rowbits = 5'b00001;
                        3: glyph_rowbits = 5'b00010;
                        4: glyph_rowbits = 5'b00100;
                        5: glyph_rowbits = 5'b01000;
                        6: glyph_rowbits = 5'b11111;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "3": begin
                    case (r)
                        0: glyph_rowbits = 5'b11110;
                        1: glyph_rowbits = 5'b00001;
                        2: glyph_rowbits = 5'b00001;
                        3: glyph_rowbits = 5'b01110;
                        4: glyph_rowbits = 5'b00001;
                        5: glyph_rowbits = 5'b00001;
                        6: glyph_rowbits = 5'b11110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "4": begin
                    case (r)
                        0: glyph_rowbits = 5'b00010;
                        1: glyph_rowbits = 5'b00110;
                        2: glyph_rowbits = 5'b01010;
                        3: glyph_rowbits = 5'b10010;
                        4: glyph_rowbits = 5'b11111;
                        5: glyph_rowbits = 5'b00010;
                        6: glyph_rowbits = 5'b00010;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "5": begin
                    case (r)
                        0: glyph_rowbits = 5'b11111;
                        1: glyph_rowbits = 5'b10000;
                        2: glyph_rowbits = 5'b11110;
                        3: glyph_rowbits = 5'b00001;
                        4: glyph_rowbits = 5'b00001;
                        5: glyph_rowbits = 5'b10001;
                        6: glyph_rowbits = 5'b01110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "6": begin
                    case (r)
                        0: glyph_rowbits = 5'b01110;
                        1: glyph_rowbits = 5'b10000;
                        2: glyph_rowbits = 5'b11110;
                        3: glyph_rowbits = 5'b10001;
                        4: glyph_rowbits = 5'b10001;
                        5: glyph_rowbits = 5'b10001;
                        6: glyph_rowbits = 5'b01110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "7": begin
                    case (r)
                        0: glyph_rowbits = 5'b11111;
                        1: glyph_rowbits = 5'b00001;
                        2: glyph_rowbits = 5'b00010;
                        3: glyph_rowbits = 5'b00100;
                        4: glyph_rowbits = 5'b01000;
                        5: glyph_rowbits = 5'b01000;
                        6: glyph_rowbits = 5'b01000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "8": begin
                    case (r)
                        0: glyph_rowbits = 5'b01110;
                        1: glyph_rowbits = 5'b10001;
                        2: glyph_rowbits = 5'b10001;
                        3: glyph_rowbits = 5'b01110;
                        4: glyph_rowbits = 5'b10001;
                        5: glyph_rowbits = 5'b10001;
                        6: glyph_rowbits = 5'b01110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "9": begin
                    case (r)
                        0: glyph_rowbits = 5'b01110;
                        1: glyph_rowbits = 5'b10001;
                        2: glyph_rowbits = 5'b10001;
                        3: glyph_rowbits = 5'b01111;
                        4: glyph_rowbits = 5'b00001;
                        5: glyph_rowbits = 5'b00001;
                        6: glyph_rowbits = 5'b01110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "+": begin
                    case (r)
                        0: glyph_rowbits = 5'b00100;
                        1: glyph_rowbits = 5'b00100;
                        2: glyph_rowbits = 5'b11111;
                        3: glyph_rowbits = 5'b00100;
                        4: glyph_rowbits = 5'b00100;
                        5: glyph_rowbits = 5'b00000;
                        6: glyph_rowbits = 5'b00000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "-": begin
                    case (r)
                        0: glyph_rowbits = 5'b00000;
                        1: glyph_rowbits = 5'b00000;
                        2: glyph_rowbits = 5'b11111;
                        3: glyph_rowbits = 5'b00000;
                        4: glyph_rowbits = 5'b00000;
                        5: glyph_rowbits = 5'b00000;
                        6: glyph_rowbits = 5'b00000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "*": begin
                    case (r)
                        0: glyph_rowbits = 5'b00100;
                        1: glyph_rowbits = 5'b10101;
                        2: glyph_rowbits = 5'b01110;
                        3: glyph_rowbits = 5'b10101;
                        4: glyph_rowbits = 5'b00100;
                        5: glyph_rowbits = 5'b00000;
                        6: glyph_rowbits = 5'b00000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "/": begin
                    case (r)
                        0: glyph_rowbits = 5'b00001;
                        1: glyph_rowbits = 5'b00010;
                        2: glyph_rowbits = 5'b00100;
                        3: glyph_rowbits = 5'b01000;
                        4: glyph_rowbits = 5'b10000;
                        5: glyph_rowbits = 5'b00000;
                        6: glyph_rowbits = 5'b00000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "=": begin
                    case (r)
                        0: glyph_rowbits = 5'b00000;
                        1: glyph_rowbits = 5'b11111;
                        2: glyph_rowbits = 5'b00000;
                        3: glyph_rowbits = 5'b11111;
                        4: glyph_rowbits = 5'b00000;
                        5: glyph_rowbits = 5'b00000;
                        6: glyph_rowbits = 5'b00000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "^": begin
                    case (r)
                        0: glyph_rowbits = 5'b00100;
                        1: glyph_rowbits = 5'b01010;
                        2: glyph_rowbits = 5'b10001;
                        3: glyph_rowbits = 5'b00000;
                        4: glyph_rowbits = 5'b00000;
                        5: glyph_rowbits = 5'b00000;
                        6: glyph_rowbits = 5'b00000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "C": begin
                    case (r)
                        0: glyph_rowbits = 5'b01110;
                        1: glyph_rowbits = 5'b10001;
                        2: glyph_rowbits = 5'b10000;
                        3: glyph_rowbits = 5'b10000;
                        4: glyph_rowbits = 5'b10000;
                        5: glyph_rowbits = 5'b10001;
                        6: glyph_rowbits = 5'b01110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "B": begin
                    case (r)
                        0: glyph_rowbits = 5'b11110;
                        1: glyph_rowbits = 5'b10001;
                        2: glyph_rowbits = 5'b10001;
                        3: glyph_rowbits = 5'b11110;
                        4: glyph_rowbits = 5'b10001;
                        5: glyph_rowbits = 5'b10001;
                        6: glyph_rowbits = 5'b11110;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "X": begin
                    case (r)
                        0: glyph_rowbits = 5'b10001;
                        1: glyph_rowbits = 5'b01010;
                        2: glyph_rowbits = 5'b00100;
                        3: glyph_rowbits = 5'b01010;
                        4: glyph_rowbits = 5'b10001;
                        5: glyph_rowbits = 5'b00000;
                        6: glyph_rowbits = 5'b00000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                "Y": begin
                    case (r)
                        0: glyph_rowbits = 5'b10001;
                        1: glyph_rowbits = 5'b01010;
                        2: glyph_rowbits = 5'b00100;
                        3: glyph_rowbits = 5'b00100;
                        4: glyph_rowbits = 5'b00100;
                        5: glyph_rowbits = 5'b00000;
                        6: glyph_rowbits = 5'b00000;
                        default: glyph_rowbits = 5'b00000;
                    endcase
                end
                default: begin
                    glyph_rowbits = 5'b00000;
                end
            endcase
        end
    endfunction

    // -------------------------
    // Draw
    // -------------------------
    wire valid_cell = (col < 5) && (row < 4);

    // Cell rect
    wire in_grid_x = (x >= GX0) && (x < GX0 + 5*CELL_W);
    wire in_grid_y = (y >= GY0) && (y < GY0 + 4*CELL_H);
    wire in_grid   = in_grid_x && in_grid_y;

    // Cell border (1px)
    wire left_b   = valid_cell && (cx == 0);
    wire right_b  = valid_cell && (cx == CELL_W-1);
    wire top_b    = valid_cell && (cy == 0);
    wire bot_b    = valid_cell && (cy == CELL_H-1);
    wire border   = in_grid && (left_b || right_b || top_b || bot_b);

    // Highlight current cell background
    wire is_sel   = valid_cell && (row == cur_row) && (col == cur_col);

    // Character area inside cell
    wire in_char_box = valid_cell &&
                       (cx >= PAD_X) && (cx < PAD_X + 5) &&
                       (cy >= PAD_Y) && (cy < PAD_Y + 7);

    // Pixel of the glyph (5×7)
    wire [7:0] ascii_here = key_ascii(row,col);
    wire [2:0] glyph_r    = cy - PAD_Y;
    wire [2:0] glyph_c    = cx - PAD_X;
    wire [4:0] glyph_bits;
    assign glyph_bits = glyph_rowbits(ascii_here, glyph_r);
    wire draw_dot = in_char_box && glyph_bits[4 - glyph_c];

    always @* begin
        if (border)
            pixel_data = C_GREY;
        else if (is_sel)
            pixel_data = C_CYAN;
        else if (draw_dot)
            pixel_data = C_WHITE;
        else
            pixel_data = C_BLACK;
    end

endmodule
