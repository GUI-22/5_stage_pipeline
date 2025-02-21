`default_nettype none
`include "./lab6/common_macros.svh"
`include "./lab6/exception_macros.svh"


module thinpad_top (
    input wire clk_50M,     // 50MHz ʱ������
    input wire clk_11M0592, // 11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire push_btn,  // BTN5 ��ť���أ���������·������ʱΪ 1
    input wire reset_btn, // BTN6 ��λ��ť����������·������ʱΪ 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4����ť���أ�����ʱΪ 1
    input  wire [31:0] dip_sw,     // 32 λ���뿪�أ�������ON��ʱΪ 1
    output wire [15:0] leds,       // 16 λ LED�����ʱ 1 ����
    output wire [ 7:0] dpy0,       // ����ܵ�λ�źţ�����С���㣬��� 1 ����
    output wire [ 7:0] dpy1,       // ����ܸ�λ�źţ�����С���㣬��� 1 ����

    // CPLD ���ڿ������ź�
    output wire uart_rdn,        // �������źţ�����Ч
    output wire uart_wrn,        // д�����źţ�����Ч
    input  wire uart_dataready,  // ��������׼����
    input  wire uart_tbre,       // �������ݱ�־
    input  wire uart_tsre,       // ���ݷ�����ϱ�־

    // BaseRAM �ź�
    inout wire [31:0] base_ram_data,  // BaseRAM ���ݣ��� 8 λ�� CPLD ���ڿ���������
    output wire [19:0] base_ram_addr,  // BaseRAM ��ַ
    output wire [3:0] base_ram_be_n,  // BaseRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ 0
    output wire base_ram_ce_n,  // BaseRAM Ƭѡ������Ч
    output wire base_ram_oe_n,  // BaseRAM ��ʹ�ܣ�����Ч
    output wire base_ram_we_n,  // BaseRAM дʹ�ܣ�����Ч

    // ExtRAM �ź�
    inout wire [31:0] ext_ram_data,  // ExtRAM ����
    output wire [19:0] ext_ram_addr,  // ExtRAM ��ַ
    output wire [3:0] ext_ram_be_n,  // ExtRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ 0
    output wire ext_ram_ce_n,  // ExtRAM Ƭѡ������Ч
    output wire ext_ram_oe_n,  // ExtRAM ��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,  // ExtRAM дʹ�ܣ�����Ч

    // ֱ�������ź�
    output wire txd,  // ֱ�����ڷ��Ͷ�
    input  wire rxd,  // ֱ�����ڽ��ն�

    // Flash �洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0] flash_a,  // Flash ��ַ��a0 ���� 8bit ģʽ��Ч��16bit ģʽ������
    inout wire [15:0] flash_d,  // Flash ����
    output wire flash_rp_n,  // Flash ��λ�źţ�����Ч
    output wire flash_vpen,  // Flash д�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,  // Flash Ƭѡ�źţ�����Ч
    output wire flash_oe_n,  // Flash ��ʹ���źţ�����Ч
    output wire flash_we_n,  // Flash дʹ���źţ�����Ч
    output wire flash_byte_n, // Flash 8bit ģʽѡ�񣬵���Ч����ʹ�� flash �� 16 λģʽʱ����Ϊ 1

    // USB �������źţ��ο� SL811 оƬ�ֲ�
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB ������������������� dm9k_sd[7:0] ����
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // ����������źţ��ο� DM9000A оƬ�ֲ�
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // ͼ������ź�
    output wire [2:0] video_red,    // ��ɫ���أ�3 λ
    output wire [2:0] video_green,  // ��ɫ���أ�3 λ
    output wire [1:0] video_blue,   // ��ɫ���أ�2 λ
    output wire       video_hsync,  // ��ͬ����ˮƽͬ�����ź�
    output wire       video_vsync,  // ��ͬ������ֱͬ�����ź�
    output wire       video_clk,    // ����ʱ�����
    output wire       video_de      // ��������Ч�źţ���������������
);

  /* =========== Demo code begin =========== */

    // PLL ��Ƶʾ��
    logic locked, clk_70M;
    clk_wiz_0 clock_gen (
        // Clock in ports
        .clk_in1(clk_50M),  // �ⲿʱ������
        // Clock out ports
        .clk_out1(clk_70M),  // ʱ����� 1��Ƶ���� IP ���ý���������
        // Status and control signals
        .reset(reset_btn),  // PLL ��λ����
        .locked(locked)  // PLL ����ָʾ�����"1"��ʾʱ���ȶ���
                        // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
    );

    logic reset_of_clk70M;
    always_ff @(posedge clk_70M or negedge locked) begin
      if (~locked) reset_of_clk70M <= 1'b1;
      else reset_of_clk70M <= 1'b0;
    end

//   always_ff @(posedge clk_10M or posedge reset_of_clk10M) begin
//     if (reset_of_clk10M) begin
//       // Your Code
//     end else begin
//       // Your Code
//     end
//   end

//   // ��ʹ���ڴ桢����ʱ��������ʹ���ź�
//   assign base_ram_ce_n = 1'b1;
//   assign base_ram_oe_n = 1'b1;
//   assign base_ram_we_n = 1'b1;

//   assign ext_ram_ce_n = 1'b1;
//   assign ext_ram_oe_n = 1'b1;
//   assign ext_ram_we_n = 1'b1;

//   assign uart_rdn = 1'b1;
//   assign uart_wrn = 1'b1;

//   // ��������ӹ�ϵʾ��ͼ��dpy1 ͬ��
//   // p=dpy0[0] // ---a---
//   // c=dpy0[1] // |     |
//   // d=dpy0[2] // f     b
//   // e=dpy0[3] // |     |
//   // b=dpy0[4] // ---g---
//   // a=dpy0[5] // |     |
//   // f=dpy0[6] // e     c
//   // g=dpy0[7] // |     |
//   //           // ---d---  p

//   // 7 ���������������ʾ���� number �� 16 ������ʾ�����������
//   logic [7:0] number;
//   SEG7_LUT segL (
//       .oSEG1(dpy0),
//       .iDIG (number[3:0])
//   );  // dpy0 �ǵ�λ�����
//   SEG7_LUT segH (
//       .oSEG1(dpy1),
//       .iDIG (number[7:4])
//   );  // dpy1 �Ǹ�λ�����

//   logic [15:0] led_bits;
//   assign leds = led_bits;

//   always_ff @(posedge push_btn or posedge reset_btn) begin
//     if (reset_btn) begin  // ��λ���£����� LED Ϊ��ʼֵ
//       led_bits <= 16'h1;
//     end else begin  // ÿ�ΰ��°�ť���أ�LED ѭ������
//       led_bits <= {led_bits[14:0], led_bits[15]};
//     end
//   end

//   // ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
//   logic [7:0] ext_uart_rx;
//   logic [7:0] ext_uart_buffer, ext_uart_tx;
//   logic ext_uart_ready, ext_uart_clear, ext_uart_busy;
//   logic ext_uart_start, ext_uart_avai;

//   assign number = ext_uart_buffer;

//   // ����ģ�飬9600 �޼���λ
//   async_receiver #(
//       .ClkFrequency(50000000),
//       .Baud(9600)
//   ) ext_uart_r (
//       .clk           (clk_50M),         // �ⲿʱ���ź�
//       .RxD           (rxd),             // �ⲿ�����ź�����
//       .RxD_data_ready(ext_uart_ready),  // ���ݽ��յ���־
//       .RxD_clear     (ext_uart_clear),  // ������ձ�־
//       .RxD_data      (ext_uart_rx)      // ���յ���һ�ֽ�����
//   );

//   assign ext_uart_clear = ext_uart_ready; // �յ����ݵ�ͬʱ�������־����Ϊ������ȡ�� ext_uart_buffer ��
//   always_ff @(posedge clk_50M) begin  // ���յ������� ext_uart_buffer
//     if (ext_uart_ready) begin
//       ext_uart_buffer <= ext_uart_rx;
//       ext_uart_avai   <= 1;
//     end else if (!ext_uart_busy && ext_uart_avai) begin
//       ext_uart_avai <= 0;
//     end
//   end
//   always_ff @(posedge clk_50M) begin  // �������� ext_uart_buffer ���ͳ�ȥ
//     if (!ext_uart_busy && ext_uart_avai) begin
//       ext_uart_tx <= ext_uart_buffer;
//       ext_uart_start <= 1;
//     end else begin
//       ext_uart_start <= 0;
//     end
//   end

//   // ����ģ�飬9600 �޼���λ
//   async_transmitter #(
//       .ClkFrequency(50000000),
//       .Baud(9600)
//   ) ext_uart_t (
//       .clk      (clk_50M),         // �ⲿʱ���ź�
//       .TxD      (txd),             // �����ź����
//       .TxD_busy (ext_uart_busy),   // ������æ״ָ̬ʾ
//       .TxD_start(ext_uart_start),  // ��ʼ�����ź�
//       .TxD_data (ext_uart_tx)      // �����͵�����
//   );

//   // ͼ�������ʾ���ֱ��� 800x600@72Hz������ʱ��Ϊ 50MHz
//   logic [11:0] hdata;
//   assign video_red   = hdata < 266 ? 3'b111 : 0;  // ��ɫ����
//   assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0;  // ��ɫ����
//   assign video_blue  = hdata >= 532 ? 2'b11 : 0;  // ��ɫ����
//   assign video_clk   = clk_50M;
//   vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at72 (
//       .clk        (clk_50M),
//       .hdata      (hdata),        // ������
//       .vdata      (),             // ������
//       .hsync      (video_hsync),
//       .vsync      (video_vsync),
//       .data_enable(video_de)
//   );
//   /* =========== Demo code end =========== */




    logic sys_clk;
    logic sys_rst;

    assign sys_clk = clk_70M;
    assign sys_rst = reset_of_clk70M;
    parameter uart_controller_clk_freq = 70_000_000;

    // ��ʵ�鲻ʹ�� CPLD ���ڣ����÷�ֹ���߳�ͻ
    assign uart_rdn = 1'b1;
    assign uart_wrn = 1'b1;

    logic [`ADDR_WIDTH-1:0] IF_pc;
    logic [`ADDR_WIDTH-1:0] ID_pc;
    logic [`ADDR_WIDTH-1:0] EXE_pc;
    logic [`ADDR_WIDTH-1:0] MEM_pc;
    logic [`ADDR_WIDTH-1:0] WB_pc;


    // CONTROLLER
    logic bubble_PC;
    logic stall_PC;

    logic stall_IM;

    logic bubble_IF_ID_REG;
    logic stall_IF_ID_REG;

    logic bubble_ID_EXE_REG;
    logic stall_ID_EXE_REG;

    logic bubble_EXE_MEM_REG;
    logic stall_EXE_MEM_REG;

    logic bubble_MEM_WB_REG;

    // from MEM_EXCEPTION_PROCESSOR
    logic MEM_catch_from_excp_processor;
    logic [`ADDR_WIDTH-1:0] MEM_npc_from_exception_processor;
    logic [`PRIVILEGE_WIDTH-1:0] current_privilege;
    satp_t current_satp;

    // from SATP_MUX
    satp_t IF_satp;

    // TIME
    logic [`TIME_DATA_WIDTH-1:0] mtime;
    logic [`TIME_DATA_WIDTH-1:0] mtimecmp;
    logic time_exceeded;


    // IF
    
    // to inst cache
    logic [`ADDR_WIDTH-1:0] adr_im;
    logic [`DATA_WIDTH-1:0] dat_m2s_im;
    logic [`DATA_WIDTH-1:0] dat_s2m_im;
    logic we_im;
    logic [`SELECT_WIDTH-1:0] sel_im;
    logic stb_im;
    logic ack_im;
    logic cyc_im;
    logic err_im;

    // inst cache to im mmu
    logic mmu_ack;
    logic mmu_err;
    logic mmu_stb;
    logic mmu_cyc;
    logic [`ADDR_WIDTH-1:0] mmu_adr;
    logic mmu_we;
    logic [`SELECT_WIDTH-1:0] mmu_sel;
    logic [`DATA_WIDTH-1:0] mmu_dat_m2s;
    logic [`DATA_WIDTH-1:0] mmu_dat_s2m;

    // im mmu to arbit
    logic [`ADDR_WIDTH-1:0]   wbm_adr_im;    // ADR_I() address input
    logic [`DATA_WIDTH-1:0]   wbm_dat_m2s_im;    // DAT_I() data in
    logic [`DATA_WIDTH-1:0]   wbm_dat_s2m_im;    // DAT_O() data out
    logic wbm_we_im;     // WE_I write enable input
    logic [`SELECT_WIDTH-1:0] wbm_sel_im;    // SEL_I() select input
    logic wbm_stb_im;    // STB_I strobe input
    logic wbm_ack_im;    // ACK_O acknowledge output
    logic wbm_cyc_im;    // CYC_I cycle input

    // for IF
    // logic [`ADDR_WIDTH-1:0] IF_pc;
    logic [`INSTR_WIDTH-1:0] IF_instr;
    logic IF_im_query_ack;
    logic [`ADDR_WIDTH-1:0] IF_npc_from_mux_pc;
    logic IF_pc_wrong;

    logic IF_exception_flag;
    logic [`EXCP_CODE_WIDTH-1:0] IF_exception_code;
    logic [`MXLEN-1:0] IF_exception_val;

    // for ID
    logic [`ADDR_WIDTH-1:0] ID_npc_from_calculator;
    logic ID_need_branch;

    // logic [`ADDR_WIDTH-1:0] ID_pc;
    logic [`INSTR_WIDTH-1:0] ID_instr;

    logic BEFORE_ID_exception_flag;
    logic [`EXCP_CODE_WIDTH-1:0] BEFORE_ID_exception_code;
    logic [`MXLEN-1:0] BEFORE_ID_exception_val;

    // IM TLB related
    logic [`VPN_WIDTH-1:0] vpn_query_im;
    logic [`PPN_WIDTH-1:0] ppn_query_im;
    logic hit_query_im;
    logic [`VPN_WIDTH-1:0] vpn_update_im;
    logic [`PPN_WIDTH-1:0] ppn_update_im;
    logic tlb_wen_im;

    logic sfence_flag; // both for im and dm tlb

    IF_PC 
    instance_IF_PC(
        .clk        (sys_clk        ),
        .rst        (sys_rst        ),

        .stall_pc_i (stall_PC ),
        .npc_i      (IF_npc_from_mux_pc      ),
        .pc_o       (IF_pc       )
    );

    IF_MUX_PC 
    instance_IF_MUX_PC(
        .pc_i                                  (IF_pc                    ),
        .npc_from_calculator_i               (ID_npc_from_calculator ),
        .need_branch_i                       (ID_need_branch         ),
        .npc_from_exception_processor_i      (MEM_npc_from_exception_processor),
        .catch_from_excp_processor_i         (MEM_catch_from_excp_processor),

        .npc_from_mux_pc_o                   (IF_npc_from_mux_pc     ),
        .pc_wrong_o                          (IF_pc_wrong            )
    );  
    
    
    IF_IM 
    instance_IF_IM(
        .clk_i         (sys_clk         ),
        .rst_i         (sys_rst         ),

        .stall_im_i    (stall_IM    ),
        .query_adr_i   (IF_pc   ),
        .query_ack_o   (IF_im_query_ack   ),
        .query_data_o  (IF_instr  ),

        .exception_flag_o   (IF_exception_flag  ),
        .exception_code_o   (IF_exception_code  ),
        .exception_val_o    (IF_exception_val   ),

        .wbm_adr_o     (adr_im     ),
        .wbm_dat_m2s_o (dat_m2s_im ),
        .wbm_dat_s2m_i (dat_s2m_im ),
        .wbm_we_o      (we_im      ),
        .wbm_sel_o     (sel_im     ),
        .wbm_stb_o     (stb_im     ),
        .wbm_ack_i     (ack_im     ),
        .wbm_cyc_o     (cyc_im     ),
        .wbm_err_i     (err_im     ),

        .exception_handled_i (MEM_catch_from_excp_processor)
    );

    // add middle ware: INST_CACHE
    INST_CACHE
    instance_INST_CACHE(
        .clk       (sys_clk       ),
        .rst       (sys_rst       ),

        .wbm_adr_i   (adr_im   ),
        .wbm_stb_i   (stb_im   ),
        .wbm_cyc_i   (cyc_im   ),
        .wbm_we_i    (we_im    ),
        .wbm_sel_i   (sel_im   ),
        .wbm_dat_i   (dat_m2s_im   ),

        .wbm_ack_o   (ack_im   ),
        .wbm_err_o   (err_im   ),
        .wbm_dat_o   (dat_s2m_im   ),

        .mmu_ack_i   (mmu_ack   ),
        .mmu_err_i   (mmu_err   ),
        .mmu_dat_i   (mmu_dat_s2m   ),

        .mmu_stb_o   (mmu_stb   ),
        .mmu_cyc_o   (mmu_cyc   ),
        .mmu_adr_o   (mmu_adr   ),
        .mmu_we_o    (mmu_we    ),
        .mmu_sel_o   (mmu_sel   ),
        .mmu_dat_o (mmu_dat_m2s)
    );
    
    IM_MMU 
    instance_IM_MMU(
        .clk_i       (sys_clk       ),
        .rst_i       (sys_rst       ),

        .im_addr_i   (mmu_adr   ),
        .im_data_i   (mmu_dat_m2s   ),
        .im_data_o   (mmu_dat_s2m   ),
        .im_we_i     (mmu_we    ),
        .im_sel_i    (mmu_sel   ),
        .im_stb_i    (mmu_stb   ),
        .im_ack_o    (mmu_ack   ),
        .im_cyc_i    (mmu_cyc   ),
        .im_err_o    (mmu_err   ),

        .arb_addr_o  (wbm_adr_im  ),
        .arb_data_o  (wbm_dat_m2s_im  ),
        .arb_data_i  (wbm_dat_s2m_im  ),
        .arb_we_o    (wbm_we_im    ),
        .arb_sel_o   (wbm_sel_im   ),
        .arb_stb_o   (wbm_stb_im   ),
        .arb_ack_i   (wbm_ack_im   ),
        .arb_cyc_o   (wbm_cyc_im   ),

        .satp_i      (IF_satp),
        .privilege_i (current_privilege),

        .vpn_query_o (vpn_query_im),
        .ppn_query_i (ppn_query_im),
        .hit_query_i (hit_query_im),

        .vpn_update_o (vpn_update_im),
        .ppn_update_o (ppn_update_im),
        .tlb_wen_o    (tlb_wen_im)
    );
    
    TLB 
    IM_TLB(
        .clk_i        (sys_clk        ),
        .rst_i        (sys_rst        ),
        .vpn_query_i  (vpn_query_im  ),
        .ppn_query_o  (ppn_query_im  ),
        .hit_query_o  (hit_query_im  ),
        .vpn_update_i (vpn_update_im ),
        .ppn_update_i (ppn_update_im ),
        .tlb_wen_i    (tlb_wen_im    ),
        .sfence_i     (sfence_flag   )
    );
    

    IF_ID_REG
    instance_IF_ID_REG(
        .clk                 (sys_clk                 ),
        .rst                 (sys_rst                 ),

        .bubble_i            (bubble_IF_ID_REG            ),
        .stall_i             (stall_IF_ID_REG             ),

        .IF_instr_i          (IF_instr          ),
        .IF_pc_i             (IF_pc             ),

        .IF_exception_flag_i (IF_exception_flag ),
        .IF_exception_code_i (IF_exception_code ),
        .IF_exception_val_i  (IF_exception_val  ),

        .ID_instr_o          (ID_instr          ),
        .ID_pc_o             (ID_pc             ),

        .BEFORE_ID_exception_flag_o (BEFORE_ID_exception_flag ),
        .BEFORE_ID_exception_code_o (BEFORE_ID_exception_code ),
        .BEFORE_ID_exception_val_o  (BEFORE_ID_exception_val  )
    );
    

    

    // ID 

    logic [5:0] ID_instr_type;
    logic [`REG_NUM_WIDTH-1:0] ID_rf_addr_a;
    logic [`REG_NUM_WIDTH-1:0] ID_rf_addr_b;
    logic [`DATA_WIDTH-1:0] ID_rf_data_a;
    logic [`DATA_WIDTH-1:0] ID_rf_data_b;
    logic [`DATA_WIDTH-1:0] ID_imm;
    logic ID_mux_a_choice;
    logic ID_mux_b_choice;

    // excp
    logic ID_exception_flag;
    logic [`EXCP_CODE_WIDTH-1:0] ID_exception_code;
    logic [`MXLEN-1:0] ID_exception_val;
    
    // to exe (alu)
    logic [`DATA_WIDTH-1:0] ID_alu_oprand_a;
    logic [`DATA_WIDTH-1:0] ID_alu_oprand_b;
    logic [`ALU_OPERATOR_WIDTH-1:0] ID_alu_op;

    // to mem (dm & mux_dm)
    logic ID_query_wen;
    logic ID_query_ren;
    logic [2:0] ID_query_width;
    logic ID_query_sign_ext;
    logic [`MUX_MEM_CHOICE_WIDTH-1:0] ID_mux_mem_choice;

    logic [`CSR_OP_WIDTH-1:0] ID_csr_op;
    logic [`CSR_ADDR_WIDTH-1:0] ID_csr_addr;

    // to wb
    logic [`REG_NUM_WIDTH-1:0] ID_rf_waddr;
    logic ID_rf_wen;

    // excp
    logic BEFORE_EXE_exception_flag;
    logic [`EXCP_CODE_WIDTH-1:0] BEFORE_EXE_exception_code;
    logic [`MXLEN-1:0] BEFORE_EXE_exception_val;

    // to exe (alu)
    logic [`DATA_WIDTH-1:0] EXE_alu_oprand_a;
    logic [`DATA_WIDTH-1:0] EXE_alu_oprand_b;
    logic [`ALU_OPERATOR_WIDTH-1:0] EXE_alu_op;

    // to mem (dm & mux_dm)
    // logic [`ADDR_WIDTH-1:0] EXE_pc;

    logic EXE_query_wen;
    logic EXE_query_ren;
    logic [2:0] EXE_query_width;
    logic EXE_query_sign_ext;
    logic [`DATA_WIDTH-1:0] EXE_query_data_m2s;
    logic [`MUX_MEM_CHOICE_WIDTH-1:0] EXE_mux_mem_choice;

    logic [`CSR_OP_WIDTH-1:0] EXE_csr_op;
    logic [`CSR_ADDR_WIDTH-1:0] EXE_csr_addr;

    // to wb
    logic [`REG_NUM_WIDTH-1:0] EXE_rf_waddr;
    logic EXE_rf_wen;


    ID_DECODER 
    instance_ID_DECODER(
        .instr_i          (ID_instr          ),

        .BEFORE_ID_exception_flag_i     (BEFORE_ID_exception_flag ),
        .BEFORE_ID_exception_code_i     (BEFORE_ID_exception_code ),
        .BEFORE_ID_exception_val_i      (BEFORE_ID_exception_val  ),

        .instr_type_o     (ID_instr_type     ),
        .rf_addr_a_o      (ID_rf_addr_a      ),
        .rf_addr_b_o      (ID_rf_addr_b      ),
        .imm_o            (ID_imm            ),
        .mux_a_choice_o   (ID_mux_a_choice   ),
        .mux_b_choice_o   (ID_mux_b_choice   ),

        .ID_exception_flag_o        (ID_exception_flag        ),
        .ID_exception_code_o        (ID_exception_code        ),
        .ID_exception_val_o         (ID_exception_val         ),

        .alu_op_o         (ID_alu_op         ),

        .query_wen_o      (ID_query_wen      ),
        .query_ren_o      (ID_query_ren      ),
        .query_width_o    (ID_query_width    ),
        .query_sign_ext_o (ID_query_sign_ext ),
        .mux_mem_choice_o (ID_mux_mem_choice ),

        .csr_op_o          (ID_csr_op         ),
        .csr_addr_o        (ID_csr_addr       ),

        .rf_waddr_o       (ID_rf_waddr       ),
        .rf_wen_o         (ID_rf_wen         ),

        .sfence_o         (sfence_flag)
    );


    
    ID_RF 
    instance_ID_RF(
        .clk         (sys_clk         ),
        .rst         (sys_rst         ),

        .rf_wen_i    (WB_rf_wen    ),
        .rf_waddr_i  (WB_rf_waddr  ),
        .rf_wdata_i  (WB_rf_wdata  ),

        .rf_addr_a_i (ID_rf_addr_a ),
        .rf_data_a_o (ID_rf_data_a ),
        .rf_addr_b_i (ID_rf_addr_b ),
        .rf_data_b_o (ID_rf_data_b ),

        .EXE_rf_waddr_i (EXE_rf_waddr),
        .EXE_rf_wdata_i (EXE_alu_result),
        .EXE_rf_wen_i   (EXE_rf_wen  ),
        .EXE_query_ren_i (EXE_query_ren),

        .MEM_rf_waddr_i (MEM_rf_waddr),
        .MEM_rf_wdata_i (MEM_alu_result),
        .MEM_rf_wen_i   (MEM_rf_wen  ),

        .WB_rf_waddr_i (WB_rf_waddr),
        .WB_rf_wdata_i (WB_rf_wdata),
        .WB_rf_wen_i   (WB_rf_wen  )
    );


    ID_NPC_CALCULATOR 
    instance_ID_NPC_CALCULATOR(
        .instr_type_i          (ID_instr_type          ),
        .rf_data_a_i           (ID_rf_data_a           ),
        .rf_data_b_i           (ID_rf_data_b           ),
        .pc_i                  (ID_pc                  ),
        .imm_offset_i          (ID_imm          ),
        .npc_from_calculator_o (ID_npc_from_calculator ),
        .need_branch_o         (ID_need_branch         )
    );


    ID_MUX_A 
    instance_ID_MUX_A(
        .rf_data_a_i    (ID_rf_data_a    ),
        .pc_i           (ID_pc           ),
        .mux_a_choice_i (ID_mux_a_choice ),
        .alu_oprand_a_o (ID_alu_oprand_a )
    );

    ID_MUX_B 
    instance_ID_MUX_B(
        .rf_data_b_i    (ID_rf_data_b    ),
        .imm_i          (ID_imm          ),
        .mux_b_choice_i (ID_mux_b_choice ),
        .alu_oprand_b_o (ID_alu_oprand_b )
    );



    ID_EXE_REG 
    instance_ID_EXE_REG(
        .clk                  (sys_clk                  ),
        .rst                  (sys_rst                  ),

        .bubble_i             (bubble_ID_EXE_REG             ),
        .stall_i              (stall_ID_EXE_REG            ),

        .ID_alu_oprand_a_i    (ID_alu_oprand_a    ),
        .ID_alu_oprand_b_i    (ID_alu_oprand_b    ),
        .ID_alu_op_i          (ID_alu_op          ),
        .ID_query_wen_i       (ID_query_wen       ),
        .ID_query_ren_i       (ID_query_ren       ),
        .ID_query_width_i     (ID_query_width     ),
        .ID_query_sign_ext_i  (ID_query_sign_ext  ),
        .ID_query_data_m2s_i  (ID_rf_data_b       ),
        .ID_mux_mem_choice_i  (ID_mux_mem_choice  ),

        .ID_csr_op_i          (ID_csr_op                 ),
        .ID_csr_addr_i        (ID_csr_addr               ),

        .ID_rf_waddr_i        (ID_rf_waddr        ),
        .ID_rf_wen_i          (ID_rf_wen          ),
        .ID_pc_i          (ID_pc          ),

        .ID_exception_flag_i         (ID_exception_flag         ),
        .ID_exception_code_i         (ID_exception_code         ),
        .ID_exception_val_i          (ID_exception_val          ),

        .EXE_alu_oprand_a_o   (EXE_alu_oprand_a   ),
        .EXE_alu_oprand_b_o   (EXE_alu_oprand_b   ),
        .EXE_alu_op_o         (EXE_alu_op         ),
        
        .EXE_query_wen_o      (EXE_query_wen      ),
        .EXE_query_ren_o      (EXE_query_ren      ),
        .EXE_query_width_o    (EXE_query_width    ),
        .EXE_query_sign_ext_o (EXE_query_sign_ext ),
        .EXE_query_data_m2s_o (EXE_query_data_m2s ),
        .EXE_mux_mem_choice_o (EXE_mux_mem_choice ),

        .EXE_csr_op_o         (EXE_csr_op                ),
        .EXE_csr_addr_o       (EXE_csr_addr              ),

        .EXE_rf_waddr_o       (EXE_rf_waddr       ),
        .EXE_rf_wen_o         (EXE_rf_wen         ),
        .EXE_pc_o          (EXE_pc          ),

        .BEFORE_EXE_exception_flag_o (BEFORE_EXE_exception_flag ),
        .BEFORE_EXE_exception_code_o (BEFORE_EXE_exception_code ),
        .BEFORE_EXE_exception_val_o  (BEFORE_EXE_exception_val  )
    );


    // EXE

    logic [`DATA_WIDTH-1:0] EXE_alu_result;

    // for EXE exception
    logic EXE_exception_flag;
    logic [`EXCP_CODE_WIDTH-1:0] EXE_exception_code;
    logic [`MXLEN-1:0] EXE_exception_val;

    // excp
    logic BEFORE_MEM_exception_flag;
    logic [`EXCP_CODE_WIDTH-1:0] BEFORE_MEM_exception_code;
    logic [`MXLEN-1:0] BEFORE_MEM_exception_val;

    // to mem (dm & mux_dm)
    // logic [`ADDR_WIDTH-1:0] MEM_pc;

    logic [`DATA_WIDTH-1:0] MEM_alu_result;
    logic MEM_query_wen;
    logic MEM_query_ren;
    logic [2:0] MEM_query_width;
    logic MEM_query_sign_ext;
    logic [`DATA_WIDTH-1:0] MEM_query_data_m2s;
    logic [`MUX_MEM_CHOICE_WIDTH-1:0] MEM_mux_mem_choice;

    logic [`CSR_OP_WIDTH-1:0] MEM_csr_op;
    logic [`CSR_ADDR_WIDTH-1:0] MEM_csr_addr;

    logic MEM_interrupt_flag;

    // to wb
    logic [`REG_NUM_WIDTH-1:0] MEM_rf_waddr;
    logic MEM_rf_wen;

    EXE_ALU 
    instance_EXE_ALU(
        .alu_a                       (EXE_alu_oprand_a          ),
        .alu_b                       (EXE_alu_oprand_b          ),
        .alu_op                      (EXE_alu_op                ),

        .EXE_query_wen_i             (EXE_query_wen             ),
        .EXE_query_ren_i             (EXE_query_ren             ),
        .EXE_query_width_i           (EXE_query_width           ),

        .BEFORE_EXE_exception_flag_i (BEFORE_EXE_exception_flag ),
        .BEFORE_EXE_exception_code_i (BEFORE_EXE_exception_code ),
        .BEFORE_EXE_exception_val_i  (BEFORE_EXE_exception_val  ),

        .alu_y                       (EXE_alu_result            ),

        .EXE_exception_flag_o        (EXE_exception_flag        ),
        .EXE_exception_code_o        (EXE_exception_code        ),
        .EXE_exception_val_o         (EXE_exception_val         )
    );
    
    
    
    EXE_MEM_REG 
    instance_EXE_MEM_REG(
        .clk                  (sys_clk                  ),
        .rst                  (sys_rst                  ),

        .bubble_i             (bubble_EXE_MEM_REG            ),
        .stall_i              (stall_EXE_MEM_REG             ),

        .time_exceeded_i      (time_exceeded                 ),

        .EXE_alu_result_i     (EXE_alu_result),
        .EXE_query_wen_i      (EXE_query_wen      ),
        .EXE_query_ren_i      (EXE_query_ren      ),
        .EXE_query_width_i    (EXE_query_width    ),
        .EXE_query_sign_ext_i (EXE_query_sign_ext ),
        .EXE_query_data_m2s_i (EXE_query_data_m2s ),
        .EXE_mux_mem_choice_i (EXE_mux_mem_choice ),

        .EXE_csr_op_i       (EXE_csr_op         ),
        .EXE_csr_addr_i     (EXE_csr_addr       ),

        .EXE_rf_waddr_i       (EXE_rf_waddr       ),
        .EXE_rf_wen_i         (EXE_rf_wen         ),
        .EXE_pc_i         (EXE_pc         ),

        .EXE_exception_flag_i      (EXE_exception_flag      ),
        .EXE_exception_code_i      (EXE_exception_code      ),
        .EXE_exception_val_i       (EXE_exception_val       ),

        .MEM_alu_result_o     (MEM_alu_result),
        .MEM_query_wen_o      (MEM_query_wen      ),
        .MEM_query_ren_o      (MEM_query_ren      ),
        .MEM_query_width_o    (MEM_query_width    ),
        .MEM_query_sign_ext_o (MEM_query_sign_ext ),
        .MEM_query_data_m2s_o (MEM_query_data_m2s),
        .MEM_mux_mem_choice_o (MEM_mux_mem_choice ),

        .MEM_csr_op_o           (MEM_csr_op     ),
        .MEM_csr_addr_o         (MEM_csr_addr   ),

        .MEM_rf_waddr_o       (MEM_rf_waddr       ),
        .MEM_rf_wen_o         (MEM_rf_wen         ),
        .MEM_pc_o             (MEM_pc),

        .BEFORE_MEM_exception_flag_o (BEFORE_MEM_exception_flag ),
        .BEFORE_MEM_exception_code_o (BEFORE_MEM_exception_code ),
        .BEFORE_MEM_exception_val_o  (BEFORE_MEM_exception_val  ),

        .interrupt_flag_o       (MEM_interrupt_flag     )
    );




    // MEM
    logic MEM_dm_query_ack;
    logic [`DATA_WIDTH-1:0] MEM_query_data_s2m;
    logic [`DATA_WIDTH-1:0] MEM_rf_wdata;
    logic [`MXLEN-1:0] MEM_orig_csr_data;

    // excp
    logic MEM_exception_flag;
    logic [`EXCP_CODE_WIDTH-1:0] MEM_exception_code;
    logic [`MXLEN-1:0] MEM_exception_val;

    // to wb
    // logic [`ADDR_WIDTH-1:0] WB_pc;

    logic [`REG_NUM_WIDTH-1:0] WB_rf_waddr;
    logic [`DATA_WIDTH-1:0] WB_rf_wdata;
    logic WB_rf_wen;

    // to dm mmu

    logic [`ADDR_WIDTH-1:0] adr_dm;
    logic [`DATA_WIDTH-1:0] dat_m2s_dm;
    logic [`DATA_WIDTH-1:0] dat_s2m_dm;
    logic we_dm;
    logic [`SELECT_WIDTH-1:0] sel_dm;
    logic stb_dm;
    logic ack_dm;
    logic cyc_dm;
    logic err_dm;

    // dm mmu to arbit
    logic [`ADDR_WIDTH-1:0]   wbm_adr_dm;    // ADR_I() address input
    logic [`DATA_WIDTH-1:0]   wbm_dat_m2s_dm;    // DAT_I() data in
    logic [`DATA_WIDTH-1:0]   wbm_dat_s2m_dm;    // DAT_O() data out
    logic wbm_we_dm;     // WE_I write enable input
    logic [`SELECT_WIDTH-1:0] wbm_sel_dm;    // SEL_I() select input
    logic wbm_stb_dm;    // STB_I strobe input
    logic wbm_ack_dm;    // ACK_O acknowledge output
    logic wbm_cyc_dm;    // CYC_I cycle input

    // DM tlb related
    logic [`VPN_WIDTH-1:0] vpn_query_dm;
    logic [`PPN_WIDTH-1:0] ppn_query_dm;
    logic hit_query_dm;
    logic [`VPN_WIDTH-1:0] vpn_update_dm;
    logic [`PPN_WIDTH-1:0] ppn_update_dm;
    logic tlb_wen_dm;

    MEM_DM 
    instance_MEM_DM(
        .clk_i          (sys_clk          ),
        .rst_i          (sys_rst          ),

        .query_width_i    (MEM_query_width    ),
        .query_sign_ext_i (MEM_query_sign_ext ),
        .query_adr_i    (MEM_alu_result    ),
        .query_dat_i    (MEM_query_data_m2s    ),
        .query_wen_i    (MEM_query_wen    ),
        .query_ren_i    (MEM_query_ren    ),

        .BEFORE_MEM_exception_flag_i (BEFORE_MEM_exception_flag ),
        .BEFORE_MEM_exception_code_i (BEFORE_MEM_exception_code ),
        .BEFORE_MEM_exception_val_i  (BEFORE_MEM_exception_val  ),

        .mtime_i        (mtime      ),
        .mtimecmp_i     (mtimecmp   ),

        .query_ack_o    (MEM_dm_query_ack    ),
        .query_data_o   (MEM_query_data_s2m   ),

        .MEM_exception_flag_o        (MEM_exception_flag        ),
        .MEM_exception_code_o        (MEM_exception_code        ),
        .MEM_exception_val_o         (MEM_exception_val         ),

        .wbm_adr_o      (adr_dm      ),
        .wbm_dat_m2s_o  (dat_m2s_dm  ),
        .wbm_dat_s2m_i  (dat_s2m_dm  ),
        .wbm_we_o       (we_dm       ),
        .wbm_sel_o      (sel_dm      ),
        .wbm_stb_o      (stb_dm      ),
        .wbm_ack_i      (ack_dm      ),
        .wbm_cyc_o      (cyc_dm      ),

        .wbm_err_i      (err_dm      )
    );

    DM_MMU 
    instance_DM_MMU(
        .clk_i       (sys_clk       ),
        .rst_i       (sys_rst       ),

        .dm_addr_i   (adr_dm   ),
        .dm_data_i   (dat_m2s_dm   ),
        .dm_data_o   (dat_s2m_dm   ),
        .dm_we_i     (we_dm     ),
        .dm_sel_i    (sel_dm    ),
        .dm_stb_i    (stb_dm    ),
        .dm_ack_o    (ack_dm    ),
        .dm_cyc_i    (cyc_dm    ),
        .dm_err_o    (err_dm    ),

        .arb_addr_o  (wbm_adr_dm  ),
        .arb_data_o  (wbm_dat_m2s_dm  ),
        .arb_data_i  (wbm_dat_s2m_dm  ),
        .arb_we_o    (wbm_we_dm    ),
        .arb_sel_o   (wbm_sel_dm   ),
        .arb_stb_o   (wbm_stb_dm   ),
        .arb_ack_i   (wbm_ack_dm   ),
        .arb_cyc_o   (wbm_cyc_dm   ),

        .satp_i      (current_satp),
        .privilege_i (current_privilege),

        .vpn_query_o (vpn_query_dm),
        .ppn_query_i (ppn_query_dm),
        .hit_query_i (hit_query_dm),

        .vpn_update_o (vpn_update_dm),
        .ppn_update_o (ppn_update_dm),
        .tlb_wen_o (tlb_wen_dm)
    );
    
    TLB 
    DM_TLB(
        .clk_i        (sys_clk        ),
        .rst_i        (sys_rst        ),
        .vpn_query_i  (vpn_query_dm  ),
        .ppn_query_o  (ppn_query_dm  ),
        .hit_query_o  (hit_query_dm  ),
        .vpn_update_i (vpn_update_dm ),
        .ppn_update_i (ppn_update_dm ),
        .tlb_wen_i    (tlb_wen_dm    ),
        .sfence_i     (sfence_flag   )
    );
    

    MEM_EXCEPTION_PROCESSOR
    instance_MEM_EXCEPTION_PROCESSOR(
        .clk_i                        (sys_clk                    ),
        .rst_i                        (sys_rst                    ),

        .csr_op_i                     (MEM_csr_op                 ),
        .csr_reg_addr_i               (MEM_csr_addr               ),
        .rf_data_rs1                  (MEM_alu_result             ),
        .IF_im_query_ack_i            (IF_im_query_ack            ),
        .IF_pc_i                      (IF_pc                      ),

        .BEFORE_MEM_exception_flag_i  (BEFORE_MEM_exception_flag  ),
        .BEFORE_MEM_exception_code_i  (BEFORE_MEM_exception_code  ),
        .BEFORE_MEM_exception_val_i   (BEFORE_MEM_exception_val   ),

        .time_exceeded_i        (time_exceeded                    ),
        .interrupt_flag_i       (MEM_interrupt_flag               ),

        .MEM_pc_i                     (MEM_pc                     ),
        .MEM_dm_query_ack_i           (MEM_dm_query_ack           ),
        .MEM_query_wen_i              (MEM_query_wen              ),
        .MEM_query_ren_i              (MEM_query_ren              ),

        .MEM_exception_flag_i         (MEM_exception_flag         ),
        .MEM_exception_code_i         (MEM_exception_code         ),
        .MEM_exception_val_i          (MEM_exception_val          ),

        .catch_o                      (MEM_catch_from_excp_processor      ),
        .npc_from_exception_processor_o (MEM_npc_from_exception_processor ),
        .csr_data2rf_o                (MEM_orig_csr_data              ),
        .current_privilege_o          (current_privilege              ),

        .satp_o                       (current_satp                   )
    );
    


    MEM_MUX_MEM 
    instance_MEM_MUX_MEM(
        .alu_rst_i        (MEM_alu_result        ),
        .mem_data_i       (MEM_query_data_s2m       ),
        .csr_data_i       (MEM_orig_csr_data       ),
        .mux_mem_choice_i (MEM_mux_mem_choice ),

        .rf_wdata_o       (MEM_rf_wdata       )
    );


    IF_SATP_MUX 
    instance_IF_SATP_MUX(
        .ID_csr_op_i    (ID_csr_op    ),
        .ID_csr_addr_i  (ID_csr_addr  ),
        .ID_rs1_i       (ID_alu_oprand_a),
        .EXE_csr_op_i   (EXE_csr_op   ),
        .EXE_csr_addr_i (EXE_csr_addr ),
        .EXE_rs1_i      (EXE_alu_result),
        .MEM_csr_op_i   (MEM_csr_op   ),
        .MEM_csr_addr_i (MEM_csr_addr ),
        .MEM_rs1_i      (MEM_alu_result),
        .current_satp_i (current_satp ),
        .satp_o         (IF_satp         )
    );
    
    

    MEM_WB_REG 
    instance_MEM_WB_REG(
        .clk            (sys_clk            ),
        .rst            (sys_rst            ),

        .bubble_i       (bubble_MEM_WB_REG       ),

        .MEM_rf_waddr_i (MEM_rf_waddr ),
        .MEM_rf_wdata_i (MEM_rf_wdata ),
        .MEM_rf_wen_i   (MEM_rf_wen   ),
        .MEM_pc_i       (MEM_pc),

        .WB_rf_waddr_o  (WB_rf_waddr  ),
        .WB_rf_wdata_o  (WB_rf_wdata  ),
        .WB_rf_wen_o    (WB_rf_wen    ),
        .WB_pc_o        (WB_pc)
    );




    // these signals: arbit --> mux
    logic [`ADDR_WIDTH-1:0]   wbs_adr_o;     // ADR_O() address output
    logic [`DATA_WIDTH-1:0]   wbs_dat_i;     // DAT_I() data in
    logic [`DATA_WIDTH-1:0]   wbs_dat_o;     // DAT_O() data out
    logic wbs_we_o;      // WE_O write enable output
    logic [`SELECT_WIDTH-1:0] wbs_sel_o;     // SEL_O() select output
    logic wbs_stb_o;     // STB_O strobe output
    logic wbs_ack_i;     // ACK_I acknowledge input
    logic wbs_err_i;     // ERR_I error input
    logic wbs_rty_i;     // RTY_I retry input
    logic wbs_cyc_o;     // CYC_O cycle output

    wb_arbiter_2 arbiter_2
    (
        .clk(sys_clk),
        .rst(sys_rst),

        /*
        * Wishbone master 0 input, i.e DM input (priority: DM > IM)
        */
        .wbm0_adr_i(wbm_adr_dm),    // ADR_I() address input
        .wbm0_dat_i(wbm_dat_m2s_dm),    // DAT_I() data in
        .wbm0_dat_o(wbm_dat_s2m_dm),    // DAT_O() data out
        .wbm0_we_i(wbm_we_dm),     // WE_I write enable input
        .wbm0_sel_i(wbm_sel_dm),    // SEL_I() select input
        .wbm0_stb_i(wbm_stb_dm),    // STB_I strobe input
        .wbm0_ack_o(wbm_ack_dm),    // ACK_O acknowledge output
        .wbm0_err_o(),    // ERR_O error output
        .wbm0_rty_o(),    // RTY_O retry output
        .wbm0_cyc_i(wbm_cyc_dm),    // CYC_I cycle input

        /*
        * Wishbone master 1 input, i.e. IM input
        */
        .wbm1_adr_i(wbm_adr_im),    // ADR_I() address input
        .wbm1_dat_i(wbm_dat_m2s_im),    // DAT_I() data in
        .wbm1_dat_o(wbm_dat_s2m_im),    // DAT_O() data out
        .wbm1_we_i(wbm_we_im),     // WE_I write enable input
        .wbm1_sel_i(wbm_sel_im),    // SEL_I() select input
        .wbm1_stb_i(wbm_stb_im),    // STB_I strobe input
        .wbm1_ack_o(wbm_ack_im),    // ACK_O acknowledge output
        .wbm1_err_o(),    // ERR_O error output
        .wbm1_rty_o(),    // RTY_O retry output
        .wbm1_cyc_i(wbm_cyc_im),    // CYC_I cycle input

        /*
        * Wishbone slave output
        */
        .wbs_adr_o(wbs_adr_o),     // ADR_O() address output
        .wbs_dat_i(wbs_dat_i),     // DAT_I() data in
        .wbs_dat_o(wbs_dat_o),     // DAT_O() data out
        .wbs_we_o(wbs_we_o),      // WE_O write enable output
        .wbs_sel_o(wbs_sel_o),     // SEL_O() select output
        .wbs_stb_o(wbs_stb_o),     // STB_O strobe output
        .wbs_ack_i(wbs_ack_i),     // ACK_I acknowledge input
        .wbs_err_i(wbs_err_i),     // ERR_I error input
        .wbs_rty_i(wbs_rty_i),     // RTY_I retry input
        .wbs_cyc_o(wbs_cyc_o)      // CYC_O cycle output
    );







    /* =========== Lab6 MUX begin =========== */
    // Wishbone MUX (Masters) => bus slaves
    logic wbs0_cyc_o;
    logic wbs0_stb_o;
    logic wbs0_ack_i;
    logic [31:0] wbs0_adr_o;
    logic [31:0] wbs0_dat_o;
    logic [31:0] wbs0_dat_i;
    logic [3:0] wbs0_sel_o;
    logic wbs0_we_o;

    logic wbs1_cyc_o;
    logic wbs1_stb_o;
    logic wbs1_ack_i;
    logic [31:0] wbs1_adr_o;
    logic [31:0] wbs1_dat_o;
    logic [31:0] wbs1_dat_i;
    logic [3:0] wbs1_sel_o;
    logic wbs1_we_o;

    logic wbs2_cyc_o;
    logic wbs2_stb_o;
    logic wbs2_ack_i;
    logic [31:0] wbs2_adr_o;
    logic [31:0] wbs2_dat_o;
    logic [31:0] wbs2_dat_i;
    logic [3:0] wbs2_sel_o;
    logic wbs2_we_o;

    wb_mux_3 wb_mux (
        .clk(sys_clk),
        .rst(sys_rst),

        // Master interface (to arbiter)
        .wbm_adr_i(wbs_adr_o),
        .wbm_dat_i(wbs_dat_o),
        .wbm_dat_o(wbs_dat_i),
        .wbm_we_i (wbs_we_o),
        .wbm_sel_i(wbs_sel_o),
        .wbm_stb_i(wbs_stb_o),
        .wbm_ack_o(wbs_ack_i),
        .wbm_err_o(),
        .wbm_rty_o(),
        .wbm_cyc_i(wbs_cyc_o),

        // Slave interface 0 (to BaseRAM controller)
        // Address range: 0x8000_0000 ~ 0x803F_FFFF
        .wbs0_addr    (32'h8000_0000),
        .wbs0_addr_msk(32'hFFC0_0000),

        .wbs0_adr_o(wbs0_adr_o),
        .wbs0_dat_i(wbs0_dat_i),
        .wbs0_dat_o(wbs0_dat_o),
        .wbs0_we_o (wbs0_we_o),
        .wbs0_sel_o(wbs0_sel_o),
        .wbs0_stb_o(wbs0_stb_o),
        .wbs0_ack_i(wbs0_ack_i),
        .wbs0_err_i('0),
        .wbs0_rty_i('0),
        .wbs0_cyc_o(wbs0_cyc_o),

        // Slave interface 1 (to ExtRAM controller)
        // Address range: 0x8040_0000 ~ 0x807F_FFFF
        .wbs1_addr    (32'h8040_0000),
        .wbs1_addr_msk(32'hFFC0_0000),

        .wbs1_adr_o(wbs1_adr_o),
        .wbs1_dat_i(wbs1_dat_i),
        .wbs1_dat_o(wbs1_dat_o),
        .wbs1_we_o (wbs1_we_o),
        .wbs1_sel_o(wbs1_sel_o),
        .wbs1_stb_o(wbs1_stb_o),
        .wbs1_ack_i(wbs1_ack_i),
        .wbs1_err_i('0),
        .wbs1_rty_i('0),
        .wbs1_cyc_o(wbs1_cyc_o),

        // Slave interface 2 (to UART controller)
        // Address range: 0x1000_0000 ~ 0x1000_FFFF
        .wbs2_addr    (32'h1000_0000),
        .wbs2_addr_msk(32'hFFFF_0000),

        .wbs2_adr_o(wbs2_adr_o),
        .wbs2_dat_i(wbs2_dat_i),
        .wbs2_dat_o(wbs2_dat_o),
        .wbs2_we_o (wbs2_we_o),
        .wbs2_sel_o(wbs2_sel_o),
        .wbs2_stb_o(wbs2_stb_o),
        .wbs2_ack_i(wbs2_ack_i),
        .wbs2_err_i('0),
        .wbs2_rty_i('0),
        .wbs2_cyc_o(wbs2_cyc_o)
    );

    /* =========== Lab6 MUX end =========== */

    /* =========== Lab6 Slaves begin =========== */
    sram_controller #(
        .SRAM_ADDR_WIDTH(20),
        .SRAM_DATA_WIDTH(32)
    ) sram_controller_base (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i(wbs0_cyc_o),
        .wb_stb_i(wbs0_stb_o),
        .wb_ack_o(wbs0_ack_i),
        .wb_adr_i(wbs0_adr_o),
        .wb_dat_i(wbs0_dat_o),
        .wb_dat_o(wbs0_dat_i),
        .wb_sel_i(wbs0_sel_o),
        .wb_we_i (wbs0_we_o),

        // To SRAM chip
        .sram_addr(base_ram_addr),
        .sram_data(base_ram_data),
        .sram_ce_n(base_ram_ce_n),
        .sram_oe_n(base_ram_oe_n),
        .sram_we_n(base_ram_we_n),
        .sram_be_n(base_ram_be_n)
    );

    sram_controller #(
        .SRAM_ADDR_WIDTH(20),
        .SRAM_DATA_WIDTH(32)
    ) sram_controller_ext (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i(wbs1_cyc_o),
        .wb_stb_i(wbs1_stb_o),
        .wb_ack_o(wbs1_ack_i),
        .wb_adr_i(wbs1_adr_o),
        .wb_dat_i(wbs1_dat_o),
        .wb_dat_o(wbs1_dat_i),
        .wb_sel_i(wbs1_sel_o),
        .wb_we_i (wbs1_we_o),

        // To SRAM chip
        .sram_addr(ext_ram_addr),
        .sram_data(ext_ram_data),
        .sram_ce_n(ext_ram_ce_n),
        .sram_oe_n(ext_ram_oe_n),
        .sram_we_n(ext_ram_we_n),
        .sram_be_n(ext_ram_be_n)
    );

    // ���ڿ�����ģ��
    // NOTE: ����޸�ϵͳʱ��Ƶ�ʣ�Ҳ��Ҫ�޸Ĵ˴���ʱ��Ƶ�ʲ���
    uart_controller #(
        .CLK_FREQ(uart_controller_clk_freq),
        .BAUD    (115200)
    ) uart_controller (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        .wb_cyc_i(wbs2_cyc_o),
        .wb_stb_i(wbs2_stb_o),
        .wb_ack_o(wbs2_ack_i),
        .wb_adr_i(wbs2_adr_o),
        .wb_dat_i(wbs2_dat_o),
        .wb_dat_o(wbs2_dat_i),
        .wb_sel_i(wbs2_sel_o),
        .wb_we_i (wbs2_we_o),

        // to UART pins
        .uart_txd_o(txd),
        .uart_rxd_i(rxd)
    );

    /* =========== Lab6 Slaves end =========== */

    TIME_COMPARASION 
    instance_TIME_COMPARASION(
        .clk_i                       (sys_clk                       ),
        .rst_i                       (sys_rst                       ),

        .query_addr_i                (MEM_alu_result                ),
        .query_data_i                (MEM_query_data_m2s                ),
        .query_wen_i                 (MEM_query_wen                 ),
        .BEFORE_MEM_exception_flag_i (BEFORE_MEM_exception_flag ),

        .time_exceeded_o             (time_exceeded             ),
        .mtime_o                     (mtime                     ),
        .mtimecmp_o                  (mtimecmp                  )
    );
    

    CONTROLLER 
    instance_CONTROLLER(
        .catch_from_excp_processor_i (MEM_catch_from_excp_processor ),

        .IF_im_query_ack_i    (IF_im_query_ack    ),
        .IF_pc_wrong_i        (IF_pc_wrong        ),
        .ID_instr_type_i      (ID_instr_type      ),

        .ID_mux_a_choice_i    (ID_mux_a_choice    ),
        .ID_rf_addr_a_i       (ID_rf_addr_a       ),
        .ID_mux_b_choice_i    (ID_mux_b_choice    ),
        .ID_rf_addr_b_i       (ID_rf_addr_b       ),

        .EXE_rf_waddr_i       (EXE_rf_waddr       ),
        .EXE_rf_wen_i         (EXE_rf_wen         ),
        .EXE_csr_op_i         (EXE_csr_op         ),

        .MEM_rf_waddr_i       (MEM_rf_waddr       ),
        .MEM_rf_wen_i         (MEM_rf_wen         ),

        .WB_rf_waddr_i        (WB_rf_waddr        ),
        .WB_rf_wen_i          (WB_rf_wen          ),

        .MEM_query_ren_i      (MEM_query_ren      ),
        .MEM_query_wen_i      (MEM_query_wen      ),
        .MEM_dm_query_ack_i   (MEM_dm_query_ack   ),
        .BEFORE_MEM_exception_flag_i (BEFORE_MEM_exception_flag ),

        .bubble_PC_o          (bubble_PC          ),
        .stall_PC_o           (stall_PC           ),
        .stall_IM_o           (stall_IM           ),
        .bubble_IF_ID_REG_o   (bubble_IF_ID_REG   ),
        .stall_IF_ID_REG_o    (stall_IF_ID_REG    ),
        .bubble_ID_EXE_REG_o  (bubble_ID_EXE_REG  ),
        .stall_ID_EXE_REG_o   (stall_ID_EXE_REG   ),
        .bubble_EXE_MEM_REG_o (bubble_EXE_MEM_REG ),
        .stall_EXE_MEM_REG_o  (stall_EXE_MEM_REG  ),
        .bubble_MEM_WB_REG_o  (bubble_MEM_WB_REG  ),

        // for data bypass
        .EXE_query_ren_i      (EXE_query_ren      )
    );
    



endmodule
