`timescale 1 ns/ 100 ps
module VGAController(     
	input clk, 			// 100 MHz System Clock
	input reset, 		// Reset Signal
	input[31:0] score1,
	input[31:0] score2,
	input[31:0] time1,
	input[31:0] time2,
	input[31:0] time3,
	output hSync, 		// H Sync Signal
	output vSync, 		// Veritcal Sync Signal
	output[3:0] VGA_R,  // Red Signal Bits
	output[3:0] VGA_G,  // Green Signal Bits
	output[3:0] VGA_B,  // Blue Signal Bits
	inout ps2_clk,
	inout ps2_data);
	
	// Lab Memory Files Location
	localparam FILES_PATH = "C:/Users/cjwso/Downloads/processor/Test Files/Memory Files/";

	// Clock divider 100 MHz -> 25 MHz
	wire clk25, score1Boolean, score2Boolean, time1Boolean, time2Boolean, time3Boolean; // 25MHz clock
	wire[11:0] colorDataSquare;

	reg[1:0] pixCounter = 0;      // Pixel counter to divide the clock
    assign clk25 = pixCounter[1]; // Set the clock high whenever the second bit (2) is high
	always @(posedge clk) begin
		pixCounter <= pixCounter + 1; // Since the reg is only 2 bits, it will reset every 4 cycles
	end

	// VGA Timing Generation for a Standard VGA Screen
	localparam 
		VIDEO_WIDTH = 640,  // Standard VGA Width
		VIDEO_HEIGHT = 480; // Standard VGA Height

	wire active, screenEnd;
	wire[9:0] x;
	wire[8:0] y;
	
	VGATimingGenerator #(
		.HEIGHT(VIDEO_HEIGHT), // Use the standard VGA Values
		.WIDTH(VIDEO_WIDTH))
	Display( 
		.clk25(clk25),  	   // 25MHz Pixel Clock
		.reset(reset),		   // Reset Signal
		.screenEnd(screenEnd), // High for one cycle when between two frames
		.active(active),	   // High when drawing pixels
		.hSync(hSync),  	   // Set Generated H Signal
		.vSync(vSync),		   // Set Generated V Signal
		.x(x), 				   // X Coordinate (from left)
		.y(y)); 			   // Y Coordinate (from top)	   

	// Image Data to Map Pixel Location to Color Address
	localparam 
		PIXEL_COUNT = VIDEO_WIDTH*VIDEO_HEIGHT, 	             // Number of pixels on the screen
		PIXEL_ADDRESS_WIDTH = $clog2(PIXEL_COUNT) + 1,           // Use built in log2 command
		BITS_PER_COLOR = 12, 	  								 // Nexys A7 uses 12 bits/color
		PALETTE_COLOR_COUNT = 256, 								 // Number of Colors available
		PALETTE_ADDRESS_WIDTH = $clog2(PALETTE_COLOR_COUNT) + 1, // Use built in log2 Command
		SPRITE_COUNT = 25000,
		SPRITE_ADDRESS_WIDTH = $clog2(SPRITE_COUNT) + 1; 

	wire[PIXEL_ADDRESS_WIDTH-1:0] imgAddress;  	 // Image address for the image data
	wire[SPRITE_ADDRESS_WIDTH-1:0] spriteAddress;
	wire[PALETTE_ADDRESS_WIDTH-1:0] colorAddr; 	 // Color address for the color palette
	wire[PALETTE_ADDRESS_WIDTH-1:0] spriteColorAddr;
	wire[11:0] xOffset, yOffset;
	wire[31:0] numOffset;
	assign imgAddress = x + 640*y;				 // Address calculated coordinate
	assign numOffset = score1Boolean ? score1 : (score2Boolean ? score2 : (time1Boolean ? time1 : (time2Boolean ? time2 : (time3Boolean ? time3 : 31'd0))));
	assign xOffset = score1Boolean ? 12'd80 : (score2Boolean ? 12'd510 : (time1Boolean ? 12'd240 : (time2Boolean ? 12'd340 : (time3Boolean ? 12'd390 : 12'd0))));
	assign yOffset = score1Boolean ? 12'd140 : (score2Boolean ? 12'd140 : (time1Boolean ? 12'd110 : (time2Boolean ? 12'd110 : (time3Boolean ? 12'd110: 12'd0))));
	assign spriteAddress = (x - xOffset) + (49*(y - yOffset) + 2450*(numOffset));

	VGARAM #(		
		.DEPTH(PIXEL_COUNT), 				     // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),      // Set data width according to the color palette
		.ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),     // Set address width according to the pixel count
		.MEMFILE({FILES_PATH, "image.mem"})) // Memory initialization
	ImageData(
		.clk(clk), 						 // Falling edge of the 100 MHz clk
		.addr(imgAddress),					 // Image data address
		.dataOut(colorAddr),				 // Color palette address
		.wEn(1'b0)); 						 // We're always reading

	VGARAM #(
		.DEPTH(SPRITE_COUNT),
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),
		.ADDRESS_WIDTH(SPRITE_ADDRESS_WIDTH),
		.MEMFILE({FILES_PATH, "spriteImage.mem"})) // Memory initialization
	SpriteData(
		.clk(clk),
		.addr(spriteAddress),
		.dataOut(spriteColorAddr),
		.wEn(1'b0));

	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] colorData; // 12-bit color data at current pixel
	wire[BITS_PER_COLOR-1:0] spriteColorData;

	VGARAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({FILES_PATH, "colors.mem"}))  // Memory initialization
	ColorPalette(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(colorAddr),					       // Address from the ImageData RAM
		.dataOut(colorData),				       // Color at current pixel
		.wEn(1'b0)); 						       // We're always reading
	
	VGARAM #(
		.DEPTH(PALETTE_COLOR_COUNT),
		.DATA_WIDTH(BITS_PER_COLOR),
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),
		.MEMFILE({FILES_PATH, "spriteColors.mem"})) // Memory initialization
	SpriteColorPalette(
		.clk(clk),
		.addr(spriteColorAddr),
		.dataOut(spriteColorData),
		.wEn(1'b0));

	wire[BITS_PER_COLOR-1:0] colorOut;
	assign score1Boolean = ((x >= 12'd80) & (x <= 12'd130)) & ((y >= 12'd140) & (y <= 12'd190));
	assign score2Boolean = ((x >= 12'd510) & (x <= 12'd560)) & ((y >= 12'd140) & (y <= 12'd190));
	assign time1Boolean = ((x >= 12'd240) & (x <= 12'd290)) & ((y >= 12'd110) & (y <= 12'd160));
	assign time2Boolean = ((x >= 12'd340) & (x <= 12'd390)) & ((y >= 12'd110) & (y <= 12'd160));
	assign time3Boolean = ((x >= 12'd390) & (x <= 12'd440)) & ((y >= 12'd110) & (y <= 12'd160));
	assign colorDataSquare = (score1Boolean | score2Boolean | time1Boolean | time2Boolean | time3Boolean) ? spriteColorData : colorData; 
	assign colorOut = active ? colorDataSquare : 12'd0;
	assign {VGA_R, VGA_G, VGA_B} = colorOut;
endmodule
