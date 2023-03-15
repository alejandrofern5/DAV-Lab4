module clockDiv #(parameter SPEED = 100) (clock, newClock);
	int counter = 0;
	int max = 25000000/SPEED;
	input clock;
	output reg newClock = 0;
	
	always@(posedge clock) begin
		counter <= counter + 1;
		if (counter == max) begin
			counter <= 0;
			newClock <= ~newClock;
		end
	end
endmodule