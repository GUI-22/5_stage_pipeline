## PIPELINE 信号与模块说明文档

## 注意！！！：所有信号都是 XXX(大写表示阶段)_xxx(小写)，所有模块都是 XXX(大写表示阶段)_XXX(大写)


### thinpad.top顶层信号

##### clk & rst
- logic sys_clk：所有模块目前都用的这个clk！！！（sys_clk = clk_10M）
- logic sys_rst：所有模块目前都用的这个rst！！！（sys_rst = reset_of_clk10M）


##### CONTROLLER类，以下，stall==1的时候，clk跳变时对应模块保持不变，bubble==1的时候，clk跳变时对应模块为nop（nop的说明见文档后面“其他”）
- logic bubble_PC;
- logic stall_PC;
- logic stall_IM;
- logic bubble_IF_ID_REG;
- logic stall_IF_ID_REG;
- logic bubble_ID_EXE_REG;
- logic stall_ID_EXE_REG;
- logic bubble_EXE_MEM_REG;
- logic stall_EXE_MEM_REG;
- logic bubble_MEM_WB_REG;


##### 与slave（arbit）交互的信号（参见lab4）
- logic [`ADDR_WIDTH-1:0]   wbm_adr_im;    
- logic [`DATA_WIDTH-1:0]   wbm_dat_m2s_im;  数据，从master到slave  
- logic [`DATA_WIDTH-1:0]   wbm_dat_s2m_im;   数据，从slave到master 
- logic wbm_we_im;     
- logic [`SELECT_WIDTH-1:0] wbm_sel_im;    
- logic wbm_stb_im;    // STB_I strobe input
- logic wbm_ack_im;    // ACK_O acknowledge output
- logic wbm_cyc_im;    // CYC_I cycle input


##### IF阶段信号
- logic [`ADDR_WIDTH-1:0] IF_pc：IF阶段的pc，从IF_PC模块之间接出来
- logic [`INSTR_WIDTH-1:0] IF_instr：从IF_IM取出的instr
- logic IF_im_query_ack：IF_IM返回的ack，**注意：slave的ack在某周期返回，则下一周期ack才为1**
- logic [`ADDR_WIDTH-1:0] IF_npc_from_mux_pc
- logic IF_pc_wrong：由IF_MUX_PC输出


##### ID阶段信号
    logic [`ADDR_WIDTH-1:0] ID_npc_from_calculator：返回IF
    logic ID_need_branch：返回IF

    logic [`ADDR_WIDTH-1:0] ID_pc：可以用于观察和debug
    logic [`INSTR_WIDTH-1:0] ID_instr;

    logic [2:0] ID_instr_type：宏定义中，信号的种类
    logic [`DATA_WIDTH-1:0] ID_rf_addr_a;
    logic [`DATA_WIDTH-1:0] ID_rf_addr_b;
    logic [`DATA_WIDTH-1:0] ID_rf_data_a;
    logic [`DATA_WIDTH-1:0] ID_rf_data_b;
    logic [`DATA_WIDTH-1:0] ID_imm：之间生成的imm，没管imm_type
    logic ID_mux_a_choice; 宏定义，给到MUX_A
    logic ID_mux_b_choice; 宏定义，给MUX_B
    
    // to exe (alu)
    logic [`DATA_WIDTH-1:0] ID_alu_oprand_a; 由MUX_A输出
    logic [`DATA_WIDTH-1:0] ID_alu_oprand_b; 由MUX_B输出
    logic [`ALU_OPERATOR_WIDTH-1:0] ID_alu_op; alu的运算操作

    // to mem (dm & mux_dm)
    logic ID_query_wen; 即在MEM段时，对SRAM要写
    logic ID_query_ren; 在MEM段时，对SRAM要读
    logic [2:0] ID_query_width; 对MEM要读或者写的数据宽度
    logic ID_query_sign_ext; 符号扩展（用于lb之类的指令）
    logic ID_mux_mem_choice; 给MUX_MEM

    // to wb
    logic [`REG_NUM_WIDTH-1:0] ID_rf_waddr; 写寄存器的地址
    logic ID_rf_wen; 为1则要写寄存器

##### EXE阶段信号
- 新增
    logic [`DATA_WIDTH-1:0] EXE_alu_result;
