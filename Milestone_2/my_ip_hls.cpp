#include "my_ip_hls.hpp"


void my_ip_hls(stream<axiWord> &slaveIn,stream<axiWord> &masterOut, uint32 rule0, uint32 rule1, uint32 rule2,
		uint32 &rule0_cnt,uint32 &rule1_cnt,uint32 &rule2_cnt) {

	#pragma HLS INTERFACE s_axilite port=rule0 bundle=ruleConf
	#pragma HLS INTERFACE s_axilite port=rule1 bundle=ruleConf
	#pragma HLS INTERFACE s_axilite port=rule2 bundle=ruleConf
	#pragma HLS INTERFACE s_axilite port=rule0_cnt bundle=ruleConf
	#pragma HLS INTERFACE s_axilite port=rule1_cnt bundle=ruleConf
	#pragma HLS INTERFACE s_axilite port=rule2_cnt bundle=ruleConf

	//#pragma HLS latency max = 2
	#pragma HLS DATAFLOW interval=1
	#pragma HLS INTERFACE axis register both port=slaveIn
	#pragma HLS INTERFACE axis register both port=masterOut
	#pragma HLS INTERFACE ap_ctrl_none port=return

	//internal fifos
	static stream<axiWord> ps2ipFifo("ps2ipFifo");
	#pragma HLS STREAM variable=ps2ipFifo depth=64 dim=1

	static stream<axiWord> ip2psFifo("ip2psFifo");
	#pragma HLS STREAM variable=ip2psFifo depth=64 dim=1

	static uint32 rule0_reg;
	static uint32 rule1_reg;
	static uint32 rule2_reg;

	//TODO: add function for configuration registers / counters via AXI Lite

	rules(rule0, rule1, rule2, rule0_reg, rule1_reg, rule2_reg);
	//fifo that keeps input data
	ps2ip_fifo(slaveIn,ps2ipFifo);
	//core of the IP
	core(ps2ipFifo,ip2psFifo,rule0_reg,rule1_reg,rule2_reg,rule0_cnt,rule1_cnt,rule2_cnt);
	//fifo that keeps output data
	ip2ps_fifo(ip2psFifo,masterOut);

	return;

}





