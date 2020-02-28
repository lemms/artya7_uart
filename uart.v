`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Laurence Emms
// 
// Create Date: 02/25/2020 10:21:21 PM
// Module Name: uart
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart(
    input clk,
    input reset,
    input send_btn,
    input uart_txd_in,
    output led0_b,
    output led0_r,
    output uart_rxd_out
    );

parameter read_idle = 1'd0;
parameter read_recv = 1'd1;

parameter write_idle = 2'd0;
parameter write_start = 2'd1;
parameter write_bits = 2'd2;
parameter write_end = 2'd3;

parameter uart_offset = 16'd5210;
parameter uart_len = 16'd10420;

parameter c_H = 8'h48;
parameter c_d = 8'h64;
parameter c_e = 8'h65;
parameter c_l = 8'h6C;
parameter c_o = 8'h6F;
parameter c_r = 8'h72;
parameter c_w = 8'h77;

parameter c_CR = 8'h0D;
parameter c_EXCLAMATION = 8'h21;
parameter c_LF = 8'h0A;
parameter c_SPACE = 8'h20;

parameter string_end = 5'd13;

reg read_state_reg;
reg led0_b_r;
reg led0_r_r;

reg [1:0] write_state_reg;
reg [15:0] clock_counter;
reg clock_trigger;
reg [3:0] send_bit;
reg [7:0] send_char;
reg [7:0] send_string [13:0];
reg [4:0] send_index;

reg uart_rxd_out_r;

// Design implementation

assign led0_b = led0_b_r;
assign led0_r = led0_r_r;

assign uart_rxd_out = uart_rxd_out_r;

// Update 9600 baud clock counter
always @(posedge clk or posedge reset)
begin
    if (reset)
        begin
            clock_counter <= 16'd0;
        end
    else
        begin
            if (clock_counter == uart_len)
                begin
                    clock_trigger <= 1'd1;
                    clock_counter <= 16'd0;
                end
            else
                begin
                    clock_trigger <= 1'd0;
                    clock_counter <= clock_counter + 1;
                end
        end
end

// Send message
always @(posedge clk or posedge reset)
begin
    if (reset)
        begin
            write_state_reg <= write_idle;
            send_bit <= 4'd0;
            send_string[0] <= c_H;
            send_string[1] <= c_e;
            send_string[2] <= c_l;
            send_string[3] <= c_l;
            send_string[4] <= c_o;
            send_string[5] <= c_SPACE;
            send_string[6] <= c_w;
            send_string[7] <= c_o;
            send_string[8] <= c_r;
            send_string[9] <= c_l;
            send_string[10] <= c_d;
            send_string[11] <= c_EXCLAMATION;
            send_string[12] <= c_CR;
            send_string[13] <= c_LF;
            send_index <= 5'd0;
            send_char <= send_string[5'd0];
        end
    else if (clock_trigger)
        begin
            case (write_state_reg)
                write_idle:
                    begin
                        send_index <= 5'd0;
                        send_char <= send_string[5'd0];
                        uart_rxd_out_r <= 1'b1;
                        if (send_btn)
                            write_state_reg <= write_start; // Move to start state
                    end
                write_start:
                    begin
                        send_bit <= 4'd0;
                        uart_rxd_out_r <= 1'b0; // Send 0 start bit
                        write_state_reg <= write_bits; // Move to bits state
                    end
                write_bits:
                    begin
                        if (send_bit == 4'd7) // Last bit
                            begin
                                uart_rxd_out_r <= send_char[send_bit]; // Send char bit
                                write_state_reg <= write_end; // Move to end state
                            end
                        else
                            begin
                                uart_rxd_out_r <= send_char[send_bit]; // Send char bit
                                send_bit <= send_bit + 1;
                            end
                    end
                write_end:
                    begin
                        uart_rxd_out_r <= 1'b1; // Send 1 end bit
                        send_index <= send_index + 1;
                        send_char <= send_string[send_index + 1]; // Read next character
                        if (send_index == string_end)
                            write_state_reg <= write_idle; // Move to idle state
                        else
                            write_state_reg <= write_start; // Move to start state
                    end
            endcase
        end
end

// Update read state
always @(posedge clk or posedge reset)
begin
    if (reset)
        read_state_reg <= read_idle;
    else
        if (read_state_reg == read_idle && ~uart_txd_in)
            read_state_reg <= read_recv;
end

// Update status LED
always @(posedge clk or posedge reset)
begin
    if (reset)
        begin
            // set led to red when idle
            led0_b_r <= 1'b0;
            led0_r_r <= 1'b1;
        end
    else
        begin
            if (read_state_reg == read_idle)
                begin
                    // set led to red when idle
                    led0_b_r <= 1'b0;
                    led0_r_r <= 1'b1;
                end
            else if (read_state_reg == read_recv)
                begin
                    // set led to blue when recv
                    led0_b_r <= 1'b1;
                    led0_r_r <= 1'b0;
                end
        end
end

endmodule
