# AHB Bus with Layered Testbench
## Introduction
This project implements a fully functional AHB-Lite compliant slave module in Verilog, intended to interface with an AMBA-based system. The slave supports basic read and write operations and includes configurable wait states to simulate realistic memory latency. The design is carefully modeled using a Finite State Machine (FSM) to adhere to AHB-Lite protocol behavior.

A major highlight of this project is the layered SystemVerilog testbench, designed to verify the slave module through a clean, reusable, and modular architecture. The testbench structure separates the stimulus generation, protocol checking, and environment setup to reflect industry-standard verification practices.

## Features

<table style="border: 1px solid black; border-collapse: collapse;">
  <tr style="background-color: #cccccc;">
    <th style="border: 1px solid black; padding: 8px;">Feature</th>
    <th style="border: 1px solid black; padding: 8px;">Description</th>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">Protocol</td>
    <td style="border: 1px solid black; padding: 8px;">AHB-Lite (single master, single slave)</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">FSM States</td>
    <td style="border: 1px solid black; padding: 8px;">IDLE, WAIT, RESP, ERRWAIT, ERRRESP</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">Wait State Handling</td>
    <td style="border: 1px solid black; padding: 8px;">Configurable wait cycles before response phase</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">Address Range Check</td>
    <td style="border: 1px solid black; padding: 8px;">Detects out-of-bound addresses and generates an error response</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">Memory Depth</td>
    <td style="border: 1px solid black; padding: 8px;">Configurable internal memory (default: 256 words)</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">Read/Write Support</td>
    <td style="border: 1px solid black; padding: 8px;">Handles both read and write operations</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">Layered Testbench</td>
    <td style="border: 1px solid black; padding: 8px;">Modular testbench with Driver, Monitor, Scoreboard, and Interface</td>
  </tr>
</table>

## FSM Description

<table style="border: 1px solid black; border-collapse: collapse;">
  <tr style="background-color: #cccccc;">
    <th style="border: 1px solid black; padding: 8px;">FSM State</th>
    <th style="border: 1px solid black; padding: 8px;">Description</th>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">SL_IDLE</td>
    <td style="border: 1px solid black; padding: 8px;">Waits for a valid transfer (HTRANS is NONSEQ or SEQ and HSEL is high)</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">SL_WAIT</td>
    <td style="border: 1px solid black; padding: 8px;">Inserts wait states to simulate latency (duration based on WAIT_CYCLES)</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">SL_RESP</td>
    <td style="border: 1px solid black; padding: 8px;">Generates response; updates memory in case of write, provides HRDATA in case of read</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">SL_ERRWAIT</td>
    <td style="border: 1px solid black; padding: 8px;">Signals error response (HRESP=1, HREADYOUT=0) for one cycle if address is invalid</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 8px;">SL_ERRRESP</td>
    <td style="border: 1px solid black; padding: 8px;">Continues error signaling (HRESP=1, HREADYOUT=1) before returning to IDLE</td>
  </tr>
</table>

## Testbench Overview
- The layered testbench follows a structured approach inspired by the UVM-like architecture:

- Interface Module: Bundles all AHB signals for clean connectivity between DUT and test components.

- Driver: Sends valid AHB read/write transfers by manipulating HTRANS, HADDR, HWRITE, and HWDATA.

- Monitor: Observes HRDATA, HREADYOUT, and HRESP, and logs behavior for analysis.

- Scoreboard: Compares expected vs actual values to flag mismatches in functional correctness.

- Top Testbench: Instantiates all components and connects them via the interface.

## RTL

<img width="745" alt="image" src="https://github.com/user-attachments/assets/a91ad990-df25-4d88-bc0d-5c961f7c8549" />



## How to Run
- Compile all Verilog and SystemVerilog files in your simulator (e.g., using VCS, Questa, or XSIM).

- Run the simulation and observe waveform or logs to validate correctness.

- Customize WAIT_CYCLES and memory depth as needed for different test scenarios.

## Future Enhancements
- Extend support for multiple masters and protection attributes.

- Add assertions and coverage collection.

- Create error injection scenarios for robustness testing.






 
