`timescale 1 ns/ 1 ns

module nunchukDriver_tb(SDApin, SCLpin, stick_x, stick_y, accel_x, accel_y, accel_z, z, c);

	reg clk, rst;
	
	inout SDApin;
	output SCLpin;
	output [7:0] stick_x, stick_y;
	output [9:0] accel_x, accel_y, accel_z;
	output z, c;
	
	initial begin
		clk = 0;
		rst = 0;
	end
	
	always begin
		#1;
		clk = ~clk;
	end
	
	nunchukDriver test_driver(clk, SDApin, SCLpin, stick_x, stick_y, accel_x, accel_y, accel_z, z, c, rst);
endmodule