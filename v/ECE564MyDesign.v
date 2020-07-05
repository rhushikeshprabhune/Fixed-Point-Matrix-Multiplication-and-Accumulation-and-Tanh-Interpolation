//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// DUT

module ECE564MyDesign
	    (

            //---------------------------------------------------------------------------
            // Control
            //
            input  wire               xxx__dut__run            ,             
            output reg                dut__xxx__busy           , // high when computing
            input  wire               clk                      ,
            input  wire               reset_b                  ,


            //--------------------------------------------------------------------------- 
            //---------------------------------------------------------------------------
            // SRAM interface
            //
            output reg  [11:0]        dut__sram__write_address  ,
            output reg  [15:0]        dut__sram__write_data     ,
            output reg                dut__sram__write_enable   ,
            output reg  [11:0]        dut__sram__read_address   ,
            input  wire [15:0]        sram__dut__read_data      ,

            //---------------------------------------------------------------------------
            // g memory interface
            //
            output reg  [11:0]        dut__gmem__read_address   ,
            input  wire [15:0]        gmem__dut__read_data      ,  // read data

            //---------------------------------------------------------------------------
            // Tanh look up table tanhmem 
            //
            output reg  [11:0]        dut__tanhmem__read_address     ,
            input  wire [15:0]        tanhmem__dut__read_data           // read data

            );

  //---------------------------------------------------------------------------
  //

reg [51:0] tanh_op_intermediate;
reg [51:0] tanh_op;
reg [35:0] tanhAddr_higher;
reg [35:0] tanhAddr_lower;
reg [35:0] pre_tanh_calc;
reg [35:0] tanh_post_negative;
reg [35:0] tanhAddr_calc;
reg [15:0] post_tanh_op;
reg [35:0] accumulator; 
reg [31:0] product;

reg [3:0] sram_address_increment;
reg [7:0] gmem_counter;
reg [3:0] accumulator_counter;
reg [8:0] tanh_counter;
reg [3:0] sram_counter;
reg [3:0] counter_inner;

reg	restart_calculation;
reg halt_tanh_calc;
reg begin_tanh;
reg tanh_write;
reg halt_op;
 
always@(posedge clk)
begin
	if(!reset_b)
		begin
		pre_tanh_calc <= 0;
		begin_tanh <= 0;
		dut__xxx__busy <= 1'b0;
		sram_counter <= 4'b0;
		tanh_op <= 0;
		restart_calculation <= 1;
		tanh_write <= 0;
		tanh_counter <= 0;
		accumulator_counter <= 4'b0;
		sram_address_increment <= 4'b0;
		accumulator <= 0;
		halt_tanh_calc <= 1;
		end
	else
		begin
			
		if(dut__xxx__busy == 1)
			begin
			// x data fetch logic
			
			//compute sram read address
			dut__sram__read_address <= 12'd32 * {8'h00, sram_address_increment};
			if(sram_counter != 0)
				begin
				dut__sram__read_address <= dut__sram__read_address + 2;
				end
			
			//compute sram address increment
			if(gmem_counter >= 255)
				begin
				sram_address_increment <= sram_address_increment + 1;
				end

			//compute sram counter
			sram_counter <= sram_counter + 1;
				
			//compute accumulator
			if(accumulator_counter > 0)
			begin
				accumulator <= {{4{product[31]}}, product[31:0]} + accumulator;
			end	
			else
			begin
				accumulator <= {{4{product[31]}}, product[31:0]};
			end
			
			//handle halt_tanh_calc
			if(accumulator_counter > 0)
			begin
				halt_tanh_calc <= 1;
			end
			else
			begin
				if(accumulator > 0)
				begin
					halt_tanh_calc <= 0;
				end
			end
			
			//compute pre_tanh_calc
			if(accumulator_counter == 0 && accumulator > 0)
			begin
				pre_tanh_calc <= accumulator;
			end
			
			if(halt_tanh_calc == 0)
				begin
				begin_tanh <= 1'b1;
				end
			else
				begin
				begin_tanh <= 1'b0;
				end
			
            //interpolation formula			
			if(begin_tanh == 0)
				begin
				tanh_op <= tanh_op + (64*(tanhmem__dut__read_data*(tanhAddr_calc - tanhAddr_lower)));
				halt_op <= 1'b1;
				end
			else
				begin
				tanh_op <= 64*(tanhmem__dut__read_data*(tanhAddr_higher - tanhAddr_calc));
				halt_op <= 1'b0;
				end
				
			tanh_write <= ~halt_op;

			if (gmem_counter > 0)
				begin
				restart_calculation <= 0;
				end
end

