#include "my_ip_hls.hpp"

void rules(uint32 rule0,uint32 rule1,uint32 rule2, uint32 &rule0_reg,uint32 &rule1_reg,uint32 &rule2_reg){

	rule0_reg = rule0;
	rule1_reg = rule1;
	rule2_reg = rule2;

	//static uint32 rule0_cnt = 0;
	//static uint32 rule1_cnt = 0;
	//static uint32 rule2_cnt = 0;

	//printf("[DBG]:Rule counter write enable: %d\n",(int)rule_counter_wr_en);
	//printf("[DBG]:Rules called: %d\n",(int)rule_counter_index);

	/*if (rule_counter_wr_en == 0b1){
		if (rule_counter_index == 0b00){
			rule0_cnt = rule0_cnt + 1;
		}
		else if (rule_counter_index == 0b01){
			rule1_cnt = rule1_cnt + 1;
		}
		else if (rule_counter_index == 0b10){
			rule2_cnt = rule2_cnt + 1;
		}
	}*/

}
