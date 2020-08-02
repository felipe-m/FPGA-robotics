//------------------------------------------------------------------------------
//   Felipe Machado Sanchez
//   Area de Tecnologia Electronica
//   Universidad Rey Juan Carlos
//   https://github.com/felipe-m
//
//   mode selection
//

module mode_sel
  #(parameter
    c_on    = 1'b1
   )
   (input        rst,
    input        clk,
    input        sig_in,
    output reg   rgbmode,
    output reg   testmode,
    output [2:0] rgbfilter);

  reg    [23:0]  count_16ms;  // 16.7 million count
  reg    [5:0]   count_2sec;  // count for a seconds aprox (64 x 16ms)
  wire           pulse_16ms;
  wire           pulse_1sec;
  wire           end1sec;

  reg    [1:0]   mode;
  reg    [2:0]   rgb_filter;

  assign rgbfilter = rgb_filter;

  // count around 16 ms approx
  always @(posedge rst, posedge clk)
  begin
    if (rst) begin
      count_16ms <= 24'hFF_FFFF;
    end
    else begin
      if (sig_in) begin
        if (count_16ms == 0) begin
          count_16ms <= 24'hFF_FFFF;
        end
        else 
          count_16ms <= count_16ms - 1;
      end
      else
        count_16ms <= 24'hFF_FFFF;
    end
  end

  assign pulse_16ms = (count_16ms == 0) ? 1'b1 : 1'b0;

  // to see if it has been pulsed for more than a second
  // the count is of 2 seconds to give time to release the button
  always @(posedge rst, posedge clk)
  begin
    if (rst) begin
      count_2sec    <= 6'b00_0000;
    end
    else begin
      if (sig_in) begin
        if (pulse_16ms) begin
          if (count_2sec == 6'b11_1111)
            count_2sec    <= 6'b00_0000;
          else
            count_2sec <= count_2sec + 1;
        end
      end
      else 
        count_2sec  <= 6'b00_0000;
    end
  end

  assign end1sec = (count_2sec == 7'b01_1111) ? 1'b1 : 1'b0;
  assign pulse_1sec = ((end1sec==1'b1) && (pulse_16ms==1'b1)) ? 1'b1 : 1'b0;

  always @ (posedge rst, posedge clk)
  begin
    if (rst) begin
      rgb_filter <= 3'b000; // no filter
    end
    else begin
      if (pulse_16ms && count_2sec == 0) begin
        case (rgb_filter)
          3'b000: // no filter, output same as input
            rgb_filter <= 3'b100; // red filter
          3'b100: // red filter
            rgb_filter <= 3'b010; // green filter
          3'b010: // green filter
            rgb_filter <= 3'b001; // blue filter
          3'b001: // blue filter
            rgb_filter <= 3'b110; // red and green filter
          3'b110: // red and green filter
            rgb_filter <= 3'b101; // red and blue filter
          3'b101: // red and blue filter
            rgb_filter <= 3'b011; // green and blue filter
          3'b011: // green and blue filter
            rgb_filter <= 3'b111; // red, green and blue filter
          3'b111: // red, green and blue filter
            rgb_filter <= 3'b000; // no filter
        endcase
      end
    end
  end

  always @ (posedge rst, posedge clk)
  begin
    if (rst) begin
      mode <= 2'b0;
    end
    else begin
      if (pulse_1sec) begin
        if (mode == 2'b11) 
          mode <= 2'b0;
        else
          mode <= mode + 1;
      end
    end
  end


  always @(*)
  begin
    case (mode)
      2'b00: begin  // RGB Normal
        rgbmode = 1'b1;
        testmode = 1'b0;
      end
      2'b01: begin  // YUV Normal
        rgbmode = 1'b0;
        testmode = 1'b0;
      end
      2'b10: begin // RGB Test
        rgbmode = 1'b1;
        testmode = 1'b1;
      end
      default: begin //2'b11: begin  // YUV Test
        rgbmode = 1'b0;
        testmode = 1'b1;
      end
    endcase
  end

endmodule

