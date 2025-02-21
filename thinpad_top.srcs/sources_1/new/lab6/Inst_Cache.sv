/*
    Implementation of the instruction cache module
*/

`include "./cache_macros.svh"

module INST_CACHE #(
    parameter ADDR_WIDTH = 32,
    parameter SEL_WIDTH = $clog2(ADDR_WIDTH),
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,

    // inputs from IF_IM
    input wire [ADDR_WIDTH-1:0] wbm_adr_i,
    input wire wbm_stb_i,
    input wire wbm_cyc_i,
    input wire wbm_we_i,
    input wire [SEL_WIDTH-1:0] wbm_sel_i,
    input wire [DATA_WIDTH-1:0] wbm_dat_i,

    // outputs to IF_IM
    output wire wbm_ack_o,
    output wire wbm_err_o,
    output wire [DATA_WIDTH-1:0] wbm_dat_o,

    // inputs from IF_MMU
    input wire mmu_ack_i,
    input wire mmu_err_i,
    input wire [DATA_WIDTH-1:0] mmu_dat_i,

    // outputs to IF_MMU
    output wire mmu_stb_o,
    output wire mmu_cyc_o,
    output wire [ADDR_WIDTH-1:0] mmu_adr_o,
    output wire mmu_we_o,
    output wire [SEL_WIDTH-1:0] mmu_sel_o,
    output wire [DATA_WIDTH-1:0] mmu_dat_o
);

    // Cache way def
    typedef struct {
        inst_cache_entry_t entries[`CACHE_WAY_SIZE-1:0];
    } cache_way_t;

    // Cache def
    typedef struct {
        cache_way_t ways[`CACHE_WAYS-1:0];
        logic [`INDEX_WIDTH-1:0] last_indices[`CACHE_WAYS-1:0]; // least recently used index
        logic use_ens[`CACHE_WAYS-1:0];
        logic [`INDEX_WIDTH-1:0] use_indices[`CACHE_WAYS-1:0]; // index to be used
    } inst_cache_t;

    // Cache instance
    inst_cache_t inst_cache;

    // queue instances
    generate
        genvar i;
        for (i = 0; i < `CACHE_WAYS; i = i + 1) begin : queue_array
            queue #(`CACHE_WAY_SIZE) queue_inst (
                .clk(clk),
                .rst(rst),
                .use_en(inst_cache.use_ens[i]),
                .in_data(inst_cache.use_indices[i]),
                .last(inst_cache.last_indices[i])
            );
        end
    endgenerate

    // query indices
    logic [`TAG_WIDTH-1:0] query_tag;
    logic [`WAY_SEL_WIDTH-1:0] way_sel;

    assign query_tag = wbm_adr_i[ADDR_WIDTH-1:2+`WAY_SEL_WIDTH];
    assign way_sel = wbm_adr_i[1+`WAY_SEL_WIDTH:2];

    // query cache
    logic hit;
    logic [`INDEX_WIDTH-1:0] hit_index;
    logic [`DATA_WIDTH-1:0] hit_data;

    always_comb begin
        hit = 0;
        hit_index = inst_cache.last_indices[way_sel]; //TODO: maybe use it to update the LRU
        hit_data = 0;

        for (int i = 0; i < `CACHE_WAY_SIZE; i++) begin
            if (
                // if find the same tag and valid
                inst_cache.ways[way_sel].entries[i].tag == query_tag && inst_cache.ways[way_sel].entries[i].valid
                ) begin
                hit = 1;
                hit_index = i;
                hit_data = inst_cache.ways[way_sel].entries[i].data;
                break;
            end
        end
    end

    // fence.i logic
    wire is_fence_i;
    assign is_fence_i = wbm_dat_o[6:0] == 7'b0001111; // if opcode is 7'b0001111 then it is fence.i

    typedef enum logic [1:0] { 
        STATE_IDLE,
        STATE_HIT,
        STATE_MISS
    } state_t;
    state_t state, next_state;

    // transition logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        if (rst) begin
            // if reset then go to idle
            next_state = STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (hit && wbm_stb_i) begin
                        // if hit and wbm_stb_i then go to hit
                        next_state = STATE_HIT;
                    end else if (!hit && wbm_stb_i) begin
                        // if miss and wbm_stb_i then go to miss
                        next_state = STATE_MISS;
                    end else begin
                        // otherwise stay in idle
                        next_state = STATE_IDLE;
                    end
                end
                STATE_HIT: begin
                    next_state = STATE_IDLE; // if hit then go to idle
                end
                STATE_MISS: begin
                    if (mmu_ack_i) begin
                        // if mmu_ack_i then go to hit
                        next_state = STATE_HIT;
                    end else begin
                        // otherwise stay in miss
                        next_state = STATE_MISS;
                    end
                end
                default: begin
                    next_state = STATE_IDLE; // if cannot decide then go to idle
                end
            endcase
        end
    end

    // regs for im output
    reg [DATA_WIDTH-1:0] im_data_o_reg;
    reg im_ack_o_reg;
    reg im_err_o_reg;

    // im output
    assign wbm_ack_o = im_ack_o_reg;
    assign wbm_err_o = im_err_o_reg;
    assign wbm_dat_o = im_data_o_reg;

    // regs for mmu output
    reg [DATA_WIDTH-1:0] mmu_dat_o_reg;
    reg mmu_stb_o_reg;
    reg mmu_cyc_o_reg;
    reg [ADDR_WIDTH-1:0] mmu_adr_o_reg;
    reg mmu_we_o_reg;
    reg [SEL_WIDTH-1:0] mmu_sel_o_reg;

    // mmu output
    assign mmu_dat_o = mmu_dat_o_reg;
    assign mmu_stb_o = mmu_stb_o_reg;
    assign mmu_cyc_o = mmu_cyc_o_reg;
    assign mmu_adr_o = mmu_adr_o_reg;
    assign mmu_we_o = mmu_we_o_reg;
    assign mmu_sel_o = mmu_sel_o_reg;

    // state actions
    always_ff @(posedge clk) begin
        if (rst) begin
            // if reset then reset the cache
            for (int i = 0; i < `CACHE_WAYS; i++) begin
                // reset cache ways
                for (int j = 0; j < `CACHE_WAY_SIZE; j++) begin
                    inst_cache.ways[i].entries[j].valid <= 0;
                    inst_cache.ways[i].entries[j].tag <= 0;
                    inst_cache.ways[i].entries[j].data <= 0;
                end
                inst_cache.use_ens[i] <= 0;
                inst_cache.use_indices[i] <= 0;
            end
            // reset im output
            im_data_o_reg <= 0;
            im_ack_o_reg <= 0;
            im_err_o_reg <= 0;
            // reset mmu output
            mmu_dat_o_reg <= 0;
            mmu_stb_o_reg <= 0;
            mmu_cyc_o_reg <= 0;
            mmu_adr_o_reg <= 0;
            mmu_we_o_reg <= 0;
            mmu_sel_o_reg <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    case (next_state)
                        STATE_IDLE: begin
                            // set im output to 0
                            im_data_o_reg <= 0;
                            im_ack_o_reg <= 0;
                            im_err_o_reg <= 0;
                            // set mmu output to 0
                            mmu_dat_o_reg <= 0;
                            mmu_stb_o_reg <= 0;
                            mmu_cyc_o_reg <= 0;
                            mmu_adr_o_reg <= 0;
                            mmu_we_o_reg <= 0;
                            mmu_sel_o_reg <= 0;
                        end
                        STATE_MISS: begin
                            // set mmu output to query
                            mmu_dat_o_reg <= 0;
                            mmu_stb_o_reg <= 1;
                            mmu_cyc_o_reg <= 1;
                            mmu_adr_o_reg <= wbm_adr_i;
                            mmu_we_o_reg <= 0;
                            mmu_sel_o_reg <= wbm_sel_i;
                        end
                        STATE_HIT: begin
                            // set mmu output to 0
                            mmu_dat_o_reg <= 0;
                            mmu_stb_o_reg <= 0;
                            mmu_cyc_o_reg <= 0;
                            mmu_adr_o_reg <= 0;
                            mmu_we_o_reg <= 0;
                            mmu_sel_o_reg <= 0;

                            // set im output to hit data
                            im_data_o_reg <= hit_data;
                            im_ack_o_reg <= 1;
                            im_err_o_reg <= 0;

                            // if hit then update the LRU
                            inst_cache.use_ens[way_sel] <= 1;
                            inst_cache.use_indices[way_sel] <= hit_index;
                        end
                        default: begin
                            // if cannot decide then do nothing
                        end
                    endcase
                end
                STATE_HIT: begin
                    // set mmu output to 0
                    mmu_dat_o_reg <= 0;
                    mmu_stb_o_reg <= 0;
                    mmu_cyc_o_reg <= 0;
                    mmu_adr_o_reg <= 0;
                    mmu_we_o_reg <= 0;
                    mmu_sel_o_reg <= 0;

                    // set im output to 0
                    im_ack_o_reg <= 0;
                    im_err_o_reg <= 0;

                    // set all use_ens to 0
                    for (int i = 0; i < `CACHE_WAYS; i++) begin
                        inst_cache.use_ens[i] <= 0;
                    end

                    // if the inst is fence.i set all valid to 0
                    if (is_fence_i) begin
                        for (int i = 0; i < `CACHE_WAYS; i++) begin
                            for (int j = 0; j < `CACHE_WAY_SIZE; j++) begin
                                inst_cache.ways[i].entries[j].valid <= 0;
                            end
                        end
                    end
                end
                STATE_MISS: begin
                    case (next_state)
                        STATE_MISS: begin
                            // set mmu output to query
                            mmu_dat_o_reg <= 0;
                            mmu_stb_o_reg <= 1;
                            mmu_cyc_o_reg <= 1;
                            mmu_adr_o_reg <= wbm_adr_i;
                            mmu_we_o_reg <= 0;
                            mmu_sel_o_reg <= wbm_sel_i;

                            // set im output to 0
                            im_data_o_reg <= 0;
                            im_ack_o_reg <= 0;
                            im_err_o_reg <= 0;
                        end
                        STATE_HIT: begin
                            // set mmu output to 0
                            mmu_dat_o_reg <= 0;
                            mmu_stb_o_reg <= 0;
                            mmu_cyc_o_reg <= 0;
                            mmu_adr_o_reg <= 0;
                            mmu_we_o_reg <= 0;
                            mmu_sel_o_reg <= 0;
                           if (mmu_err_i) begin
                                // do nothing but faithfully pass the error
                                im_ack_o_reg <= 1;
                                im_err_o_reg <= 1;
                                im_data_o_reg <= 0;
                            end else begin
                                // write to cache
                                inst_cache.ways[way_sel].entries[hit_index].valid <= 1;
                                inst_cache.ways[way_sel].entries[hit_index].tag <= query_tag;
                                inst_cache.ways[way_sel].entries[hit_index].data <= mmu_dat_i;

                                // set im output to hit data
                                im_data_o_reg <= mmu_dat_i;
                                im_ack_o_reg <= 1;
                                im_err_o_reg <= 0;

                                // if hit then update the LRU
                                inst_cache.use_ens[way_sel] <= 1;
                                // we use the last index !!!
                                inst_cache.use_indices[way_sel] <= inst_cache.last_indices[way_sel];
                            end
                        end
                    default: begin
                        // if cannot decide then do nothing
                    end
                    endcase
                end
                default: begin
                    // if cannot decide then do nothing
                end
            endcase
        end
    end

endmodule