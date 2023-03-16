`timescale 1ns/1ns
module I2C #(parameter MAX_BYTES = 6) (clk, rst, driverDisable, deviceAddr_d, regAddr_d, numBytes_d, dataIn_d, dataOut, write_d, start, done, scl, sda);
	
	// bus width parameter:
	localparam NUMBYTES_WIDTH = $clog2(MAX_BYTES + 2);
	
	// FSM state declarations
	localparam RESET = 0;
	localparam START = 1;
	localparam DEV_ADDR = 2;
	localparam REG_ADDR = 3;
	localparam DATA = 4;
	localparam STOP = 5;
	localparam IDLE = 6;
	
	input clk, rst, write_d, start, driverDisable;
	input[6:0] deviceAddr_d;
	input[7:0] regAddr_d;
	input[NUMBYTES_WIDTH-1:0] numBytes_d;
	input[7:0] dataIn_d [MAX_BYTES-1:0];
	
	output reg [7:0] dataOut[MAX_BYTES-1:0] = '{default: '0};
	output done;
	output reg scl = 1'b0;
	inout sda;
	
	
	// Tri-state buffer
	reg in = 0;		//input value to write when we=1
	reg we = 1;		//write enable for tri-state buffer
	wire out;		//output from buffer when we=0
	IOBuffer sdaBuff(in, out, we, sda);

	// FSM state
	reg [2:0] state = RESET;
	reg [2:0] next_state = RESET;
	
	reg write = 1'b0;						// determines if writing/reading to peripheral
	reg [6:0] deviceAddr;					//device address to talk to
	reg [NUMBYTES_WIDTH:0] numBytes;	//input # of bytes to read/write. NOTE: This is 1 bit larger since we will include reg/dev addresses as bytes and add this to the numbytes_d
	reg [7:0] dataIn [MAX_BYTES-1:0];	//data input register
	reg [7:0] regAddr;						//register address
	
	// internal variables
	reg [7:0] data2send;				//data to send (used as buffer for individual bytes)
	reg [7:0] byteOut;						//byte output (used as buffer for individual bytes)
	reg [NUMBYTES_WIDTH-1:0] byte_cnt = '{default: '0};	//counts # of bytes sent/received
	reg [3:0] bit_cnt = 3'b0;			//counts # of bits
	reg [1:0] subbit_cnt = 2'b0;		//counts # of sub-bit ticks
	reg [7:0] delayCounter = 8'b0;	//counts # of delay ticks after command is finished
	
	// flags
	reg done_sending = 0;	//triggered when each state is finished
	reg sending_byte = 0;	//high if currently writing, low if currently reading
	reg data_start = 0;		//high if currently sending / receiving data
	reg notAcked = 0;			//high if peripheral returned NACK
	
	initial done = (state == RESET); //set done output HIGH when FSM returns to RESET.
	
	
	// FSM sequential logic
	// This block handles setting state=next_state
	always @(negedge clk) begin
		if(rst || driverDisable) begin
			state <= IDLE;
			write <= 0;
			deviceAddr <= 0;
			numBytes <= 0;
			dataIn <= '{default: '0};
			regAddr <= 0;
		end else begin
			state <= next_state;
			if (state == START) begin
				deviceAddr <= deviceAddr_d;
				regAddr <= regAddr_d;
				numBytes <= numBytes_d;
				dataIn <= dataIn_d;
				write <= write_d;
			end
		end
	end
	
	// I2C communication logic
	// This block does the dirty work!
	always @(posedge clk) begin
		if(rst || driverDisable) begin
			subbit_cnt <= 0;
			bit_cnt <= 0;
			done_sending <= 0;
			in <= 0;
			scl <= 0;
			notAcked <= 0;
			byteOut <= 8'b0;
			if(rst) begin
				dataOut <= '{default: '0};
			end
		end else begin
			if(state != RESET && state != IDLE) begin
				subbit_cnt <= subbit_cnt + 1;
			end else begin
				subbit_cnt <= 0;
			end
			if(state == IDLE) begin
				delayCounter <= delayCounter + 1;
			end else begin
				delayCounter <= 0;
			end

			if (state == START || state == STOP) begin
				byte_cnt <= 0;
				case (subbit_cnt)
					0: begin
						scl <= 0;
						done_sending <= 0;
						in <= (state == START);
					end
					1: begin
						scl <= 0;
						done_sending <= 0;
						in <= (state == START);
					end
					2: scl <= 1;
					3: begin
						scl <= 1;
						in <= ~in;
						done_sending <= 1;
					end
				endcase
			end else if (data_start) begin
				if(bit_cnt < 8) begin
					done_sending <= 0;
					case (subbit_cnt)
						0: begin
							scl <= 0;
							if(sending_byte) begin
								in <= data2send[bit_cnt];
							end else begin
								byteOut[bit_cnt] <= out;
							end
						end
						1: begin
							scl <= 0;
							if(sending_byte) begin
								in <= data2send[bit_cnt];
							end else begin
								byteOut[bit_cnt] <= out;
							end
						end
						2: scl <= 1;
						3: begin
							scl <= 1;
							bit_cnt <= bit_cnt + 1;
							if (bit_cnt == 8) begin
								if (sending_byte)
									dataOut[byte_cnt] = byteOut; 
								byte_cnt <= byte_cnt + 1;
							end	
						end
					endcase
				end else begin
					case (subbit_cnt)
						0: begin
							scl <= 0;
							if (write) begin
								notAcked <= out;
							end else begin
								in <= byte_cnt == numBytes;
							end
						end
						1: begin
							scl <= 0;
							if (write) begin
								notAcked <= out;
							end else begin
								in <= byte_cnt == numBytes;
							end
						end
						2: scl <= 1;
						3: begin
							scl <= 1;
							done_sending <= 1;
						end
					endcase
				end
			end else begin
				// idle state
				done_sending <= 0;
			end
		end
	end

	
	// FSM combinational logic
	always_comb begin
		case (state)
			RESET: begin
				we = 0;
				data_start = 0;
				sending_byte = 0;
				done = 1;
				data2send = '{default: '0};
				if(start) begin
					next_state = START;
				end else begin
					next_state = IDLE;
				end
			end
			START: begin
				data_start = 0;
				done = 0;
				sending_byte = 0;
				we = 1;
				data2send = '{default: '0};
				if(done_sending) begin
					next_state = DEV_ADDR;
				end else begin
					next_state = START;
				end
			end
			DEV_ADDR: begin
				we = 1;
				done = 0;
				data_start = 1;
				sending_byte = 1;
				data2send = {deviceAddr, ~write};
				if(done_sending) begin
					if(notAcked) begin
						next_state = RESET;
					end else begin
						next_state = write ? REG_ADDR : DATA;
					end
				end
				else begin
					next_state = DEV_ADDR;
				end
			end
			REG_ADDR: begin
				we = 1;
				data_start = 1;
				done = 0;
				sending_byte = 1;
				data2send = regAddr;
				if(done_sending && (subbit_cnt == 3 || subbit_cnt == 0)) begin
					if(notAcked) begin
						next_state = RESET;
					end else begin
						next_state = (numBytes == byte_cnt) ? STOP : DATA; 
					end
				end
				else begin
					next_state = REG_ADDR;
				end
			end
			DATA: begin
				data_start = 1;
				sending_byte = bit_cnt < 8;
				we = write;
				done = 0;
				data2send = write ? dataIn[byte_cnt - 2] : '{default: '0};
				if(done_sending && (subbit_cnt == 3 || subbit_cnt == 0)) begin
					if(notAcked) begin
						next_state = RESET;
					end else begin
						if (numBytes == byte_cnt) begin
							next_state = STOP;
						end else begin
							next_state = DATA;
						end
					end
				end else begin
					next_state = DATA;
				end
			end
			STOP: begin
				data_start = 0;
				sending_byte = 0;
				we = 1;
				done = 0;
				data2send = '{default: '0};
				next_state = done_sending ? IDLE : STOP;
			end
			IDLE: begin
				data_start = 0;
				done = 0;
				we = 0;
				sending_byte = 0;
				data2send = '{default: '0};
				if(delayCounter > 7) begin
					next_state = start ? START : IDLE;
				end else begin
					next_state = IDLE;
				end
			end
			default: next_state = IDLE;
		endcase
	end
endmodule