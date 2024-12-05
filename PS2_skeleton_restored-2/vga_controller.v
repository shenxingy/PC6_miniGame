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
        if (move_left && spaceship_x > 5)
            spaceship_x <= spaceship_x - 5;
        if (move_right && spaceship_x < 624)  // 640 - spaceship width (16)
            spaceship_x <= spaceship_x + 5;
    end else begin
        move_counter <= move_counter + 1;
    end
end

// Define the size of the monsters and their properties
parameter MONSTER_SIZE = 16;  // Monsters are 16x16 pixels
parameter NUM_MONSTERS = 5;   // Number of monsters

// Monster coordinates and active state
reg [9:0] monster_x [0:NUM_MONSTERS-1];  // X coordinates of monsters
reg [8:0] monster_y [0:NUM_MONSTERS-1];  // Y coordinates of monsters
reg monster_active [0:NUM_MONSTERS-1];   // Active state of monsters

integer j;


always @(posedge iVGA_CLK or negedge iRST_n) begin
    if (!iRST_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            bullet_active[i] <= 1'b0;
            bullet_x[i] <= 10'b0;
            bullet_y[i] <= 9'b0;
        end
        for (j = 0; j < NUM_MONSTERS; j = j + 1) begin
            monster_x[j] <= 10'd50 + (j * (MONSTER_SIZE + 10)); // Space monsters evenly
            monster_y[j] <= 9'd50;  // Place monsters at the top
            monster_active[j] <= 1'b1;  // All monsters are active initially
        end
        bullet_counter <= 21'd0;
    end else begin
        if (fire) begin
            reg found_slot;  // Flag to indicate if an empty bullet slot was found
            found_slot = 1'b0;  // Initialize to not found
            
            for (i = 0; i < 8; i = i + 1) begin
                if (!bullet_active[i] && !found_slot) begin
                    bullet_x[i] <= spaceship_x + 8;  // Align the bullet with the spaceship
                    bullet_y[i] <= spaceship_y;
                    bullet_active[i] <= 1'b1;
                    found_slot = 1'b1;  // Mark as found
                end
            end
        end

        if (bullet_counter == 21'd100000) begin
            bullet_counter <= 0;  // Reset the counter
            for (i = 0; i < 8; i = i + 1) begin
                if (bullet_active[i]) begin
                    if (bullet_y[i] > 0)
                        bullet_y[i] <= bullet_y[i] - 5;  // Move the bullet upwards
                    else
                        bullet_active[i] <= 1'b0;  // Deactivate the bullet when off-screen
                end
            end
        end else begin
            bullet_counter <= bullet_counter + 1;  // Increment the bullet counter
        end

        for (j = 0; j < NUM_MONSTERS; j = j + 1) begin
            if (monster_active[j]) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if (bullet_active[i] &&
                        bullet_x[i] >= monster_x[j] && bullet_x[i] < monster_x[j] + MONSTER_SIZE &&
                        bullet_y[i] >= monster_y[j] && bullet_y[i] < monster_y[j] + MONSTER_SIZE) begin
                        monster_active[j] <= 1'b0;  // Deactivate the monster
                        bullet_active[i] <= 1'b0;   // Deactivate the bullet
                    end
                end
            end
        end
    end
end

// Rendering logic
wire [9:0] pixel_x = ADDR % 640;  // Current pixel x-coordinate
wire [8:0] pixel_y = ADDR / 640;  // Current pixel y-coordinate

// Check if the current pixel is within the spaceship
wire is_spaceship = (pixel_x >= spaceship_x) && (pixel_x < spaceship_x + 16) &&
                    (pixel_y >= spaceship_y) && (pixel_y < spaceship_y + 16);


// Create a register array to store bullet hit detection results
wire [7:0] bullet_hit;  // Array for bullet hit detection
genvar x;

// Generate logic for each bullet to check if the current pixel overlaps
generate
    for (x = 0; x < 8; x = x + 1) begin : bullet_check
        assign bullet_hit[x] = (pixel_x >= bullet_x[x] && pixel_x < bullet_x[x] + 4 &&
                                pixel_y >= bullet_y[x] && pixel_y < bullet_y[x] + 8 &&
                                bullet_active[x]);
    end
endgenerate

// Combine all bullet hit conditions into a single signal
assign is_bullet = |bullet_hit;

// Rendering logic for monsters
wire [NUM_MONSTERS-1:0] monster_hit;  // Array for monster hit detection
genvar m;

generate
    for (m = 0; m < NUM_MONSTERS; m = m + 1) begin : monster_rendering
        assign monster_hit[m] = monster_active[m] &&
                                (pixel_x >= monster_x[m]) && (pixel_x < monster_x[m] + MONSTER_SIZE) &&
                                (pixel_y >= monster_y[m]) && (pixel_y < monster_y[m] + MONSTER_SIZE);
    end
endgenerate

// Combine all monster hit signals
wire is_monster = |monster_hit;

// Assign colors: spaceship in green, bullets in yellow, monsters in red, and background
assign b_data = is_spaceship ? 8'h00 : (is_bullet ? 8'hFF : (is_monster ? 8'h00 : 8'h00));
assign g_data = is_spaceship ? 8'hFF : (is_bullet ? 8'hFF : (is_monster ? 8'h00 : 8'h00));
assign r_data = is_spaceship ? 8'h00 : (is_bullet ? 8'h00 : (is_monster ? 8'hFF : 8'h00));


// Delay the iHD, iVD, iDEN signals by one clock cycle
always @(negedge iVGA_CLK) begin
    oHS <= cHS;
    oVS <= cVS;
    oBLANK_n <= cBLANK_n;
end

endmodule