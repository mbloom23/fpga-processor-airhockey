module AudioController(
    input        clk, 		// System Clock Input 100 Mhz
	input 		 enable, 	// Enable audio output, from scoring logic	
    output       audioOut, 
	output		 audioEn);	// Audio Enable

	wire[6:0] duty_cycle;
	wire[31:0] CounterLimit; 
	reg[31:0] counter = 32'd0;
	reg clkFREQ = 1'd0;

	localparam MHz = 1000000;
	localparam SYSTEM_FREQ = 100*MHz; // System clock frequency

	assign chSel   = 1'b0;  // Collect Mic Data on the rising edge 
	assign audioEn = 1'b1;  // Enable Audio Output

	// Initialize the frequency array. FREQs[0] = 261
	reg[10:0] FREQs[0:15];
	initial begin
		$readmemh("FREQs.mem", FREQs);
	end

	assign duty_cycle = clkFREQ ? 7'd100 : 7'd0;
	assign CounterLimit = (SYSTEM_FREQ / FREQs[0]) - 1;
	always @(posedge clk & enable) begin
		if(counter < CounterLimit)
			counter <= counter + 1;
		else begin
			counter <= 0;
			clkFREQ <= ~clkFREQ;
		end
	end
	PWMSerializer serial(clk, 1'b0, duty_cycle, audioOut);
endmodule