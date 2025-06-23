## Verilog Implementation of a Simple Vending Machine

## Overview
This project implements a simple vending machine controller in Verilog HDL.  
It can accept two types of coin (50, 100), allows selection of five distinct items and manages dispensing, out‑of‑stock, and refund operations via a finite‑state machine.

## Features
- **Coin Handling**: Supports two coin inputs (50 and 100).  
- **Item Selection**: Can select 5 products, having its own price and stock.  
- **Dispensing**: Automatically dispenses when enough credit is accumulated.  
- **Refund/Cancellation**: User can cancel at any time before dispensing and gets an immediate refund.  
- **Out‑of‑Stock Detection**: Flags “out of stock” for items not in stock.  


## Main module

```verilog
module vending_machine(
    input        clk,           // System clock
    input        reset,         // Active‑high reset
    input  [2:0] sel,           // Item selection (0–4)
    input        coin50,        // Insert 50 
    input        coin100,       // Insert 100
    input        cancel,        // Cancel in between
    output       ready,         // Machine ready to take a new order
    output       dispense,      // High when dispensing
    output       coin50_out,    // High on 50 refund
    output       coin100_out,   // High on 100 refund
    output       out_of_stock   // Indicates selected item unavailable
);
```  

## Price Structure

| Item Number (`sel`) | Item Name | Price     | Initial Stock |
|:-------------------:|:---------:|:---------:|:-------------:|
| 1                   | Chips     | 50        | 5             |
| 2                   | Juice     | 100       | 5             |
| 3                   | Candy     | 150       | 5             |
| 4                   | Chocolate | 200       | 5             |
| 5                   | Cupcake   | 250       | 5             |

## State Table

| Current State | Input Condition                              | Next State    | Action to be Performed            |
|---------------|----------------------------------------------|---------------|-----------------------------------|
| IDLE          | Sel = 0                                      | IDLE          | Enter a valid Select              |
| IDLE          | Sel != 0                                     | COIN_INSERT   | Insert money                      |
| COIN_INSERT   | Credit < Price                               | COIN_INSERT   | Insert money                      |
| COIN_INSERT   | Credit >= Price                              | DISPENSE      | Item will get dispensed           |
| COIN_INSERT   | Cancel = 1                                   | REFUND        | Money will be refunded            |
| COIN_INSERT   | Timeout                                      | REFUND        | Money will be refunded            |
| COIN_INSERT   | Item stock = 0                               | REFUND        | Money will be refunded            |
| DISPENSE      | ----------x-----------                       | CHANGE_RETURN | Change will be given              |
| REFUND        | ----------x-----------                       | IDLE          | Money refunded                    |
| CHANGE_RETURN | ----------x-----------                       | IDLE          | Money given back                  |


## Test Cases

### TC1: Exact‑Price Purchase
- **Description**: Buy Juice (ID 2, price 100) with exact 100 coin.  

---

### TC2: Overpayment & Change
- **Description**: Buy Chips (ID 1, price 50) by inserting 100, expect 50 refund.  

---

### TC3: Out‑of‑Stock Handling
- **Description**: Finish Cupcake (ID 5, price 250) by ordering it 5 times, and then order it 6th time to get an out of stock message.
  
---

### TC4: Timeout
- **Description**: Try to buy Chocolate (ID 4, price 200), but the time limit (100 ns) exceeded. 

---

### TC5: Cancel in Between
- **Description**: Insert 100 to buy Candy (ID 3, price 150¢), then cancel.  






