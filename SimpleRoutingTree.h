#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H

enum{
	SENDER_QUEUE_SIZE=10,
	RECEIVER_QUEUE_SIZE=10,

	// IDs of the type of messages
	AM_ROUTINGMSG_2_1=21,
	AM_ROUTINGMSG_2_2=22,
	AM_MSG1 =13,
	AM_MSG2 =14,
	AM_MSG3 =15,
	AM_MSG4 =16,
	AM_MSG5 =17,
	AM_MSG6 =18,
	AM_MSG7 =19,

	SEND_CHECK_MILLIS=70000,
	TIMER_PERIOD_MILLI=150000,
	TIMER_FAST_PERIOD=200 ,
	WAIT_TO_START= 2, // 2 ms (Radio initialization takes 10.000000016 secs)
	TIMER_EPOCH = 60 * 1024, // 60 secs
	LEVEL_TIME = 4 * 102 , // 400 ms
};

typedef nx_struct RoutingMsg_2_1 // 2.1 RoutingMSG
{
	nx_uint8_t depth;
	nx_uint8_t choice;
} RoutingMsg_2_1;

typedef nx_struct RoutingMsg_2_2 // TinA RoutingMSG
{
	nx_uint8_t depth;
	nx_uint8_t choice;
	nx_uint8_t TCT;
} RoutingMsg_2_2;

typedef nx_struct Message1 // sum
{
	nx_uint16_t sum;
} Message1;

typedef nx_struct Message2 // count,min,max
{
	nx_uint8_t num;
} Message2;

typedef nx_struct Message3 // AVG,{sum,count},{sum,min},{sum,max},{sum,AVG},{count,AVG}
{
	nx_uint16_t num1; // sum
	nx_uint8_t num2; // count or max or min
} Message3;

typedef nx_struct Message4 // VAR,{sum,VAR},{count,VAR},{AVG,VAR}
{
	nx_uint32_t num1; // sum of (value^2)
	nx_uint16_t num2; // sum
	nx_uint8_t num3; // count
} Message4;

typedef nx_struct Message5 // {count,min},{count,max},{min,max}
{
	nx_uint8_t num1; // count,min
	nx_uint8_t num2; // min,max
} Message5;

typedef nx_struct Message6 // {min,AVG},{max,AVG}
{
	nx_uint16_t num1; // sum
	nx_uint8_t num2; // count
	nx_uint8_t num3; // min,max
} Message6;

typedef nx_struct Message7 // {min,VAR},{max,VAR}
{
	nx_uint32_t num1; // sum of (value^2)
	nx_uint16_t num2; // sum
	nx_uint8_t num3; // count
	nx_uint8_t num4; // min,max
} Message7;

#endif
