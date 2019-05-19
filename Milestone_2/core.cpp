#include "my_ip_hls.hpp"


void core(stream<axiWord> &ps2ipIntFifo,stream<axiWord> &ip2psIntFifo,uint32 rule0_reg, uint32 rule1_reg, uint32 rule2_reg,
		uint32 &rule0_cnt,uint32 &rule1_cnt,uint32 &rule2_cnt) {

	#pragma HLS PIPELINE II=1 enable_flush
	#pragma HLS INTERFACE ap_ctrl_none port=return


	static axiWord newInWord = {0,0,0};

	static uint32 rule_0_counter;
	static uint32 rule_1_counter;
	static uint32 rule_2_counter;

	static uint1 flag0;
	static uint1 flag1;
	static uint1 flag2;

	static uint32 rule0_temp;
	static uint32 rule1_temp;
	static uint32 rule2_temp;


	if (flag0 == 0){
		flag0 = 1;
		rule0_temp = rule0_reg;
	}
	if (flag1 == 0){
		flag1 = 1;
		rule1_temp = rule1_reg;
	}
	if (flag2 == 0){
		flag2 = 1;
		rule2_temp = rule2_reg;
	}

	if (!ps2ipIntFifo.empty()) {
		ps2ipIntFifo.read(newInWord);

		if ((rule0_reg != newInWord.data) and (rule1_reg != newInWord.data) and (rule2_reg != newInWord.data)){
			ip2psIntFifo.write(newInWord);
		}
		else if (rule0_reg == newInWord.data){

			rule_0_counter = rule_0_counter + 1;
		}
		else if (rule1_reg == newInWord.data){
			rule_1_counter = rule_1_counter + 1;
		}
		else if (rule2_reg == newInWord.data){
			rule_2_counter = rule_2_counter + 1;
		}
	}

	if (rule0_temp != rule0_reg){
		flag0 = 0;
		rule_0_counter = 0;
	}
	if (rule1_temp != rule1_reg){
		flag1 = 0;
		rule_1_counter = 0;
	}
	if (rule2_temp != rule2_reg){
		flag2 = 0;
		rule_2_counter = 0;
	}

	rule0_cnt = rule_0_counter;
	rule1_cnt = rule_1_counter;
	rule2_cnt = rule_2_counter;

	return;

}





