module nunchukDriver(clock, SDApin, SCLpin, stick_x, stick_y, accel_x, accel_y, accel_z, z, c, addr, reset);
	input clock, reset;
	inout SDApin;
	output SCLpin;
	output [7:0] stick_x, stick_y;
	output [9:0] accel_x, accel_y, accel_z;
	output z, c;
	output [7:0] addr;
	localparam HANDSHAKE1 = 3'd0;
	localparam HANDSHAKE2 = 3'd1;
	localparam WRITE = 3'd2;
	localparam READ = 3'd3;
	localparam READ2 = 3'd5;
	localparam DONE = 3'd4;
	localparam BEGIN = 3'd7;
	localparam deviceAddr = 7'h52;
	reg [2:0] state;
	reg [2:0] next_state = BEGIN;
	reg start, write;
	reg i2c_clock;
	reg [7:0] dataIn [5:0];
	reg [7:0] dataOut [5:0] = '{default: '0};
	reg done;
	reg [2:0] numBytes;
	reg driverDisable = 0;
	
	clockDiv #(400000) clock_400kHz(clock, i2c_clock);
	I2C UUT(i2c_clock, reset, driverDisable, deviceAddr, addr, numBytes, dataIn, dataOut, write, start, done, SCLpin, SDApin);
	
	always@(posedge clock && done) begin
		state <= next_state;
		if (reset) begin
			state <= BEGIN;
		end else if(state == HANDSHAKE1) begin
			addr <= 8'hF0;
			dataIn[0] <= 8'h55;
			numBytes <= 1;
			write <= 1;
			start <= 1;
		end else if(state == HANDSHAKE2) begin
			addr <= 8'hFB;
			dataIn[0] <= 8'h00;
			numBytes <= 1;
			write <= 1;
			start <= 1;
		end else if(state == WRITE) begin
			addr <= 8'h00;
			numBytes <= 0;
			write <= 1;
			start <= 1;
		end else if(state == READ) begin
			numBytes <= 6;
			write <= 0;
			start <= 1;
		end else if (state == READ2) begin
			numBytes <= 6;
			write <= 0;
			start <= 1;
		end
	end
	
	always_comb begin
		case(state)
			BEGIN: next_state = done ? HANDSHAKE1 : BEGIN;
			HANDSHAKE1: next_state = done ? HANDSHAKE2 : HANDSHAKE1;
			HANDSHAKE2: next_state = done ? WRITE : HANDSHAKE2;
			WRITE: next_state = done ? READ : WRITE;
			READ: next_state = done ? READ2 : READ;
			READ2: next_state = done ? WRITE : READ2;
		endcase
	end
	
endmodule