- 以下参考ID阶段
    // to exe (alu)
    logic [`DATA_WIDTH-1:0] EXE_alu_oprand_a;
    logic [`DATA_WIDTH-1:0] EXE_alu_oprand_b;
    logic [`ALU_OPERATOR_WIDTH-1:0] EXE_alu_op;

    // to mem (dm & mux_dm)
    logic [`ADDR_WIDTH-1:0] EXE_pc;

    logic EXE_query_wen;
    logic EXE_query_ren;
    logic [2:0] EXE_query_width;
    logic EXE_query_sign_ext;
    logic [`DATA_WIDTH-1:0] EXE_query_data_m2s;
    logic EXE_mux_mem_choice;

    // to wb
    logic [`REG_NUM_WIDTH-1:0] EXE_rf_waddr;
    logic EXE_rf_wen;


##### MEM阶段信号
- 新增
    // MEM
    logic MEM_dm_query_ack; 指示当前DM是否取回数据，注意这个信号是在slave的ack来临后的紧接着的第一个上升沿才置为1，相比slave的ack要晚不到一个周期
    logic [`DATA_WIDTH-1:0] MEM_query_data_s2m; 数据，从slave到master
    logic [`DATA_WIDTH-1:0] MEM_rf_wdata; 数据，写回寄存器的data，从MUX_MEM输出
- 以下参考ID阶段
    // to mem (dm & mux_dm)
    logic [`ADDR_WIDTH-1:0] MEM_pc;

    logic [`DATA_WIDTH-1:0] MEM_alu_result;
    logic MEM_query_wen;
    logic MEM_query_ren;
    logic [2:0] MEM_query_width;
    logic MEM_query_sign_ext;
    logic [`DATA_WIDTH-1:0] MEM_query_data_m2s;
    logic MEM_mux_mem_choice;

    // to wb
    logic [`REG_NUM_WIDTH-1:0] MEM_rf_waddr;
    logic MEM_rf_wen;

##### WB阶段信号
    // to wb
    logic [`ADDR_WIDTH-1:0] WB_pc;

    logic [`REG_NUM_WIDTH-1:0] WB_rf_waddr;
    logic [`DATA_WIDTH-1:0] WB_rf_wdata;
    logic WB_rf_wen;


### thinpad.top例化的模块

#### CONTROLLER
1. 组合逻辑
2. 优先级：DM段冲突（即sram访问没结束）> 数据冲突（即指令src时上几条指令的dst）> pc_wrong需要跳转 > IM段冲突（instr没取出来）
3. TODO: 增加数据旁路后，有一些信号要修改

### IF
#### IF_PC

1. 信号
- clk 上沿触发
- rst 上沿触发
- stall_pc_i 为1时stall
- npc_i： 来自ID_NPC_CALCULATOR计算的npc
- pc_o：“正在IF_IM中取指”的PC
  
2. 逻辑
- rst时，pc_o置为程序的启动地址（默认32'h80000000）
- clk上沿，而且stall_pc==0, 则一定将npc->pc


#### IF_MUX_PC 

1. 信号
- input wire [ADDR_WIDTH-1:0] pc: IF_PC模块输出的pc，表示IF_IM正在取指的pc
- input wire[ADDR_WIDTH-1:0] npc_from_calculator_i：
- input wire need_branch_i：来自ID_NPC_CALCULATOR的信号，当为1的时候，表示需要跳转，也就需要比较当前pc和calculator计算的npc是否相同
- output logic[ADDR_WIDTH-1:0] npc_from_mux_pc_o：最终给到IF_PC的pc
- pc_wrong_o：当需要跳转，而且正在取指的“下一条指令”不对，那么该信号为1

2. 组合逻辑
- need_branch_i==1 && pc != npc_from_calculator_i，就输出npc_from_calculator_i作为下一次取指的pc，同时pc_wrong_o = 1
- 否则下一次取指就是pc+4，输出pc_wrong_o = 0

#### IF_IM

1. 信号
- input wire clk_i
- input wire rst_i,
- input wire stall_im_i：为1时则stall
- input wire [ADDR_WIDTH-1:0] query_adr_i：pc地址
- output logic query_ack_o：IF_IM模块作为master，这是master返回给顶层top文件的信号，CONTROLLER根据该信号进行各个模块的 stall 或 bubble 处理
- output logic [DATA_WIDTH-1:0] query_data_o：这是本模块作为master返回给top文件的“向slave请求得到的数据”（也即取得的instr）

- 以下信号是作为master，与slave交互的信号
- output logic [ADDR_WIDTH-1:0]   wbm_adr_o：请求数据的地址  
- output logic [DATA_WIDTH-1:0]   wbm_dat_m2s_o：数据，从master 到 slave   
- input wire [DATA_WIDTH-1:0]   wbm_dat_s2m_i：数据，从slave到master  
- output logic wbm_we_o,     
- output logic [`SELECT_WIDTH-1:0] wbm_sel_o,    
- output logic wbm_stb_o,    
- input wire wbm_ack_i：从slave返回的ack
- output logic wbm_cyc_o

