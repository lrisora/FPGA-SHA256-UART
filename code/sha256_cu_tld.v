/**
 * 开发板使用<https://wiki.seeedstudio.com/cn/Spartan-Edge-Accelerator-Board/>
 * 引脚绑定：
 * set_property PACKAGE_PIN H4  [get_ports CLK_100]
 * set_property PACKAGE_PIN D14 [get_ports KEY]
 * set_property PACKAGE_PIN J1  [get_ports LED1]
 * set_property PACKAGE_PIN A13 [get_ports LED2]
 * set_property PACKAGE_PIN N14 [get_ports UART_TXD]
 * set_property PACKAGE_PIN M14 [get_ports UART_RXD]
 *
 * set_property IOSTANDARD LVCMOS33 [get_ports CLK_100]
 * set_property IOSTANDARD LVCMOS33 [get_ports KEY]
 * set_property IOSTANDARD LVCMOS33 [get_ports LED1]
 * set_property IOSTANDARD LVCMOS33 [get_ports LED2]
 * set_property IOSTANDARD LVCMOS33 [get_ports UART_TXD]
 * set_property IOSTANDARD LVCMOS33 [get_ports UART_RXD]
 */
`include "define.v"
module sha256_cu_tld (CLK_100, KEY, UART_RXD, UART_TXD, LED1, LED2);
    // I/O
    input CLK_100, UART_RXD;
    input KEY;            // 复位
    output UART_TXD;
    output LED1, LED2;

    wire RxError;
    wire [7:0] Test;

    assign LED1 = (^Test[7:4]) ^ (^Test[3:0]); // fpga连续接收时会闪烁？
    assign LED2 = RxError;                     // 串口接收出错指示

`ifdef _DC
    sha256_cu cu (CLK_100, KEY, UART_RXD, UART_TXD, RxError, Test);
`else
    wire CLK_80;
    // 此sha256代码未使用流水线结构提频，在Spartan-7 XC7515只能跑到80M
    // 此处使用PLL生成80M时钟，修改时钟需要同步修改串口时钟生成
    clk_PLL instance_name (.clk_out80(CLK_80), .clk_in1(CLK_100));
    sha256_cu cu (CLK_80, KEY, UART_RXD, UART_TXD, RxError, Test);
`endif

endmodule
