`timescale 1ps/1ps

module AWMC_tb();
    reg c_in, clk, reset, start, pause,lid;
    wire [2:0] stage;
    wire done;
    wire input_valve;
    wire output_drain;

    AWMC uut(.c_in(c_in),.clk(clk),.reset(reset),.start(start),.pause(pause),.stage(stage),.done(done),.lid(lid),.input_valve(input_valve),.output_drain(output_drain));

    initial begin
        reset = 1'b0;
        #1
        reset = 1'b1;
        #1
        reset = 1'b0;
        c_in = 1'b0;
        forever #5 c_in = ~c_in;
     end
     
    initial begin   
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        start = 1'b0;
        pause = 1'b0;

        #10
        start = 1'b1;
        lid = 1'b1;
        #20
        start = 1'b0;
        #100
        pause = 1'b1;
        lid = 1'b0;
        #105
        pause = 1'b0;
        #110
        start = 1'b1;
        #120 
        start = 1'b0;
        #150
        reset = 1'b0;
        #155
        start = 1'b1;
        lid = 1'b1;
        #160
        start = 1'b0;
        #165
        lid = 1'b1;
        #167
        lid = 1'b0;
        #170
        pause = 1'b0;
        #200
        reset = 1'b1;
        start = 1'b1;
        lid = 1'b1;
        #205
        reset = 1'b0;  
        #240
        start = 1'b0;
        lid = 1'b0;
        #250
        pause = 1'b1;
        #310
        pause = 1'b0;
        lid = 1'b1;
        #360
        lid = 1'b0;

        #400 $finish;

    end

endmodule