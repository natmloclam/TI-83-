module edge_rise (
    input  wire clk,
    input  wire sig,
    output wire rise
);
    reg d = 1'b0;
    always @(posedge clk) d <= sig;
    assign rise = sig & ~d;
endmodule
