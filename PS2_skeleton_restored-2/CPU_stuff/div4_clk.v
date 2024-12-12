module div4_clk (
    input wire clk,      
    input wire reset,    
    output reg div4_clk  
);

    reg [1:0] counter;   

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 2'b00;
            div4_clk <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 2'b11) 
                div4_clk <= ~div4_clk;  
        end
    end

endmodule
