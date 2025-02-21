// cache settings
`define CACHE_WAYS 8
`define CACHE_WAY_SIZE 16
`define WAY_SEL_WIDTH $clog2(`CACHE_WAYS)
`define INDEX_WIDTH $clog2(`CACHE_WAY_SIZE)

// inst cache macros
`define TAG_WIDTH 30
`define DATA_WIDTH 32
`define VALID_WIDTH 1
`define DIRTY_WIDTH 1

// inst cache entry fields
`define CACHE_ENTRY_FIELDS \
    logic [`TAG_WIDTH-`WAY_SEL_WIDTH-1:0] tag; \
    logic [`DATA_WIDTH-1:0] data; \
    logic [`VALID_WIDTH-1:0] valid;
    //logic [`DIRTY_WIDTH-1:0] dirty;

typedef struct {
    `CACHE_ENTRY_FIELDS
} inst_cache_entry_t;