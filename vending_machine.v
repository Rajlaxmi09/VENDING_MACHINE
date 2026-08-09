`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// vending_machine.v
//
// RECONSTRUCTED from schematic + simulation waveform after the original
// source was accidentally deleted. Assumptions made during reconstruction
// (change these constants if they don't match the original design):
//
//   select_product encoding : 2'b01 = Tea, 2'b10 = Coffee, 2'b11 = Milk,
//                              2'b00 = no selection (idle)
//   TEA_PRICE    = 10
//   COFFEE_PRICE = 15
//   MILK_PRICE   = 5
//
// Behavior:
//   - money + extra_money are summed each cycle (total_i, matches the
//     RTL_ADD block seen in the schematic).
//   - Once a product is selected, the FSM waits (accumulating balance)
//     until enough money has been inserted (RTL_GEQ comparators), then
//     moves to a one-cycle DISPENSE state.
//   - In DISPENSE state the corresponding output pulses high for one
//     clock, balance is updated to reflect any change (RTL_SUB), and the
//     machine returns to IDLE with balance cleared on the next cycle.
//   - reset is asynchronous and returns the FSM to IDLE (matches the
//     RTL_REG_ASYNC block on state_reg in the schematic).
//////////////////////////////////////////////////////////////////////////////

module vending_machine (
    input  wire       clk,
    input  wire       reset,
    input  wire [4:0] money,
    input  wire [4:0] extra_money,
    input  wire [1:0] select_product,
    output reg  [4:0] balance,
    output reg         tea,
    output reg         coffee,
    output reg         milk
);

    // ---------------------------------------------------------------
    // Parameters 
    // ---------------------------------------------------------------
    localparam [4:0] TEA_PRICE    = 5'd10;
    localparam [4:0] COFFEE_PRICE = 5'd15;
    localparam [4:0] MILK_PRICE   = 5'd5;

    localparam [1:0] SEL_NONE   = 2'b00;
    localparam [1:0] SEL_TEA    = 2'b01;
    localparam [1:0] SEL_COFFEE = 2'b10;
    localparam [1:0] SEL_MILK   = 2'b11;

    // ---------------------------------------------------------------
    // State encoding
    // ---------------------------------------------------------------
    localparam [2:0] S_IDLE        = 3'b000,
                      S_TEA_WAIT    = 3'b001,
                      S_COFFEE_WAIT = 3'b010,
                      S_MILK_WAIT   = 3'b011,
                      S_TEA_DISP    = 3'b100,
                      S_COFFEE_DISP = 3'b101,
                      S_MILK_DISP   = 3'b110;

    reg [2:0] state_reg, next_state_reg;
    reg [5:0] total_i;          // money + extra_money (RTL_ADD)
    reg [4:0] balance_next;

    // ---------------------------------------------------------------
    // Combinational: total money inserted this cycle
    // ---------------------------------------------------------------
    always @(*) begin
        total_i = money + extra_money;
    end

    // ---------------------------------------------------------------
    // Next-state logic (RTL_GEQ / RTL_EQ / RTL_MUX equivalent)
    // ---------------------------------------------------------------
    always @(*) begin
        next_state_reg = state_reg;
        case (state_reg)
            S_IDLE: begin
                case (select_product)
                    SEL_TEA:    next_state_reg = S_TEA_WAIT;
                    SEL_COFFEE: next_state_reg = S_COFFEE_WAIT;
                    SEL_MILK:   next_state_reg = S_MILK_WAIT;
                    default:    next_state_reg = S_IDLE;
                endcase
            end

            S_TEA_WAIT: begin
                if (balance + total_i >= TEA_PRICE)
                    next_state_reg = S_TEA_DISP;
                else
                    next_state_reg = S_TEA_WAIT;
            end

            S_COFFEE_WAIT: begin
                if (balance + total_i >= COFFEE_PRICE)
                    next_state_reg = S_COFFEE_DISP;
                else
                    next_state_reg = S_COFFEE_WAIT;
            end

            S_MILK_WAIT: begin
                if (balance + total_i >= MILK_PRICE)
                    next_state_reg = S_MILK_DISP;
                else
                    next_state_reg = S_MILK_WAIT;
            end

            S_TEA_DISP:    next_state_reg = S_IDLE;
            S_COFFEE_DISP: next_state_reg = S_IDLE;
            S_MILK_DISP:   next_state_reg = S_IDLE;

            default: next_state_reg = S_IDLE;
        endcase
    end

    // ---------------------------------------------------------------
    // Balance datapath (RTL_SUB / RTL_MUX equivalent)
    // ---------------------------------------------------------------
    always @(*) begin
        balance_next = balance;
        case (state_reg)
            S_TEA_WAIT, S_COFFEE_WAIT, S_MILK_WAIT:
                balance_next = balance + total_i[4:0];

            S_TEA_DISP:    balance_next = (balance - TEA_PRICE);
            S_COFFEE_DISP: balance_next = (balance - COFFEE_PRICE);
            S_MILK_DISP:   balance_next = (balance - MILK_PRICE);

            default: balance_next = 5'd0; // IDLE: cleared / ready for next customer
        endcase
    end

    // ---------------------------------------------------------------
    // Sequential: state register (async reset, matches RTL_REG_ASYNC)
    // ---------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            state_reg <= S_IDLE;
        else
            state_reg <= next_state_reg;
    end

    // ---------------------------------------------------------------
    // Sequential: balance_reg
    // ---------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            balance <= 5'd0;
        else
            balance <= balance_next;
    end

    // ---------------------------------------------------------------
    // Sequential: dispense output registers (coffee_reg / milk_reg / tea_reg)
    // Each pulses high for exactly one clock cycle in its DISP state.
    // ---------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tea    <= 1'b0;
            coffee <= 1'b0;
            milk   <= 1'b0;
        end else begin
            tea    <= (next_state_reg == S_TEA_DISP)    && (state_reg == S_TEA_WAIT);
            coffee <= (next_state_reg == S_COFFEE_DISP) && (state_reg == S_COFFEE_WAIT);
            milk   <= (next_state_reg == S_MILK_DISP)   && (state_reg == S_MILK_WAIT);
        end
    end

endmodule
