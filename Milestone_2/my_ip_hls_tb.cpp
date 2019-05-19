#include <hls_stream.h>
#include <ap_int.h>
#include <iostream>
#include <stdint.h>

using namespace hls;

#include "my_ip_hls.hpp"

//Number of data to be processed by IP.
#define STREAM_TEST_ITERATIONS 13

int main() {

	uint32 i = 0;

	stream<axiWord> slaveIn("slaveIn");
	stream<axiWord> masterOut("masterOut");

	int input_words[STREAM_TEST_ITERATIONS] = {10,20,30,40,50,60,70,10,20,30,40,50,60};

	uint32 input_rule0 = 10;
	uint32 input_rule1 = 20;
	uint32 input_rule2 = 30;

	uint32 rule0cnt;
	uint32 rule1cnt;
	uint32 rule2cnt;

	printf("Rule 0 is: %d\n",(int)input_rule0);
	printf("Rule 1 is: %d\n",(int)input_rule1);
	printf("Rule 2 is: %d\n",(int)input_rule2);

	for (i=0;i<STREAM_TEST_ITERATIONS;i++) {

		//Set up of the data entering the IP.
		axiWord dataIn = {0,0,0};
		dataIn.data = input_words[i];
		dataIn.strb = 0b1111;

		//Configuration of the "TLAST" signal of the AXI interface.
		if (i == STREAM_TEST_ITERATIONS-1)
			dataIn.last = 0;
		else
			dataIn.last = 1;

		if(i==5){

			printf("Rule 0 counter value: %d\n",(int)rule0cnt);
			printf("Rule 1 counter value: %d\n",(int)rule1cnt);
			printf("Rule 2 counter value: %d\n",(int)rule2cnt);

			printf("\nRule change during run-time. Rule 2 now is 40\n\n");
			input_rule2 = 40;
		}

		slaveIn.write(dataIn);

		my_ip_hls(slaveIn, masterOut,input_rule0,input_rule1,input_rule2,rule0cnt,rule1cnt,rule2cnt);

		printf("Data is: %d\n",(int)dataIn.data);

		if (!masterOut.empty()) {
			axiWord dataOut = {0,0,0};
			masterOut.read(dataOut);
			printf("%d: Read data: %u\n",(int)(i+1), (int)dataOut.data);
		}
		else {
			printf("%d: Malicious data, dumped!\n",(int)(i+1));
		}
		printf("\n");

	}




	printf("Rule 0 counter value: %d\n",(int)rule0cnt);
	printf("Rule 1 counter value: %d\n",(int)rule1cnt);
	printf("Rule 2 counter value: %d\n",(int)rule2cnt);

	return 0;
}