2. 时序逻辑
- 一共3个状态：ST_IDLE ST_READ_ACTION ST_DONE
- IDLE的下一个周期一定进入READ_ACTION
- READ_ACTION收到slave_ack==1，下个周期才会进入DONE
- DONE中，如果stall==1，则仍然为DONE，否则下个周期进入IDLE

#### IF_ID_REG
1. 时序逻辑
- rst时，置nop
- stall时不变
- bubble时，置nop
- 否则才更新
（优先级rst > stall > bubble > 更新）

### ID

##### ID_DECODER
1. 组合逻辑
2. 信号见“顶层文件信号”的说明

##### ID_NPC_CALCULATOR
1. 根据instr_type判断，若为跳转指令，则根据指令判断是否需要跳转，并计算出跳转后的地址npc_from_calculator_o，且输出need_branch_o = 1
2. 若不是跳转指令或者不需要跳转，则npc_from_calculator_o为pc+4 (该pc+4是ID_PC+4，正常情况和该时刻的IF_PC一样)，且need_branch_o = 0

##### ID_RF
1. 目前写入了一个特殊判断（判断WB和ID的数据冲突），不过应该用不上
```
if (rf_addr_a_i == rf_waddr_i && rf_wen_i && rf_waddr_i != 0) begin
    rf_data_a_o = rf_wdata_i;
end else begin
    rf_data_a_o = regs[rf_addr_a_i];
end

if (rf_addr_b_i == rf_waddr_i && rf_wen_i && rf_waddr_i != 0) begin
    rf_data_a_o = rf_wdata_i;
end else begin
    rf_data_b_o = regs[rf_addr_b_i];
end
```

### EXE
##### EXE_ALU
1. 组合逻辑


### MEM
##### MEM_DM
1. 信号
    input wire clk_i,
    input wire rst_i,

    input wire [2:0] query_width_i,
    input wire query_sign_ext_i,
    input wire [ADDR_WIDTH-1:0] query_adr_i, 访问的地址
    input wire [DATA_WIDTH-1:0] query_dat_i, top给DM的数据
    input wire query_wen_i,
    input wire query_ren_i,
    
    output logic query_ack_o,
    output logic [DATA_WIDTH-1:0] query_data_o,

    output logic [ADDR_WIDTH-1:0]   wbm_adr_o,    
    output logic [DATA_WIDTH-1:0]   wbm_dat_m2s_o,    
    input wire [DATA_WIDTH-1:0]   wbm_dat_s2m_i,    
    output logic wbm_we_o,     
    output logic [`SELECT_WIDTH-1:0] wbm_sel_o,    
    output logic wbm_stb_o,    
    input wire wbm_ack_i,    
    output logic wbm_cyc_o



### 其他
1. 宏定义：lab6\macros.svh中，需要新的宏定义时请在其中添加，或者不同模块的宏定义新建.svh文件
2. 插件：推荐VSCode搭配Verilog-HDL/SystemVerilog/Bluespec SystemVerilog插件，方便宏定义、信号的代码跳转
3. nop：目前nop的PC为 PC_NOP_ADDR==32'h80000000，debug时可以观察各阶段PC，若显示80000000大概率表明该阶段处于nop