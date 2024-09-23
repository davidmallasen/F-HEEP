// Copyright 2022 OpenHW Group
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

module testharness #(
    parameter JTAG_DPI      = 0,
    parameter CLK_FREQUENCY = 'd100_000  //KHz
) (
    inout wire clk_i,
    inout wire rst_ni,

    inout wire boot_select_i,
    inout wire execute_from_flash_i,

    inout  wire         jtag_tck_i,
    inout  wire         jtag_tms_i,
    inout  wire         jtag_trst_ni,
    inout  wire         jtag_tdi_i,
    inout  wire         jtag_tdo_o,
    output logic [31:0] exit_value_o,
    inout  wire         exit_valid_o
);

  `include "tb_util.svh"

  import obi_pkg::*;
  import reg_pkg::*;
  import addr_map_rule_pkg::*;

  localparam SWITCH_ACK_LATENCY = 15;
  localparam EXT_XBAR_NMASTER_RND = 1;

  localparam int unsigned LOG_EXT_XBAR_NSLAVE = 32'd1;

  localparam EXT_DOMAINS_RND = core_v_mini_mcu_pkg::EXTERNAL_DOMAINS == 0 ? 1 : core_v_mini_mcu_pkg::EXTERNAL_DOMAINS;
  localparam NEXT_INT_RND = core_v_mini_mcu_pkg::NEXT_INT == 0 ? 1 : core_v_mini_mcu_pkg::NEXT_INT;

  wire uart_rx;
  wire uart_tx;
  logic sim_jtag_enable = (JTAG_DPI == 1);
  wire sim_jtag_tck;
  wire sim_jtag_tms;
  wire sim_jtag_tdi;
  wire sim_jtag_tdo;
  wire sim_jtag_trstn;
  wire mux_jtag_tck;
  wire mux_jtag_tms;
  wire mux_jtag_tdi;
  wire mux_jtag_tdo;
  wire mux_jtag_trstn;
  wire [31:0] gpio;

  wire [3:0] spi_flash_sd_io;
  wire [1:0] spi_flash_csb;
  wire spi_flash_sck;

  wire [3:0] spi_sd_io;
  wire [1:0] spi_csb;
  wire spi_sck;

  logic iffifo_in_ready, iffifo_out_valid;
  logic iffifo_int_o;

  // External DMA slots
  logic [core_v_mini_mcu_pkg::DMA_CH_NUM-1:0] ext_dma_slot_tx;
  logic [core_v_mini_mcu_pkg::DMA_CH_NUM-1:0] ext_dma_slot_rx;

  assign ext_dma_slot_tx[0] = iffifo_in_ready;
  assign ext_dma_slot_rx[0] = iffifo_out_valid;
  if (core_v_mini_mcu_pkg::DMA_CH_NUM > 1) begin
    assign ext_dma_slot_tx[core_v_mini_mcu_pkg::DMA_CH_NUM-1:1] = '0;
    assign ext_dma_slot_rx[core_v_mini_mcu_pkg::DMA_CH_NUM-1:1] = '0;
  end

  // External xbar master/slave and peripheral ports
  obi_req_t [EXT_XBAR_NMASTER_RND-1:0] heep_slave_req;
  obi_resp_t [EXT_XBAR_NMASTER_RND-1:0] heep_slave_resp;
  obi_req_t heep_core_instr_req;
  obi_resp_t heep_core_instr_resp;
  obi_req_t heep_core_data_req;
  obi_resp_t heep_core_data_resp;
  obi_req_t heep_debug_master_req;
  obi_resp_t heep_debug_master_resp;
  obi_req_t heep_dma_read_ch0_req;
  obi_resp_t heep_dma_read_ch0_resp;
  obi_req_t heep_dma_write_ch0_req;
  obi_resp_t heep_dma_write_ch0_resp;
  obi_req_t heep_dma_addr_ch0_req;
  obi_resp_t heep_dma_addr_ch0_resp;
  reg_req_t periph_slave_req;
  reg_rsp_t periph_slave_rsp;

  // External interrupts
  logic [NEXT_INT_RND-1:0] intr_vector_ext;
  logic memcopy_intr;

  // External subsystems
  logic [EXT_DOMAINS_RND-1:0] external_subsystem_powergate_switch_n;
  logic [EXT_DOMAINS_RND-1:0] external_subsystem_powergate_switch_ack_n;
  logic [EXT_DOMAINS_RND-1:0] external_subsystem_powergate_iso_n;
  logic [EXT_DOMAINS_RND-1:0] external_subsystem_rst_n;
  logic [EXT_DOMAINS_RND-1:0] external_ram_banks_set_retentive_n;
  logic [EXT_DOMAINS_RND-1:0] external_subsystem_clkgate_en_n;

  always_comb begin
    // All interrupt lines set to zero by default
    for (int i = 0; i < core_v_mini_mcu_pkg::NEXT_INT; i++) begin
      intr_vector_ext[i] = 1'b0;
    end
    // Re-assign the interrupt lines used here
    intr_vector_ext[0] = memcopy_intr;
    intr_vector_ext[1] = iffifo_int_o;
  end

  //log parameters
  initial begin
    $display("%t: the parameter JTAG_DPI is %x", $time, JTAG_DPI);
    $display("%t: the parameter EXT_DOMAINS is %x", $time, core_v_mini_mcu_pkg::EXTERNAL_DOMAINS);
    $display("%t: the parameter CLK_FREQUENCY is %d KHz", $time, CLK_FREQUENCY);
  end

  fheep #(
      .EXT_XBAR_NMASTER(0)
  ) x_heep_system_i (  // Don't modify the implementation name, hardcoded in tb_util.svh and at the bottom in this file
      .clk_i,
      .rst_ni,
      .jtag_tck_i(mux_jtag_tck),
      .jtag_tms_i(mux_jtag_tms),
      .jtag_trst_ni(mux_jtag_trstn),
      .jtag_tdi_i(mux_jtag_tdi),
      .jtag_tdo_o(mux_jtag_tdo),
      .boot_select_i,
      .execute_from_flash_i,
      .exit_valid_o,
      .uart_rx_i(uart_rx),
      .uart_tx_o(uart_tx),
      .gpio_0_io(gpio[0]),
      .gpio_1_io(gpio[1]),
      .gpio_2_io(gpio[2]),
      .gpio_3_io(gpio[3]),
      .gpio_4_io(gpio[4]),
      .gpio_5_io(gpio[5]),
      .gpio_6_io(gpio[6]),
      .gpio_7_io(gpio[7]),
      .gpio_8_io(gpio[8]),
      .gpio_9_io(gpio[9]),
      .gpio_10_io(gpio[10]),
      .gpio_11_io(gpio[11]),
      .gpio_12_io(gpio[12]),
      .gpio_13_io(gpio[13]),
      .gpio_14_io(gpio[14]),
      .gpio_15_io(gpio[15]),
      .gpio_16_io(gpio[16]),
      .gpio_17_io(gpio[17]),
      .spi_flash_sck_io(spi_flash_sck),
      .spi_flash_cs_0_io(spi_flash_csb[0]),
      .spi_flash_cs_1_io(spi_flash_csb[1]),
      .spi_flash_sd_0_io(spi_flash_sd_io[0]),
      .spi_flash_sd_1_io(spi_flash_sd_io[1]),
      .spi_flash_sd_2_io(spi_flash_sd_io[2]),
      .spi_flash_sd_3_io(spi_flash_sd_io[3]),
      .spi_sck_io(spi_sck),
      .spi_cs_0_io(spi_csb[0]),
      .spi_cs_1_io(spi_csb[1]),
      .spi_sd_0_io(spi_sd_io[0]),
      .spi_sd_1_io(spi_sd_io[1]),
      .spi_sd_2_io(spi_sd_io[2]),
      .spi_sd_3_io(spi_sd_io[3]),
      .pdm2pcm_pdm_io(gpio[18]),
      .pdm2pcm_clk_io(gpio[19]),
      .i2s_sck_io(gpio[20]),
      .i2s_ws_io(gpio[21]),
      .i2s_sd_io(gpio[22]),
      .spi2_cs_0_io(gpio[23]),
      .spi2_cs_1_io(gpio[24]),
      .spi2_sck_io(gpio[25]),
      .spi2_sd_0_io(gpio[26]),
      .spi2_sd_1_io(gpio[27]),
      .spi2_sd_2_io(gpio[28]),
      .spi2_sd_3_io(gpio[29]),
      .i2c_scl_io(gpio[31]),
      .i2c_sda_io(gpio[30]),
      .exit_value_o,
      .intr_vector_ext_i(intr_vector_ext),
      .ext_xbar_master_req_i(heep_slave_req),
      .ext_xbar_master_resp_o(heep_slave_resp),
      .ext_core_instr_req_o(heep_core_instr_req),
      .ext_core_instr_resp_i(heep_core_instr_resp),
      .ext_core_data_req_o(heep_core_data_req),
      .ext_core_data_resp_i(heep_core_data_resp),
      .ext_debug_master_req_o(heep_debug_master_req),
      .ext_debug_master_resp_i(heep_debug_master_resp),
      .ext_dma_read_ch0_req_o(heep_dma_read_ch0_req),
      .ext_dma_read_ch0_resp_i(heep_dma_read_ch0_resp),
      .ext_dma_write_ch0_req_o(heep_dma_write_ch0_req),
      .ext_dma_write_ch0_resp_i(heep_dma_write_ch0_resp),
      .ext_dma_addr_ch0_req_o(heep_dma_addr_ch0_req),
      .ext_dma_addr_ch0_resp_i(heep_dma_addr_ch0_resp),
      .ext_peripheral_slave_req_o(periph_slave_req),
      .ext_peripheral_slave_resp_i(periph_slave_rsp),
      .external_subsystem_powergate_switch_no(external_subsystem_powergate_switch_n),
      .external_subsystem_powergate_switch_ack_ni(external_subsystem_powergate_switch_ack_n),
      .external_subsystem_powergate_iso_no(external_subsystem_powergate_iso_n),
      .external_subsystem_rst_no(external_subsystem_rst_n),
      .external_ram_banks_set_retentive_no(external_ram_banks_set_retentive_n),
      .external_subsystem_clkgate_en_no(external_subsystem_clkgate_en_n),
      .ext_dma_slot_tx_i(ext_dma_slot_tx),
      .ext_dma_slot_rx_i(ext_dma_slot_rx),
      .ext_dma_stop_i('0)
  );

  //pretending to be SWITCH CELLs that delay by SWITCH_ACK_LATENCY cycles the ACK signal
  logic
      tb_cpu_subsystem_powergate_switch_ack_n[SWITCH_ACK_LATENCY+1],
      tb_peripheral_subsystem_powergate_switch_ack_n[SWITCH_ACK_LATENCY+1];
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] tb_memory_subsystem_banks_powergate_switch_ack_n[SWITCH_ACK_LATENCY+1];
  logic [EXT_DOMAINS_RND-1:0] tb_external_subsystem_powergate_switch_ack_n[SWITCH_ACK_LATENCY+1];

  logic delayed_tb_cpu_subsystem_powergate_switch_ack_n;
  logic delayed_tb_peripheral_subsystem_powergate_switch_ack_n;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] delayed_tb_memory_subsystem_banks_powergate_switch_ack_n;
  logic [EXT_DOMAINS_RND-1:0] delayed_tb_external_subsystem_powergate_switch_ack_n;

  always_ff @(negedge clk_i) begin
    tb_cpu_subsystem_powergate_switch_ack_n[0] <= x_heep_system_i.cpu_subsystem_powergate_switch_n;
    tb_peripheral_subsystem_powergate_switch_ack_n[0] <= x_heep_system_i.peripheral_subsystem_powergate_switch_n;
    tb_memory_subsystem_banks_powergate_switch_ack_n[0] <= x_heep_system_i.core_v_mini_mcu_i.memory_subsystem_banks_powergate_switch_n;
    tb_external_subsystem_powergate_switch_ack_n[0] <= external_subsystem_powergate_switch_n;
    for (int i = 0; i < SWITCH_ACK_LATENCY; i++) begin
      tb_memory_subsystem_banks_powergate_switch_ack_n[i+1] <= tb_memory_subsystem_banks_powergate_switch_ack_n[i];
      tb_cpu_subsystem_powergate_switch_ack_n[i+1] <= tb_cpu_subsystem_powergate_switch_ack_n[i];
      tb_peripheral_subsystem_powergate_switch_ack_n[i+1] <= tb_peripheral_subsystem_powergate_switch_ack_n[i];
      tb_external_subsystem_powergate_switch_ack_n[i+1] <= tb_external_subsystem_powergate_switch_ack_n[i];
    end
  end

  assign delayed_tb_cpu_subsystem_powergate_switch_ack_n = tb_cpu_subsystem_powergate_switch_ack_n[SWITCH_ACK_LATENCY];
  assign delayed_tb_peripheral_subsystem_powergate_switch_ack_n = tb_peripheral_subsystem_powergate_switch_ack_n[SWITCH_ACK_LATENCY];
  assign delayed_tb_memory_subsystem_banks_powergate_switch_ack_n = tb_memory_subsystem_banks_powergate_switch_ack_n[SWITCH_ACK_LATENCY];
  assign delayed_tb_external_subsystem_powergate_switch_ack_n = tb_external_subsystem_powergate_switch_ack_n[SWITCH_ACK_LATENCY];

  always_comb begin
`ifndef VERILATOR
    force x_heep_system_i.core_v_mini_mcu_i.cpu_subsystem_powergate_switch_ack_ni = delayed_tb_cpu_subsystem_powergate_switch_ack_n;
    force x_heep_system_i.core_v_mini_mcu_i.peripheral_subsystem_powergate_switch_ack_ni = delayed_tb_peripheral_subsystem_powergate_switch_ack_n;
    force x_heep_system_i.core_v_mini_mcu_i.memory_subsystem_banks_powergate_switch_ack_n = delayed_tb_memory_subsystem_banks_powergate_switch_ack_n;
    force external_subsystem_powergate_switch_ack_n = delayed_tb_external_subsystem_powergate_switch_ack_n;
