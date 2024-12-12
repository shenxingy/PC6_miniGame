module regfile(
   clock, ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
   ctrl_readRegA, ctrl_readRegB, data_writeReg, data_readRegA,
   data_readRegB,
   move_left, move_right, game_status, spaceship_x
);
   input clock, ctrl_writeEnable, ctrl_reset;
   input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
   input [31:0] data_writeReg;
   output [31:0] data_readRegA, data_readRegB;

   // New inputs for external signals, can be read from register $1-3 (game status is 1 when reset is needed)
   input move_left, move_right, game_status;
	// New output, can be written at register $4
   output [31:0] spaceship_x;


   reg[31:0] registers[31:0];


   integer i;
   always @(posedge clock or posedge ctrl_reset)
   begin
       if(ctrl_reset)
           begin
               for(i = 0; i < 32; i = i + 1)
                   begin
                       registers[i] = 32'd0;
                   end
           end
       else
           if(ctrl_writeEnable && ctrl_writeReg != 5'd0)
               registers[ctrl_writeReg] = data_writeReg;
   end


   // Assign outputs using muxes for providing external signals
   assign data_readRegA = (ctrl_readRegA == 32'd1) ? {31'd0, move_left} :
                          (ctrl_readRegA == 32'd2) ? {31'd0, move_right} :
                          (ctrl_readRegA == 32'd3) ? {31'd0, game_status} :
                          registers[ctrl_readRegA];

   assign data_readRegB = (ctrl_readRegB == 32'd1) ? {31'd0, move_left} :
                          (ctrl_readRegB == 32'd2) ? {31'd0, move_right} :
                          (ctrl_readRegB == 32'd3) ? {31'd0, game_status} :
                          registers[ctrl_readRegB];

   // Output spaceship X-coordinate for the VGA controller
   assign spaceship_x = registers[4];  // Register 4: Spaceship X-coordinate
	
endmodule


