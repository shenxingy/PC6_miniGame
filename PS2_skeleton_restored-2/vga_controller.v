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

reg [9:0] spaceship_x;  // Spaceship X coordinate
reg [8:0] spaceship_y;   // Spaceship Y coordinate
reg [20:0] move_counter = 0;      // Counter to control movement speed
reg [3:0] remaining_enemies;  // Supports up to 15 enemies

// Bullet variables
reg [9:0] bullet_x [0:7];         // Array of bullet X coordinates
reg [8:0] bullet_y [0:7];         // Array of bullet Y coordinates
reg bullet_active [0:7];          // Active state for bullets
integer i;

// Clock divider for bullet movement speed
reg [20:0] bullet_counter = 0;

// Game over flag
reg game_over = 1'b0;
reg win = 1'b0;

// Video sync generator instance
assign rst = ~iRST_n;
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

task reset_game;
    integer i, j;
    begin
        spaceship_x <= 10'd320;
        spaceship_y <= 9'd450;
        for (i = 0; i < 8; i = i + 1) begin
            bullet_active[i] <= 1'b0;
            bullet_x[i] <= 0;
            bullet_y[i] <= 0;
        end

        for (j = 0; j < NUM_MONSTERS; j = j + 1) begin
            monster_x[j] <= 10'd50 + (j * (MONSTER_SIZE + 10));  
            monster_y[j] <= 9'd50;
            monster_active[j] <= 1'b1;
        end
        remaining_enemies <= NUM_MONSTERS;
        monster_move_counter <= 21'd0;
        game_over <= 1'b0;
        win <= 1'b0;
    end
endtask


// Define the size of the monsters and their properties
parameter MONSTER_SIZE = 32;    // Monsters are 32x32 pixels
parameter NUM_MONSTERS = 10;    // Number of monsters

// Monster coordinates and active state
reg [9:0] monster_x [0:NUM_MONSTERS-1]; 
reg [8:0] monster_y [0:NUM_MONSTERS-1]; 
reg monster_active [0:NUM_MONSTERS-1];  

integer j;

// Make monsters move slower by increasing interval
parameter MONSTER_MOVE_INTERVAL = 21'd6000000; // Slower than before
reg [20:0] monster_move_counter = 0;


