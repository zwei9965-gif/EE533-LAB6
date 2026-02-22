// ============================================================
// arm_pipeline.v  ?  5-Stage ARM Pipeline  (Step 3c)
// EE 533 Lab 6  Team 4
//
// Step 3c ???CPSR / CMP / ???? + flush
//
// ?????
//   MOV Rd, #imm          (3a)
//   ADD Rd, Rn, #imm      (3a)
//   SUB Rd, Rn, #imm      (3a)
//   LDR Rd, [Rn, #off]   (3b)
//   STR Rd, [Rn, #off]   (3b)
//   CMP Rn, #imm          (3c) ? SUB + ??CPSR, ??Rd
//   B / BGT / BGE / BLT / BLE / BEQ / BNE  (3c)
//
// Branch flush ???
//   ??? EX ????????
//   ?? IF/ID ???? 2 ?????
//   ? ? IF/ID ? ID/EX ??????????? NOP
//   ? ???? PC = ????
//
// CPSR ?????
//   CMP/SUB-S ? EX ?????EX/MEM ??????? CPSR
//   ? ??? EX ??? CPSR??????? CMP ?????
//   ? ?? CMP ? BXX ??????? NOP?????????
//     ???? CMP ??????? CPSR???? CMP ? EX ??
//     CMP ? addr k ? EX ?? k+3 ??
//     BGT ? addr k+4 ? EX ?? k+7 ??  ?
//     ?? CMP ? 3 ? NOP + BGT ????
//
// Verilog-2001, ISE 10.1 compatible.
// ============================================================
`timescale 1ns / 1ps

module arm_pipeline (
    input wire clk,
    input wire rst
);

    // =========================================================
    // Rotated immediate decode
    // =========================================================
    function [31:0] rot_imm;
        input [7:0]  imm8;
        input [3:0]  rot;
        reg   [31:0] tmp;
        integer      amt;
        begin
            tmp = {24'b0, imm8};
            amt = rot * 2;
            if (amt == 0)
                rot_imm = tmp;
            else
                rot_imm = (tmp >> amt) | (tmp << (32 - amt));
        end
    endfunction

    // =========================================================
    // CPSR ? ??????? N/Z/C/V
    // ? EX/MEM ??????set_flags=1 ??
    // =========================================================
    reg cpsr_N, cpsr_Z, cpsr_C, cpsr_V;

    // =========================================================
    // Stage 1: IF ? Instruction Fetch
    // =========================================================

    reg  [8:0]  pc;
    wire [31:0] if_instr;

    // branch_taken ? branch_target ?? EX ????????
    wire        branch_taken;
    wire [8:0]  branch_target_pc;

    // imem ???????addr ? posedge ???dout ??????
    // ????? addr=X ? ?? dout=mem[X] ? ????? ifid_instr
    //
    // branch_taken ???
    //   ???branch_taken=1, pc ??? target, imem addr=target
    //   ???dout=mem[target], IF/ID ? flush ? NOP
    //   ????ifid_instr=mem[target], ID/EX ? flush ? NOP
    //   ???2? NOP bubble + target ????????? ?
    always @(posedge clk) begin
        if (rst)
            pc <= 9'b0;
        else if (branch_taken)
            pc <= branch_target_pc;   // ??imem????target???pc=target????
        else if (!load_use_hazard)   // ? stall ??? PC
            pc <= pc + 1;
    end

    // imem addr: branch_taken ???? target???imem?????
    // stall ????? pc??????????
    wire [31:0] imem_data_dout;
    imem imem_inst (
        .addr      (branch_taken ? branch_target_pc : pc),
        .dout      (if_instr),
        .data_addr (exmem_alu_result[10:2]),
        .data_dout (imem_data_dout),
        .clk       (clk),
        .we        (1'b0),
        .din       (32'b0)
    );

    // =========================================================
    // Pipeline Register: IF/ID
    // =========================================================

    reg [31:0] ifid_instr;
    reg [8:0]  ifid_pc;

    always @(posedge clk) begin
        if (rst || branch_taken) begin
            ifid_instr <= 32'hE1A0B00B;
            ifid_pc    <= 9'b0;
        end else if (!load_use_hazard) begin   // ? stall ??? IF/ID
            ifid_instr <= if_instr;
            ifid_pc    <= pc;
        end
        // load_use_hazard ? ifid ?????id/ex ? bubble?? id/ex always ??
    end

    // =========================================================
    // Stage 2: ID ? Decode + Register Read
    // =========================================================

    // ?? ?????? ?????????????????????????????????????
    wire id_is_dp  = (ifid_instr[27:26] == 2'b00);
    wire id_is_ls  = (ifid_instr[27:26] == 2'b01);
    wire id_is_br  = (ifid_instr[27:25] == 3'b101); // B ? BL
    wire id_is_bl  = id_is_br && ifid_instr[24];     // BL: bit24=1
    wire id_is_bx  = (ifid_instr[27:4] == 24'h12FFF1); // BX Rm

    // ?? DP ?? ??????????????????????????????????????????
    wire        id_I     = ifid_instr[25];
    wire [3:0]  id_opraw = ifid_instr[24:21];
    wire        id_S     = ifid_instr[20];
    wire [3:0]  id_Rn_dp = ifid_instr[19:16];
    wire [3:0]  id_Rd_dp = ifid_instr[15:12];
    wire [3:0]  id_rot   = ifid_instr[11:8];
    wire [7:0]  id_imm8  = ifid_instr[7:0];
    wire [3:0]  id_Rm    = ifid_instr[3:0];
    wire [31:0] id_dp_imm = rot_imm(id_imm8, id_rot);

    // CMP: opcode=1010, S ???1, ?? Rd
    wire id_is_cmp = id_is_dp && (id_opraw == 4'hA);

    // ?? LS ?? ??????????????????????????????????????????
    wire        id_ls_L   = ifid_instr[20];
    wire        id_ls_U   = ifid_instr[23];
    wire        id_ls_P   = ifid_instr[24];  // 1=???, 0=???
    wire        id_ls_W   = ifid_instr[21];  // 1=??
    wire [3:0]  id_ls_Rn  = ifid_instr[19:16];
    wire [3:0]  id_ls_Rd  = ifid_instr[15:12];
    wire [11:0] id_ls_off = ifid_instr[11:0];

    // ????????????????
    wire [31:0] id_ls_off32 = id_ls_U ? {20'b0, id_ls_off}
                                       : (~{20'b0, id_ls_off} + 1);

    // ALU ????????=off????=0????? Rn ???
    wire [31:0] id_ls_imm = id_ls_P ? id_ls_off32 : 32'b0;

    // ????????W=1??????P=0?
    wire id_ls_wb = id_is_ls && ((id_ls_P && id_ls_W) || !id_ls_P);

    // ?? PC-relative LDR ???Rn = R15 = 4'hF?????????????
    wire id_ls_pc_rel = id_is_ls && (id_ls_Rn == 4'hF);
    // ARM PC = ??????? + 2???? = (ifid_pc+2)<<2
    wire [31:0] id_pc_val = {ifid_pc + 9'd2, 2'b00};
    wire [3:0]  id_cond      = ifid_instr[31:28];
    wire [23:0] id_br_off24  = ifid_instr[23:0];
    // ????? 32 ??? <<2 ?????
    wire [31:0] id_br_offset = {{6{id_br_off24[23]}}, id_br_off24, 2'b00};

    // ?? DP ??????bit25=0 ?????????????????????????
    // bits[6:5] = shift_type: 00=LSL 01=LSR 10=ASR 11=ROR
    // bits[11:7] = shift_amount (5????)
    wire [1:0]  id_shift_type = ifid_instr[6:5];
    wire [4:0]  id_shift_amt  = ifid_instr[11:7];
    // ? Rm ????
    reg [31:0] id_rm_shifted;
    always @(*) begin
        case (id_shift_type)
            2'b00: id_rm_shifted = id_r1_val << id_shift_amt;           // LSL
            2'b01: id_rm_shifted = id_r1_val >> id_shift_amt;           // LSR
            2'b10: id_rm_shifted = $signed(id_r1_val) >>> id_shift_amt; // ASR
            2'b11: id_rm_shifted = (id_r1_val >> id_shift_amt) |        // ROR
                                   (id_r1_val << (32 - id_shift_amt));
        endcase
    end
    // ?? DP ??????bit25=0??????????????? Rm
    wire [31:0] id_op2_reg = (id_is_dp && !id_I) ? id_rm_shifted : id_r1_val;
    wire [3:0]  id_rn_addr  = id_is_bx ? id_Rm :
                              id_is_ls  ? id_ls_Rn : id_Rn_dp;
    wire [3:0]  id_r1_addr  = id_is_ls ? id_ls_Rd : id_Rm;
    wire [31:0] id_imm_val  = id_is_ls ? id_ls_imm : id_dp_imm;
    wire        id_alu_src  = id_is_ls | id_I;
    // ?? op2???? or ??????
    wire [31:0] id_op2_final = id_alu_src ? id_imm_val : id_op2_reg;

    // ?? ALU ?? ?????????????????????????????????????????
    reg [2:0] id_alu_op;
    always @(*) begin
        if (id_is_ls || id_is_br)
            id_alu_op = 3'b000;       // ADD?????/???????ALU?
        else case (id_opraw)
            4'b0100: id_alu_op = 3'b000; // ADD
            4'b0010: id_alu_op = 3'b001; // SUB
            4'b1010: id_alu_op = 3'b001; // CMP (SUB, ??Rd)
            4'b1101: id_alu_op = 3'b101; // MOV
            4'b0000: id_alu_op = 3'b010; // AND
            4'b1100: id_alu_op = 3'b011; // ORR
            4'b0001: id_alu_op = 3'b100; // XOR
            default: id_alu_op = 3'b101; // NOP safe
        endcase
    end

    // ?? ???? ?????????????????????????????????????????
    wire id_mem_read  = id_is_ls &&  id_ls_L;
    wire id_mem_write = id_is_ls && !id_ls_L;
    // CMP ? Branch ???????BL ? R14?? WB ?????
    wire id_reg_write = (id_is_dp && !id_is_cmp) || id_mem_read;
    // S flag: CMP ?????SUB/ADD ? S ????
    wire id_set_flags = id_is_cmp || (id_is_dp && id_S);

    wire [3:0] id_rd_addr = id_is_ls ? id_ls_Rd : id_Rd_dp;

    // ?? ?????? ?????????????????????????????????????
    wire        wb_we;
    wire [3:0]  wb_waddr;
    wire [31:0] wb_wdata;
    // wb2_* ? WB ??? assign ????????? regfile ???
    wire        wb2_we;
    wire [3:0]  wb2_waddr;
    wire [31:0] wb2_wdata;
    wire [31:0] id_rn_val, id_r1_val;

    arm_regfile regfile_inst (
        .clk    (clk),     .rst    (rst),
        .r0addr (id_rn_addr), .r0data (id_rn_val),
        .r1addr (id_r1_addr), .r1data (id_r1_val),
        .we     (wb_we),   .waddr  (wb_waddr),  .wdata  (wb_wdata),
        .we2    (wb2_we),  .waddr2 (wb2_waddr), .wdata2 (wb2_wdata)
    );

    // =========================================================
    // Pipeline Register: ID/EX
    // branch_taken ??? NOP ???flush ????????
    // =========================================================

    reg [31:0] idex_rn;
    reg [31:0] idex_op2;
    reg [31:0] idex_store_data;
    reg [3:0]  idex_rd_addr;
    reg [3:0]  idex_rn_addr;
    reg [3:0]  idex_rs1_addr;   // forwarding: Rn ??
    reg [3:0]  idex_rs2_addr;   // forwarding: Rm/Rd(store) ??
    reg        idex_alu_src;    // forwarding: 1=???????? B
    reg [2:0]  idex_alu_op;
    reg        idex_mem_read;
    reg        idex_mem_write;
    reg        idex_reg_write;
    reg        idex_set_flags;
    reg        idex_ls_wb;
    reg [31:0] idex_wb_val;   // ????? EX ?????
    reg [31:0] idex_ls_off32; // offset ?? EX?? forwarded Rn ?? wb_val
    reg        idex_pc_rel;
    // Branch ??
    reg        idex_is_branch;
    reg        idex_is_bx;
    reg        idex_is_bl;
    reg [31:0] idex_bl_ret;
    reg [31:0] idex_bx_target;
    reg [3:0]  idex_cond;
    reg [8:0]  idex_branch_target;
    reg [8:0]  idex_pc;

    // Load-use ?????LDR ? EX ????????????? ? ? bubble
    // Load-use ?????LDR ? EX ????????????? ? ? bubble
    // ???????
    //   1. Rd????????????? Rn ? Rm
    //   2. Rn??????pre/post-index???????? Rn ? Rm
    wire load_use_hazard = idex_mem_read && (
         // ARM ? R0 ?????????? rd_addr!=0 ????? MIPS ????
         // ?? idex_reg_write ?? LDR ???????????
         (idex_reg_write && ((idex_rd_addr == id_rn_addr) || (!id_alu_src && idex_rd_addr == id_r1_addr))) ||
         // WB2?pre/post-index ???????? idex_ls_wb ????????????
         (idex_ls_wb && ((idex_rn_addr == id_rn_addr) || (!id_alu_src && idex_rn_addr == id_r1_addr)))
         );

    always @(posedge clk) begin
        if (rst || branch_taken || load_use_hazard) begin
            idex_rn          <= 32'b0;
            idex_op2         <= 32'b0;
            idex_store_data  <= 32'b0;
            idex_rd_addr     <= 4'b0;
            idex_rn_addr     <= 4'b0;
            idex_rs1_addr    <= 4'b0;
            idex_rs2_addr    <= 4'b0;
            idex_alu_src     <= 1'b1;
            idex_alu_op      <= 3'b101;
            idex_mem_read    <= 1'b0;
            idex_mem_write   <= 1'b0;
            idex_reg_write   <= 1'b0;
            idex_set_flags   <= 1'b0;
            idex_ls_wb       <= 1'b0;
            idex_wb_val      <= 32'b0;
            idex_ls_off32    <= 32'b0;
            idex_pc_rel      <= 1'b0;
            idex_is_branch   <= 1'b0;
            idex_is_bx       <= 1'b0;
            idex_is_bl       <= 1'b0;
            idex_bl_ret      <= 32'b0;
            idex_bx_target   <= 32'b0;
            idex_cond        <= 4'hE;
            idex_branch_target <= 9'b0;
            idex_pc          <= 9'b0;
        end else begin
            idex_rn          <= id_ls_pc_rel ? id_pc_val : id_rn_val;
            idex_op2         <= id_op2_final;
            idex_store_data  <= id_r1_val;
            idex_rd_addr     <= id_rd_addr;
            idex_rn_addr     <= id_rn_addr;
            idex_rs1_addr    <= id_rn_addr;
            idex_rs2_addr    <= id_r1_addr;
            idex_alu_src     <= id_alu_src;
            idex_alu_op      <= id_alu_op;
            idex_mem_read    <= id_mem_read;
            idex_mem_write   <= id_mem_write;
            idex_reg_write   <= id_reg_write;
            idex_set_flags   <= id_set_flags;
            idex_ls_wb       <= id_ls_wb;
            idex_wb_val      <= id_rn_val + id_ls_off32;  // ???????
            idex_ls_off32    <= id_ls_off32;
            idex_pc_rel      <= id_ls_pc_rel;
            idex_is_branch   <= id_is_br || id_is_bx;
            idex_is_bx       <= id_is_bx;
            idex_is_bl       <= id_is_bl;
            idex_bl_ret      <= {ifid_pc + 9'd1, 2'b00};
            idex_bx_target   <= id_rn_val;
            idex_cond        <= id_cond;
            idex_branch_target <= ifid_pc + 9'd2 + id_br_off24[8:0];
            idex_pc          <= ifid_pc;
        end
    end

    // =========================================================
    // Stage 3: EX ? Forwarding + ALU + ???? + CPSR ??
    // =========================================================

    // ?? Forwarding ???? ???????????????????????????????
    // EX/MEM ? EX forwarding
    // ?????LDR ? EX/MEM ?????????????!exmem_mem_read?
    // load-use stall ?? LDR ????? MEM/WB?EX ??
    wire fwd_ex_rs1 = exmem_reg_write && exmem_cond_met &&
                      !exmem_mem_read &&           // ? LDR ??? EX/MEM ??
                      (exmem_rd_addr != 4'b0) &&
                      (exmem_rd_addr == idex_rs1_addr);
    wire fwd_ex_rs2 = exmem_reg_write && exmem_cond_met &&
                      !exmem_mem_read &&           // ? ??
                      (exmem_rd_addr != 4'b0) &&
                      (exmem_rd_addr == idex_rs2_addr);

    // MEM/WB ? EX forwarding?WB1??????
    wire fwd_wb_rs1 = (memwb_reg_write || memwb_is_bl) && memwb_cond_met &&
                      (wb_waddr != 4'b0) &&
                      (wb_waddr == idex_rs1_addr) && !fwd_ex_rs1;
    wire fwd_wb_rs2 = (memwb_reg_write || memwb_is_bl) && memwb_cond_met &&
                      (wb_waddr != 4'b0) &&
                      (wb_waddr == idex_rs2_addr) && !fwd_ex_rs2;

    // MEM/WB ? EX forwarding?WB2?pre/post-index ???? Rn ???
    // e.g. ldr r1,[r3,#4]! ?? R3 ? strgt r1,[r3,#-4] ??? R3
    wire fwd_wb2_rs1 = memwb_ls_wb && memwb_cond_met &&
                       (memwb_rn_addr != 4'b0) &&
                       (memwb_rn_addr == idex_rs1_addr) && !fwd_ex_rs1 && !fwd_wb_rs1;
    wire fwd_wb2_rs2 = memwb_ls_wb && memwb_cond_met &&
                       (memwb_rn_addr != 4'b0) &&
                       (memwb_rn_addr == idex_rs2_addr) && !fwd_ex_rs2 && !fwd_wb_rs2;

    // EX/MEM WB2 ???pre/post-index Rn ? EX/MEM ????
    wire fwd_ex2_rs1 = exmem_ls_wb && exmem_cond_met &&
                       (exmem_rn_addr != 4'b0) &&
                       (exmem_rn_addr == idex_rs1_addr) && !fwd_ex_rs1;
    wire fwd_ex2_rs2 = exmem_ls_wb && exmem_cond_met &&
                       (exmem_rn_addr != 4'b0) &&
                       (exmem_rn_addr == idex_rs2_addr) && !fwd_ex_rs2;

    // ?????
    wire [31:0] fwd_ex_data  = exmem_is_bl ? exmem_bl_ret : exmem_alu_result;
    wire [31:0] fwd_ex2_data = exmem_wb_val;   // EX/MEM ????????
    wire [31:0] fwd_wb_data  = wb_wdata;
    wire [31:0] fwd_wb2_data = memwb_wb_val;   // MEM/WB ????????

    // ?? ???? ALU ?? ?????????????????????????????????
    wire [31:0] ex_alu_A = fwd_ex_rs1  ? fwd_ex_data  :
                           fwd_ex2_rs1 ? fwd_ex2_data :
                           fwd_wb_rs1  ? fwd_wb_data  :
                           fwd_wb2_rs1 ? fwd_wb2_data : idex_rn;
    wire [31:0] ex_alu_B = idex_alu_src  ? idex_op2 :   // ??????
                           fwd_ex_rs2   ? fwd_ex_data  :
                           fwd_ex2_rs2  ? fwd_ex2_data :
                           fwd_wb_rs2   ? fwd_wb_data  :
                           fwd_wb2_rs2  ? fwd_wb2_data : idex_op2;
    // STR store data ??????
    wire [31:0] ex_store_data = fwd_ex_rs2  ? fwd_ex_data  :
                                fwd_ex2_rs2 ? fwd_ex2_data :
                                fwd_wb_rs2  ? fwd_wb_data  :
                                fwd_wb2_rs2 ? fwd_wb2_data : idex_store_data;

    wire [31:0] ex_result;
    wire        ex_N, ex_Z, ex_C, ex_V;

    arm_alu alu_inst (
        .A      (ex_alu_A),
        .B      (ex_alu_B),
        .op     (idex_alu_op),
        .result (ex_result),
        .N      (ex_N), .Z(ex_Z), .C(ex_C), .V(ex_V)
    );

    // ?? ????????? CPSR????????????????????????
    reg cond_met;
    always @(*) begin
        case (idex_cond)
            4'h0: cond_met = cpsr_Z;                         // EQ
            4'h1: cond_met = ~cpsr_Z;                        // NE
            4'h2: cond_met = cpsr_C;                         // CS
            4'h3: cond_met = ~cpsr_C;                        // CC
            4'h4: cond_met = cpsr_N;                         // MI
            4'h5: cond_met = ~cpsr_N;                        // PL
            4'h6: cond_met = cpsr_V;                         // VS
            4'h7: cond_met = ~cpsr_V;                        // VC
            4'h8: cond_met = cpsr_C && ~cpsr_Z;              // HI
            4'h9: cond_met = ~cpsr_C || cpsr_Z;              // LS
            4'hA: cond_met = (cpsr_N == cpsr_V);             // GE
            4'hB: cond_met = (cpsr_N != cpsr_V);             // LT
            4'hC: cond_met = ~cpsr_Z && (cpsr_N == cpsr_V);  // GT
            4'hD: cond_met = cpsr_Z  || (cpsr_N != cpsr_V);  // LE
            4'hE: cond_met = 1'b1;                           // AL
            4'hF: cond_met = 1'b1;                           // AL
            default: cond_met = 1'b1;
        endcase
    end

    // ??????
    // BX: ?????????????????word???
    // B/BL: ??????????? branch_target
    assign branch_taken     = idex_is_branch && cond_met;
    assign branch_target_pc = idex_is_bx
                              ? idex_bx_target[10:2]  // ???? ? word??
                              : idex_branch_target;

    // ?? CPSR ?????posedge ?????????????????????????
    always @(posedge clk) begin
        if (rst) begin
            cpsr_N <= 1'b0; cpsr_Z <= 1'b0;
            cpsr_C <= 1'b0; cpsr_V <= 1'b0;
        end else if (idex_set_flags) begin
            cpsr_N <= ex_N;
            cpsr_Z <= ex_Z;
            cpsr_C <= ex_C;
            cpsr_V <= ex_V;
        end
    end

    // =========================================================
    // Pipeline Register: EX/MEM
    // =========================================================

    reg [31:0] exmem_alu_result;
    reg [31:0] exmem_store_data;
    reg [3:0]  exmem_rd_addr;
    reg [3:0]  exmem_rn_addr;
    reg [31:0] exmem_wb_val;
    reg        exmem_mem_read;
    reg        exmem_mem_write;
    reg        exmem_reg_write;
    reg        exmem_cond_met;
    reg        exmem_ls_wb;
    reg        exmem_is_bl;
    reg [31:0] exmem_bl_ret;
    reg        exmem_pc_rel;  // ? PC-relative LDR ??

    always @(posedge clk) begin
        if (rst) begin
            exmem_alu_result <= 32'b0;
            exmem_store_data <= 32'b0;
            exmem_rd_addr    <= 4'b0;
            exmem_rn_addr    <= 4'b0;
            exmem_wb_val     <= 32'b0;
            exmem_mem_read   <= 1'b0;
            exmem_mem_write  <= 1'b0;
            exmem_reg_write  <= 1'b0;
            exmem_cond_met   <= 1'b0;
            exmem_ls_wb      <= 1'b0;
            exmem_is_bl      <= 1'b0;
            exmem_bl_ret     <= 32'b0;
            exmem_pc_rel     <= 1'b0;
        end else begin
            exmem_alu_result <= ex_result;
            exmem_store_data <= ex_store_data;
            exmem_rd_addr    <= idex_rd_addr;
            exmem_rn_addr    <= idex_rn_addr;
            // ?????WB2 ???? EX ??? forwarded Rn ??
            // idex_wb_val ? ID ????????? Rn?EX/MEM ?????
            // ex_alu_A ???? forwarding ??? Rn ?
            exmem_wb_val     <= ex_alu_A + idex_ls_off32;
            exmem_mem_read   <= idex_mem_read;
            exmem_mem_write  <= idex_mem_write;
            exmem_reg_write  <= idex_reg_write;
            exmem_cond_met   <= cond_met;
            exmem_ls_wb      <= idex_ls_wb;
            exmem_is_bl      <= idex_is_bl;
            exmem_bl_ret     <= idex_bl_ret;
            exmem_pc_rel     <= idex_pc_rel;  // ? ??
        end
    end

    // =========================================================
    // Stage 4: MEM ? Memory Access
    // =========================================================

    // dmem?????????? EX ?????? ex_result???1??
    wire [7:0]  dmem_addr = ex_result[9:2];
    wire [31:0] dmem_read_data;

    dmem_32 dmem_inst (
        .clka  (clk),
        .wea   (idex_mem_write && cond_met),
        .addra (dmem_addr),
        .dina  (ex_store_data),
        .douta (dmem_read_data),
        .clkb  (clk),
        .addrb (8'b0),
        .doutb ()
    );

    // imem ?????????address = exmem_alu_result????EX???
    // PC-relative LDR ? imem ???? LDR ? dmem ?
    wire [31:0] mem_read_data = exmem_pc_rel ? imem_data_dout : dmem_read_data;

    // =========================================================
    // Pipeline Register: MEM/WB
    // =========================================================

    reg [31:0] memwb_alu_result;
    reg [31:0] memwb_mem_data;
    reg [3:0]  memwb_rd_addr;
    reg        memwb_mem_to_reg;
    reg        memwb_reg_write;
    reg        memwb_cond_met;
    reg        memwb_is_bl;
    reg [31:0] memwb_bl_ret;
    reg        memwb_ls_wb;      // ? ?? Rn
    reg [3:0]  memwb_rn_addr;    // ? ???????
    reg [31:0] memwb_wb_val;     // ? ????= alu_result = Rn±off?

    always @(posedge clk) begin
        if (rst) begin
            memwb_alu_result <= 32'b0;
            memwb_mem_data   <= 32'b0;
            memwb_rd_addr    <= 4'b0;
            memwb_mem_to_reg <= 1'b0;
            memwb_reg_write  <= 1'b0;
            memwb_cond_met   <= 1'b0;
            memwb_is_bl      <= 1'b0;
            memwb_bl_ret     <= 32'b0;
            memwb_ls_wb      <= 1'b0;
            memwb_rn_addr    <= 4'b0;
            memwb_wb_val     <= 32'b0;
        end else begin
            memwb_alu_result <= exmem_alu_result;
            memwb_mem_data   <= mem_read_data;
            memwb_rd_addr    <= exmem_rd_addr;
            memwb_mem_to_reg <= exmem_mem_read;
            memwb_reg_write  <= exmem_reg_write;
            memwb_cond_met   <= exmem_cond_met;
            memwb_is_bl      <= exmem_is_bl;
            memwb_bl_ret     <= exmem_bl_ret;
            memwb_ls_wb      <= exmem_ls_wb;
            memwb_rn_addr    <= exmem_rn_addr;
            memwb_wb_val     <= exmem_wb_val;  // ? ????????? ALU ????
        end
    end

    // =========================================================
    // Stage 5: WB ? Write Back
    // =========================================================
    // ??1????? (DP?? / LDR?? / BL????)
    // ??2?LDR/STR ???? Rn?????? / ????
    assign wb_we    = (memwb_reg_write || memwb_is_bl) && memwb_cond_met;
    assign wb_waddr = memwb_is_bl ? 4'd14 : memwb_rd_addr;
    assign wb_wdata = memwb_is_bl     ? memwb_bl_ret :
                      memwb_mem_to_reg ? memwb_mem_data : memwb_alu_result;

    // ??2???????? assign ??? wire ... = ???????
    assign wb2_we    = memwb_ls_wb && memwb_cond_met;
    assign wb2_waddr = memwb_rn_addr;
    assign wb2_wdata = memwb_wb_val;

endmodule