`else
    x_heep_system_i.cpu_subsystem_powergate_switch_ack_n = delayed_tb_cpu_subsystem_powergate_switch_ack_n;
    x_heep_system_i.peripheral_subsystem_powergate_switch_ack_n = delayed_tb_peripheral_subsystem_powergate_switch_ack_n;
    x_heep_system_i.core_v_mini_mcu_i.memory_subsystem_banks_powergate_switch_ack_n = delayed_tb_memory_subsystem_banks_powergate_switch_ack_n;
    external_subsystem_powergate_switch_ack_n = delayed_tb_external_subsystem_powergate_switch_ack_n;
`endif
  end


  uartdpi #(
      .BAUD('d256000),
      .FREQ(CLK_FREQUENCY * 1000),  //Hz
      .NAME("uart0")
  ) i_uart0 (
      .clk_i,
      .rst_ni,
      .tx_o(uart_rx),
      .rx_i(uart_tx)
  );

  // jtag calls from dpi
  SimJTAG #(
      .TICK_DELAY(1),
      .PORT      (4567)
  ) i_sim_jtag (
      .clock(clk_i),
      .reset(~rst_ni),
      .enable(sim_jtag_enable),
      .init_done(rst_ni),
      .jtag_TCK(sim_jtag_tck),
      .jtag_TMS(sim_jtag_tms),
      .jtag_TDI(sim_jtag_tdi),
      .jtag_TRSTn(sim_jtag_trstn),
      .jtag_TDO_data(sim_jtag_tdo),
      .jtag_TDO_driven(1'b1),
      .exit()
  );

  // Flash used for booting (execute from flash or copy from flash)
  spiflash flash_boot_i (
      .csb(spi_flash_csb[0]),
      .clk(spi_flash_sck),
      .io0(spi_flash_sd_io[0]),  // MOSI
      .io1(spi_flash_sd_io[1]),  // MISO
      .io2(spi_flash_sd_io[2]),
      .io3(spi_flash_sd_io[3])
  );

  assign mux_jtag_tck   = JTAG_DPI ? sim_jtag_tck : jtag_tck_i;
  assign mux_jtag_tms   = JTAG_DPI ? sim_jtag_tms : jtag_tms_i;
  assign mux_jtag_tdi   = JTAG_DPI ? sim_jtag_tdi : jtag_tdi_i;
  assign mux_jtag_trstn = JTAG_DPI ? sim_jtag_trstn : jtag_trst_ni;

  assign sim_jtag_tdo   = JTAG_DPI ? mux_jtag_tdo : '0;
  assign jtag_tdo_o     = !JTAG_DPI ? mux_jtag_tdo : '0;

  assign memcopy_intr = '0;
  assign iffifo_int_o = '0;
  assign periph_slave_rsp = '0;

  assign heep_core_instr_resp = '0;
  assign heep_core_data_resp = '0;
  assign heep_debug_master_resp = '0;
  assign heep_dma_read_ch0_resp = '0;
  assign heep_dma_write_ch0_resp = '0;
  assign heep_dma_addr_ch0_resp = '0;
  assign heep_slave_req = '0;

endmodule  // testharness
