`define ADDR_SPLL_CSR                  7'h0
`define SPLL_CSR_UNUSED0_OFFSET 0
`define SPLL_CSR_UNUSED0 32'h0000003f
`define SPLL_CSR_N_REF_OFFSET 8
`define SPLL_CSR_N_REF 32'h00003f00
`define SPLL_CSR_N_OUT_OFFSET 16
`define SPLL_CSR_N_OUT 32'h00070000
`define SPLL_CSR_DBG_SUPPORTED_OFFSET 19
`define SPLL_CSR_DBG_SUPPORTED 32'h00080000
`define ADDR_SPLL_ECCR                 7'h4
`define SPLL_ECCR_EXT_EN_OFFSET 0
`define SPLL_ECCR_EXT_EN 32'h00000001
`define SPLL_ECCR_EXT_SUPPORTED_OFFSET 1
`define SPLL_ECCR_EXT_SUPPORTED 32'h00000002
`define SPLL_ECCR_ALIGN_EN_OFFSET 2
`define SPLL_ECCR_ALIGN_EN 32'h00000004
`define SPLL_ECCR_ALIGN_DONE_OFFSET 3
`define SPLL_ECCR_ALIGN_DONE 32'h00000008
`define SPLL_ECCR_EXT_REF_PRESENT_OFFSET 4
`define SPLL_ECCR_EXT_REF_PRESENT 32'h00000010
`define ADDR_SPLL_OCCR                 7'h10
`define SPLL_OCCR_OUT_EN_OFFSET 0
`define SPLL_OCCR_OUT_EN 32'h000000ff
`define SPLL_OCCR_OUT_LOCK_OFFSET 8
`define SPLL_OCCR_OUT_LOCK 32'h0000ff00
`define SPLL_OCCR_OUT_DET_TYPE_OFFSET 16
`define SPLL_OCCR_OUT_DET_TYPE 32'h00ff0000
`define ADDR_SPLL_RCER                 7'h14
`define ADDR_SPLL_OCER                 7'h18
`define ADDR_SPLL_DAC_HPLL             7'h20
`define ADDR_SPLL_DAC_MAIN             7'h24
`define SPLL_DAC_MAIN_VALUE_OFFSET 0
`define SPLL_DAC_MAIN_VALUE 32'h0000ffff
`define SPLL_DAC_MAIN_DAC_SEL_OFFSET 16
`define SPLL_DAC_MAIN_DAC_SEL 32'h000f0000
`define ADDR_SPLL_DEGLITCH_THR         7'h28
`define ADDR_SPLL_DFR_SPLL             7'h2c
`define SPLL_DFR_SPLL_VALUE_OFFSET 0
`define SPLL_DFR_SPLL_VALUE 32'h7fffffff
`define SPLL_DFR_SPLL_EOS_OFFSET 31
`define SPLL_DFR_SPLL_EOS 32'h80000000
`define ADDR_SPLL_CRR_IN               7'h30
`define ADDR_SPLL_CRR_OUT              7'h34
`define ADDR_SPLL_AUX_CR               7'h38
`define SPLL_AUX_CR_AUX_SEL_OFFSET 0
`define SPLL_AUX_CR_AUX_SEL 32'h00000007
`define SPLL_AUX_CR_DIV_REF_OFFSET 3
`define SPLL_AUX_CR_DIV_REF 32'h000001f8
`define SPLL_AUX_CR_DIV_FB_OFFSET 9
`define SPLL_AUX_CR_DIV_FB 32'h00007e00
`define SPLL_AUX_CR_GATE_OFFSET 15
`define SPLL_AUX_CR_GATE 32'h00078000
`define ADDR_SPLL_FREQ_CSR             7'h3c
`define SPLL_FREQ_CSR_FREQ_OFFSET 0
`define SPLL_FREQ_CSR_FREQ 32'h03ffffff
`define SPLL_FREQ_CSR_VALID_OFFSET 26
`define SPLL_FREQ_CSR_VALID 32'h04000000
`define SPLL_FREQ_CSR_CHAN_SEL_OFFSET 27
`define SPLL_FREQ_CSR_CHAN_SEL 32'hf8000000
`define ADDR_SPLL_EIC_IDR              7'h40
`define SPLL_EIC_IDR_TAG_OFFSET 0
`define SPLL_EIC_IDR_TAG 32'h00000001
`define ADDR_SPLL_EIC_IER              7'h44
`define SPLL_EIC_IER_TAG_OFFSET 0
`define SPLL_EIC_IER_TAG 32'h00000001
`define ADDR_SPLL_EIC_IMR              7'h48
`define SPLL_EIC_IMR_TAG_OFFSET 0
`define SPLL_EIC_IMR_TAG 32'h00000001
`define ADDR_SPLL_EIC_ISR              7'h4c
`define SPLL_EIC_ISR_TAG_OFFSET 0
`define SPLL_EIC_ISR_TAG 32'h00000001
`define ADDR_SPLL_DFR_HOST_R0          7'h50
`define SPLL_DFR_HOST_R0_VALUE_OFFSET 0
`define SPLL_DFR_HOST_R0_VALUE 32'hffffffff
`define ADDR_SPLL_DFR_HOST_R1          7'h54
`define SPLL_DFR_HOST_R1_SEQ_ID_OFFSET 0
`define SPLL_DFR_HOST_R1_SEQ_ID 32'h0000ffff
`define ADDR_SPLL_DFR_HOST_CSR         7'h58
`define SPLL_DFR_HOST_CSR_FULL_OFFSET 16
`define SPLL_DFR_HOST_CSR_FULL 32'h00010000
`define SPLL_DFR_HOST_CSR_EMPTY_OFFSET 17
`define SPLL_DFR_HOST_CSR_EMPTY 32'h00020000
`define SPLL_DFR_HOST_CSR_USEDW_OFFSET 0
`define SPLL_DFR_HOST_CSR_USEDW 32'h00001fff
`define ADDR_SPLL_TRR_R0               7'h5c
`define SPLL_TRR_R0_VALUE_OFFSET 0
`define SPLL_TRR_R0_VALUE 32'h00ffffff
`define SPLL_TRR_R0_CHAN_ID_OFFSET 24
`define SPLL_TRR_R0_CHAN_ID 32'h7f000000
`define SPLL_TRR_R0_DISC_OFFSET 31
`define SPLL_TRR_R0_DISC 32'h80000000
`define ADDR_SPLL_TRR_CSR              7'h60
`define SPLL_TRR_CSR_EMPTY_OFFSET 17
`define SPLL_TRR_CSR_EMPTY 32'h00020000
