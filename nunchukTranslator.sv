module nunchukTranslator(data_in, stick_x, stick_y, accel_x, accel_y, accel_z, z, c);
	input [7:0] data_in [5:0];
	output [7:0] stick_x, stick_y;
	output [9:0] accel_x, accel_y, accel_z;
	output z, c;
	
	always_comb begin
		stick_x <= data_in[0];
		stick_y <= data_in[1];
		accel_x[9:2] <= data_in[2];
		accel_x[1:0] <= data_in[5][3:2];
		accel_y[9:2] <= data_in[3];
		accel_y[1:0] <= data_in[5][5:4];
		accel_z[9:2] <= data_in[4];
		accel_z[1:0] <= data_in[5][7:6];
		z <= data_in[5][0];
		c <= data_in[5][1];
	end
	
endmodule