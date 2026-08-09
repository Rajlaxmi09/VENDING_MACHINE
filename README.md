# Digital Vending Machine Controller — Verilog RTL Design

A synthesizable Verilog RTL project implementing a finite-state-machine-based
vending machine controller, designed, synthesized, and functionally verified
in Xilinx Vivado targeting an Artix-7 FPGA (`xc7a35tcpg236-1`).

The controller accepts money in two parts (`money` + `extra_money`), tracks
running balance, lets the user select one of three products, and dispenses
the product — with change — once enough money has been inserted.

---

## Features

- **FSM-based control logic** — 7-state finite state machine (`IDLE`,
  per-product `WAIT` states, per-product `DISPENSE` states) with
  asynchronous reset.
- **Incremental payment support** — accepts money across multiple clock
  cycles and accumulates balance until the selected product's price is met.
- **Automatic change calculation** — computes and returns leftover balance
  after dispensing via combinational subtractor logic.
- **Three product outputs** — `tea`, `coffee`, `milk`, each registered and
  pulsed for exactly one clock cycle on dispense.
- **Fully synthesizable** — clean synthesis in Vivado with no inferred
  latches; verified via RTL schematic and post-synthesis netlist.

---

## Architecture

| Signal              | Direction | Width | Description                          |
|----------------------|-----------|-------|---------------------------------------|
| `clk`                | Input     | 1     | System clock                          |
| `reset`              | Input     | 1     | Asynchronous active-high reset        |
| `money`              | Input     | 5     | Primary money input                   |
| `extra_money`        | Input     | 5     | Additional money input (same cycle)   |
| `select_product`     | Input     | 2     | `01`=Tea, `10`=Coffee, `11`=Milk      |
| `balance`            | Output    | 5     | Current accumulated / change balance  |
| `tea`, `coffee`, `milk` | Output | 1 each | Dispense pulse (1 clock cycle)     |

**Product pricing:**

| Product | Price |
|---------|-------|
| Milk    | 5     |
| Tea     | 10    |
| Coffee  | 15    |

Synthesis results (Vivado, Artix-7): **51 logic cells · 22 I/O ports · 125 nets**

### RTL Schematic

The synthesized RTL schematic below shows the datapath comparators
(`RTL_GEQ`), balance subtractors (`RTL_SUB`), state register with async
reset (`RTL_REG_ASYNC`), and the registered dispense outputs.

`Schematic.JPG`

---

## Simulation

The design was functionally verified in Vivado's behavioral simulator by
driving a sequence of coin insertions and product selections and observing
the `balance`, `tea`, `coffee`, and `milk` outputs.

`simulation.JPG`

**Example test sequence:**
1. Reset the machine.
2. Select Coffee, insert money across two cycles (10 + 5) → coffee dispenses.
3. Select Tea, insert 10 in one shot → tea dispenses.
4. Select Milk, overpay (5 + 5) → milk dispenses with change reflected in `balance`.
5. Select Coffee again, pay in three increments of 5 → coffee dispenses.

---

## Repository Structure

```
├── vending_machine.v       # Top-level RTL source (FSM + datapath)
├── vending_machine_tb.v    # Self-checking testbench
├── Schematic.JPG           # Post-synthesis RTL schematic
├── simulation.JPG          # Behavioral simulation waveform
└── README.md
```

---

## Getting Started (Vivado)

1. Create a new RTL project targeting your FPGA part (or the same
   `xc7a35tcpg236-1` used here).
2. Add `vending_machine.v` as a design source.
3. Add `vending_machine_tb.v` as a simulation source and set it as the
   simulation top module.
4. Run **Run Simulation → Run Behavioral Simulation** to view the waveform.
5. Run **Synthesis** to generate the RTL schematic and utilization report.

---

## Possible Extensions

- Guard against re-dispensing while a selection is still held (require
  `select_product` to return to idle before re-arming).
- Add a 7-segment display driver to show live balance on hardware.
- Map outputs to onboard LEDs for a physical FPGA board demo (e.g., Basys3).
- Add support for coin-return / cancel functionality.

---

## Author

Designed and independently implemented as a personal RTL design project to
practice FSM design, datapath implementation, and functional verification
in Verilog / Vivado.
