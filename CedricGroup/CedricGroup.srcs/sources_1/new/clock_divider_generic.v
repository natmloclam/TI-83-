module clock_divider_generic #(parameter DIV = 1) (
    input  wire clk_in,
    output reg  clk_out = 1'b0
);
    reg [31:0] ctr = 0;
    always @(posedge clk_in) begin
        if (ctr == DIV-1) begin
            ctr <= 0;
            clk_out <= ~clk_out; // output freq = F_in / (2*DIV)
        end else begin
            ctr <= ctr + 1;
        end
    end
endmodule
