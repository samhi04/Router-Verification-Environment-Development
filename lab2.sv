// Code your testbench here
// or browse Examples
module testbench;

  // Section 1: Define variables for DUT port connections
  reg clk, reset;
  // TODO
  reg [7:0] dut_inp;
  reg inp_valid;
  wire [7:0] dut_outp;
  wire outp_valid;
  wire busy;
  wire [3:0] error;

  // Section 2: Router DUT instantiation
  // TODO router_dut dut_inst(.clk(clk),.reset(reset),..........);
  router_dut D1 (.clk(clk), .reset(reset), .dut_inp(dut_inp), .inp_valid(inp_valid), .dut_outp(dut_outp), .outp_valid(outp_valid), .busy(busy), .error(error));

  // Section 3: Clock initialization and Generation
  // TODO
  initial clk = 0;
  always #5 clk = ~clk;

  // Section 4: TB Variables declarations.
  // Variables required for various testbench related activities . ex: stimulus generation,packing ....
  // TODO
  typedef struct {
    logic [7:0] sa;
    logic [7:0] da;
    logic [31:0] len;
    logic [31:0] crc;
    bit [7:0]  payload[]; // dynamic array for payload
  } packet;

  packet pkt;
  
  packet stimulus_pkt;
  bit [31:0] pkt_count; 
  
  
  //lab2 
  bit [7:0] inp_stream[$];

  // Section 5: Methods (functions/tasks) definitions related to Verification Environment
  // function void f1 (ref packet pkt);
  
  function automatic void pack (ref bit[7:0] q_inp[$],input packet pkt);
    q_inp = {<< 8{pkt.payload,pkt.crc,pkt.len,pkt.da,pkt.sa}};
  endfunction

  function automatic void generate_stimulus(ref packet pkt);
    pkt.sa = $urandom_range(1,8);
	pkt.da = $urandom_range(1,8);
	pkt.payload = new [$urandom_range(10,20)];
	foreach (pkt.payload[i])
	    pkt.payload[i] = i+1;
	pkt.len = pkt.payload.size() +1+1+4+4;
	pkt.crc = pkt.payload.sum();
	$display("[TB Generate] Packet (size=%0d) Generated at time=%0t",pkt.len,$time);
  endfunction
  
  
  task drive(const ref bit [7:0] inp_stream[$]);
    wait (busy == 0); // wait until router is ready to accept packets
    @(posedge clk);
    $display("[TB Drive] Driving of packet started at time=%0t", $time);
    // TODO
    inp_valid <= 1; // start of the packet
    foreach (inp_stream[i]) begin
      @(posedge clk);
      dut_inp = inp_stream[i];
    end
    @(posedge clk);
    inp_valid <= 0; // end of packet
  endtask


  task apply_reset();
    // TODO
    $display("[TB Reset] Applied reset to DUT");
    reset <= 1;
    repeat (2) @ (posedge clk);
    reset <= 0;
    $display("[TB Reset] reset completed");
  endtask


  function void print(input packet pkt);
    $display("[TB Packet] Sa=%0h Da=%0h Len=%0h Crc=%0h", pkt.sa, pkt.da, pkt.len, pkt.crc);
    foreach (pkt.payload[k])
      $display("[TB Packet] Payload[%0d]=%0h", k, pkt.payload[k]);
  endfunction
  //--------End of Section 5 ----------------

  // Section 6: Verification Flow
 
  initial begin
    // TODO
	pkt_count = 5;
    apply_reset();
	repeat(pkt_count) begin 
    generate_stimulus(stimulus_pkt);
	pack(inp_stream,stimulus_pkt);
    drive(inp_stream);
	print (stimulus_pkt);
    repeat (5) @(posedge clk);
	end 
    // Wait for DUT to process the packet and to drive on output
    wait (busy == 0);
    repeat (10) @ (posedge clk);
    $finish;
  end
  //--------End of Section 6 ----------------

  // Section 7: Dumping Waveform
  // TODO
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench.D1);
    $dumpvars(0, testbench.D1.dut_inp);
    $dumpvars(0, testbench.D1.inp_valid);
    $dumpvars(0, testbench.D1.dut_outp);
  end
  //--------End of Section 7 ----------------

  // Section 8: Collect DUT output
  // TODO
  // capture the output packet
  bit [7:0] stream_out[$];
  function void unpack();
  {<< 8 {pkt.payload,pkt.crc,pkt.len,pkt.da,pkt.sa}} = stream_out;
  endfunction 
  
  // Compare input and output packets
  function automatic bit compare_packets(packet pkt1, packet pkt2);
    bit result = 1;
    if (pkt1.sa !== pkt2.sa) result = 0;
    if (pkt1.da !== pkt2.da) result = 0;
    if (pkt1.len !== pkt2.len) result = 0;
    if (pkt1.crc !== pkt2.crc) result = 0;
    if (pkt1.payload.size() !== pkt2.payload.size()) result = 0;
    else begin
      foreach (pkt1.payload[i])
        if (pkt1.payload[i] !== pkt2.payload[i]) result = 0;
    end
    return result;
  endfunction

  initial begin 
    if (compare_packets(stimulus_pkt, out_pkt))
      $display("[TB Info] Input and output packets match.");
    else
      $display("[TB Info] Input and output packets do not match.");
    
    $display("[TB Info] Input Packet:");
    print(stimulus_pkt);
    
    $display("[TB Info] Output Packet:");
    print(out_pkt);
  end 
  

  //--------End of Section 8---------------- 

  always @ (error) begin
    case (error)
      1: $display("[TB Error] Protocol Violation. Packet driven while Router is busy");
      2: $display("[TB Error] Packet Dropped due to CRC mismatch");
      3: $display("[TB Error] Packet Dropped due to Minimum packet size mismatch");
      4: $display("[TB Error] Packet Dropped due to Maximum packet size mismatch");
      5: begin
        $display("[TB Error] Packet Corrupted. Packet dropped due to packet length mismatch");
        $display("[TB Error] Step 1: Check value of len field of packet driven from TB");
        $display("[TB Error] Step 2: Check total number of bytes received in DUT in the waveform (Check dut_inp)");
        $display("[TB Error] Check value of Step 1 matching with Step 2 or not");
      end
    endcase
  end

endmodule

