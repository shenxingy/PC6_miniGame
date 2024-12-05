module PS2_Interface(
    input inclock, resetn,
    inout ps2_clock, ps2_data,
    output ps2_key_pressed,
    output [7:0] ps2_key_data,
    output reg [7:0] last_data_received,
    output reg move_left, move_right, fire, pause
);

    // Internal Registers
    reg [7:0] ascii_data;       // Store mapped ASCII value
    reg key_released;           // Flag to detect Break Code (key release)

    // Mapping scan codes to control signals
    always @(posedge inclock or negedge resetn) begin
        if (!resetn) begin
            // Reset all control signals and internal states
            move_left <= 1'b0;
            move_right <= 1'b0;
            fire <= 1'b0;
            pause <= 1'b0;
            ascii_data <= 8'd32;  // Default to space character
            key_released <= 1'b0;
        end
        else if (ps2_key_pressed) begin
            if (ps2_key_data == 8'hF0) begin
                // Break Code detected
                key_released <= 1'b1;
            end else begin
                if (key_released) begin
                    // Key release: process the subsequent key code
                    key_released <= 1'b0; // Clear release flag
                    case (ps2_key_data)
                        8'h1C: move_left <= 1'b0;  // 'A' key released
                        8'h23: move_right <= 1'b0; // 'D' key released
                        8'h29: fire <= 1'b0;       // Space key released
                        8'h76: pause <= 1'b0;      // 'ESC' key released
                    endcase
                end else begin
                    // Key press: process the key code
                    case (ps2_key_data)
                        8'h1C: move_left <= 1'b1;  // 'A' key pressed
                        8'h23: move_right <= 1'b1; // 'D' key pressed
                        8'h29: fire <= 1'b1;       // Space key pressed
                        8'h76: pause <= 1'b1;      // 'ESC' key pressed
                    endcase
                end
            end
        end
    end

    // Update the last_data_received register
    always @(posedge inclock) begin
        if (!resetn)
            last_data_received <= 8'h00;
        else if (ps2_key_pressed)
            last_data_received <= ps2_key_data;
    end

    // PS2 Controller instantiation
    PS2_Controller PS2 (
        .CLOCK_50 (inclock),
        .reset (~resetn),
        .PS2_CLK (ps2_clock),
        .PS2_DAT (ps2_data),
        .received_data (ps2_key_data),
        .received_data_en (ps2_key_pressed)
    );

endmodule
