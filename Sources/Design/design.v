module AWMC(input c_in,
                  clk,  
                  reset,
                  start,
                  pause,
                  lid,
            output reg [2:0] stage,
            output reg done,
            output reg input_valve,
            output reg output_drain);

    parameter IDLE  = 3'b111,
              FILL  = 3'b000,
              WASH  = 3'b001,
              RINSE = 3'b010,
              SPIN  = 3'b011,
              STOP  = 3'b100,
              TIMER = 4'd10,
              VALVE_DURATION = 2'd2;


    reg [2:0] prev_state = IDLE;
    reg [3:0] count = 4'd0;
    reg running = 1'b0;
    reg paused = 1'b0;
    reg times = 1'b0;
    reg lidcond = 1'b0;
    reg pauser = 1'b0;

    always @(posedge c_in or posedge reset) begin
        if(reset) begin
            count <= 4'd0;
            input_valve <= 1'b0;
            output_drain <= 1'b0;
            stage <= IDLE;
            prev_state <= IDLE;
            running <= 1'b0;
            lidcond <= 1'b0;
            paused <= 1'b0;
            done <= 1'b0; 
        end
        else if(clk) begin
            if(pause) begin
                running <= 1'b0;
                if(stage != IDLE) 
                    prev_state <= stage;
                stage <= IDLE;
                paused <= 1'b1;
                input_valve <= 1'b0;
                output_drain <= 1'b0;
            end
            else if(pauser) begin
                if(stage != IDLE) 
                    prev_state <= stage;
                else if(prev_state == FILL && lid) begin
                    lidcond <= 1'b1;
                    pauser <= 1'b0;
                    times <= 1'b1;
                end
                else if((prev_state == WASH || prev_state == RINSE || prev_state == SPIN) && !lid) begin
                    lidcond <= 1'b1;
                    pauser <= 1'b0;
                end
                running <= 1'b0;
                stage <= IDLE;
                input_valve <= 1'b0;
                output_drain <= 1'b0;
            end

            else if(start || ((running || paused || lidcond) && !done)) begin
                running <= 1'b1;
                done <= 1'b0;
                if(count < TIMER) begin
                    count <= count + 1;
                end

                case (stage)
                    IDLE : begin
                        input_valve <= 1'b0;
                        output_drain <= 1'b0;
                        if(start && (!paused || !lidcond) && lid) begin
                            stage <= FILL;
                        end
                        if(paused || lidcond) begin
                            stage <= prev_state;
                            paused <= 1'b0;
                            lidcond <= 1'b0;
                        end 
                    end
                    FILL: begin
                        input_valve <= 1'b0;
                        output_drain <= 1'b0;
                        if(lid && !times)
                            pauser <= 1'b1;
                        else if(!pauser && !lid) begin
                            if (count == TIMER) begin
                                stage <= WASH;
                                count <= 4'd0;
                            end
                        end
                    end
                    WASH: begin
                        if(lid) begin
                            pauser <= 1'b1;
                        end
                        else if(!pauser) begin
                            if (count == TIMER) begin
                                stage <= RINSE;
                                count <= 4'd0;
                            end
                            else begin
                                output_drain <= 1'b0;
                                if(count < VALVE_DURATION)
                                    input_valve <= 1'b1;
                                else
                                    input_valve <= 1'b0;  
                            end 
                        end    
                    end
                    RINSE: begin
                        if(lid) begin
                            pauser <= 1'b1;
                        end
                        else if(!pauser) begin
                            if (count == TIMER) begin
                                stage <= SPIN;
                                count <= 4'd0;
                            end
                            else begin
                                case (count) 
                                    4'd0: begin input_valve <= 1'b0 ; output_drain <= 1'b1; end
                                    4'd2: begin input_valve <= 1'b1 ; output_drain <= 1'b0; end
                                    4'd4: begin input_valve <= 1'b0 ; output_drain <= 1'b1; end
                                    4'd6: begin input_valve <= 1'b1 ; output_drain <= 1'b0; end
                                    4'd8: begin input_valve <= 1'b0 ; output_drain <= 1'b1; end
                                    4'd10:begin input_valve <= 1'b0 ; output_drain <= 1'b1; end
                                endcase
                            end
                        end
                    end
                    SPIN: begin
                        if(lid) begin
                            pauser <= 1'b1;
                        end
                        else if(!pauser) begin
                            if (count == TIMER) begin
                                stage <= STOP;

                                count <= 4'd0;
                            end
                            else begin
                                input_valve <= 1'b0;
                                if(count < VALVE_DURATION)
                                    output_drain <= 1'b1;
                                else
                                    output_drain <= 1'b0;
                            end
                        end
                    end
                    STOP : begin
                        input_valve <= 1'b0;
                        output_drain <= 1'b0;
                        done <= 1'b1;
                        running <= 1'b0;
                        stage <= IDLE;
                    end
                endcase
            end 
        end
    end
endmodule