// Copyright (c) 2020 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module sram_wrapper #(
    parameter int unsigned NumWords = 32'd1024,  // Number of Words in data array
    parameter int unsigned DataWidth = 32'd32,  // Data signal width
    // DEPENDENT PARAMETERS, DO NOT OVERWRITE!
    parameter int unsigned AddrWidth = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1
) (
    input logic clk_i,
    input logic rst_ni,
    // input ports
    input logic req_i,
    input logic we_i,
    input logic [AddrWidth-1:0] addr_i,
    input logic [31:0] wdata_i,
    input logic [3:0] be_i,
    input logic set_retentive_i,
    // output ports
    output logic [31:0] rdata_o
);

  tc_sram #(
      .NumWords (NumWords),
      .DataWidth(DataWidth),
      .NumPorts (32'd1)
  ) tc_ram_i (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .req_i  (req_i),
      .we_i   (we_i),
      .addr_i (addr_i),
      .wdata_i(wdata_i),
      .be_i   (be_i),
      // output ports
      .rdata_o(rdata_o)
  );

endmodule
