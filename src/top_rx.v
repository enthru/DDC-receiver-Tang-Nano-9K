`timescale 1 ns / 1 ps
module Top_rx(
	input sck,			//61.440MHz
    input uart_rx,
	output uart_tx,

    input btn1,

	// ADC interface		
	input [11:0] adc_data,
	input adc_overrange,

	// I2S bus, master mode
	output DOUT,
	output BCK,
	output MCK,
	output LRCK,
	
    //LED
    output [5:0]led,

    //reconfig
    output reg Reconfig = 1'b1,
    input Reset_Button,

    output test
	);

    wire reset = 1'b1;
    wire clipping,work_rx;

    Gowin_CLKDIV5 div5(
        .clkout(MCK), //output clkout MCK = sck/5
        .hclkin(sck), //input hclkin
        .resetn(1'b1) //input resetn
    );

    Gowin_CLKDIV4 div4(
        .clkout(BCK), //output clkout BCK = MCK/4
        .hclkin(MCK), //input hclkin
        .resetn(1'b1) //input resetn
    ); 


    reg signed [11:0]temp_ADC;
    always @ (posedge sck)temp_ADC <= adc_data;

	wire signed [23:0] rx_real, rx_imag;

////////////////get_frequency//////////////////////////

    wire [31:0] frequency_rx;
    wire [31:0] frequency_out;
    reg [31:0] frequency_reg = 32'd7050000;
    reg [0:5] led_reg;
    wire uart_ready;


    assign frequency_rx = frequency_reg;

    uart uart_top(
        .clk(sck),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .led(led),
        .frequency_rx(frequency_rx),
        .frequency_out(frequency_out),
        .byteReady(uart_ready),
        .btn1(btn1)
    );

    always @(posedge sck) begin
        if (uart_ready) begin
            frequency_reg <= frequency_out;
        end 
    end


/////////////////////////////////////////////////////////////

    assign led = led_reg;

/////////////////Recieve///////////////////////////////////////
    reciever rx(sck, frequency_rx, temp_ADC,rx_real,rx_imag);
///////////////////////////////////////////////////////////////

	// I2S module, 32 bit, master
	i2s_module i2s (reset, MCK, BCK, LRCK, DOUT, rx_real, rx_imag);

///////////////////Reconfig//////////////////////////////////////
        reg [31:0] time_r = 16'd70;
        always @(posedge sck)
        begin
           if(Reset_Button) begin
            if(time_r < 16'd70) begin time_r <= time_r + 1; Reconfig <= 0;end
            else Reconfig <= 1;
           end
           else time_r <= 0;
        end
///////////////////////////////////////////////////////////////
endmodule