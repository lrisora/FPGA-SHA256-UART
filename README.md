# FPGA-SHA256-UART

串口收发的FPGA计算SHA256源码。仅学习，不能挖矿。
开发板使用[Spartan-Edge-Accelerator-Board](https://wiki.seeedstudio.com/cn/Spartan-Edge-Accelerator-Board/)

![资源使用](https://raw.githubusercontent.com/lrisora/FPGA-SHA256-UART/master/%E6%88%AA%E5%9B%BE/1.png)

哈希算法预设的不涉及时序的非线性函数代码以及文件名来自
<https://github.com/JeremyV2014/VerilogSHA256Miner>。

串口收发均为ASCII码格式，若模块接收到一个字节不能被解释为`0-9/a-f/A-F`则将此字节作为命令处理。具体参见源码。

串口每收到一个字节进行一次异步时钟对齐，保证连续大量接收不出错。

`testbench`只覆盖`sha256.v`核心算法，串口收发没有`testbench`，在`ModelSim`测试通过。
`WpfApp_SHA256.exe`为`testbench`配套程序，生成待哈希区块与哈希结果供`testbench`读取。

![测试波形](https://raw.githubusercontent.com/lrisora/FPGA-SHA256-UART/master/%E6%88%AA%E5%9B%BE/2.png)

`cu.tcl`为顶层模块DC脚本，在`synopsys dc vO-2018.06-SP1`测试通过。

项目中不含工程文件，请自行新建。
虽然扩展名是`.v`不过为`System verilog`语法，注意文件属性。
项目顶层模块使用一个PLL提供时钟，请自行新建或修改。
