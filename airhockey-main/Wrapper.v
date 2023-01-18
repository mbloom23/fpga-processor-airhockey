`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to generate the bitstream to upload to the FPGA.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v and memory modules to work with the 
 * provided Wrapper interface.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must change line 36 to add the memory file of the test you created using the assembler
 * For example, you would add sample inside of the quotes on line 38 after assembling sample.s
 *
 **/

module Wrapper (clock100, reset, out, VGA_B, VGA_R, VGA_G, ps2_clk, ps2_data, hSync, vSync, break1, break2, p1LEDout, p2LEDout, audioOut, audioEn);
	input clock100, reset, break1, break2;
	output hSync, vSync, audioOut, audioEn;
	output reg p1LEDout, p2LEDout;
	output[3:0] VGA_B, VGA_R, VGA_G;
	output[7:0] out;
	inout ps2_clk, ps2_data;
	wire rwe, mwe, hSync, vSync, soundON, p1LED, p2LED;
	wire[4:0] rd, rs1, rs2; 
	wire[31:0] instAddr, instData, rData, regA, regB, memAddr, memDataIn, memDataOut, score1, score2, time1, time2, time3, m, s10, s1, rsc1, rsc2, reg3, reg4;
    reg clk;
    reg[31:0] counter;

    initial begin
        counter = 0;
        clk = 0;
    end
    always @(posedge(clock100)) begin
        if(counter == 0) begin
            counter <= 3;
            clk <= ~clk;
        end else begin
            counter <= counter - 1;
        end
    end

    reg[31:0] LEDcounter1;
	initial begin
		LEDcounter1 = 50000000;
		p1LEDout = 0;
	end
    always @(posedge(clk) or posedge(reset)) begin
		if(reset == 1'b1) begin
			p1LEDout <= 0;
			p2LEDout <= 0;
		end else if(LEDcounter1 == 50000000 & p1LED == 1) begin
			p1LEDout <= 1;
			LEDcounter1 <= LEDcounter1 - 1;
        end else if(LEDcounter1 == 0) begin
			LEDcounter1 <= 50000000;
			p1LEDout <= 0;
		end else if(LEDcounter1 < 50000000) begin
            LEDcounter1 <= LEDcounter1 - 1;
		end
    end

	reg[31:0] LEDcounter2;
	initial begin
		LEDcounter2 = 50000000;
		p2LEDout = 0;
	end
    always @(posedge(clk) or posedge(reset)) begin
		if(reset == 1'b1) begin
			p1LEDout <= 0;
			p2LEDout <= 0;
		end else if(LEDcounter2 == 50000000 & p2LED == 1) begin
			p2LEDout <= 1;
			LEDcounter2 <= LEDcounter2 - 1;
        end else if(LEDcounter2 == 0) begin
			LEDcounter2 <= 50000000;
			p2LEDout <= 0;
		end else if(LEDcounter2 < 50000000) begin
            LEDcounter2 <= LEDcounter2 - 1;
		end
    end

	dig_clock TIME(clock100, reset, m, s10, s1);
	assign score1 = rsc1;
	assign score2 = rsc2;
	assign time1 = m;
	assign time2 = s10;
	assign time3 = s1;
    segment7 SEG(p1LED, out);
	localparam INSTR_FILE = "gamecontrol";
	processor CPU(.clock(clk), .reset(reset), .address_imem(instAddr), .q_imem(instData), .ctrl_writeEnable(rwe), .ctrl_writeReg(rd), .ctrl_readRegA(rs1), .ctrl_readRegB(rs2), .data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB), .wren(mwe), .address_dmem(memAddr), .data(memDataIn), .q_dmem(memDataOut)); 
	
	ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
	InstMem(.clk(clk), 
		.addr(instAddr[11:0]), 
		.dataOut(instData));

	regfile RegisterFile(.clock(clk), 
		.ctrl_writeEnable(rwe), .ctrl_reset(reset), 
		.ctrl_writeReg(rd),
		.ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB), .break1(break1), .break2(break2), .p1LED(p1LED), .p2LED(p2LED), .p1score(rsc1), .p2score(rsc2), .reg3(reg3), .reg4(reg4), .m(m), .s10(s10), .s1(s1));

	RAM ProcMem(.clk(clk), 
		.wEn(mwe), 
		.addr(memAddr[11:0]), 
		.dataIn(memDataIn), 
		.dataOut(memDataOut));
	
	VGAController VGAC(.clk(clock100), 
		.reset(reset),
		.score1(score1),
		.score2(score2),
		.time1(time1),
		.time2(time2),
		.time3(time3),
		.hSync(hSync), 	
		.vSync(vSync), 	
		.VGA_R(VGA_R),
		.VGA_G(VGA_G), 
		.VGA_B(VGA_B), 
		.ps2_clk(ps2_clk),
		.ps2_data(ps2_data));

	assign soundON = p1LEDout | p2LEDout;
	AudioController AC(.clk(clock100), .enable(soundON),  .audioOut(audioOut), .audioEn(audioEn));
endmodule
