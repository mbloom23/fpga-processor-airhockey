`timescale 1ns / 1ps
module dig_clock(clk, reset, m, s10, s1);
    input clk, reset;
    output [31:0] s1;
    output [31:0] s10;
    output [31:0] m;
    reg [31:0] s1;
    reg [31:0] s10;
    reg [31:0] m;

    reg sclk;
    reg[31:0] counter;
    initial begin
        counter = 0;
        sclk = 0;
    end
    always @(posedge(clk)) begin
        if(counter == 0) begin
            counter <= 49999999;
            sclk <= ~sclk;
        end else begin
            counter <= counter - 1;
        end
    end
    always @(posedge(sclk) or posedge(reset))
    begin
        if(reset == 1'b1) begin 
            s1 = 0;
            s10 = 0;
            m = 2;
        end else if(m == 0 & s10 == 0 & s1 == 0) begin
        end
        else if(sclk == 1'b1) begin 
            s1 = s1 - 1; 
            if(s1 == -1) begin
                s1 = 9;
                s10 = s10 - 1;
                if(s10 == -1) begin
                    s10 = 5;
                    m = m - 1;
                end     
            end
        end
    end     
endmodule