module processor(clock, reset, /*ps2_key_pressed, ps2_out, lcd_write, lcd_data,*/ dmem_data_in, dmem_address,
	move_left, move_right, game_status, spaceship_x
);

	input 			clock, reset/*, ps2_key_pressed*/;
	//input 	[7:0]	ps2_out;
	
	//output 			lcd_write;
	//output 	[31:0] 	lcd_data;
	
	// GRADER OUTPUTS - YOU MUST CONNECT TO YOUR DMEM
	output 	[31:0] 	dmem_data_in;
	output	[11:0]	dmem_address;
	
	
	// your processor here
	//
	wire imem_clock, dmem_clock, processor_clock, regfile_clock;
	
	// New inputs for external signals, can be read from register $1-3
   input move_left, move_right, game_status;
	// New output, can be written at register $4
   output [31:0] spaceship_x;
	
		
	 assign imem_clock = ~clock;
	 assign dmem_clock = clock;

     div4_clk my_div4_clk(
        .clk(clock),
        .reset(reset),
        .div4_clk(processor_clock)
    );
	 assign regfile_clock = processor_clock;

    /** REGFILE **/
    // Instantiate your regfile
    wire ctrl_writeEnable;
    wire [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    wire [31:0] data_writeReg;
    wire [31:0] data_readRegA, data_readRegB;
    regfile my_regfile(
        regfile_clock,
        ctrl_writeEnable,
        reset,
        ctrl_writeReg,
        ctrl_readRegA,
        ctrl_readRegB,
        data_writeReg,
        data_readRegA,
        data_readRegB,
		  move_left,
		  move_right,
		  game_status,
		  space_ship_x
    );

    /** PROCESSOR **/
    cpu my_cpu(
        // Control signals
        processor_clock,                          // I: The master clock
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
        ctrl_writeEnable,               // O: Write enable for regfile
        ctrl_writeReg,                  // O: Register to write to in regfile
        ctrl_readRegA,                  // O: Register to read from port A of regfile
        ctrl_readRegB,                  // O: Register to read from port B of regfile
        data_writeReg,                  // O: Data to write to for regfile
        data_readRegA,                  // I: Data from port A of regfile
        data_readRegB                   // I: Data from port B of regfile
    );
	 
	 /** IMEM **/
    // Figure out how to generate a Quartus syncram component and commit the generated verilog file.
    // Make sure you configure it correctly!
    wire [11:0] address_imem;
    wire [31:0] q_imem;
    imem my_imem(
        .address    (address_imem),            // address of data
        .clock      (imem_clock),                  // you may need to invert the clock
        .q          (q_imem)                   // the raw instruction
    );
	
	 /** DMEM **/
    // Figure out how to generate a Quartus syncram component and commit the generated verilog file.
    // Make sure you configure it correctly!
    wire [11:0] address_dmem;
    wire [31:0] data;
    wire wren;
    wire [31:0] q_dmem;
    dmem my_dmem(
        .address    (address_dmem),       // address of data
        .clock      (dmem_clock),                  // may need to invert the clock
        .data	    (data),    // data you want to write
        .wren	    (wren),      // write enable
        .q          (q_dmem)    // data from dmem
    );
	
	//////////////////////////////////////
	////// THIS IS REQUIRED FOR GRADING
	// CHANGE THIS TO ASSIGN YOUR DMEM WRITE ADDRESS ALSO TO debug_addr
	assign dmem_address = address_dmem;
	// CHANGE THIS TO ASSIGN YOUR DMEM DATA INPUT (TO BE WRITTEN) ALSO TO debug_data
	assign dmem_data_in = data;
	////////////////////////////////////////////////////////////
	
		
//	// You'll need to change where the dmem and imem read and write...
//	dmem mydmem(	.address	(dmem_address),
//					.clock		(clock),
//					.data		(debug_data),
//					.wren		(1'b1) //,	//need to fix this!
//					//.q			(wherever_you_want) // change where output q goes...
//	);
//	
//	imem myimem(	.address 	(dmem_data_in),
//					.clken		(1'b1),
//					.clock		(clock) //,
//					//.q			(wherever_you_want) // change where output q goes...
//	); 
	
endmodule
