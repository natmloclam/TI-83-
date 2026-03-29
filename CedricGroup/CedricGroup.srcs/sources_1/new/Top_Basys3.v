`timescale 1ns / 1ps

module Top_Basys3 (
    input  wire        CLK_100MHZ,
    input  wire        BTNU, BTND, BTNL, BTNR, BTNC,
    input  wire [15:0] SW,
    output wire [15:0] LED,
    output wire [6:0]  SEG,
    output wire [3:0]  AN,
    output wire        DP,
    output wire [7:0]  JB,
    output wire [7:0]  JA
);
    // ------------------------------------------------------------
    // Pixel clock generation (100 MHz ? 6.25 MHz)
    // ------------------------------------------------------------
    wire clk_6p25mhz;
    clock_divider_generic #(.DIV(8)) div_pix (
        .clk_in (CLK_100MHZ),
        .clk_out(clk_6p25mhz)
    );

    // ------------------------------------------------------------
    // OLED pixel data buses
    // ------------------------------------------------------------
    wire [12:0] pixel_index_left;
    wire [12:0] pixel_index_right;
    wire [15:0] pixel_data_left;
    wire [15:0] pixel_data_right;

    // ------------------------------------------------------------
    // Core logic (Top_Cedric)
    // ------------------------------------------------------------
    Top_Cedric core (
        .CLK_100MHZ       (CLK_100MHZ),
        .clk_6p25mhz      (clk_6p25mhz),
        .BTNU             (BTNU),
        .BTND             (BTND),
        .BTNL             (BTNL),
        .BTNR             (BTNR),
        .BTNC             (BTNC),
        .SW               (SW[15:0]),
        .pixel_index_left (pixel_index_left),
        .pixel_index_right(pixel_index_right),
        .pixel_data_left  (pixel_data_left),
        .pixel_data_right (pixel_data_right),
        .LED             (LED),
        .SEG              (SEG),
        .AN              (AN)
    );

    // Decimal point off (active low)
    assign DP = 1'b1;

    // ------------------------------------------------------------
    // LEFT OLED (JB) - working lab mapping
    // ------------------------------------------------------------
    Oled_Display oled_right (
        .clk           (clk_6p25mhz),
        .reset         (1'b0),
        .frame_begin   (),
        .sending_pixels(),
        .sample_pixel  (),
        .pixel_index   (pixel_index_right),
        .pixel_data    (pixel_data_right),
        .cs            (JB[0]),
        .sdin          (JB[1]),
        .sclk          (JB[3]),
        .d_cn          (JB[4]),
        .resn          (JB[5]),
        .vccen         (JB[6]),
        .pmoden        (JB[7])
    );

    // ------------------------------------------------------------
    // RIGHT OLED (JC) - same mapping order
    // ------------------------------------------------------------
    Oled_Display oled_left (
        .clk           (clk_6p25mhz),
        .reset         (1'b0),
        .frame_begin   (),
        .sending_pixels(),
        .sample_pixel  (),
        .pixel_index   (pixel_index_left),
        .pixel_data    (pixel_data_left),
        .cs            (JA[0]),
        .sdin          (JA[1]),
        .sclk          (JA[3]),
        .d_cn          (JA[4]),
        .resn          (JA[5]),
        .vccen         (JA[6]),
        .pmoden        (JA[7])
    );

endmodule
