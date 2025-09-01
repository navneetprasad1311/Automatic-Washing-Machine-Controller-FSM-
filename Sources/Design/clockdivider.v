module clockdivider(
    input  wire clk,
    input  wire rst,
    output reg  c_out
);

    reg [27:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count  <= 28'd0;
            c_out <= 1'b0;
        end 
        else if (count == 100000000) begin
            count  <= 28'd0;
            c_out <= 1'b1;
        end 
        else begin
            count  <= count + 1;
            c_out <= 1'b0;
        end
    end

endmodule

/*"Clock enables or dedicated clock management resources (MMCM, PLL) must be used 
Logic-derived clocks are not placed on clock routing resources, leading to skew and timing issues."*/