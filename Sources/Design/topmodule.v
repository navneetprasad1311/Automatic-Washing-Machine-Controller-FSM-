`timescale 1ns / 1ps

module top_module(
            input c_in,  
                  reset,
                  start,
                  pause,
                  lid,
            output [2:0] stage,
            output done,
            output input_valve,
            output output_drain
    );
    
    wire clk;
    clockdivider clk_div(.c_out(clk),.clk(c_in),.rst(reset));
    AWMC awmc(.c_in(c_in),.clk(clk),.reset(reset),.start(start),.pause(pause),.lid(lid),.stage(stage),.done(done),.input_valve(input_valve),.output_drain(output_drain));
    
endmodule