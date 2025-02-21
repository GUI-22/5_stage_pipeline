`include "./common_macros.svh"
`include "./exception_macros.svh"


module MEM_EXCEPTION_PROCESSOR #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk_i,
    input wire rst_i,

    input wire [`CSR_OP_WIDTH-1:0] csr_op_i,
    input wire [`CSR_ADDR_WIDTH-1:0] csr_reg_addr_i,
    input wire [`DATA_WIDTH-1:0] rf_data_rs1,

    input wire IF_im_query_ack_i,
    input wire [`ADDR_WIDTH-1:0] IF_pc_i,

    input wire BEFORE_MEM_exception_flag_i,
    input wire [`EXCP_CODE_WIDTH-1:0] BEFORE_MEM_exception_code_i,
    input wire [`MXLEN-1:0] BEFORE_MEM_exception_val_i,

    input wire time_exceeded_i,
    input wire interrupt_flag_i,

    // from MEM
    input wire [`ADDR_WIDTH-1:0] MEM_pc_i,
    input wire MEM_dm_query_ack_i,
    input wire MEM_query_wen_i,
    input wire MEM_query_ren_i,
    input wire MEM_exception_flag_i,
    input wire [`EXCP_CODE_WIDTH-1:0] MEM_exception_code_i,
    input wire [`MXLEN-1:0] MEM_exception_val_i,
    
    
    output logic catch_o,
    output logic [`ADDR_WIDTH-1:0] npc_from_exception_processor_o,

    output logic [`MXLEN-1:0] csr_data2rf_o,
    output logic [`PRIVILEGE_WIDTH-1:0] current_privilege_o,

    // To MMU

    output satp_t satp_o
);

    // csr regs
    // EXCEPTION CSR
    tvec_t mtvec;
    scratch_t mscratch;
    epc_t mepc;
    cause_t mcause;
    status_t mstatus;
    tval_t mtval;
    ie_t mie;
    ip_t mip;
    satp_t satp;

    logic mtvec_wen;
    logic mscratch_wen;
    logic mepc_wen;
    logic mcause_wen;
    logic mstatus_wen;
    logic mtval_wen;
    logic mie_wen;
    logic mip_wen;
    logic satp_wen;

    tvec_t mtvec_wdata;
    scratch_t mscratch_wdata;
    epc_t mepc_wdata;
    cause_t mcause_wdata;
    status_t mstatus_wdata;
    tval_t mtval_wdata;
    ie_t mie_wdata;
    ip_t mip_wdata;
    satp_t satp_wdata;

    // current_privilege
    logic [`PRIVILEGE_WIDTH-1:0] current_privilege;
    logic current_privilege_wen;
    logic [`PRIVILEGE_WIDTH-1:0] current_privilege_wdata;
    always_comb begin
        current_privilege_o = current_privilege;
    end

    // satp output
    assign satp_o = satp;

    // state
    typedef enum logic {
        ST_NORMAL,
        ST_CATCH
    } state_t;
    state_t state;

    // catch_flag: excp or mret or interrupt
    logic catch_flag;
    always_comb begin
        catch_flag = 
        BEFORE_MEM_exception_flag_i 
        ||
        ( 
            MEM_exception_flag_i &&
            MEM_dm_query_ack_i &&
            (MEM_query_ren_i || MEM_query_wen_i)
        ) 
        ||
        csr_op_i == `CSR_OP_MRET 
        || 
        (
            mstatus.mie &&
            mie.mtie &&
            mip.mtip &&
            interrupt_flag_i &&
            (csr_op_i != `CSR_OP_CSRRC && csr_op_i != `CSR_OP_CSRRW && csr_op_i != `CSR_OP_CSRRS)
        );
    end

    // record npc_from_exception_processor_o
    logic [`ADDR_WIDTH-1:0] npc_from_exception_processor_o_last_cycle;
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            // reset
            npc_from_exception_processor_o_last_cycle <= 0;  
        end else begin
            npc_from_exception_processor_o_last_cycle <= npc_from_exception_processor_o;
        end
    end

    logic already_get_excp_required_instr;
    always_comb begin
        already_get_excp_required_instr = 
        IF_im_query_ack_i && (IF_pc_i == npc_from_exception_processor_o_last_cycle);
    end

    // csr_calc_rst
    logic [`MXLEN-1:0] orig_csr_data;
    logic [`MXLEN-1:0] csr_calc_rst;
    always_comb begin 
        case(csr_op_i)
            `CSR_OP_CSRRC: begin
                csr_calc_rst = orig_csr_data & (~rf_data_rs1);
            end
            `CSR_OP_CSRRS: begin
                csr_calc_rst = orig_csr_data | rf_data_rs1;
            end
            `CSR_OP_CSRRW: begin
                csr_calc_rst = rf_data_rs1;
            end
            default: begin
                // do nothing
                csr_calc_rst = 0;
            end
        endcase        
    end

    // state transfer
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            // reset
            state <= ST_NORMAL;
        end else begin
            if (state == ST_NORMAL) begin
                if (catch_flag) begin
                    state <= ST_CATCH;
                end
                else begin
                    state <= ST_NORMAL;
                end
            end
            else begin // state == ST_CATCH
                if (already_get_excp_required_instr) begin
                    state <= ST_NORMAL;
                end
                else begin
                    state <= ST_CATCH;
                end
            end
        end
    end


    // main logic
    always_comb begin 
        mtvec_wen = 0;
        mscratch_wen = 0;
        mepc_wen = 0;
        mcause_wen = 0;
        mstatus_wen = 0;
        mtval_wen = 0;
        mie_wen = 0;
        mip_wen = 0;
        satp_wen = 0;
        current_privilege_wen = 0;

        csr_data2rf_o = 0;
        orig_csr_data = 0;
        npc_from_exception_processor_o = 0;

        mtvec_wdata = 0;
        mscratch_wdata = 0;
        mepc_wdata = 0;
        mcause_wdata = 0;
        mstatus_wdata = 0;
        mtval_wdata = 0;
        mie_wdata = 0;
        mip_wdata = 0;
        satp_wdata = 0;
        current_privilege_wdata = `MODE_M;

        if (state == ST_NORMAL) begin
            if (catch_flag == 0) begin
                catch_o = 0;
                if (csr_op_i == `CSR_OP_CSRRC || csr_op_i == `CSR_OP_CSRRS || csr_op_i == `CSR_OP_CSRRW) begin
                    // no exception
                    case (csr_reg_addr_i) 
                        `CSR_ADDR_MTVEC: begin
                            mtvec_wen = 1;
                            csr_data2rf_o = mtvec;
                            orig_csr_data = mtvec;
                            mtvec_wdata = csr_calc_rst;
                        end
                        `CSR_ADDR_MSCRATCH: begin
                            mscratch_wen = 1;
                            csr_data2rf_o = mscratch;
                            orig_csr_data = mscratch;
                            mscratch_wdata = csr_calc_rst;
                        end
                        `CSR_ADDR_MEPC: begin
                            mepc_wen = 1;
                            csr_data2rf_o = mepc;
                            orig_csr_data = mepc;
                            mepc_wdata = csr_calc_rst;
                        end
                        `CSR_ADDR_MCAUSE: begin
                            mcause_wen = 1;
                            csr_data2rf_o = mcause;
                            orig_csr_data = mcause;
                            mcause_wdata = csr_calc_rst;
                        end
                        `CSR_ADDR_MSTATUS: begin
                            mstatus_wen = 1;
                            csr_data2rf_o = mstatus;
                            orig_csr_data = mstatus;
                            mstatus_wdata = csr_calc_rst;
                        end
                        `CSR_ADDR_MIE: begin
                            mie_wen = 1;
                            csr_data2rf_o = mie;
                            orig_csr_data = mie;
                            mie_wdata = csr_calc_rst;
                        end
                        `CSR_ADDR_MIP: begin
                            mip_wen = 1;
                            csr_data2rf_o = mip;
                            orig_csr_data = mip;
                            mip_wdata = csr_calc_rst;
                        end
                        `CSR_ADDR_MTVAL: begin
                            mtval_wen = 1;
                            csr_data2rf_o = mtval;
                            orig_csr_data = mtval;
                            mtval_wdata = csr_calc_rst;
                        end
                        `CSR_ADDR_SATP: begin
                            satp_wen = 1;
                            csr_data2rf_o = satp;
                            orig_csr_data = satp;
                            satp_wdata = csr_calc_rst;
                        end
                        default: begin
                            // do nothing
                        end
                    endcase
                end
                else begin
                    // NO_CSR_OP
                end
            end
            else begin // catch_flag == 1, and excp > mret > inter
                catch_o = 1;
                if (BEFORE_MEM_exception_flag_i || MEM_exception_flag_i) begin
                    // npc
                    npc_from_exception_processor_o = mtvec;
                    // mepc
                    mepc_wdata = MEM_pc_i;
                    mepc_wen = 1;
                    // mstatus
                    mstatus_wdata = {
                        mstatus[31:13],
                        current_privilege, // mpp
                        mstatus[10:8],
                        mstatus.mie,     // mpie
                        mstatus[6:4],
                        1'b0,            // mie
                        mstatus[2:0]
                    };
                    mstatus_wen = 1;
                    // mcause & mtval
                    if (BEFORE_MEM_exception_flag_i) begin
                        mcause_wdata = {
                            1'b0, // is an exception
                            {27{1'b0}}, // [30:4]
                            (BEFORE_MEM_exception_code_i == `EXCP_ECALL && current_privilege == `MODE_U) ? `EXCP_ECALL_U :
                            (BEFORE_MEM_exception_code_i == `EXCP_ECALL && current_privilege == `MODE_S) ? `EXCP_ECALL_S :
                            (BEFORE_MEM_exception_code_i == `EXCP_ECALL && current_privilege == `MODE_M) ? `EXCP_ECALL_M :
                            BEFORE_MEM_exception_code_i 
                        };
                        mtval_wdata = BEFORE_MEM_exception_val_i;
                    end
                    else begin // excp genereted from MEM
                        mcause_wdata = {
                            1'b0, // is an exception
                            {27{1'b0}}, // [30:4]
                            MEM_exception_code_i
                        };
                        mtval_wdata = MEM_exception_val_i;
                    end 
                    mcause_wen = 1;
                    mtval_wen = 1;
                    // privilege_mode
                    current_privilege_wdata = `MODE_M;
                    current_privilege_wen = 1;
                end
                else if (csr_op_i == `CSR_OP_MRET) begin
                    // npc
                    npc_from_exception_processor_o = mepc;
                    // mstatus
                    mstatus_wdata = {
                        mstatus[31:13],
                        `MODE_U, // mpp
                        mstatus[10:8],
                        1'b1,     // mpie
                        mstatus[6:4],
                        mstatus.mpie,            // mie
                        mstatus[2:0]
                    };
                    mstatus_wen = 1;
                    // privilege_mode
                    current_privilege_wdata = mstatus[12:11];  // mpp
                    current_privilege_wen = 1;
                end
                else begin // interrupt
                    // npc
                    npc_from_exception_processor_o = mtvec;
                    // mepc
                    mepc_wdata = MEM_pc_i;
                    mepc_wen = 1;
                    // mstatus
                    mstatus_wdata = {
                        mstatus[31:13],
                        current_privilege, // mpp
                        mstatus[10:8],
                        mstatus.mie,     // mpie
                        mstatus[6:4],
                        1'b0,            // mie
                        mstatus[2:0]
                    };
                    mstatus_wen = 1;
                    // mcause 
                    mcause_wdata = {
                        1'b1, // is an interrupt
                        {27{1'b0}}, // [30:4]
                        `INTER_M_TIMER
                    };
                    mcause_wen = 1;
                    // privilege_mode
                    current_privilege_wdata = `MODE_M;
                    current_privilege_wen = 1;
                end
            end
        end

        else begin // state == ST_CATCH
            if (already_get_excp_required_instr == 1) begin
                catch_o = 0;
                npc_from_exception_processor_o = 0;
            end 

            else begin // already_get_excp_required_instr == 0
                catch_o = 1;
                npc_from_exception_processor_o = npc_from_exception_processor_o_last_cycle;
            end
        end
        
    end


    // rf for csr regs
    always_ff @(posedge clk_i or posedge rst_i) begin

        if (rst_i) begin
            // reset
            mtvec <= 0;
            mscratch <= 0;
            mepc <= 0;
            mcause <= 0;
            mstatus <= 
            {
                {19{1'b0}},
                `MODE_U, // mpp
                {3{1'b0}},
                1'b1,     // mpie
                {3{1'b0}},
                1'b0,            // mie
                {3{1'b0}}
            };
            mtval <= 0;
            mie <= 0;
            mip <= 0;
            satp <= 0;
            current_privilege <= `MODE_M;
            
        end else begin
            if (mtvec_wen == 1) begin
                mtvec <= mtvec_wdata;
            end
            if (mscratch_wen == 1) begin
                mscratch <= mscratch_wdata;
            end
            if (mepc_wen == 1) begin
                mepc <= mepc_wdata;
            end
            if (mcause_wen == 1) begin
                mcause <= mcause_wdata;
            end
            if (mstatus_wen == 1) begin
                mstatus <= mstatus_wdata;
            end
            if (mtval_wen == 1) begin
                mtval <= mtval_wdata;
            end
            if (mie_wen == 1) begin
                mie <= mie_wdata;
            end
            if (satp_wen == 1) begin
                satp <= satp_wdata;
            end

            if (mip_wen == 1) begin
                mip <= mip_wdata;
            end
            else if (time_exceeded_i == 1) begin
                mip.mtip <= 1'b1;
            end
            else begin
                mip.mtip <= 1'b0;
            end

            if (current_privilege_wen == 1) begin
                current_privilege <= current_privilege_wdata;
            end

        end

    end


endmodule