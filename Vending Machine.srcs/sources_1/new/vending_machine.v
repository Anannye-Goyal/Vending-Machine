`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: Simple Vending Machine
// Module Name: vending_machine
// Project Name: Vending Machine
//////////////////////////////////////////////////////////////////////////////////

module vending_machine(input clk,
                       input reset, 
                       input [2:0] sel,
                       input coin50,
                       input coin100,
                       input cancel,
                       output ready,
                       output dispense,
                       output coin50_out,
                       output coin100_out,
                       output out_of_stock
    );
    
    reg [31:0] timer_cnt;
    parameter clk_period_ns = 10;        // 10 ns period  100 MHz
    parameter timeout_nano_secs = 100;    // timeout in 30 ns
    parameter timeout_limit = timeout_nano_secs / clk_period_ns;
    wire timer_expired = (timer_cnt >= timeout_limit);
    
    
    reg [2:0] select_fix;
    reg [2:0] state, next_state;
    
    reg [2:0] inventory [0:4];
    wire valid_sel = (select_fix >= 1 && select_fix <=5);
    wire stock_empty = valid_sel ? (inventory[select_fix - 1] == 0) : 1'b1;
    
    reg change_done;
    reg refund_done;
    
    reg [8:0] credit;
    reg [8:0] change_amt;
    
    parameter IDLE = 3'd0,
              COIN_INSERT = 3'd1,
              DISPENSE = 3'd2,
              REFUND = 3'd3,
              CHANGE_RETURN = 3'd4;
              
    wire [7:0] item_price = (select_fix == 1) ? 8'd50 :
                            (select_fix == 2) ? 8'd100 :
                            (select_fix == 3) ? 8'd150 :
                            (select_fix == 4) ? 8'd200 :
                            (select_fix == 5) ? 8'd250 : 8'd0;          
              
    reg ready_reg;
    reg dispense_reg;
    reg out_of_stock_reg;   
    reg coin50_out_reg;
    reg coin100_out_reg;       
              
    always @(*)
        begin
           next_state = state;
           ready_reg = 1'b0;
           out_of_stock_reg = 1'b0;
           dispense_reg = 1'b0; 
           
           case(state)
              IDLE: begin
                 ready_reg = reset ? 1'b0 : 1'b1;
                 next_state = sel ? COIN_INSERT : IDLE;
              end   
              COIN_INSERT: begin
                 if(timer_expired || cancel) next_state = REFUND; 
                 else if(stock_empty) begin 
                    out_of_stock_reg = 1'b1;
                    next_state = REFUND;  
                 end   
                 else if(credit < item_price) next_state = COIN_INSERT;
                 else if(credit >= item_price) next_state = DISPENSE;
              end
              DISPENSE: begin
                 dispense_reg = 1'b1;
                 next_state = CHANGE_RETURN;
              end   
              CHANGE_RETURN: next_state = change_done ? IDLE : CHANGE_RETURN;
              REFUND: next_state = refund_done ? IDLE : REFUND;
              default: next_state = IDLE;
           endcase
        end     
        
     always @(posedge clk)
        begin
           if(reset) begin
              state <= IDLE;
              credit <= 0;
              timer_cnt <= 0;
              select_fix <= 0;
              refund_done <= 0;
              change_amt <= 0;
              change_done <= 0;
              coin50_out_reg <= 0;
              coin100_out_reg <= 0;
              dispense_reg <= 0;
              
              inventory[0] <= 5;
              inventory[1] <= 5;
              inventory[2] <= 5;
              inventory[3] <= 5;
              inventory[4] <= 5;
           end
           else begin
              coin50_out_reg <= 0;
              coin100_out_reg <= 0;
              state <= next_state;
              
              if(state == IDLE && sel!= 0 ) select_fix <= sel;
              
              if(state == COIN_INSERT) timer_cnt <= timer_cnt + 1;
              else timer_cnt <= 0;
              
              if(state == COIN_INSERT) begin
                 if(coin50) credit <= credit + 9'd50;
                 if(coin100) credit <= credit + 9'd100;          
              end
              
              if(state == DISPENSE) begin
                 if(credit > item_price) change_amt <= credit - item_price;
                 else change_amt <= 0;
                 if(valid_sel && inventory[select_fix - 1] > 0) inventory[select_fix - 1] <= inventory[select_fix - 1] - 1;
              end   
              
              if(state == CHANGE_RETURN) begin
                 
                 if(change_amt >= 100) begin
                    change_amt <= change_amt - 8'd100;
                    coin100_out_reg <= 1;
                 end
                 else if(change_amt >=50) begin
                    change_amt <= change_amt - 8'd50;
                    coin50_out_reg <= 1;
                 end   
                 else begin
                    change_done <= 1;
                    credit <= 0;
                 end   
              end
              else change_done <= 0;
              
              if(state == REFUND) begin
                 
                 if(credit >= 100) begin
                    credit <= credit - 8'd100;
                    coin100_out_reg <= 1;
                 end
                 else if(credit >=50) begin
                    credit <= credit - 8'd50;
                    coin50_out_reg <= 1;
                 end   
                 else refund_done <= 1;
              end
              else refund_done <= 0;
           end                        
        end
        
     assign ready = ready_reg;
     assign out_of_stock = out_of_stock_reg;
     assign dispense = dispense_reg;
     assign coin50_out = coin50_out_reg;
     assign coin100_out = coin100_out_reg; 
        
endmodule