// Main logic
always @(posedge iVGA_CLK or negedge iRST_n) begin
    if (!iRST_n) begin
        reset_game();
    end else begin
        if ((game_over|| win) && pause) begin
            reset_game();
        end 
        if (!game_over && !win) begin
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

            // Monster movement logic
            if (monster_move_counter == MONSTER_MOVE_INTERVAL) begin
                monster_move_counter <= 21'd0;  // Reset the counter
                for (j = 0; j < NUM_MONSTERS; j = j + 1) begin
                    if (monster_active[j]) begin
                        monster_y[j] <= monster_y[j] + 2;  // Move the monster down
                    end
                end
            end else begin
                monster_move_counter <= monster_move_counter + 1;  
            end

            // Fire bullet logic
            if (fire) begin
                reg found_slot;
                found_slot = 1'b0;  
                for (i = 0; i < 8; i = i + 1) begin
                    if (!bullet_active[i] && !found_slot) begin
                        bullet_x[i] <= spaceship_x + 8;  
                        bullet_y[i] <= spaceship_y;
                        bullet_active[i] <= 1'b1;
                        found_slot = 1'b1;
                    end
                end
            end

            // Bullet movement logic
            if (bullet_counter == 21'd100000) begin
                bullet_counter <= 0;
                for (i = 0; i < 8; i = i + 1) begin
                    if (bullet_active[i]) begin
                        if (bullet_y[i] > 0)
                            bullet_y[i] <= bullet_y[i] - 5; 
                        else
                            bullet_active[i] <= 1'b0; 
                    end
                end
            end else begin
                bullet_counter <= bullet_counter + 1; 
            end

            // Bullet-monster collisions
            for (j = 0; j < NUM_MONSTERS; j = j + 1) begin
                if (monster_active[j]) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (bullet_active[i] &&
                            bullet_x[i] >= monster_x[j] && bullet_x[i] < monster_x[j] + MONSTER_SIZE &&
                            bullet_y[i] >= monster_y[j] && bullet_y[i] < monster_y[j] + MONSTER_SIZE) begin
                            monster_active[j] <= 1'b0;  
                            bullet_active[i] <= 1'b0;
                            if (remaining_enemies > 0)
                                remaining_enemies <= remaining_enemies - 1;
                        end
                    end
                end
            end

            // Check for game over conditions
            for (j = 0; j < NUM_MONSTERS; j = j + 1) begin
                if (monster_active[j]) begin
                    // If monster passes or reaches spaceship line
                    if (monster_y[j] + MONSTER_SIZE >= spaceship_y)
                        game_over <= 1'b1;

                    // Monster-spaceship collision
                    if ((monster_x[j] < (spaceship_x + 16)) && ((monster_x[j] + MONSTER_SIZE) > spaceship_x) &&
                        (monster_y[j] < (spaceship_y + 16)) && ((monster_y[j] + MONSTER_SIZE) > spaceship_y)) begin
                        game_over <= 1'b1;
                    end
                end
            end
            if (remaining_enemies == 0) begin
                win <= 1'b1;
            end
        end
    end
end

// Rendering logic
wire [9:0] pixel_x = ADDR % 640;  
wire [8:0] pixel_y = ADDR / 640;  

wire is_spaceship = (pixel_x >= spaceship_x) && (pixel_x < spaceship_x + 16) &&
                    (pixel_y >= spaceship_y) && (pixel_y < spaceship_y + 16);

// Bullets
wire [7:0] bullet_hit;  
genvar x;
generate
    for (x = 0; x < 8; x = x + 1) begin : bullet_check
        assign bullet_hit[x] = bullet_active[x] &&
                               (pixel_x >= bullet_x[x]) && (pixel_x < bullet_x[x] + 4) &&
                               (pixel_y >= bullet_y[x]) && (pixel_y < bullet_y[x] + 8);
    end
endgenerate
wire is_bullet = |bullet_hit;

// Monsters
wire [NUM_MONSTERS-1:0] monster_hit;  
genvar m;
generate
    for (m = 0; m < NUM_MONSTERS; m = m + 1) begin : monster_rendering
        assign monster_hit[m] = monster_active[m] &&
                                (pixel_x >= monster_x[m]) && (pixel_x < monster_x[m] + MONSTER_SIZE) &&
                                (pixel_y >= monster_y[m]) && (pixel_y < monster_y[m] + MONSTER_SIZE);
    end
endgenerate
wire is_monster = |monster_hit;

//--------------------------------------
// 8x8 Font for Letters
//--------------------------------------
function [0:63] get_char_bitmap(input [7:0] char_code);
    // Simple uppercase letters for "YOU WIN"
    // Each character is 8x8, 1-bit per pixel.
    // '1' = pixel on, '0' = pixel off
    // Font: A basic block style
    case (char_code)
        "G": get_char_bitmap = 64'b00011100_00100010_01000000_01001110_01000010_00100010_00011100_00000000;
        "A": get_char_bitmap = 64'b00011100_00100010_01000010_01111110_01000010_01000010_01000010_00000000;
        "M": get_char_bitmap = 64'b01000010_01100110_01011010_01000010_01000010_01000010_01000010_00000000;
        "E": get_char_bitmap = 64'b01111110_01000000_01000000_01111100_01000000_01000000_01111110_00000000;
        "O": get_char_bitmap = 64'b00011100_00100010_01000010_01000010_01000010_00100010_00011100_00000000;
        "V": get_char_bitmap = 64'b01000010_01000010_01000010_00100100_00100100_00011000_00011000_00000000;
        "R": get_char_bitmap = 64'b01111100_01000010_01000010_01111100_01000100_01000010_01000010_00000000;
        "Y": get_char_bitmap = 64'b01000010_01000010_01000010_00100100_00011000_00011000_00011000_00000000;
        "U": get_char_bitmap = 64'b01000010_01000010_01000010_01000010_01000010_01000010_00111100_00000000;
        "W": get_char_bitmap = 64'b01000010_01000010_01000010_01011010_01011010_01100110_01000010_00000000;
        "I": get_char_bitmap = 64'b00111100_00001000_00001000_00001000_00001000_00001000_00111100_00000000;
        "N": get_char_bitmap = 64'b01000010_01100010_01110010_01011010_01001110_01000110_01000010_00000000;
        " ": get_char_bitmap = 64'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000; 
        default: get_char_bitmap = 64'b0;
    endcase
endfunction


function is_char_pixel_on(
    input [7:0] char_code,
    input [3:0] x,
    input [3:0] y
);
    reg [0:63] bitmap;
    begin
        bitmap = get_char_bitmap(char_code);
        is_char_pixel_on = bitmap[y*8 + x]; 
    end
endfunction

// Display "GAME OVER" at roughly the center of the screen
// Let's place it at (200,200) 
// Characters: G A M E [space] O V E R
// We'll place each char 8x8, no scaling, one pixel gap between chars
localparam CHAR_WIDTH = 8;
localparam CHAR_HEIGHT = 8;
localparam TEXT_X = 200;
localparam TEXT_Y = 200;
localparam TEXT_STR = 9; // "GAME OVER" length

reg [7:0] text_str [0:TEXT_STR-1];
initial begin
    text_str[0] = "G";
    text_str[1] = "A";
    text_str[2] = "M";
    text_str[3] = "E";
    text_str[4] = " "; 
    text_str[5] = "O";
    text_str[6] = "V";
    text_str[7] = "E";
    text_str[8] = "R";
end

function is_game_over_text_pixel(
    input [9:0] px,
    input [8:0] py
);
    integer c;
    integer char_x, char_y;
    integer str_len;
    reg pixel_on;
    begin
        pixel_on = 1'b0;
        str_len = TEXT_STR;
        for (c = 0; c < str_len; c = c + 1) begin
            // position of character c
            // one pixel gap between chars
            if (px >= (TEXT_X + c*(CHAR_WIDTH+1)) && px < (TEXT_X + c*(CHAR_WIDTH+1) + CHAR_WIDTH) &&
                py >= TEXT_Y && py < (TEXT_Y + CHAR_HEIGHT)) begin
                char_x = px - (TEXT_X + c*(CHAR_WIDTH+1));
                char_y = py - TEXT_Y;
                if (is_char_pixel_on(text_str[c], char_x[3:0], char_y[3:0]))
                    pixel_on = 1'b1;
            end
        end
        is_game_over_text_pixel = pixel_on;
    end
endfunction

wire is_game_over_text = game_over && is_game_over_text_pixel(pixel_x, pixel_y);

reg [7:0] win_text_str [0:6];  // "YOU WIN" is 7 characters
initial begin
    win_text_str[0] = "Y";
    win_text_str[1] = "O";
    win_text_str[2] = "U";
    win_text_str[3] = " ";
    win_text_str[4] = "W";
    win_text_str[5] = "I";
    win_text_str[6] = "N";
end

function is_win_text_pixel(
    input [9:0] px,
    input [8:0] py
);
    integer c;
    integer char_x, char_y;
    reg pixel_on;
    begin
        pixel_on = 1'b0;
        for (c = 0; c < 7; c = c + 1) begin
            if (px >= (TEXT_X + c * (CHAR_WIDTH + 1)) &&
                px < (TEXT_X + c * (CHAR_WIDTH + 1) + CHAR_WIDTH) &&
                py >= TEXT_Y &&
                py < (TEXT_Y + CHAR_HEIGHT)) begin
                char_x = px - (TEXT_X + c * (CHAR_WIDTH + 1));
                char_y = py - TEXT_Y;
                if (is_char_pixel_on(win_text_str[c], char_x[3:0], char_y[3:0]))
                    pixel_on = 1'b1;
            end
        end
        is_win_text_pixel = pixel_on;
    end
endfunction

wire is_win_text = win && is_win_text_pixel(pixel_x, pixel_y);


reg [7:0] font [0:9][0:7];

initial begin
    font[0][0] = 8'b00111100;
    font[0][1] = 8'b01000010;
    font[0][2] = 8'b01000110;
    font[0][3] = 8'b01001010;
    font[0][4] = 8'b01010010;
    font[0][5] = 8'b01100010;
    font[0][6] = 8'b01000010;
    font[0][7] = 8'b00111100;
    
    font[1][0] = 8'b00011000;
    font[1][1] = 8'b00101000;
    font[1][2] = 8'b00001000;
    font[1][3] = 8'b00001000;
    font[1][4] = 8'b00001000;
    font[1][5] = 8'b00001000;
    font[1][6] = 8'b00001000;
    font[1][7] = 8'b00111100;
    
    font[2][0] = 8'b00111100;
    font[2][1] = 8'b01000010;
    font[2][2] = 8'b00000010;
    font[2][3] = 8'b00000100;
    font[2][4] = 8'b00001000;
    font[2][5] = 8'b00010000;
    font[2][6] = 8'b00100000;
    font[2][7] = 8'b01111110;
    
    font[3][0] = 8'b00111100;
    font[3][1] = 8'b01000010;
    font[3][2] = 8'b00000010;
    font[3][3] = 8'b00011100;
    font[3][4] = 8'b00000010;
    font[3][5] = 8'b00000010;
    font[3][6] = 8'b01000010;
    font[3][7] = 8'b00111100;
    
    font[4][0] = 8'b00000100;
    font[4][1] = 8'b00001100;
    font[4][2] = 8'b00010100;
    font[4][3] = 8'b00100100;
    font[4][4] = 8'b01000100;
    font[4][5] = 8'b01111110;
    font[4][6] = 8'b00000100;
    font[4][7] = 8'b00000100;
    
    font[5][0] = 8'b01111110;
    font[5][1] = 8'b01000000;
    font[5][2] = 8'b01000000;
    font[5][3] = 8'b01111100;
    font[5][4] = 8'b00000010;
    font[5][5] = 8'b00000010;
    font[5][6] = 8'b01000010;
    font[5][7] = 8'b00111100;
    
    font[6][0] = 8'b00111100;
    font[6][1] = 8'b01000010;
    font[6][2] = 8'b01000000;
    font[6][3] = 8'b01111100;
    font[6][4] = 8'b01000010;
    font[6][5] = 8'b01000010;
    font[6][6] = 8'b01000010;
    font[6][7] = 8'b00111100;
    
    font[7][0] = 8'b01111110;
    font[7][1] = 8'b00000010;
    font[7][2] = 8'b00000100;
    font[7][3] = 8'b00001000;
    font[7][4] = 8'b00010000;
    font[7][5] = 8'b00100000;
    font[7][6] = 8'b00100000;
    font[7][7] = 8'b00100000;
    
    font[8][0] = 8'b00111100;
    font[8][1] = 8'b01000010;
    font[8][2] = 8'b01000010;
    font[8][3] = 8'b00111100;
    font[8][4] = 8'b01000010;
    font[8][5] = 8'b01000010;
    font[8][6] = 8'b01000010;
    font[8][7] = 8'b00111100;
    
    font[9][0] = 8'b00111100;
    font[9][1] = 8'b01000010;
    font[9][2] = 8'b01000010;
    font[9][3] = 8'b00111110;
    font[9][4] = 8'b00000010;
    font[9][5] = 8'b00000010;
    font[9][6] = 8'b01000010;
    font[9][7] = 8'b00111100;
end

// Function to get digit bits
function [7:0] get_font;
    input [3:0] digit;
    input [2:0] row;
    begin
        if (digit < 10)
            get_font = font[digit][row];
        else
            get_font = 8'b00000000;
    end
endfunction

// Decode remaining_enemies into two digits
wire [3:0] tens = remaining_enemies / 10;
wire [3:0] units = remaining_enemies % 10;

// Define digit size
parameter DIGIT_WIDTH = 8;
parameter DIGIT_HEIGHT = 8;

// Define position for the score display (right top corner)
parameter SCORE_X = 600;  // Starting X position
parameter SCORE_Y = 10;   // Starting Y position

// Check if the current pixel is within the tens digit area
wire [2:0] tens_row = pixel_y - SCORE_Y;
wire [2:0] tens_col = pixel_x - SCORE_X;
wire is_tens = (pixel_x >= SCORE_X && pixel_x < SCORE_X + DIGIT_WIDTH) &&
               (pixel_y >= SCORE_Y && pixel_y < SCORE_Y + DIGIT_HEIGHT);

// Check if the current pixel is within the units digit area
wire [2:0] units_row = pixel_y - SCORE_Y;
wire [2:0] units_col = pixel_x - (SCORE_X + DIGIT_WIDTH + 2);  // 2 pixels spacing
wire is_units = (pixel_x >= (SCORE_X + DIGIT_WIDTH + 2) && pixel_x < (SCORE_X + 2*DIGIT_WIDTH + 2)) &&
                (pixel_y >= SCORE_Y && pixel_y < SCORE_Y + DIGIT_HEIGHT);

wire tens_bit = is_tens ? ((get_font(tens, tens_row) >> (7 - tens_col)) & 1'b1) : 1'b0;
wire units_bit = is_units ? ((get_font(units, units_row) >> (7 - units_col)) & 1'b1) : 1'b0;
wire is_score_number = tens_bit || units_bit;


wire [7:0] final_b = (!game_over && !win) ?
                     (is_spaceship ? 8'h00 :
                     (is_bullet ? 8'hFF :
                     (is_monster ? 8'h00 :
                     (is_score_number ? 8'hFF : 8'h00)))) :
                     (is_game_over_text ? 8'hFF :
                     (is_win_text ? 8'h00 : 8'h00));

wire [7:0] final_g = (!game_over && !win) ?
                     (is_spaceship ? 8'hFF :
                     (is_bullet ? 8'hFF :
                     (is_monster ? 8'h00 :
                     (is_score_number ? 8'hFF : 8'h00)))) :
                     (is_game_over_text ? 8'hFF :
                     (is_win_text ? 8'hFF : 8'h00));

wire [7:0] final_r = (!game_over && !win) ?
                     (is_spaceship ? 8'h00 :
                     (is_bullet ? 8'h00 :
                     (is_monster ? 8'hFF :
                     (is_score_number ? 8'hFF : 8'h00)))) :
                     (is_game_over_text ? 8'hFF :
                     (is_win_text ? 8'hFF : 8'hFF));



// Assign final colors
assign b_data = final_b;
assign g_data = final_g;
assign r_data = final_r;

// Delay the iHD, iVD, iDEN signals by one clock cycle
always @(negedge iVGA_CLK) begin
    oHS <= cHS;
    oVS <= cVS;
    oBLANK_n <= cBLANK_n;
end

endmodule