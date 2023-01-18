module regfile(
	clock, ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg, data_readRegA,
	data_readRegB, break1, break2, p1LED, p2LED, p1score, p2score, reg3, reg4, m, s10, s1);
	
	input clock, ctrl_writeEnable, ctrl_reset, break1, break2;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg, m, s10, s1;
	output reg p1LED, p2LED;
	output [31:0] data_readRegA, data_readRegB, reg3, reg4;
	output reg[31:0] p1score, p2score;

	reg[31:0] registers[31:0];
	assign reg3 = registers[3];
	assign reg4 = registers[4];

	integer count;
	initial begin
		for (count=0; count<32; count=count+1)
			registers[count] <= 0;
	end

	integer i;
	always @(posedge clock or posedge ctrl_reset)
	begin
		if(ctrl_reset)
			begin
				for(i = 0; i < 32; i = i + 1)
					begin
						registers[i] <= 32'd0;
					end
			end
		else
			if(ctrl_writeEnable && ctrl_writeReg != 5'd0)
				registers[ctrl_writeReg] <= data_writeReg;
			registers[3] <= {31'd0, ~break1};
			registers[4] <= {31'd0, ~break2};
			registers[8] <= m;
			registers[9] <= s10;
			registers[10] <= s1;
			p1score <= registers[1];
			p2score <= registers[2];
			p1LED <= registers[5][0];
			p2LED <= registers[6][0];
	end
	
	assign data_readRegA = registers[ctrl_readRegA];
	assign data_readRegB = registers[ctrl_readRegB];
	
endmodule