`timescale 1 ns/ 1 ns

module I2C_tb(dataOut, done, scl, sda);
	output reg [7:0] dataOut[5:0] = '{default: '0};
	output done;
	output reg scl;
	inout sda;
	
	reg deviceAddr_d = 8'h52;
	reg regAddr_d = 8'h0;
	reg [7:0] dataIn_d[5:0];
	reg write_d = 1;
	reg start = 1;
	reg rst = 0;
	reg driverDisable = 0;
	reg clk = 0;
	reg [2:0] numBytes_d = 3'd6;
	
	I2C test_i2c(clk, rst, driverDisable, deviceAddr_d, regAddr_d, numBytes_d, dataIn_d, dataOut, write_d, start, done, scl, sda);

endmodule