///////////////////////////////////////////////////////////////////////////////////////////
			if (restart_calculation == 0) 
				begin
				accumulator_counter <= accumulator_counter + 1;
				end
			else 
				begin
				accumulator_counter <= 0;
				end
		end
		
		if(tanh_counter > 255)
			begin
			dut__xxx__busy <= 1'b0;
			end	
			
	if(!reset_b)
		begin
		dut__sram__write_address <= 12'b0;
		end
	else
		begin	
			if(xxx__dut__run == 1)
			begin
			dut__xxx__busy <= 1'b1;
			dut__sram__write_address <= 12'b000111111110;
			end
			
			if(tanh_write == 0)
				begin
				dut__sram__write_enable <= 1'b0;   //write enable zero to enable reads
				end
			else if(tanh_write ==1)
				begin
				dut__sram__write_enable <= 1'b1;   //write enable high while writing
				end
			else
				begin
			    dut__sram__write_enable <= dut__sram__write_enable;
			    end
				
			if(tanh_write == 1)
			begin
			dut__sram__write_data <= post_tanh_op;
			end
			
			if(tanh_write == 1)
			begin
			dut__sram__write_address <= dut__sram__write_address + 2;
			end
			
			if(tanh_write == 1)
			begin
			tanh_counter <= tanh_counter + 1;   //write enable zero to enable reads
			end
			
		end

	if(!reset_b)
		begin
		gmem_counter <= 8'b0;
		end
	else if(dut__xxx__busy == 1)
			begin
			if(gmem_counter > 0)
				begin
				dut__gmem__read_address <= dut__gmem__read_address + 2;
				end
			else
				begin
				dut__gmem__read_address <= 12'b0;
				end
			gmem_counter <= gmem_counter + 1;
			end	
			
 end
 
always@(*)
begin
dut__tanhmem__read_address = 0;
tanhAddr_higher = 0;
tanhAddr_lower = 0;
post_tanh_op = 0;
	if(dut__xxx__busy == 1)
		begin
			if (restart_calculation == 0)
			begin
			product = {{16{sram__dut__read_data[15]}}, sram__dut__read_data[15:0]} * {{16{gmem__dut__read_data[15]}}, gmem__dut__read_data[15:0]};
			end
		else 
			begin
			product = 32'b0;
			end
			
			if(halt_tanh_calc == 1 && pre_tanh_calc[35] == 0)
		        begin
				tanh_post_negative = pre_tanh_calc;
				end
			  else
				begin
				tanh_post_negative = ~pre_tanh_calc + 1;
				 end
			
              if(halt_tanh_calc == 1 && tanh_post_negative[34:23] > 12'h1ff)
				begin
				dut__tanhmem__read_address = 12'h1ff;
				end
			else if(halt_tanh_calc == 1 && tanh_post_negative[34:23] <= 12'h1ff)
				begin
				dut__tanhmem__read_address = tanh_post_negative[34:23] + 2;
				end			
			
				if(halt_tanh_calc == 0 && pre_tanh_calc[35] == 0)
				begin
				tanh_post_negative = pre_tanh_calc;
				end
			else
				begin
				tanh_post_negative = ~pre_tanh_calc[35:0] + 1;
				end
				
				if(halt_tanh_calc == 0 && tanh_post_negative[34:23] > 12'h1ff)
				begin
				dut__tanhmem__read_address = 12'h1ff;
				end
			else if(halt_tanh_calc == 0 && tanh_post_negative[34:23] <= 12'h1ff)
				begin
				dut__tanhmem__read_address = tanh_post_negative[34:23];
				end
				
			end
		
	else
		begin
	product = 32'b0;
		end
		if(begin_tanh == 0)
			begin
				if(pre_tanh_calc[35] == 0)
				begin
				tanhAddr_calc = pre_tanh_calc;
				end
			else
				begin
				tanhAddr_calc = ~pre_tanh_calc[35:0] + 1;
				end
			
			tanhAddr_lower = {tanhAddr_calc[35:24], 24'b0};
			end
		else
			begin
			if(pre_tanh_calc[35] == 0)
				begin
				tanhAddr_calc = pre_tanh_calc;
				end
			else
				begin
				tanhAddr_calc = ~pre_tanh_calc[35:0] + 1;
				end
	
			tanhAddr_higher = {(tanhAddr_calc[35:24] + 1), 24'b0};
			end
			
		if(tanh_write == 1)
			begin
			if(pre_tanh_calc[35] == 0)
				begin
				post_tanh_op = tanh_op[45:30];
				end
			else
				begin
				tanh_op_intermediate = ~tanh_op + 1;
				post_tanh_op = tanh_op_intermediate[45:30];
				end
			end
		
end


endmodule

