module vga_controller(
    iRST_n,
    iVGA_CLK,
    oBLANK_n,
    oHS,
    oVS,
    b_data,
    g_data,
    r_data,
    move_left,
    move_right,
    fire,
    pause
);

input iRST_n;
input iVGA_CLK;
input move_left, move_right, fire, pause;
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

reg [9:0] spaceship_x = 10'd320;  // Spaceship X coordinate
reg [8:0] spaceship_y = 9'd450;   // Spaceship Y coordinate
reg [20:0] move_counter = 0;      // Counter to control movement speed

// Bullet variables
reg [9:0] bullet_x [0:7];         // Array of bullet X coordinates
reg [8:0] bullet_y [0:7];         // Array of bullet Y coordinates
reg bullet_active [0:7];          // Active state for bullets
integer i;

// Clock divider for bullet movement speed
reg [20:0] bullet_counter = 0;

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

// Update the position of the spaceship
always @(posedge iVGA_CLK) begin
    if (move_counter == 21'd1000000) begin
        move_counter <= 0;

        // Update position based on input signals, with boundary checks
        if (move_left && spaceship_x > 0)
            spaceship_x <= spaceship_x - 5;
        if (move_right && spaceship_x < 624)  // 640 - spaceship width (16)
            spaceship_x <= spaceship_x + 5;
    end else begin
        move_counter <= move_counter + 1;
    end
end

// Bullet control logic
always @(posedge iVGA_CLK or negedge iRST_n) begin
    if (!iRST_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            bullet_active[i] <= 1'b0;
        end
    end else begin
        // Fire bullet on space key press
        if (fire) begin
            for (i = 0; i < 8; i = i + 1) begin
                if (!bullet_active[i]) begin
                    bullet_x[i] <= spaceship_x + 8;  // Center bullet with spaceship
                    bullet_y[i] <= spaceship_y;
                    bullet_active[i] <= 1'b1;
                    break;
                end
            end
        end

        // Move active bullets
        if (bullet_counter == 21'd500000) begin
            bullet_counter <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (bullet_active[i]) begin
                    if (bullet_y[i] > 0)
                        bullet_y[i] <= bullet_y[i] - 5;
                    else
                        bullet_active[i] <= 1'b0;  // Deactivate bullet when off screen
                end
            end
        end else begin
            bullet_counter <= bullet_counter + 1;
        end
    end
end

// Rendering logic
wire [9:0] pixel_x = ADDR % 640;  // Current pixel x-coordinate
wire [8:0] pixel_y = ADDR / 640;  // Current pixel y-coordinate

// Check if the current pixel is within the spaceship
wire is_spaceship = (pixel_x >= spaceship_x) && (pixel_x < spaceship_x + 16) &&
                    (pixel_y >= spaceship_y) && (pixel_y < spaceship_y + 16);

// Check if the current pixel is within any active bullet
wire is_bullet = |((pixel_x >= bullet_x[0] && pixel_x < bullet_x[0] + 4 &&
                    pixel_y >= bullet_y[0] && pixel_y < bullet_y[0] + 8 && bullet_active[0]) ||
                   (pixel_x >= bullet_x[1] && pixel_x < bullet_x[1] + 4 &&
                    pixel_y >= bullet_y[1] && pixel_y < bullet_y[1] + 8 && bullet_active[1]) ||
                   // Repeat for remaining bullets
                   (pixel_x >= bullet_x[7] && pixel_x < bullet_x[7] + 4 &&
                    pixel_y >= bullet_y[7] && pixel_y < bullet_y[7] + 8 && bullet_active[7]));

// Assign colors: spaceship in green, bullets in yellow, and background
assign b_data = is_spaceship ? 8'h00 : (is_bullet ? 8'hFF : bgr_data[23:16]);
assign g_data = is_spaceship ? 8'hFF : (is_bullet ? 8'hFF : bgr_data[15:8]);
assign r_data = is_spaceship ? 8'h00 : (is_bullet ? 8'h00 : bgr_data[7:0]);

// Delay the iHD, iVD, iDEN signals by one clock cycle
always @(negedge iVGA_CLK) begin
    oHS <= cHS;
    oVS <= cVS;
    oBLANK_n <= cBLANK_n;
end

endmodule
