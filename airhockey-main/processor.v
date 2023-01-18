/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

    wire [31:0] R, J, BNE, JAL, JR, ADDI, BLT, SW, LW, SETX, BEX, DSIGNALS, XSIGNALS, MSIGNALS, WSIGNALS, BYBMUXOUT, A, B, ADXOUT, BDXOUT, BXMOUT, BDXOUTSX, DMWOUT, ALU_out, ALU_outXM, ALU_outMW, next_address_imem, PCFD_address_imem, IRFD_q_imem, PCDX_address_imem, IRDX_q_imem, NEWIRDX_q_imem, IRXM_q_imem, IRMW_q_imem, RSTATUSMUXOUT, RSTATUSALU_out, BRANCHPCALUOUT, PLUS1ADDRESS, TX, BRANCHMUXOUT, PCMW_address_imem, PCXM_address_imem, FLUSHEDFD, FLUSHEDDX, BYBJR, MUXTX, BEXTX;
    wire [16:0] immediate;
    wire [4:0] opcode, ALU_op, shamt;
    wire [2:0] RSTATUSSELECT;
    wire [1:0] BYAMUXSELECT, BY0AMUXSELECT, BY0BMUXSELECT, BYBMUXSELECT, BYDMUXSELECT;
    wire ALUNEQ, ALULT, ALUOVF, NEXTPCALUNEQ, NEXTPCALULT, NEXTPCALUOVF, BRANCHPCALUNEQ, BRANCHPCALULT, BRANCHPCALUOVF, BRANCHRECOVERY, STALL;

    reg_32 PC(address_imem, next_address_imem, clock, ~STALL, reset);
    alu NEXTPCALU(address_imem, 32'd1, 5'b0, 5'b0, PLUS1ADDRESS, NEXTPCALUNEQ, NEXTPCALULT, NEXTPCALUOVF); 

    reg_32 PCFD(PCFD_address_imem, address_imem, ~clock, 1'b1, reset);
    assign FLUSHEDFD = BRANCHRECOVERY ? 32'b0 : q_imem;
    reg_32 IRFD(IRFD_q_imem, FLUSHEDFD, ~clock, ~STALL, reset);

    mux32_32 DSIGNALMUX(DSIGNALS, IRFD_q_imem[31:27], 32'b0, 32'b0, {31'b0, 1'b1}, 32'b0, {31'b0, 1'b1}, 32'b0, {31'b0, 1'b1}, {31'b0, 1'b1}, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0);
    reg_32 PCDX(PCDX_address_imem, PCFD_address_imem, ~clock, 1'b1, reset);
    assign FLUSHEDDX = (BRANCHRECOVERY | STALL) ? 32'b0 : IRFD_q_imem;
    reg_32 IRDX(IRDX_q_imem, FLUSHEDDX, ~clock, 1'b1, reset);
    reg_32 ADX(ADXOUT, data_readRegA, ~clock, 1'b1, reset);
    reg_32 BDX(BDXOUT, data_readRegB, ~clock, 1'b1, reset);
    assign ctrl_readRegA = IRFD_q_imem[31:27] == 5'b10110 ? 5'd30 : IRFD_q_imem[21:17];
    assign ctrl_readRegB = DSIGNALS[0] ? IRFD_q_imem[26:22] : IRFD_q_imem[16:12];
    assign ctrl_writeReg = WSIGNALS[4] ? 32'd30 : (WSIGNALS[3] ? 32'd31 : (IRMW_q_imem[26:22]));
    assign ctrl_writeEnable = WSIGNALS[0];
    assign data_writeReg = WSIGNALS[4] ? {5'b0, IRMW_q_imem[26:0]} : (WSIGNALS[3] ? PCMW_address_imem : (WSIGNALS[1] ? DMWOUT : ALU_outMW));
    assign STALL = (IRDX_q_imem[31:27] == 5'b01000) & ((IRFD_q_imem[21:17] == IRDX_q_imem[26:22]) | ((IRFD_q_imem[16:12] == IRDX_q_imem[26:22]) & (IRFD_q_imem[31:27] != 5'b00111)));

    mux32_32 XSIGNALMUX(XSIGNALS, IRDX_q_imem[31:27], {25'b0, 1'b1, 1'b0, ALU_op}, {23'b0, 2'b01, 7'b0}, {22'b0, 1'b1, 2'b11, 7'b0}, {23'b0, 2'b01, 7'b0}, {22'b0, 1'b1, 2'b10, 7'b0}, {26'b0, 1'b1, 5'b0}, {22'b0, 1'b1, 2'b11, 7'b0}, {22'b0, 1'b1, 3'b0, 1'b1, 5'b0}, {26'b0, 1'b1, 5'b0}, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, {23'b0, 2'b01, 7'b0}, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0);
    reg_32 PCXM(PCXM_address_imem, PCDX_address_imem, ~clock, 1'b1, reset);
    assign ALU_op = IRDX_q_imem[6:2];
    assign shamt = IRDX_q_imem[11:7];
    assign immediate = IRDX_q_imem[16:0];
    assign BDXOUTSX = {{15{immediate[16]}}, immediate};
    assign TX = {5'b0, IRDX_q_imem[26:0]};
    assign BEXTX = ((A != 32'b0) & (IRDX_q_imem[31:27] == 5'b10110))? TX : BRANCHMUXOUT;
    assign MUXTX = IRDX_q_imem[31:27] == 5'b10110 ? BEXTX : TX;
    assign B = XSIGNALS[5] ? BDXOUTSX : BYBMUXOUT;
    alu ALU(A, B, XSIGNALS[4:0], shamt, ALU_out, ALUNEQ, ALULT, ALUOVF);
    mux4_32 BYAMUX(A, BY0AMUXSELECT, ALU_outXM, data_writeReg, ADXOUT, 32'b0);
    mux4_32 BYBMUX(BYBMUXOUT, BY0BMUXSELECT, ALU_outXM, data_writeReg, BDXOUT, 32'b0); 
    assign BYAMUXSELECT = ((IRDX_q_imem[21:17] == IRXM_q_imem[26:22]) & ~MSIGNALS[1]) ? 2'b00 : (((IRDX_q_imem[21:17] == IRMW_q_imem[26:22]) &  ~WSIGNALS[2]) ? 2'b01 : 2'b10);
    assign BY0AMUXSELECT = (IRDX_q_imem[21:17] == 5'b0) ? 2'b10 : BYAMUXSELECT; 
    assign BYBMUXSELECT = ((XSIGNALS[6] & ~MSIGNALS[1]) & (IRDX_q_imem[16:12] == IRXM_q_imem[26:22])) | ((XSIGNALS[9] & ~MSIGNALS[1]) & (IRDX_q_imem[26:22] == IRXM_q_imem[26:22])) ? 2'b00 : (((XSIGNALS[6] & ~WSIGNALS[2])& (IRDX_q_imem[16:12] == IRMW_q_imem[26:22])) | ((XSIGNALS[9] & ~WSIGNALS[2]) & (IRDX_q_imem[26:22] == IRMW_q_imem[26:22])) ? 2'b01 : 2'b10);
    assign BY0BMUXSELECT = (XSIGNALS[9] & IRDX_q_imem[26:22] == 5'b0) ? 2'b10 : BYBMUXSELECT;
    assign BYBJR = (IRDX_q_imem[26:22] == IRXM_q_imem[26:22]) ? ALU_outXM : (IRDX_q_imem[26:22] == IRXM_q_imem[26:22] ? data_writeReg: B);
    mux8_32 RSTATUSMUX(RSTATUSMUXOUT, RSTATUSSELECT, 32'd1, 32'd3, 32'd2, TX, 32'b0, 32'b0, 32'd4, 32'd5);
    assign RSTATUSSELECT = (IRDX_q_imem[31:27] == 5'b00101) ? 3'b010 : ((IRDX_q_imem[31:27] == 5'b10101) ? 3'b011 : ALU_op);
    assign RSTATUSALU_out = ALUOVF ? RSTATUSMUXOUT : ALU_out;
    assign NEWIRDX_q_imem = ALUOVF ? {IRDX_q_imem[31:27], 5'd30, IRDX_q_imem[21:0]} : IRDX_q_imem;
    alu BRANCHPCALU(PCDX_address_imem, BDXOUTSX, 5'b0, 5'b0, BRANCHPCALUOUT, BRANCHPCALUNEQ, BRANCHPCALULT, BRANCHPCALUOVF);
    mux2_32 BRANCHMUX(BRANCHMUXOUT, (ALUNEQ & IRDX_q_imem[31:27] == 5'b00010) | ((~ALULT & ALUNEQ) & IRDX_q_imem[31:27] == 5'b00110), PLUS1ADDRESS, BRANCHPCALUOUT);
    mux4_32 JBRANCHMUX(next_address_imem, XSIGNALS[8:7], BRANCHMUXOUT, MUXTX, BYBJR, BRANCHMUXOUT);
    assign BRANCHRECOVERY = (XSIGNALS[8:7] != 2'b00) & (next_address_imem != PLUS1ADDRESS) ? 1'b1 : 1'b0;

    mux32_32 MSIGNALMUX(MSIGNALS, IRXM_q_imem[31:27], 32'b0, 32'b0, {30'b0, 1'b1, 1'b0}, 32'b0, 32'b0, 32'b0, {30'b0, 1'b1, 1'b0}, {30'b0, 1'b1, 1'b1}, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0);
    reg_32 PCMW(PCMW_address_imem, PCXM_address_imem, ~clock, 1'b1, reset);
    reg_32 IRXM(IRXM_q_imem, NEWIRDX_q_imem, ~clock, 1'b1, reset);
    reg_32 ALUOUTXM(ALU_outXM, RSTATUSALU_out, ~clock, 1'b1, reset);
    reg_32 BXM(BXMOUT, BYBMUXOUT, ~clock, 1'b1, reset);
    mux4_32 BYDMUX(data, BYDMUXSELECT, data_writeReg, BXMOUT, 32'b0, 32'b0);
    assign BYDMUXSELECT = (IRXM_q_imem[26:22] == IRMW_q_imem[26:22]) ? 2'b00 : 2'b01;

    assign address_dmem = ALU_outXM;
    assign wren = MSIGNALS[0] ? 1'b1 : 1'b0;

    mux32_32 WSIGNALMUX(WSIGNALS, IRMW_q_imem[31:27], {31'b0, 1'b1}, 32'b0, {29'b0, 1'b1, 2'b0}, {28'b0, 1'b1, 2'b0, 1'b1}, {29'b0, 1'b1, 2'b0}, {31'b0, 1'b1}, {29'b0, 1'b1, 2'b0}, {29'b0, 1'b1, 2'b0}, {30'b0, 2'b11}, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, {27'b0, 1'b1, 3'b0, 1'b1}, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0, 32'b0);
    reg_32 IRMW(IRMW_q_imem, IRXM_q_imem, ~clock, 1'b1, reset);
    reg_32 ALUOUTMW(ALU_outMW, ALU_outXM, ~clock, 1'b1, reset);
    reg_32 DMW(DMWOUT, q_dmem, ~clock, 1'b1, reset);
endmodule
