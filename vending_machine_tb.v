`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// vending_machine_tb.v
//
// Testbench reconstructed to mirror the stimulus style visible in the
// original simulation waveform: an initial reset pulse, followed by a
// sequence of money insertions and product selections, with 100 ns
// timesteps and a 10 ns period clock.
//
// NOTE: exact stimulus values from the deleted original testbench could
// not be recovered - this reproduces the same *style* of test (money
// build-up over several cycles, each of the three products selected,
// leftover balance/change observed) so you can re-verify behavior and
// tweak values to match what you remember of the original.
//////////////////////////////////////////////////////////////////////////////

module vending_machine_tb;

    reg        clk;
    reg        reset;
    reg  [4:0] money;
    reg  [4:0] extra_money;
    reg  [1:0] select_product;

    wire [4:0] balance;
    wire       tea;
    wire       coffee;
    wire       milk;

    // Device under test
    vending_machine uut (
        .clk            (clk),
        .reset          (reset),
        .money          (money),
        .extra_money    (extra_money),
        .select_product (select_product),
        .balance        (balance),
        .tea            (tea),
        .coffee         (coffee),
        .milk           (milk)
    );

    // 10 ns period clock (100 MHz)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Reset
        reset          = 1'b1;
        money          = 5'd0;
        extra_money    = 5'd0;
        select_product = 2'b00;
        #100;
        reset = 1'b0;

        // ---- Select Coffee (price 15), pay in two parts ----
        select_product = 2'b10;   // coffee
        money          = 5'd10;
        extra_money    = 5'd0;
        #100;
        money          = 5'd5;    // total now covers 15
        #100;
        select_product = 2'b00;
        money          = 5'd0;
        #100;

        // ---- Select Tea (price 10), pay in one shot ----
        select_product = 2'b01;   // tea
        money          = 5'd10;
        extra_money    = 5'd0;
        #100;
        select_product = 2'b00;
        money          = 5'd0;
        #100;

        // ---- Select Milk (price 5), overpay to see change ----
        select_product = 2'b11;   // milk
        money          = 5'd5;
        extra_money    = 5'd5;    // overpay by 5
        #100;
        select_product = 2'b00;
        money          = 5'd0;
        extra_money    = 5'd0;
        #100;

        // ---- Select Coffee again, incremental payments ----
        select_product = 2'b10;
        money          = 5'd5;
        #100;
        money          = 5'd5;
        #100;
        money          = 5'd5;
        #100;
        select_product = 2'b00;
        money          = 5'd0;
        #100;

        #100;
        $display("Simulation complete.");
        $finish;
    end

    // Simple transcript of dispense events
    always @(posedge clk) begin
        if (tea)    $display("[%0t ns] TEA dispensed, balance=%0d", $time, balance);
        if (coffee) $display("[%0t ns] COFFEE dispensed, balance=%0d", $time, balance);
        if (milk)   $display("[%0t ns] MILK dispensed, balance=%0d", $time, balance);
    end

endmodule
