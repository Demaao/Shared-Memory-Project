puts "---- compile & simulate dual_port_ram ----"
read_verilog src/hdl/dual_port_ram.v
read_verilog sim/tb_dual_port_ram.v
run 40 ns
