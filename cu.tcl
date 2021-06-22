sh date
remove_design -designs

set search_path [list /home/lrisora/synopsys/library/ ]
set target_library  { smic13_ss.db }
set link_library    { * smic13_ss.db }

suppress_message  VER-130
suppress_message  VER-129
suppress_message  VER-318
suppress_message  ELAB-311
suppress_message  VER-936

# 设置工作目录为./work
define_design_lib WORK -path ./work

################################
#read&amp;link&amp;Check design#
################################
analyze -format sverilog [list ./code/define.v ]
analyze -format sverilog [list ./code/baud_generate.v ]
analyze -format sverilog [list ./code/tx_shift_reg.v ]
analyze -format sverilog [list ./code/rx_shift_reg.v ]
analyze -format sverilog [list ./code/uart_tx.v ]
analyze -format sverilog [list ./code/uart_rx.v ]
analyze -format sverilog [list ./code/calc_w.v ]
analyze -format sverilog [list ./code/hash_algorithm.v ]
analyze -format sverilog [list ./code/k_constants.v ]
analyze -format sverilog [list ./code/sha256.v ]
analyze -format sverilog [list ./code/sha256_cu.v ]
analyze -format sverilog [list ./code/sha256_cu_tld.v ]

elaborate sha256_cu_tld

uniquify

link

check_design

#############################
#   define IO port name     #
#############################
set clk     [list CLK_100 ]
set rst_n   [list KEY ]

set inputs  [list UART_RXD ]
set outputs [list UART_TXD LED1 LED2 ]

# clk
create_clock -n clock $clk -period 10 -waveform { 0 5 }
set_dont_touch_network $clk
set_drive 0            $clk
set_ideal_network      $clk
# rst_n
set_dont_touch_network $rst_n
set_drive 0            $rst_n
set_ideal_network      $rst_n
# input/output
set_input_delay  -clock clock 0 $inputs
set_output_delay -clock clock 0 $outputs

set_max_area 0
set_max_fanout 4 sha256_cu_tld
set_max_transition 0.5 sha256_cu_tld

#############################
#   compile_design          #
#############################
#compile -map_effort high -area_effort high -boundary_optimization
compile -map_effort medium

##########################
# write *.db and *.v     #
##########################
write -f ddc -hier -output     ./netlist/sha256_cu.ddc
write -f verilog -hier -output ./netlist/sha256_cu_netlist.v
write_sdf -version 2.1         ./netlist/sha256_cu.sdf

##########################
# generate reports       #
##########################
#1
report_area                       > ./rpt/sha256_cu.area_rpt
#2
report_constraint -all_violators  > ./rpt/sha256_cu.constraint_rpt
#3
report_timing                     > ./rpt/sha256_cu.timing_rpt
#4
report_power -analysis_effort low > ./rpt/sha256_cu.power_rpt