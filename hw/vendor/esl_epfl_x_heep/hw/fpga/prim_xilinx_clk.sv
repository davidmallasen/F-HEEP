// Copyright 2022 OpenHW Group
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

module xilinx_clk_gating (
    input  logic clk_i,
    input  logic en_i,
    input  logic test_en_i,
    output logic clk_o
);

  logic clk_en;

  // Use a latch based clock gate instead of BUFGCE. Otherwise we quickly run out of BUFGCTRL cells on the FPGAs.
  always_latch begin
    if (clk_i == 1'b0) clk_en <= en_i | test_en_i;
  end

  assign clk_o = clk_i & clk_en;


endmodule

module xilinx_clk_inverter (
    input  logic clk_i,
    output logic clk_o
);

  assign clk_o = ~clk_i;

endmodule


module xilinx_clk_mux2 (
    input  logic clk0_i,
    input  logic clk1_i,
    input  logic clk_sel_i,
    output logic clk_o
);

  BUFGMUX i_BUFGMUX (
      .S (clk_sel_i),
      .I0(clk0_i),
      .I1(clk1_i),
      .O (clk_o)
  );

endmodule

module cluster_clock_inverter (
    input  logic clk_i,
    output logic clk_o
);

  xilinx_clk_inverter clk_inv_i (.*);

endmodule

module pulp_clock_mux2 (
    input  logic clk0_i,
    input  logic clk1_i,
    input  logic clk_sel_i,
    output logic clk_o
);

  xilinx_clk_mux2 clk_mux2_i (.*);

endmodule

module pulp_clock_inverter (
    input  logic clk_i,
    output logic clk_o
);

  xilinx_clk_inverter clk_inv_i (.*);

endmodule

module cv32e40p_clock_gate (
    input  logic clk_i,
    input  logic en_i,
    input  logic scan_cg_en_i,
    output logic clk_o
);

  xilinx_clk_gating clk_gate_i (
      .clk_i,
      .en_i,
      .test_en_i(scan_cg_en_i),
      .clk_o
  );

endmodule

module cv32e40x_clock_gate #(
    parameter LIB = 0
) (
    input  logic clk_i,
    input  logic en_i,
    input  logic scan_cg_en_i,
    output logic clk_o
);

  xilinx_clk_gating clk_gate_i (
      .clk_i,
      .en_i,
      .test_en_i(scan_cg_en_i),
      .clk_o
  );

endmodule

module tc_clk_gating #(
    /// This paramaeter is a hint for tool/technology specific mappings of this
    /// tech_cell. It indicates wether this particular clk gate instance is
    /// required for functional correctness or just instantiated for power
    /// savings. If IS_FUNCTIONAL == 0, technology specific mappings might
    /// replace this cell with a feedthrough connection without any gating.
    parameter bit IS_FUNCTIONAL = 1'b1
) (
    input  logic clk_i,
    input  logic en_i,
    input  logic test_en_i,
    output logic clk_o
);

  xilinx_clk_gating clk_gate_i (
      .clk_i,
      .en_i,
      .test_en_i,
      .clk_o
  );

endmodule

module tc_clk_mux2 (
    input  logic clk0_i,
    input  logic clk1_i,
    input  logic clk_sel_i,
    output logic clk_o
);

  xilinx_clk_mux2 xilinx_i_clk_mux2_i (
      .clk0_i,
      .clk1_i,
      .clk_sel_i,
      .clk_o
  );

endmodule

module tc_clk_xor2 (
    input  logic clk0_i,
    input  logic clk1_i,
    output logic clk_o
);

  assign clk_o = clk0_i ^ clk1_i;

endmodule
