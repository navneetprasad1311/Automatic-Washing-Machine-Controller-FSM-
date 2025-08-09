# 🚿 Automatic Washing Machine Controller FSM

## 📌 Project Overview
This project implements a **Finite State Machine (FSM)** based controller for a **semi-automatic washing machine** using Verilog HDL. It simulates the sequential stages of the wash cycle and handles input signals like **start**, **pause**, **reset**, and **lid status**, with control outputs for **input valve** and **drain valve**.

![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/592fc4520df82c05d8770f3bcbafaf5553a9cdbc/Images/Zedboard.jpeg)

---

## ✏️ Problem Statement 

<pre>Design an FSM to simulate the working of a semi-automatic washing machine with the following operations:
        Fill → Wash → Rinse → Spin → Stop

        Each stage takes a fixed number of cycles

        Machine should respond to start, pause, and reset signals.

        Inputs:
            clk, reset, start, pause

        Outputs:
            stage[2:0] → Indicates current stage
            done → High when complete
            
        States:
            IDLE 
            FILL 
            WASH
            RINSE
            SPIN 
            STOP
  </pre>

  Additionally we included lid safety mechanism (`lid`) where the machine pauses automatically if the lid is opened during certain stages (e.g., Wash, Rinse, Spin) and valves (`input_valve`  `output_drain`) that open or close for a fixed number of clock cycles in those stages to control water flow.

---

## ⚙️ Features

- **FSM Stages**:
  - `IDLE → FILL → WASH → RINSE → SPIN → STOP`
- Each stage runs for a fixed time (defined by counters).
- Responds to:
  - `start` – Begins the washing process
  - `pause` – Temporarily halts operation
  - `reset` – Aborts current operation and returns to `IDLE`
  - `lid` – Lid must be closed for certain operations
- Controls:
  - `input_valve` – Lets water in
  - `output_drain` – Drains water out
- `done` output signal goes high when the washing cycle completes.

---

## 🛠️ Tools And Hardware

- Software: Vivado ML Edition (Standard) 2024.2
- Hardware: ZedBoard Zynq-7000 ARM / FPGA SoC Development Board

---

## 📥 Inputs

| Signal | Width | Description |
|--------|-------|-------------|
| `clk` | 1-bit | Clock input |
| `reset` | 1-bit | Asynchronous reset |
| `start` | 1-bit | Start washing |
| `pause` | 1-bit | Pause washing |
| `lid` | 1-bit | Lid status (1 = open) |

---

## 📤 Outputs

| Signal | Width | Description |
|--------|-------|-------------|
| `stage` | 3-bit | Current FSM stage |
| `done` | 1-bit | Indicates completion |
| `input_valve` | 1-bit | Controls water intake |
| `output_drain` | 1-bit | Controls water drainage |

---

## 🧠 FSM States

| State | Encoding | Function |
|-------|----------|----------|
| `IDLE` | 111 | Waits for start or resume |
| `FILL` | 000 | Water fills with lid closed |
| `WASH` | 001 | Drum rotates to wash |
| `RINSE` | 010 | Periodic refill and drain |
| `SPIN` | 011 | Water drained and spun |
| `STOP` | 100 | Final stage before done |

---

## 🔁 FSM Transition Logic

- If `pause` is pressed, the system enters `IDLE` and stores the previous state.
- `lid` is open during **FILL**, system waits until lid is closed.
- In **RINSE**, valve toggles periodically between drain and fill.
- After **SPIN**, system goes to **STOP** and then `done` is asserted.

---

## 🖼️ FSM State Diagram 

![image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/State%20Diagram.png)

## 🎨 design.v
<pre> module AWMC(input clk,  
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

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count <= 2'b00;
            case (stage)
                WASH : begin
                    if(input_valve == 1'b1) begin
                        input_valve <= 1'b0;
                        if(count < VALVE_DURATION) begin
                                output_drain <= 1'b1;
                                count++;
                        end
                        else begin
                                output_drain <= 1'b0;
                                count <= 2'b00;
                        end
                    end
                    else begin
                        input_valve <= 1'b0;
                        output_drain <= 1'b0;
                    end
                end
                RINSE : begin
                    if(input_valve == 1'b1 || output_drain == 1'b1) begin
                        input_valve <= 1'b0;
                        if(count < VALVE_DURATION) begin
                                output_drain <= 1'b1;
                                count++;
                        end
                        else begin
                                output_drain <= 1'b0;
                                count <= 2'b00;
                        end
                    end
                end
                SPIN : begin
                    if(output_drain == 1'b1) begin
                        if(count < VALVE_DURATION) begin
                                output_drain <= 1'b1;
                                count++;
                        end
                        else begin
                                output_drain <= 1'b0;
                                count <= 2'b00;
                        end
                    end
                end
                default : begin
                    input_valve <= 1'b0;
                    output_drain <= 1'b0;
                end
            endcase
            stage <= IDLE;
            prev_state <= IDLE;
            running <= 1'b0;
            lidcond <= 1'b0;
            paused <= 1'b0;
            done <= 1'b0; 
        end
        else begin
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
                if(prev_state == FILL && lid) begin
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
endmodule </pre>

---

## 📝 Testbench
<pre>`timescale 1ps/1ps

module AWMC_tb();
    reg clk, reset, start, pause, lid;
    wire [2:0] stage;
    wire done;
    wire input_valve;
    wire output_drain;

    AWMC uut(.clk(clk),.reset(reset),.start(start),.pause(pause),.stage(stage),.done(done),.lid(lid),.input_valve(input_valve),.output_drain(output_drain));

    initial begin
        reset = 1'b0;
        #1
        reset = 1'b1;
        #1
        reset = 1'b0;
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

endmodule</pre>

---

## 🧪 Simulation 

📸 **Waveform**: ![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/Waveform.jpg)

---

## 🔍 Overview


### 📂 File Structure

![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/File%20Structure.jpg)

---

### ⚙️ Schematic View 

![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/Schematic%20View.png)


### ⏹️ Technology View

![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/Technology%20View.jpg)

---

### 🔌 Pin Assignment

![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/Pin%20Assignment.jpg)

---

### ⛓️ Resource Utilization (Post-Implementation)

![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/Resource%20Utilisation.jpg)
![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/Resource%20Utilisation%202.png)

---

### ⏱️ Timing Summary

![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/Timing%20Summary.jpg)

---

### ⚡ Power Summary

![Image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/87b593b565084cfb3729c1ad1eeb0b6131b790ac/Images/Power%20Summary.jpg)

---

## 💫 Implementation

![image](https://github.com/navneetprasad1311/Automatic-Washing-Machine-Controller-FSM-/blob/592fc4520df82c05d8770f3bcbafaf5553a9cdbc/Images/Zedboard.jpeg)


[FPGA Implementation Video]()

---

## 👥 Contributors

[Navneet Prasad]()

[Akash P]( )

## Notes

Working on this FSM project was a great learning experience. We learned how to break a problem into clear states, plan transitions, and implement them effectively. Along the way, we improved our debugging skills, understood the value of systematic design, and gained confidence in applying FSM concepts to real-world problems. Overall, it was both challenging and rewarding.
