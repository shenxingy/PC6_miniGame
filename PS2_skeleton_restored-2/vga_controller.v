module vga_controller(
    iRST_n,
    iVGA_CLK,
    oBLANK_n,
    oHS,
    oVS,
    b_data,
    g_data,
    r_data,
    move_up,
    move_down,
    move_left,
    move_right
);

input iRST_n;
input iVGA_CLK;
input move_up, move_down, move_left, move_right;
output reg oBLANK_n;
output reg oHS;
output reg oVS;
output [7:0] b_data;
output [7:0] g_data;  
output [7:0] r_data;                        

reg [18:0] ADDR;
reg [23:0] bgr_data;
wire VGA_CLK_n;
wire [7:0] index;
wire [23:0] bgr_data_raw;
wire cBLANK_n, cHS, cVS, rst;

reg [9:0] square_x = 10'd320;  // Initial X coordinate (center of screen)
reg [8:0] square_y = 9'd240;   // Initial Y coordinate (center of screen)
reg [20:0] move_counter = 0;    // Counter to control the speed of movement

assign rst = ~iRST_n;

// Video sync generator instance
video_sync_generator LTM_ins (
    .vga_clk(iVGA_CLK),
    .reset(rst),
    .blank_n(cBLANK_n),
    .HS(cHS),
    .VS(cVS)
);

// Address generator
always @(posedge iVGA_CLK or negedge iRST_n) begin
    if (!iRST_n)
        ADDR <= 19'd0;
    else if (cHS == 1'b0 && cVS == 1'b0)
        ADDR <= 19'd0;
    else if (cBLANK_n == 1'b1)
        ADDR <= ADDR + 1;
end

assign VGA_CLK_n = ~iVGA_CLK;

// img_data and img_index instances for background image data
img_data img_data_inst (
    .address(ADDR),
    .clock(VGA_CLK_n),
    .q(index)
);

img_index img_index_inst (
    .address(index),
    .clock(iVGA_CLK),
    .q(bgr_data_raw)
);

// Latch valid data at falling edge
always @(posedge VGA_CLK_n)
    bgr_data <= bgr_data_raw;

// Update the position of the square based on directional inputs
always @(posedge iVGA_CLK) begin
    if (move_counter == 21'd1000000) begin  // Control movement speed
        move_counter <= 0;

        // Update position based on input signals, with boundary checks
        if (move_up && square_y > 0)
            square_y <= square_y - 1;
        if (move_down && square_y < 479)
            square_y <= square_y + 1;
        if (move_left && square_x > 0)
            square_x <= square_x - 1;
        if (move_right && square_x < 639)
            square_x <= square_x + 1;
    end else begin
        move_counter <= move_counter + 1;
    end
end

// Logic to determine if a pixel is within the square or should display the background
wire [9:0] pixel_x = ADDR % 640;  // Current pixel x-coordinate
wire [8:0] pixel_y = ADDR / 640;  // Current pixel y-coordinate
wire is_square = (pixel_x >= square_x) && (pixel_x < square_x + 16) &&
                 (pixel_y >= square_y) && (pixel_y < square_y + 16);

// Display the square in red, or the background color if not in the square area
assign b_data = is_square ? 8'hFF : bgr_data[23:16];  // Red color for the square
assign g_data = is_square ? 8'h00 : bgr_data[15:8];
assign r_data = is_square ? 8'h00 : bgr_data[7:0];

// Delay the iHD, iVD, iDEN signals by one clock cycle
always @(negedge iVGA_CLK) begin
    oHS <= cHS;
    oVS <= cVS;
    oBLANK_n <= cBLANK_n;
end

endmodule
