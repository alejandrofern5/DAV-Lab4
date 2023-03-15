module Lab4(clock, SDApin, SCLpin, stick_x, stick_y, accel_x, accel_y, accel_z, z, c, reset);
	input clock;
	input reset;
	inout SDApin;
	output SCLpin, stick_x, stick_y, accel_x, accel_y, accel_z, z, c;
	localparam deviceAddr = 8'h52;
endmodule