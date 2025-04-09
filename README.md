# AHB_bus
AHB-Lite Slave with Layered Testbench
Introduction
This project implements a fully functional AHB-Lite compliant slave module in Verilog, intended to interface with an AMBA-based system. The slave supports basic read and write operations and includes configurable wait states to simulate realistic memory latency. The design is carefully modeled using a Finite State Machine (FSM) to adhere to AHB-Lite protocol behavior.

A major highlight of this project is the layered SystemVerilog testbench, designed to verify the slave module through a clean, reusable, and modular architecture. The testbench structure separates the stimulus generation, protocol checking, and environment setup to reflect industry-standard verification practices.

Features
Feature	Description
Protocol	AHB-Lite (single master, single slave)
FSM States	IDLE, WAIT, RESP, ERRWAIT, ERRRESP
Wait State Handling	Configurable wait cycles before data phase
Address Range Check	Simple out-of-bound address detection with error response
Memory Depth	Configurable internal memory array (default: 256 words)
Read/Write Support	Read and write operations handled in RESP phase
Layered Testbench	Driver, Monitor, Scoreboard architecture for protocol validation
FSM Description
State	Meaning
IDLE	Waits for valid AHB transfer
WAIT	Simulates latency using a counter
RESP	Drives read data or performs memory write
ERRWAIT	First stage of error response, HREADYOUT low, HRESP high
ERRRESP	Second stage of error response, HREADYOUT high, HRESP still high
File Structure
graphql
Copy
Edit
ahb_slave/
├── rtl/
│   └── ahb_slave.v              # AHB-Lite slave RTL code
├── tb/
│   ├── top_tb.sv               # Top-level testbench
│   ├── driver.sv               # Stimulus generator
│   ├── monitor.sv              # Protocol monitor
│   ├── scoreboard.sv           # Functional correctness checker
│   └── interface.sv            # Interface definition for AHB signals
└── README.md                   # Project documentation
Testbench Overview
The layered testbench follows a structured approach inspired by the UVM-like architecture:

Interface Module: Bundles all AHB signals for clean connectivity between DUT and test components.

Driver: Sends valid AHB read/write transfers by manipulating HTRANS, HADDR, HWRITE, and HWDATA.

Monitor: Observes HRDATA, HREADYOUT, and HRESP, and logs behavior for analysis.

Scoreboard: Compares expected vs actual values to flag mismatches in functional correctness.

Top Testbench: Instantiates all components and connects them via the interface.

How to Run
Compile all Verilog and SystemVerilog files in your simulator (e.g., using VCS, Questa, or XSIM).

Run the simulation and observe waveform or logs to validate correctness.

Customize WAIT_CYCLES and memory depth as needed for different test scenarios.

Future Enhancements
Extend support for multiple master and protection attributes.

Add assertions and coverage collection.

Create error injection scenarios for robustness testing.

 
