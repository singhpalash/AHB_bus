# AHB_bus
AHB-Lite Slave with Layered Testbench
Introduction
This project implements a fully functional AHB-Lite compliant slave module in Verilog, intended to interface with an AMBA-based system. The slave supports basic read and write operations and includes configurable wait states to simulate realistic memory latency. The design is carefully modeled using a Finite State Machine (FSM) to adhere to AHB-Lite protocol behavior.

A major highlight of this project is the layered SystemVerilog testbench, designed to verify the slave module through a clean, reusable, and modular architecture. The testbench structure separates the stimulus generation, protocol checking, and environment setup to reflect industry-standard verification practices.

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



 
