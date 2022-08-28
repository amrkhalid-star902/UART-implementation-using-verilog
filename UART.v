`timescale 1ns / 1ps

module UART(
    input clk,
    input start,
    output reg tx,
    input rx,
    output reg [7:0] rxdata,
    output reg Rxflag
    
    );
    parameter clk_value=100_000_000;
    parameter baud=9600;
    parameter wait_count=clk_value/baud;
    reg bitdone=0;
    integer count=0;
    parameter idle=0,send=1,check=2;
    reg[1:0] state=idle;
    ///////////// Trigger for Baud Rate
    always@(posedge clk)
    begin
    if(state == idle)
    begin
        count <=0;
    end
    else begin
        if(count == wait_count)
        begin
            bitdone <=1'b1;
            count <=0;
        end
        else
        begin
            count<=count+1;
            bitdone <=1'b0;
        end
        
    end
    end
    //////////// TX Logic
    reg[9:0] txData;
    integer Bitidx=0;
    always@(posedge clk)
    begin
    case(state)
        idle: begin
            tx     <=1'b1;
            txData <=8'h00;
            Bitidx=0;
            if(start==1'b1)
            begin
                txData <={1'b1,8'h41,1'b0};
                state <=send;
            end
            else
            begin
                state <=idle;
            end
        
            end
         send: begin
            tx     <= txData[Bitidx];
            Bitidx <=Bitidx+1;
            state  <=check;
         
         end
         
         check: begin
         if(bitdone == 1'b1)
            begin
            if(Bitidx==10)
                begin
                state <=idle;
                end
             else
                begin
                state <=send;
                
                end   
            end
         
         end
    default : state <=idle;   
            
    endcase
    
    
    end
    
    
    ///////////// RX Logic
    integer rcount=0;
    integer rindex=0;
    parameter ridle=0,rwait=1,recv=2,rcheck=3;
    reg [1:0] rstate;
    always@(posedge clk)
    begin
    case(rstate)
    ridle:
        begin
            Rxflag <=0;
            rxdata <=8'h00;
            rindex <=0;
            
            if(rx == 1'b0)
            begin
                rstate <= recv;
            end
            else
            begin
                rstate <=ridle;
            end
        end
        
    rwait:
        begin
            if(rcount < wait_count/2 )
            begin
                rcount <= rcount+1;
                rstate <= rwait;
            end
            else
            begin
                rcount <=0;
                rstate <=recv;
                rxdata <={rx,rxdata[7:1]};
            end
        
        end    
    recv:
        begin
            if(bitdone == 1'b1)
            begin
                rstate <= rcheck;
            end
            else
            begin
                rstate <=recv;
           end
        end
     rcheck:
        begin
        if(rindex <8)
            begin
                rindex <= rindex+1;
                rstate <= rwait;
            end
        else
            begin
                rstate <=ridle;
                rindex <=0;
                Rxflag <= 1'b1;
                
            end    
        
        end 
        
    default : rstate <=ridle;      
    endcase
    end
    
    
    
    
endmodule
