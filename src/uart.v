module uart
#(
    parameter DELAY_FRAMES = 534 // 61,440,000 (61.44Mhz) / 115200 Baud rate
)
(
    input clk,
    input uart_rx,
    output uart_tx,
    output reg [5:0] led,
    input [31:0] frequency_rx,
    output wire [31:0] frequency_out,
    output reg byteReady,
    input btn1
);

localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

reg [3:0] rxState = 0;
reg [12:0] rxCounter = 0;
reg [7:0] dataIn = 0;
reg [2:0] rxBitNumber = 0;
reg [3:0] byteCounter = 0;
reg [31:0] receivedValue = 0;
//reg byteReady = 0;

localparam RX_STATE_IDLE = 0;
localparam RX_STATE_START_BIT = 1;
localparam RX_STATE_READ_WAIT = 2;
localparam RX_STATE_READ = 3;
localparam RX_STATE_STOP_BIT = 5;
localparam ASCII_LENGTH = 8;
localparam MEMORY_LENGTH = 8;

reg [31:0] frequency_stmp = 32'd1000000;
assign frequency_out = frequency_stmp;
reg [31:0] tmp;
reg [7:0] ascii_digit;
reg [3:0] rev_digit;
reg [31:0] rev_frequency_tmp;
reg [7:0] rev_text [MEMORY_LENGTH-1:0];
reg valid;

function automatic integer reverse_decimal(integer num);
    integer rev, tdigit, count;
    begin
        rev = 0;
        while (num > 0 && count <= 8) begin
            digit = num % 10;
            rev = rev * 10 + digit;
            num = num / 10;
            count = count + 1;
        end
        reverse_decimal = rev;
    end
endfunction

always @(posedge clk) begin
    case (rxState)
        RX_STATE_IDLE: begin
            if (uart_rx == 0) begin
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
                byteReady <= 0;
            end
        end 
        RX_STATE_START_BIT: begin
            if (rxCounter == HALF_DELAY_WAIT) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 1;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_READ_WAIT: begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_READ;
            end
        end
        RX_STATE_READ: begin
            rxCounter <= 1;
            dataIn <= {uart_rx, dataIn[7:1]};
            rxBitNumber <= rxBitNumber + 1;
            if (rxBitNumber == 3'b111) begin
                rxState <= RX_STATE_STOP_BIT;
            end else begin
                rxState <= RX_STATE_READ_WAIT;
            end
        end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 

        RX_STATE_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxCounter <= 0;
                byteReady <= 1;
                rxState <= RX_STATE_IDLE;

                if (dataIn >= 8'h30 && dataIn <= 8'h39) begin
                    receivedValue <= (receivedValue * 10) + (dataIn - 8'h30);
                    byteCounter <= byteCounter + 1;
                end
                if (byteCounter > 0 && (dataIn == 8'h0D || dataIn == 8'h0A || byteCounter == ASCII_LENGTH)) begin
                    byteCounter <= 0;
                    frequency_stmp <= receivedValue;
                    receivedValue <= 0;
                end
            end
        end
    endcase
end

reg [3:0] txState = 0;
reg [24:0] txCounter = 0;
reg [7:0] dataOut = 0;
reg txPinRegister = 1;
reg [2:0] txBitNumber = 0;
reg [3:0] txByteCounter = 0;

assign uart_tx = txPinRegister;

reg [7:0] text [MEMORY_LENGTH-1:0];
integer i;
reg [3:0] digit;
reg [31:0] frequency_tmp;

always @(*) begin
    frequency_tmp = frequency_rx;
    for (i = 0; i < MEMORY_LENGTH; i = i + 1) begin
        digit = frequency_tmp % 10;
        text[7-i] = digit + 8'h30;
        frequency_tmp = frequency_tmp / 10;
    end
end

localparam TX_STATE_IDLE = 0;
localparam TX_STATE_START_BIT = 1;
localparam TX_STATE_WRITE = 2;
localparam TX_STATE_STOP_BIT = 3;
localparam TX_STATE_DEBOUNCE = 4;

always @(posedge clk) begin
    case (txState)
        TX_STATE_IDLE: begin
            if (btn1 == 0) begin
                txState <= TX_STATE_START_BIT;
                txCounter <= 0;
                txByteCounter <= 0;
            end
            else begin
                txPinRegister <= 1;
            end
        end 
        TX_STATE_START_BIT: begin
            txPinRegister <= 0;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState <= TX_STATE_WRITE;
                dataOut <= text[txByteCounter];
                txBitNumber <= 0;
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_WRITE: begin
            txPinRegister <= dataOut[txBitNumber];
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    txState <= TX_STATE_STOP_BIT;
                end else begin
                    txState <= TX_STATE_WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_STOP_BIT: begin
            txPinRegister <= 1;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txByteCounter == MEMORY_LENGTH - 1) begin
                    txState <= TX_STATE_DEBOUNCE;
                end else begin
                    txByteCounter <= txByteCounter + 1;
                    txState <= TX_STATE_START_BIT;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_DEBOUNCE: begin
            if (txCounter == 23'b111111111111111111) begin
                if (btn1 == 1)
                    txState <= TX_STATE_IDLE;
            end else
                txCounter <= txCounter + 1;
        end
    endcase
end
endmodule