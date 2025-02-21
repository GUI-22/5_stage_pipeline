`timescale 1ns / 1ps
module lab3_tb;

  wire clk_50M, clk_11M0592;

  reg push_btn;   // BTN5 ????????????????��???????? 1
  reg reset_btn;  // BTN6 ??��?????????????��???????? 1

  reg [3:0] touch_btn; // BTN1~BTN4???????????????? 1
  reg [31:0] dip_sw;   // 32 ��?????????????ON???? 1

  wire [15:0] leds;  // 16 �� LED?????? 1 ????
  wire [7:0] dpy0;   // ??????��????????��??????? 1 ????
  wire [7:0] dpy1;   // ??????��????????��??????? 1 ????

  // ??? 3 ??????????
  `define inst_rtype(rd, rs1, rs2, op) \
    {7'b0, rs2, rs1, 3'b0, rd, op, 3'b001}

  `define inst_itype(rd, imm, op) \
    {imm, 4'b0, rd, op, 3'b010}
  
  `define inst_poke(rd, imm) `inst_itype(rd, imm, 4'b0001)
  `define inst_peek(rd, imm) `inst_itype(rd, imm, 4'b0010)

  // opcode table
  typedef enum logic [3:0] {
    ADD = 4'b0001,
    SUB = 4'b0010,
    AND = 4'b0011,
    OR  = 4'b0100,
    XOR = 4'b0101,
    NOT = 4'b0110,
    SLL = 4'b0111,
    SRL = 4'b1000,
    SRA = 4'b1001,
    ROL = 4'b1010
  } opcode_t;

  logic is_rtype, is_itype, is_load, is_store, is_unknown;
  logic [15:0] imm;
  logic [4:0] rd, rs1, rs2;
  logic [3:0] opcode;
  logic go_on;
  logic [31:0] expected;


  initial begin
    // ????????????????????????��????��
    dip_sw = 32'h0;
    touch_btn = 0;
    reset_btn = 0;
    push_btn = 0;
    go_on = 1;
    opcode = ADD; // ?????????????


    #100;
    reset_btn = 1;
    #100;
    reset_btn = 0;
    #1000;  // ?????��????

    // ????????? POKE ?????????????????
    for (integer i = 1; i < 32; i = i + 1) begin
      #100;
      rd = i;   // only lower 5 bits
      expected = $urandom_range(0, 65536);
      dip_sw = `inst_poke(rd, expected);
      push_btn = 1;

      #100;
      push_btn = 0;

      #100;
      dip_sw = `inst_peek(rd, 16'd0);
      push_btn = 1;

      #100;
      push_btn = 0;

      assert (leds == expected) else begin
        $error("Error: signal1 (%0d) is not equal to signal2 (%0d)", leds, expected);
      end

      #1000;
    end

    // ?????????????

    for (integer i = 1; i < 32 && go_on; i = i + 3) begin
      rs1 = i;
      rs2 = (i + 1) % 32;
      rd = (i + 2) % 32;

      #100; 
      dip_sw = `inst_poke(rs1, 16'd2);
      push_btn = 1;
      #100;
      push_btn = 0;

      #100;
      dip_sw = `inst_poke(rs2, 16'd1);
      push_btn = 1;
      #100;
      push_btn = 0;

      #100;
      dip_sw = `inst_rtype(rd, rs1, rs2, opcode);
      push_btn = 1;
      #100;
      push_btn = 0;

      #100;
      dip_sw = `inst_peek(rd, 16'd0);
      push_btn = 1;
      #100;
      push_btn = 0;
  

      if (opcode == ROL) begin
          go_on = 0;
      end else begin
        opcode = opcode_t'(opcode + 1);
      end

      #1000;
    end


    opcode = ADD; // ?????????????
    go_on = 1;
    for (integer i = 1; i < 32 && go_on; i = i + 3) begin
      rs1 = i;
      rs2 = (i + 1) % 32;
      rd = (i + 2) % 32;

      #100; 
      dip_sw = `inst_poke(rs1, 16'hfffc); // -4
      push_btn = 1;
      #100;
      push_btn = 0;

      #100;
      dip_sw = `inst_poke(rs2, 16'd1);
      push_btn = 1;
      #100;
      push_btn = 0;

      #100;
      dip_sw = `inst_rtype(rd, rs1, rs2, opcode);
      push_btn = 1;
      #100;
      push_btn = 0;

      #100;
      dip_sw = `inst_peek(rd, 16'd0);
      push_btn = 1;
      #100;
      push_btn = 0;
  

      if (opcode == ROL) begin
          go_on = 0;
      end else begin
        opcode = opcode_t'(opcode + 1);
      end

      #1000;
    end





    #10000 $finish;
  end

  // ????????????
  lab3_top dut (
      .clk_50M(clk_50M),
      .clk_11M0592(clk_11M0592),
      .push_btn(push_btn),
      .reset_btn(reset_btn),
      .touch_btn(touch_btn),
      .dip_sw(dip_sw),
      .leds(leds),
      .dpy1(dpy1),
      .dpy0(dpy0),

      .txd(),
      .rxd(1'b1),
      .uart_rdn(),
      .uart_wrn(),
      .uart_dataready(1'b0),
      .uart_tbre(1'b0),
      .uart_tsre(1'b0),
      .base_ram_data(),
      .base_ram_addr(),
      .base_ram_ce_n(),
      .base_ram_oe_n(),
      .base_ram_we_n(),
      .base_ram_be_n(),
      .ext_ram_data(),
      .ext_ram_addr(),
      .ext_ram_ce_n(),
      .ext_ram_oe_n(),
      .ext_ram_we_n(),
      .ext_ram_be_n(),
      .flash_d(),
      .flash_a(),
      .flash_rp_n(),
      .flash_vpen(),
      .flash_oe_n(),
      .flash_ce_n(),
      .flash_byte_n(),
      .flash_we_n()
  );

  // ????
  clock osc (
      .clk_11M0592(clk_11M0592),
      .clk_50M    (clk_50M)
  );

endmodule
