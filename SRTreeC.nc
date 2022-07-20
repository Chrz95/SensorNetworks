#include "SimpleRoutingTree.h"
#include <time.h>
/*#ifdef PRINTFDBG_MODE
	#include "printf.h"
#endif*/

module SRTreeC
{
	uses interface Boot;
	uses interface SplitControl as RadioControl;
	uses interface Random;
	uses interface ParameterInit<uint16_t> as Seed;

	uses interface Timer<TMilli> as RoutingMsgTimer;
	uses interface Timer<TMilli> as LostTaskTimer;
	uses interface Timer<TMilli> as EpochTimer;
	uses interface Timer<TMilli> as WaitforWakeUpTimer;
	uses interface Timer<TMilli> as ChildrenTimer;
	uses interface Timer<TMilli> as LevelTimer;
	uses interface Timer<TMilli> as CalcValTimer;

	uses interface Packet as Routing_2_1_Packet;
	uses interface AMSend as Routing_2_1_AMSend;
	uses interface AMPacket as Routing_2_1_AMPacket;
	uses interface Receive as Routing_2_1_Receive;
	uses interface PacketQueue as Routing_2_1_SendQueue;
	uses interface PacketQueue as Routing_2_1_ReceiveQueue;

	uses interface Packet as Routing_2_2_Packet;
	uses interface AMSend as Routing_2_2_AMSend;
	uses interface AMPacket as Routing_2_2_AMPacket;
	uses interface Receive as Routing_2_2_Receive;
	uses interface PacketQueue as Routing_2_2_SendQueue;
	uses interface PacketQueue as Routing_2_2_ReceiveQueue;

	uses interface AMSend as MSG1AMSend;
	uses interface AMPacket as MSG1AMPacket;
	uses interface Packet as MSG1Packet;
	uses interface Receive as MSG1Receive ;
	uses interface PacketQueue as MSG1SendQueue;
	uses interface PacketQueue as MSG1ReceiveQueue;

	uses interface AMSend as MSG2AMSend;
	uses interface AMPacket as MSG2AMPacket;
	uses interface Packet as MSG2Packet;
	uses interface Receive as MSG2Receive ;
	uses interface PacketQueue as MSG2SendQueue;
	uses interface PacketQueue as MSG2ReceiveQueue;

	uses interface AMSend as MSG3AMSend;
	uses interface AMPacket as MSG3AMPacket;
	uses interface Packet as MSG3Packet;
	uses interface Receive as MSG3Receive ;
	uses interface PacketQueue as MSG3SendQueue;
	uses interface PacketQueue as MSG3ReceiveQueue;

	uses interface AMSend as MSG4AMSend;
	uses interface AMPacket as MSG4AMPacket;
	uses interface Packet as MSG4Packet;
	uses interface Receive as MSG4Receive ;
	uses interface PacketQueue as MSG4SendQueue;
	uses interface PacketQueue as MSG4ReceiveQueue;

	uses interface AMSend as MSG5AMSend;
	uses interface AMPacket as MSG5AMPacket;
	uses interface Packet as MSG5Packet;
	uses interface Receive as MSG5Receive ;
	uses interface PacketQueue as MSG5SendQueue;
	uses interface PacketQueue as MSG5ReceiveQueue;

	uses interface AMSend as MSG6AMSend;
	uses interface AMPacket as MSG6AMPacket;
	uses interface Packet as MSG6Packet;
	uses interface Receive as MSG6Receive ;
	uses interface PacketQueue as MSG6SendQueue;
	uses interface PacketQueue as MSG6ReceiveQueue;

	uses interface AMSend as MSG7AMSend;
	uses interface AMPacket as MSG7AMPacket;
	uses interface Packet as MSG7Packet;
	uses interface Receive as MSG7Receive ;
	uses interface PacketQueue as MSG7SendQueue;
	uses interface PacketQueue as MSG7ReceiveQueue;
}
implementation
{
	uint8_t roundCounter = 0 ;
	uint8_t epochCounter = 0 ;
	uint8_t epochs = 0 ;
	uint8_t dataCounter = 0;
	uint8_t seedCounter = 0;
	uint8_t max_level = 16 ;
	uint8_t numOfChildren = 63;
	bool Choice = FALSE;

	uint8_t  mainVal = 0;
	uint16_t mySum = 0 ;
	uint32_t mySum_2 = 0 ;
	uint8_t myCount = 1 ;
	uint8_t myMax = 0 ;
	uint8_t myMin = 0 ;
	float myVAR = 0 ;
	float myAVG = 0;

	Message1* DataMsgRecPkt1;
	Message2* DataMsgRecPkt2;
	Message3* DataMsgRecPkt3;
	Message4* DataMsgRecPkt4;
	Message5* DataMsgRecPkt5;
	Message6* DataMsgRecPkt6;
	Message7* DataMsgRecPkt7;

	uint8_t TCT ; // [0-100]
	bool TctFlag = TRUE;
	uint8_t choice_2_1_or_2_2 ;// 1 or 2
	uint8_t choice_how_many_aggr; // 1 or 2
	uint8_t AggFunction1 ; // 1-6 or 1-4
	uint8_t AggFunction2 ; // 1-6 or 1-4

	struct ValueReg
	{
		uint8_t senderID ;
		uint16_t sum;
		uint32_t sum_2;
		uint8_t count;
		uint8_t max ;
		uint8_t min ;
	} ;

struct ValueReg childrenVals[63] ;

	message_t radioRoutingSendPkt;
	message_t DataMSGSendPkt;
	message_t* ReceivedMessage;

	bool RoutingSendBusy=FALSE;
	bool DataMSGSendBusy=FALSE;

	bool lostRoutingSendTask=FALSE;
	bool lostRoutingRecTask=FALSE;

	uint8_t curdepth;
	uint8_t parentID;
	uint16_t oldValue ;

	task void sendRoutingTask1();
	task void receiveRoutingTask1();

	task void sendRoutingTask2();
	task void receiveRoutingTask2();

	task void sendDataMsg1();
	task void receiveDataMsg1();

	task void sendDataMsg2();
	task void receiveDataMsg2();

	task void sendDataMsg3();
	task void receiveDataMsg3();

	task void sendDataMsg4();
	task void receiveDataMsg4();

	task void sendDataMsg5();
	task void receiveDataMsg5();

	task void sendDataMsg6();
	task void receiveDataMsg6();

	task void sendDataMsg7();
	task void receiveDataMsg7();

	message_t output ;

	void setLostRoutingSendTask(bool state)
	{
		atomic{
			lostRoutingSendTask=state;
		}
	}

	void setLostRoutingRecTask(bool state)
	{
		atomic{
		lostRoutingRecTask=state;
		}
	}

	void setRoutingSendBusy(bool state)
	{
		atomic{
		RoutingSendBusy=state;
		}
	}

void calc_SUM(uint8_t type_of_str)
{
	uint8_t i = 0 ;

	while ((i<= numOfChildren - 1) && (childrenVals[i].senderID != 0)) // Calculate your new values
	{
		mySum += childrenVals[i].sum ;
		i++ ;
	}

	if (type_of_str == 1) //Choose type of struct to save the value depending on the type of message
		DataMsgRecPkt1->sum = mySum;
	else if (type_of_str == 3)
		DataMsgRecPkt3->num1 = mySum;
	else if (type_of_str == 4)
		DataMsgRecPkt4->num2 = mySum;
	else if (type_of_str == 6)
		DataMsgRecPkt6->num1 = mySum;
	else if (type_of_str == 7)
		DataMsgRecPkt7->num2 = mySum;
}

void calc_SUM_2(uint8_t type_of_str)
{
	uint8_t i = 0 ;

	while ((i<= numOfChildren - 1) && (childrenVals[i].senderID != 0)) // Calculate your new values
	{
		mySum_2 += childrenVals[i].sum_2 ;
		i++ ;
	}

	if (type_of_str == 4) //Choose type of struct to save the value depending on the type of message
		DataMsgRecPkt4->num1 = mySum_2;
	else if (type_of_str == 7)
		DataMsgRecPkt7->num1 = mySum_2;

}

void calc_COUNT(uint8_t type_of_str)
{
	uint8_t i = 0 ;

	while ((i<= numOfChildren - 1) && (childrenVals[i].senderID != 0)) // Calculate your new values
	{
		myCount += childrenVals[i].count;
		i++ ;
	}

	if (type_of_str == 2) //Choose type of struct to save the value depending on the type of message
		DataMsgRecPkt2->num = myCount;
	else if (type_of_str == 3)
		DataMsgRecPkt3->num2 = myCount;
	else if (type_of_str == 4)
		DataMsgRecPkt4->num3 = myCount;
	else if (type_of_str == 5)
		DataMsgRecPkt5->num1 = myCount;
	else if (type_of_str == 6)
		DataMsgRecPkt6->num2 = myCount;
	else if (type_of_str == 7)
		DataMsgRecPkt7->num3 = myCount;
}

void calc_MAX(uint8_t type_of_str)
{
	uint8_t i = 0 ;

	while ((i<= numOfChildren - 1) && (childrenVals[i].senderID != 0)) // Calculate your new values
	{
		if ((childrenVals[i].max > myMax))
		{
			myMax = childrenVals[i].max;
		}
		i++ ;
	}

	if (type_of_str == 2)//Choose type of struct to save the value depending on the type of message
		DataMsgRecPkt2->num = myMax;
	else if (type_of_str == 3)
		DataMsgRecPkt3->num2 = myMax;
	else if (type_of_str == 5)
		DataMsgRecPkt5->num2 = myMax;
	else if (type_of_str == 6)
		DataMsgRecPkt6->num3 = myMax;
	else if (type_of_str == 7)
		DataMsgRecPkt7->num4 = myMax;

}

void calc_MIN(uint8_t type_of_str,uint8_t pos)
{
	uint8_t i = 0 ;

	while ((i<= numOfChildren - 1) && (childrenVals[i].senderID != 0)) // Calculate your new values
	{
		if ((childrenVals[i].min < myMin))
		{
			myMin = childrenVals[i].min;
		}
		i++ ;
	}

	if (type_of_str == 2)//Choose type of struct to save the value depending on the type of message
		DataMsgRecPkt2->num = myMin;
	else if (type_of_str == 3)
		DataMsgRecPkt3->num2 = myMin;
	else if (type_of_str == 5)
		if (pos == 0)
			DataMsgRecPkt5->num1 = myMin;
		if (pos == 1)
			DataMsgRecPkt5->num2 = myMin;
	else if (type_of_str == 6)
		DataMsgRecPkt6->num3 = myMin;
	else if (type_of_str == 7)
		DataMsgRecPkt7->num4 = myMin;

}

void calc_AVG(uint8_t type_of_str)
{
	calc_SUM(type_of_str);
	calc_COUNT(type_of_str);

	myAVG = (float) mySum / (float) myCount;
}

void calc_VAR(uint8_t type_of_str)
{
	calc_AVG(type_of_str);
	calc_SUM_2(type_of_str);

	myVAR = ((float) mySum_2)/((float) myCount) - myAVG*myAVG;
}

void calculations() // Calculate aggragates for every value of the choice_2_1_or_2_2,AggFunction1,AggFunction2 parameters and print msg
{
	if (choice_2_1_or_2_2 == 1) // 2.1
	{
		if ((AggFunction1 == 1) && (AggFunction2 == 0))
		{
			calc_SUM(1);
			dbg("SRTreeC", "Node %u Results : (Sum) = (%u)\n",TOS_NODE_ID ,mySum);
		}
		else if ((AggFunction1 == 2) && (AggFunction2 == 0))
		{
			calc_COUNT(2);
			dbg("SRTreeC", "Node %u Results : (Count) = (%u)\n",TOS_NODE_ID ,myCount);
		}
		else if ((AggFunction1 == 3) && (AggFunction2 == 0))
		{
			calc_MIN(2,0);
			dbg("SRTreeC", "Node %u Results : (Min) = (%u)\n",TOS_NODE_ID ,myMin);
		}
		else if ((AggFunction1 == 4) && (AggFunction2 == 0))
		{
			calc_MAX(2);
			dbg("SRTreeC", "Node %u Results : (Max) = (%u)\n",TOS_NODE_ID ,myMax);
		}
		else if ((AggFunction1 == 5) && (AggFunction2 == 0))
		{
			calc_AVG(3);
			dbg("SRTreeC", "Node %u Results : (AVG) = (%0.3f)\n",TOS_NODE_ID ,myAVG);
		}
		else if ((AggFunction1 == 6) && (AggFunction2 == 0))
		{
			calc_VAR(4);
			dbg("SRTreeC", "Node %u Results : (VAR) = (%0.3f)\n",TOS_NODE_ID ,myVAR);
		}
		else if ((AggFunction1 == 1) && (AggFunction2 == 2))
		{
			calc_SUM(3);
			calc_COUNT(3);
			dbg("SRTreeC", "Node %u Results : (Sum,Count) = (%u,%u)\n",TOS_NODE_ID ,mySum,myCount);
		}
		else if ((AggFunction1 == 1) && (AggFunction2 == 3))
		{
			calc_SUM(3);
			calc_MIN(3,0);
			dbg("SRTreeC", "Node %u Results : (Sum,Min) = (%u,%u)\n",TOS_NODE_ID ,mySum,myMin);
		}
		else if ((AggFunction1 == 1) && (AggFunction2 == 4))
		{
			calc_SUM(3);
			calc_MAX(3);
			dbg("SRTreeC", "Node %u Results : (Sum,Max) = (%u,%u)\n",TOS_NODE_ID ,mySum,myMax);
		}
		else if ((AggFunction1 == 1) && (AggFunction2 == 5))
		{
			calc_AVG(3);
			dbg("SRTreeC", "Node %u Results : (Sum,AVG) = (%u,%0.3f)\n",TOS_NODE_ID ,mySum,myAVG);
		}
		else if ((AggFunction1 == 1) && (AggFunction2 == 6))
		{
			calc_VAR(4);
			dbg("SRTreeC", "Node %u Results : (Sum,VAR) = (%u,%0.3f)\n",TOS_NODE_ID ,mySum,myVAR);
		}
		else if ((AggFunction1 == 2) && (AggFunction2 == 3))
		{
			calc_COUNT(5);
			calc_MIN(5,2);
			dbg("SRTreeC", "Node %u Results : (Count,Min) = (%u,%u)\n",TOS_NODE_ID ,myCount,myMin);
		}
		else if ((AggFunction1 == 2) && (AggFunction2 == 4))
		{
			calc_COUNT(5);
			calc_MAX(5);
			dbg("SRTreeC", "Node %u Results : (Count,Max) = (%u,%u)\n",TOS_NODE_ID ,myCount,myMax);
		}
		else if ((AggFunction1 == 2) && (AggFunction2 == 5))
		{
			calc_AVG(3);
			dbg("SRTreeC", "Node %u Results : (Count,AVG) = (%u,%0.3f))\n",TOS_NODE_ID ,myCount,myAVG);
		}
		else if ((AggFunction1 == 2) && (AggFunction2 == 6))
		{
			calc_VAR(4);
			dbg("SRTreeC", "Node %u Results : (Count,VAR) = (%u,%0.3f)\n",TOS_NODE_ID ,myCount,myVAR);
		}
		else if ((AggFunction1 == 3) && (AggFunction2 == 4))
		{
			calc_MIN(5,1);
			calc_MAX(5);
			dbg("SRTreeC", "Node %u Results : (Min,Max) = (%u,%u)\n",TOS_NODE_ID ,myMin,myMax);
		}
		else if ((AggFunction1 == 3) && (AggFunction2 == 5))
		{
			calc_MIN(6,0);
			calc_AVG(6);
			dbg("SRTreeC", "Node %u Results : (Min,AVG) = (%u,%0.3f)\n",TOS_NODE_ID ,myMin,myAVG);
		}
		else if ((AggFunction1 == 3) && (AggFunction2 == 6))
		{
			calc_MIN(7,0);
			calc_VAR(7);
			dbg("SRTreeC", "Node %u Results : (Min,VAR) = (%u,%0.3f)\n",TOS_NODE_ID ,myMin,myVAR);
		}
		else if ((AggFunction1 == 4) && (AggFunction2 == 5))
		{
			calc_MAX(6);
			calc_AVG(6);
			dbg("SRTreeC", "Node %u Results : (Max,AVG) = (%u,%0.3f)\n",TOS_NODE_ID ,myMax,myAVG);
		}
		else if ((AggFunction1 == 4) && (AggFunction2 == 6))
		{
			calc_MAX(7);
			calc_VAR(7);
			dbg("SRTreeC", "Node %u Results : (Max,VAR) = (%u,%0.3f)\n",TOS_NODE_ID ,myMax,myVAR);
		}
		else if ((AggFunction1 == 5) && (AggFunction2 == 6))
		{
			calc_VAR(4);
			dbg("SRTreeC", "Node %u Results : (AVG,VAR) = (%0.3f,%0.3f)\n",TOS_NODE_ID ,myAVG,myVAR);
		}
	}
	else if (choice_2_1_or_2_2 == 2) // 2.2 TiNA
	{
		if (AggFunction1 == 1)
		{
			calc_SUM(1);

			if(oldValue == 0) // Send Message
			{
				TctFlag = TRUE;
				if (TOS_NODE_ID !=0)
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u\n",TOS_NODE_ID,oldValue,mySum);
			}
			else if (((float)abs(oldValue - mySum))/((float) abs(oldValue))  > ((float) ((float) (TCT))/100.0)) // Send Message
			{
				TctFlag = TRUE;
				if (TOS_NODE_ID !=0)
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u,Difference = %0.3f %\n",TOS_NODE_ID,oldValue,mySum,(((float)abs(oldValue - mySum))/((float) abs(oldValue)))*100);
			}
			else // Dont send Message
			{
				TctFlag = FALSE;
				if (TOS_NODE_ID != 0) // Node 0 never sends
				{
					dbg("SRTreeC", "Node %u will not send this epoch!!!\n",TOS_NODE_ID);
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u,Difference = %0.3f %\n",TOS_NODE_ID,oldValue,mySum,(((float)abs(oldValue - mySum))/((float) abs(oldValue)))*100);
					mySum = oldValue ;
				}
			}
			dbg("SRTreeC", "Node %u Results : (Sum) = (%u)\n",TOS_NODE_ID,mySum);
		}
		else if (AggFunction1 == 2)
		{
			calc_COUNT(2);

			if(oldValue == 0) // Send Message
			{
				TctFlag = TRUE;
				if (TOS_NODE_ID !=0)
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u\n",TOS_NODE_ID,oldValue,myCount);
			}
			else if (((float)abs(oldValue - myCount))/((float) abs(oldValue))  > ((float) ((float) (TCT))/100.0)) // Send Message
			{
				TctFlag = TRUE;
				if (TOS_NODE_ID !=0)
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u,Difference = %0.3f %\n",TOS_NODE_ID,oldValue,myCount,(((float)abs(oldValue - myCount))/((float) abs(oldValue)))*100);
			}
			else //Dont send Message
			{
				TctFlag = FALSE;
				if (TOS_NODE_ID != 0) // Node 0 never sends
				{
					dbg("SRTreeC", "Node %u will not send this epoch!!!\n",TOS_NODE_ID);
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u,Difference = %0.3f %\n",TOS_NODE_ID,oldValue,myCount,(((float)abs(oldValue - myCount))/((float) abs(oldValue)))*100);
					myCount = oldValue ;
				}
			}
			dbg("SRTreeC", "Node %u Results : (Count) = (%u)\n",TOS_NODE_ID,myCount);
		}
		else if (AggFunction1 == 3)
		{
			calc_MIN(2,0);

			if(oldValue == 0) // Send Message
			{
				TctFlag = TRUE;
				if (TOS_NODE_ID !=0)
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u\n",TOS_NODE_ID,oldValue,myMin);
			}
			else if (((float)abs(oldValue - myMin))/((float) abs(oldValue))  > ((float) ((float) (TCT))/100.0)) // Send Message
			{
				TctFlag = TRUE;
				if (TOS_NODE_ID !=0)
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u,Difference = %0.3f %\n",TOS_NODE_ID,oldValue,myMin,(((float)abs(oldValue - myMin))/((float) abs(oldValue)))*100);
			}
			else //Dont send Message
			{
				TctFlag = FALSE;
				if (TOS_NODE_ID != 0) // Node 0 never sends
				{
					dbg("SRTreeC", "Node %u will not send this epoch!!!\n",TOS_NODE_ID);
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u,Difference = %0.3f %\n",TOS_NODE_ID,oldValue,myMin,(((float)abs(oldValue - myMin))/((float) abs(oldValue)))*100);
					myMin = oldValue ;
				}
			}
			dbg("SRTreeC", "Node %u Results : (Min) = (%u)\n",TOS_NODE_ID,myMin);
		}
		else if (AggFunction1 == 4)
		{
			calc_MAX(2);

			if(oldValue == 0) // Send Message
			{
				TctFlag = TRUE;
				if (TOS_NODE_ID !=0)
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u\n",TOS_NODE_ID,oldValue,myMax);
			}
			else if (((float)abs(oldValue - myMax))/((float) abs(oldValue))  > ((float) ((float) (TCT))/100.0)) // Send Message
			{
				TctFlag = TRUE;
				if (TOS_NODE_ID !=0)
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u,Difference = %0.3f %\n",TOS_NODE_ID,oldValue,myMax,(((float)abs(oldValue - myMax))/((float) abs(oldValue)))*100);
			}
			else //Dont send Message
			{
				TctFlag = FALSE;
				if (TOS_NODE_ID != 0) // Node 0 never sends
				{
					dbg("SRTreeC", "Node %u will not send this epoch!!!\n",TOS_NODE_ID);
					dbg("SRTreeC", "Node %u : Old Value = %u,New Value = %u,Difference = %0.3f %\n",TOS_NODE_ID,oldValue,myMax,(((float)abs(oldValue - myMax))/((float) abs(oldValue)))*100);
					myMax = oldValue ;
				}
			}
			dbg("SRTreeC", "Node %u Results : (Max) = (%u)\n",TOS_NODE_ID,myMax);
		}
	}
}

	uint16_t randomSeed()
	{
		struct tm *ltm;
		time_t now = time(0);

		seedCounter++ ;
		ltm = localtime(&now);
		return (uint16_t) ((ltm->tm_hour + ltm->tm_min + 5*ltm->tm_sec) + 2*TOS_NODE_ID + ltm->tm_mday*epochCounter + curdepth + seedCounter);
	}

	event void Boot.booted()
	{
		// arxikopoiisi radio kai serial
		call RadioControl.start();

		setRoutingSendBusy(FALSE);

		roundCounter = 0;

		if(TOS_NODE_ID==0)
		{
			curdepth=0;
			parentID=0;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
		}
		else
		{
			curdepth=-1;
			parentID=-1;
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);
		}
	}

	event void RadioControl.startDone(error_t err)
	{
		if (err == SUCCESS)
		{
			dbg("Radio" , "Radio initialized successfully!!!\n");
			call WaitforWakeUpTimer.startOneShot(WAIT_TO_START); // Delay Timer
		}
		else
		{
			dbg("Radio" , "Radio initialization failed! Retrying...\n");
			call RadioControl.start();
		}
	}

	event void RadioControl.stopDone(error_t err)
	{
		dbg("Radio", "Radio stopped!\n");
	}

	event void LostTaskTimer.fired()
	{
		if (lostRoutingSendTask)
		{
			post sendRoutingTask1();
			setLostRoutingSendTask(FALSE);
		}

		if (lostRoutingRecTask)
		{
			post receiveRoutingTask1();
			setLostRoutingRecTask(FALSE);
		}
	}

	// Timers

	event void WaitforWakeUpTimer.fired() // Creates a delay to stall routing until Radio for all nodes is ready
	{
		 //dbg("SRTreeC","WaitforWakeUpTimer fired!\n");
		 if (TOS_NODE_ID==0)
		 {
			 call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD); // Call at round one only
		 }
		 call EpochTimer.startPeriodic(TIMER_EPOCH); // Starts epoch every 60 secs
	}

	event void EpochTimer.fired()
	{
		 call Seed.init(randomSeed());
		 mainVal = (uint8_t) ((call Random.rand16()) % (50 + 1)); // [0,50]
		 dataCounter = 0 ; // Start entering data from the beginning of the arrays

		 //Set old values for TCT depending on epoch

if (choice_2_1_or_2_2 == 2)
{
	if (epochs == 0)
 		oldValue = 0 ;
  else
  {
 		if (AggFunction1 == 1)
 			oldValue = mySum ;
 		else if (AggFunction1 == 2)
 			oldValue = myCount ;
 		else if (AggFunction1 == 3)
 			oldValue = myMin ;
 		else if (AggFunction1 == 4)
 			oldValue = myMax ;
  }
}
			epochs++ ;

			//intitialize the values (will change with calculations())
		 mySum = mainVal;
		 mySum_2 = mainVal*mainVal;
		 myMax = mainVal;
		 myMin = mainVal;
		 myCount = 1 ;
		 myAVG = mainVal;
		 myVAR = mainVal ;

		 if (TOS_NODE_ID==0)
		 {
			 	dbg("SRTreeC", "\n \t \t \t    ##################################### \n");
			 	dbg("SRTreeC", "#######   EPOCH   %u    ############## \n", epochCounter);
			 	dbg("SRTreeC", "#####################################\n\n");

				epochCounter += 1;


				//Printing messages
				dbg("SRTreeC","Question : 2_%u\n",choice_2_1_or_2_2);
				dbg("SRTreeC","None->0,Sum->1,Count->2,Min->3,Max->4,AVG->5,VAR->6\n");
				dbg("SRTreeC","Aggregate Functions : (%u,%u)\n",AggFunction1,AggFunction2);

				if (choice_2_1_or_2_2 == 1)
							dbg("SRTreeC","\n");

				if (choice_2_1_or_2_2 == 2)
						dbg("SRTreeC","TCT = %u %\n\n",TCT);
		 }

		 dbg("SRTreeC", "Node value: %d \n" , mainVal);

		 // To avoid segmentation faults we initialize the data structs that we will need HERE depending on the parameters

		if (choice_2_1_or_2_2 == 1) // 2.1
		{
			if ((AggFunction1 == 1) && (AggFunction2 == 0))
			{
				DataMsgRecPkt1 = (Message1*) (call MSG1Packet.getPayload(&DataMSGSendPkt,sizeof(Message1)));
				if(DataMsgRecPkt1 == NULL)	 	{return;}
			}
			else if (((AggFunction1 == 2) && (AggFunction2 == 0)) || ((AggFunction1 == 3) && (AggFunction2 == 0)) || ((AggFunction1 == 4) && (AggFunction2 == 0)))
			{
				DataMsgRecPkt2 = (Message2*) (call MSG2Packet.getPayload(&DataMSGSendPkt,sizeof(Message2)));
				if(DataMsgRecPkt2 == NULL)	 	{return;}
			}
			else if (((AggFunction1 == 5) && (AggFunction2 == 0)) || ((AggFunction1 == 1) && (AggFunction2 == 2)) || ((AggFunction1 == 1) && (AggFunction2 == 3)) || ((AggFunction1 == 1) && (AggFunction2 == 4)) || ((AggFunction1 == 1) && (AggFunction2 == 5)) || ((AggFunction1 == 2) && (AggFunction2 == 5)))
			{
				DataMsgRecPkt3 = (Message3*) (call MSG3Packet.getPayload(&DataMSGSendPkt,sizeof(Message3)));
				if(DataMsgRecPkt3 == NULL)	 	{return;}
			}
			else if (((AggFunction1 == 6) && (AggFunction2 == 0)) || ((AggFunction1 == 1) && (AggFunction2 == 6)) || ((AggFunction1 == 2) && (AggFunction2 == 6)) || ((AggFunction1 == 5) && (AggFunction2 == 6)))
			{
				DataMsgRecPkt4 = (Message4*) (call MSG4Packet.getPayload(&DataMSGSendPkt,sizeof(Message4)));
				if(DataMsgRecPkt4 == NULL)	 	{return;}
			}
			else if (((AggFunction1 == 2) && (AggFunction2 == 3)) || ((AggFunction1 == 2) && (AggFunction2 == 4)) || ((AggFunction1 == 3) && (AggFunction2 == 4)))
			{
				DataMsgRecPkt5 = (Message5*) (call MSG5Packet.getPayload(&DataMSGSendPkt,sizeof(Message5)));
				if(DataMsgRecPkt5 == NULL)	 	{return;}
			}
			else if (((AggFunction1 == 3) && (AggFunction2 == 5)) || ((AggFunction1 == 4) && (AggFunction2 == 5)))
			{
				DataMsgRecPkt6 = (Message6*) (call MSG6Packet.getPayload(&DataMSGSendPkt,sizeof(Message6)));
				if(DataMsgRecPkt6 == NULL)	 	{return;}
			}
			else if (((AggFunction1 == 3) && (AggFunction2 == 6)) || ((AggFunction1 == 4) && (AggFunction2 == 6)))
			{
				DataMsgRecPkt7 = (Message7*) (call MSG7Packet.getPayload(&DataMSGSendPkt,sizeof(Message7)));
				if(DataMsgRecPkt7 == NULL)	 	{return;}
			}
		}
		else if (choice_2_1_or_2_2 == 2) // 2.2 TiNA
		{
			if (AggFunction1 == 1) // sum
			{
				DataMsgRecPkt1 = (Message1*) (call MSG1Packet.getPayload(&DataMSGSendPkt,sizeof(Message1)));
				if(DataMsgRecPkt1 == NULL)	 	{return;}
			}
			else if (AggFunction1 == 2) // count
			{
				DataMsgRecPkt2 = (Message2*) (call MSG2Packet.getPayload(&DataMSGSendPkt,sizeof(Message2)));
				if(DataMsgRecPkt2 == NULL)	 	{return;}
			}
			else if (AggFunction1 == 3) // min
			{
				DataMsgRecPkt2 = (Message2*) (call MSG2Packet.getPayload(&DataMSGSendPkt,sizeof(Message2)));
				if(DataMsgRecPkt2 == NULL)	 	{return;}
			}
			else if (AggFunction1 == 4) // max
			{
				DataMsgRecPkt2 = (Message2*) (call MSG2Packet.getPayload(&DataMSGSendPkt,sizeof(Message2)));
				if(DataMsgRecPkt2 == NULL)	 	{return;}
			}
		}

		call LevelTimer.startOneShot(LEVEL_TIME*(max_level - curdepth) + 100); // +100 so that the nodes dont start sending at the beginning of the epoch
	}

	event void LevelTimer.fired()
	{
		if (TOS_NODE_ID != 0) // All nodes except 0 send messages
		{
			call Seed.init(randomSeed());
			call ChildrenTimer.startOneShot((call Random.rand16()) % (LEVEL_TIME - 20 - 10) + 10); // [10,LEVEL_TIME - 20]
		}

		call CalcValTimer.startOneShot(10); //so that we process the values (the father of the children does) t=processtime before the next level/ we have made it so that all nodes have sent their messages by that point
		//  + 10 in case of the worst scenario that a child sends exactly at LEVEL_TIME - PROCESSTIME
	}

	event void CalcValTimer.fired()
	{
		// Calculate my values from children values
		calculations() ;
	}

	event void ChildrenTimer.fired()
	{
		//Check what aggregate functions were choosen and send respective message (1-7) (post respective task)

		if (choice_2_1_or_2_2 == 1) // 2.1
		{
			if ((AggFunction1 == 1) && (AggFunction2 == 0))
				post sendDataMsg1();
			else if (((AggFunction1 == 2) && (AggFunction2 == 0)) || ((AggFunction1 == 3) && (AggFunction2 == 0)) || ((AggFunction1 == 4) && (AggFunction2 == 0)))
				post sendDataMsg2();
			else if (((AggFunction1 == 5) && (AggFunction2 == 0)) || ((AggFunction1 == 1) && (AggFunction2 == 2)) || ((AggFunction1 == 1) && (AggFunction2 == 3)) || ((AggFunction1 == 1) && (AggFunction2 == 4)) || ((AggFunction1 == 1) && (AggFunction2 == 5)) || ((AggFunction1 == 2) && (AggFunction2 == 5)))
				post sendDataMsg3();
			else if (((AggFunction1 == 6) && (AggFunction2 == 0)) || ((AggFunction1 == 1) && (AggFunction2 == 6)) || ((AggFunction1 == 2) && (AggFunction2 == 6)) || ((AggFunction1 == 5) && (AggFunction2 == 6)))
				post sendDataMsg4();
			else if (((AggFunction1 == 2) && (AggFunction2 == 3)) || ((AggFunction1 == 2) && (AggFunction2 == 4)) || ((AggFunction1 == 3) && (AggFunction2 == 4)))
				post sendDataMsg5();
			else if (((AggFunction1 == 3) && (AggFunction2 == 5)) || ((AggFunction1 == 4) && (AggFunction2 == 5)))
				post sendDataMsg6();
			else if (((AggFunction1 == 3) && (AggFunction2 == 6)) || ((AggFunction1 == 4) && (AggFunction2 == 6)))
				post sendDataMsg7();
		}
		else if (choice_2_1_or_2_2 == 2) // 2.2 TiNA
		{
			if ((AggFunction1 == 1) && (TctFlag == TRUE)) // sum
				post sendDataMsg1();
			else if ((AggFunction1 == 2) && (TctFlag == TRUE))  // count
				post sendDataMsg2();
			else if ((AggFunction1 == 3) && (TctFlag == TRUE)) // min
				post sendDataMsg2();
			else if ((AggFunction1 == 4) && (TctFlag == TRUE))  // max
				post sendDataMsg2();
		}
	}

// Send related functions

	event void MSG1AMSend.sendDone(message_t * msg , error_t err)
	{

		DataMSGSendBusy = FALSE ;

	if(!(call MSG1SendQueue.empty()))
		{
			post sendDataMsg1();
		}
	}

	event void MSG2AMSend.sendDone(message_t * msg , error_t err)
	{


		DataMSGSendBusy = FALSE ;

	if(!(call MSG2SendQueue.empty()))
		{
			post sendDataMsg2();
		}
	}

	event void MSG3AMSend.sendDone(message_t * msg , error_t err)
	{


		DataMSGSendBusy = FALSE ;

	if(!(call MSG3SendQueue.empty()))
		{
			post sendDataMsg3();
		}
	}

	event void MSG4AMSend.sendDone(message_t * msg , error_t err)
	{
		DataMSGSendBusy = FALSE ;

	if(!(call MSG4SendQueue.empty()))
		{
			post sendDataMsg4();
		}
	}

	event void MSG5AMSend.sendDone(message_t * msg , error_t err)
	{


		DataMSGSendBusy = FALSE ;

	if(!(call MSG5SendQueue.empty()))
		{
			post sendDataMsg5();
		}
	}

	event void MSG6AMSend.sendDone(message_t * msg , error_t err)
	{

		DataMSGSendBusy = FALSE ;

	if(!(call MSG6SendQueue.empty()))
		{
			post sendDataMsg6();
		}
	}

	event void MSG7AMSend.sendDone(message_t * msg , error_t err)
	{
			DataMSGSendBusy = FALSE ;

			if(!(call MSG7SendQueue.empty()))
			{
					post sendDataMsg7();
			}
	}

// Send related tasks

	task void sendDataMsg1 ()
	{
		error_t enqueueDone , sendDone ;

		// Set the values to the struct that we will send , will change if not leaf
		DataMsgRecPkt1->sum = mySum;
		dbg("SRTreeC","Child %u ==> (Sum) = (%u) ==> Parent %u\n",TOS_NODE_ID,mySum,parentID); // Sending Message

		call MSG1AMPacket.setDestination(&DataMSGSendPkt,parentID);
		call MSG1Packet.setPayloadLength(&DataMSGSendPkt,sizeof(Message1));

		enqueueDone = call MSG1SendQueue.enqueue(DataMSGSendPkt);

		if(call MSG1SendQueue.full())
		{
				dbg("SRTreeC","MSG1SendQueue is FULL!!! \n");
				return;
		}

		if (enqueueDone==SUCCESS) // && (!DataMSGSendBusy)
		{
		 if (call MSG1SendQueue.size()==1)
		 {
				if (TOS_NODE_ID != parentID)
				{
					if (call MSG1SendQueue.empty()) // Has no messages to send
					{
						dbg("SRTreeC","sendDataMsg1(): Q is empty!\n");
						return;
					}

					if(DataMSGSendBusy) // Cant send messages
					{
						dbg("SRTreeC","sendDataMsg1(): DataMSGSendBusy= TRUE!!!\n");
						return;
					}

					DataMSGSendPkt = call MSG1SendQueue.dequeue();

					// Send the message

					sendDone = call MSG1AMSend.send(parentID,&DataMSGSendPkt,sizeof(Message1));

					if (sendDone== SUCCESS)
					{
						DataMSGSendBusy = TRUE ;
					}
					else
					{
						dbg("SRTreeC","Send failed!!!\n");
					}
			}
		 }
		//	dbg("SRTreeC","DataMsg enqueued successfully in MSG1SendQueue!!!\n");
		}
		else
		{
			dbg("SRTreeC","DataMsg failed to be enqueued in MSG1SendQueue!!!");
		}
	}

	task void sendDataMsg2 ()
	{
		error_t enqueueDone , sendDone ;

		// Set the values to the struct that we will send , will change if not leaf
		if (AggFunction1 == 2)
		{
			DataMsgRecPkt2->num = myCount;
			dbg("SRTreeC","Child %u ==> (Count) = (%u) ==> Parent %u\n",TOS_NODE_ID,myCount,parentID); // Sending Message
		}
		else if (AggFunction1 == 3)
		{
			DataMsgRecPkt2->num = myMin;
			dbg("SRTreeC","Child %u ==> (Min) = (%u) ==> Parent %u\n",TOS_NODE_ID,myMin,parentID); // Sending Message
		}
		else if (AggFunction1 == 4)
		{
			DataMsgRecPkt2->num = myMax;
			dbg("SRTreeC","Child %u ==> (Max) = (%u) ==> Parent %u\n",TOS_NODE_ID,myMax,parentID); // Sending Message
		}

		call MSG2AMPacket.setDestination(&DataMSGSendPkt,parentID);
		call MSG2Packet.setPayloadLength(&DataMSGSendPkt,sizeof(Message2));

		enqueueDone = call MSG2SendQueue.enqueue(DataMSGSendPkt);

		if(call MSG2SendQueue.full())
		{
				dbg("SRTreeC","MSG2SendQueue is FULL!!! \n");
				return;
		}

		if (enqueueDone==SUCCESS) // && (!DataMSGSendBusy)
		{
		 if (call MSG2SendQueue.size()==1)
		 {
				if (TOS_NODE_ID != parentID)
				{
					if (call MSG2SendQueue.empty()) // Has no messages to send
					{
						dbg("SRTreeC","sendDataMsg2(): Q is empty!\n");
						return;
					}

					if(DataMSGSendBusy) // Cant send messages
					{
						dbg("SRTreeC","sendDataMsg2(): DataMSGSendBusy= TRUE!!!\n");
						return;
					}

					DataMSGSendPkt = call MSG2SendQueue.dequeue();

					// Send the message

					sendDone = call MSG2AMSend.send(parentID,&DataMSGSendPkt,sizeof(Message2));

					if (sendDone== SUCCESS)
					{
						DataMSGSendBusy = TRUE ;
					}
					else
					{
						dbg("SRTreeC","Send failed!!!\n");
					}
			}
		 }
		//	dbg("SRTreeC","DataMsg enqueued successfully in MSG2SendQueue!!!\n");
		}
		else
		{
			dbg("SRTreeC","DataMsg failed to be enqueued in MSG2SendQueue!!!");
		}
	}

	task void sendDataMsg3 ()
	{
		error_t enqueueDone , sendDone ;

		// Set the values to the struct that we will send , will change if not leaf
		if (((AggFunction1 == 5) && (AggFunction2 == 0)) || ((AggFunction1 == 2) && (AggFunction2 == 5)) || ((AggFunction1 == 1) && (AggFunction2 == 5)) ||  ((AggFunction1 == 1) && (AggFunction2 == 2)))
		{
			DataMsgRecPkt3->num1 = mySum;
			DataMsgRecPkt3->num2 = myCount;
			dbg("SRTreeC","Child %u ==> (Sum,Count) = (%u,%u) ==> Parent %u\n",TOS_NODE_ID,mySum,myCount,parentID); // Sending Message
		}
		else if ((AggFunction1 == 1) && (AggFunction2 == 3))
		{
			DataMsgRecPkt3->num1 = mySum;
			DataMsgRecPkt3->num2 = myMin;
			dbg("SRTreeC","Child %u ==> (Sum,Min) = (%u,%u) ==> Parent %u\n",TOS_NODE_ID,mySum,myMin,parentID); // Sending Message
		}
		else if ((AggFunction1 == 1) && (AggFunction2 == 4))
		{
			DataMsgRecPkt3->num1 = mySum;
			DataMsgRecPkt3->num2 = myMax;
			dbg("SRTreeC","Child %u ==> (Sum,Max) = (%u,%u) ==> Parent %u\n",TOS_NODE_ID,mySum,myMax,parentID); // Sending Message
		}

		call MSG3AMPacket.setDestination(&DataMSGSendPkt,parentID);
		call MSG3Packet.setPayloadLength(&DataMSGSendPkt,sizeof(Message3));

		enqueueDone = call MSG3SendQueue.enqueue(DataMSGSendPkt);

		if(call MSG3SendQueue.full())
		{
				dbg("SRTreeC","MSG3SendQueue is FULL!!! \n");
				return;
		}

		if (enqueueDone==SUCCESS) // && (!DataMSGSendBusy)
		{
		 if (call MSG3SendQueue.size()==1)
		 {
				if (TOS_NODE_ID != parentID)
				{
					if (call MSG3SendQueue.empty()) // Has no messages to send
					{
						dbg("SRTreeC","sendDataMsg3(): Q is empty!\n");
						return;
					}

					if(DataMSGSendBusy) // Cant send messages
					{
						dbg("SRTreeC","sendDataMsg3(): DataMSGSendBusy= TRUE!!!\n");
						return;
					}

					DataMSGSendPkt = call MSG3SendQueue.dequeue();

					// Send the message

					sendDone = call MSG3AMSend.send(parentID,&DataMSGSendPkt,sizeof(Message3));

					if (sendDone== SUCCESS)
					{
						DataMSGSendBusy = TRUE ;
					}
					else
					{
						dbg("SRTreeC","Send failed!!!\n");
					}
			}
		 }
		//	dbg("SRTreeC","DataMsg enqueued successfully in MSG3SendQueue!!!\n");
		}
		else
		{
			dbg("SRTreeC","DataMsg failed to be enqueued in MSG3SendQueue!!!");
		}
	}

	task void sendDataMsg4 ()
	{
		error_t enqueueDone , sendDone ;

		// Set the values to the struct that we will send , will change if not leaf

		DataMsgRecPkt4->num1 = mySum_2;
		DataMsgRecPkt4->num2 = mySum;
		DataMsgRecPkt4->num3 = myCount;
		dbg("SRTreeC","Child %u ==> (Sum_2,Sum,Count) = (%u,%u,%u) ==> Parent %u\n",TOS_NODE_ID,mySum_2,mySum,myCount,parentID); // Sending Message

		call MSG4AMPacket.setDestination(&DataMSGSendPkt,parentID);
		call MSG4Packet.setPayloadLength(&DataMSGSendPkt,sizeof(Message4));

		enqueueDone = call MSG4SendQueue.enqueue(DataMSGSendPkt);

		if(call MSG4SendQueue.full())
		{
				dbg("SRTreeC","MSG4SendQueue is FULL!!! \n");
				return;
		}

		if (enqueueDone==SUCCESS) // && (!DataMSGSendBusy)
		{
		 if (call MSG4SendQueue.size()==1)
		 {
				if (TOS_NODE_ID != parentID)
				{
					if (call MSG4SendQueue.empty()) // Has no messages to send
					{
						dbg("SRTreeC","sendDataMsg4(): Q is empty!\n");
						return;
					}

					if(DataMSGSendBusy) // Cant send messages
					{
						dbg("SRTreeC","sendDataMsg4(): DataMSGSendBusy= TRUE!!!\n");
						return;
					}

					DataMSGSendPkt = call MSG4SendQueue.dequeue();

					// Send the message

					sendDone = call MSG4AMSend.send(parentID,&DataMSGSendPkt,sizeof(Message4));

					if (sendDone== SUCCESS)
					{
						DataMSGSendBusy = TRUE ;
					}
					else
					{
						dbg("SRTreeC","Send failed!!!\n");
					}
			}
		 }
		//	dbg("SRTreeC","DataMsg enqueued successfully in MSG4SendQueue!!!\n");
		}
		else
		{
			dbg("SRTreeC","DataMsg failed to be enqueued in MSG4SendQueue!!!");
		}
	}

	task void sendDataMsg5 ()
	{
		error_t enqueueDone , sendDone ;

			// Set the values to the struct that we will send , will change if not leaf
			if ((AggFunction1 == 2) && (AggFunction2 == 3))
			{
				DataMsgRecPkt5->num1 = myCount;
				DataMsgRecPkt5->num2 = myMin;
				dbg("SRTreeC","Child %u ==> (Count,Min) = (%u,%u) ==> Parent %u\n",TOS_NODE_ID,myCount,myMin,parentID); // Sending Message
			}
			else if ((AggFunction1 == 2) && (AggFunction2 == 4))
			{
				DataMsgRecPkt5->num1 = myCount;
				DataMsgRecPkt5->num2 = myMax;
				dbg("SRTreeC","Child %u ==> (Count,Max) = (%u,%u) ==> Parent %u\n",TOS_NODE_ID,myCount,myMax,parentID); // Sending Message
			}
			else if ((AggFunction1 == 3) && (AggFunction2 == 4))
			{
				DataMsgRecPkt5->num1 = myMin;
				DataMsgRecPkt5->num2 = myMax;
				dbg("SRTreeC","Child %u ==> (Min,Max) = (%u,%u) ==> Parent %u\n",TOS_NODE_ID,myMin,myMax,parentID); // Sending Message
			}

		call MSG5AMPacket.setDestination(&DataMSGSendPkt,parentID);
		call MSG5Packet.setPayloadLength(&DataMSGSendPkt,sizeof(Message5));

		enqueueDone = call MSG5SendQueue.enqueue(DataMSGSendPkt);

		if(call MSG5SendQueue.full())
		{
				dbg("SRTreeC","MSG5SendQueue is FULL!!! \n");
				return;
		}

		if (enqueueDone==SUCCESS) // && (!DataMSGSendBusy)
		{
		 if (call MSG5SendQueue.size()==1)
		 {
				if (TOS_NODE_ID != parentID)
				{
					if (call MSG5SendQueue.empty()) // Has no messages to send
					{
						dbg("SRTreeC","sendDataMsg5(): Q is empty!\n");
						return;
					}

					if(DataMSGSendBusy) // Cant send messages
					{
						dbg("SRTreeC","sendDataMsg5(): DataMSGSendBusy= TRUE!!!\n");
						return;
					}

					DataMSGSendPkt = call MSG5SendQueue.dequeue();

					// Send the message

					sendDone = call MSG5AMSend.send(parentID,&DataMSGSendPkt,sizeof(Message5));

					if (sendDone== SUCCESS)
					{
						DataMSGSendBusy = TRUE ;
					}
					else
					{
						dbg("SRTreeC","Send failed!!!\n");
					}
			}
		 }
		//	dbg("SRTreeC","DataMsg enqueued successfully in MSG5SendQueue!!!\n");
		}
		else
		{
			dbg("SRTreeC","DataMsg failed to be enqueued in MSG5SendQueue!!!");
		}
	}

	task void sendDataMsg6 ()
	{
		error_t enqueueDone , sendDone ;

		// Set the values to the struct that we will send , will change if not leaf
			if ((AggFunction1 == 3) && (AggFunction2 == 5))
			{
				DataMsgRecPkt6->num1 = mySum;
				DataMsgRecPkt6->num2 = myCount;
				DataMsgRecPkt6->num3 = myMin;
				dbg("SRTreeC","Child %u ==> (Sum,Count,Min) = (%u,%u,%u) ==> Parent %u\n",TOS_NODE_ID,mySum,myCount,myMin,parentID); // Sending Message
			}
			else if ((AggFunction1 == 4) && (AggFunction2 == 5))
			{
				DataMsgRecPkt6->num1 = mySum;
				DataMsgRecPkt6->num2 = myCount;
				DataMsgRecPkt6->num3 = myMax;
				dbg("SRTreeC","Child %u ==> (Sum,Count,Max) = (%u,%u,%u) ==> Parent %u\n",TOS_NODE_ID,mySum,myCount,myMax,parentID); // Sending Message
			}

		call MSG6AMPacket.setDestination(&DataMSGSendPkt,parentID);
		call MSG6Packet.setPayloadLength(&DataMSGSendPkt,sizeof(Message6));

		enqueueDone = call MSG6SendQueue.enqueue(DataMSGSendPkt);

		if(call MSG6SendQueue.full())
		{
				dbg("SRTreeC","MSG6SendQueue is FULL!!! \n");
				return;
		}

		if (enqueueDone==SUCCESS) // && (!DataMSGSendBusy)
		{
		 if (call MSG6SendQueue.size()==1)
		 {
				if (TOS_NODE_ID != parentID)
				{
					if (call MSG6SendQueue.empty()) // Has no messages to send
					{
						dbg("SRTreeC","sendDataMsg6(): Q is empty!\n");
						return;
					}

					if(DataMSGSendBusy) // Cant send messages
					{
						dbg("SRTreeC","sendDataMsg6(): DataMSGSendBusy= TRUE!!!\n");
						return;
					}

					DataMSGSendPkt = call MSG6SendQueue.dequeue();

					// Send the message

					sendDone = call MSG6AMSend.send(parentID,&DataMSGSendPkt,sizeof(Message6));

					if (sendDone== SUCCESS)
					{
						DataMSGSendBusy = TRUE ;
					}
					else
					{
						dbg("SRTreeC","Send failed!!!\n");
					}
			}
		 }
		//	dbg("SRTreeC","DataMsg enqueued successfully in MSG6SendQueue!!!\n");
		}
		else
		{
			dbg("SRTreeC","DataMsg failed to be enqueued in MSG6SendQueue!!!");
		}
	}

	task void sendDataMsg7 ()
	{
		error_t enqueueDone , sendDone ;

				// Set the values to the struct that we will send , will change if not leaf
			if((AggFunction1 == 3) && (AggFunction2 == 6))
			{
				DataMsgRecPkt7->num1 = mySum_2;
				DataMsgRecPkt7->num2 = mySum;
				DataMsgRecPkt7->num3 = myCount;
				DataMsgRecPkt7->num4 = myMin;
				dbg("SRTreeC","Child %u ==> (Sum_2,Sum,Count,Min) = (%u,%u,%u,%u) ==> Parent %u\n",TOS_NODE_ID,mySum_2,mySum,myCount,myMax,parentID); // Sending Message
			}
			else if ((AggFunction1 == 4) && (AggFunction2 == 6))
			{
				DataMsgRecPkt7->num1 = mySum_2;
				DataMsgRecPkt7->num2 = mySum;
				DataMsgRecPkt7->num3 = myCount;
				DataMsgRecPkt7->num4 = myMax;
				dbg("SRTreeC","Child %u ==> (Sum_2,Sum,Count,Max) = (%u,%u,%u,%u) ==> Parent %u\n",TOS_NODE_ID,mySum_2,mySum,myCount,myMax,parentID); // Sending Message
			}

		call MSG7AMPacket.setDestination(&DataMSGSendPkt,parentID);
		call MSG7Packet.setPayloadLength(&DataMSGSendPkt,sizeof(Message7));

		enqueueDone = call MSG7SendQueue.enqueue(DataMSGSendPkt);

		if(call MSG7SendQueue.full())
		{
				dbg("SRTreeC","MSG7SendQueue is FULL!!! \n");
				return;
		}

		if (enqueueDone==SUCCESS) // && (!DataMSGSendBusy)
		{
		 if (call MSG7SendQueue.size()==1)
		 {
				if (TOS_NODE_ID != parentID)
				{
					if (call MSG7SendQueue.empty()) // Has no messages to send
					{
						dbg("SRTreeC","sendDataMsg7(): Q is empty!\n");
						return;
					}

					if(DataMSGSendBusy) // Cant send messages
					{
						dbg("SRTreeC","sendDataMsg7(): DataMSGSendBusy= TRUE!!!\n");
						return;
					}

					DataMSGSendPkt = call MSG7SendQueue.dequeue();

					// Send the message

					sendDone = call MSG7AMSend.send(parentID,&DataMSGSendPkt,sizeof(Message7));

					if (sendDone== SUCCESS)
					{
						DataMSGSendBusy = TRUE ;
					}
					else
					{
						dbg("SRTreeC","Send failed!!!\n");
					}
			}
		 }
		//	dbg("SRTreeC","DataMsg enqueued successfully in MSG7SendQueue!!!\n");
		}
		else
		{
			dbg("SRTreeC","DataMsg failed to be enqueued in MSG7SendQueue!!!");
		}
	}

	// Receive related functions

	event message_t* MSG1Receive.receive(message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;

		ReceivedMessage = msg ;

	//	dbg("SRTreeC", "### MSG1Receive.receive() start ##### \n");

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone = call MSG1ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
		//	dbg("SRTreeC","posting receiveDataMsg()!!!! \n");
			post receiveDataMsg1(); //Receive task
		}
		else
		{
			dbg("SRTreeC","DataMsg enqueue failed!!! \n");
		}

	//	dbg("SRTreeC", "### MSG1Receive.receive() end ##### \n\n");
		return msg;
	}

	event message_t* MSG2Receive.receive(message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;

		ReceivedMessage = msg ;

	//	dbg("SRTreeC", "### MSG2Receive.receive() start ##### \n");

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone = call MSG2ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
		//	dbg("SRTreeC","posting receiveDataMsg()!!!! \n");
			post receiveDataMsg2(); //Receive task
		}
		else
		{
			dbg("SRTreeC","DataMsg enqueue failed!!! \n");
		}

	//	dbg("SRTreeC", "### MSG2Receive.receive() end ##### \n\n");
		return msg;
	}

	event message_t* MSG3Receive.receive(message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;

		ReceivedMessage = msg ;

	//	dbg("SRTreeC", "### MSG3Receive.receive() start ##### \n");

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone = call MSG3ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
		//	dbg("SRTreeC","posting receiveDataMsg()!!!! \n");
			post receiveDataMsg3(); //Receive task
		}
		else
		{
			dbg("SRTreeC","DataMsg enqueue failed!!! \n");
		}

		return msg;
	}

	event message_t* MSG4Receive.receive(message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;

		ReceivedMessage = msg ;

	//	dbg("SRTreeC", "### MSG4Receive.receive() start ##### \n");

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone = call MSG4ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
		//	dbg("SRTreeC","posting receiveDataMsg()!!!! \n");
			post receiveDataMsg4(); //Receive task
		}
		else
		{
			dbg("SRTreeC","DataMsg enqueue failed!!! \n");
		}

		return msg;
	}

	event message_t* MSG5Receive.receive(message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;

		ReceivedMessage = msg ;

	//	dbg("SRTreeC", "### MSG5Receive.receive() start ##### \n");

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone = call MSG5ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
		//	dbg("SRTreeC","posting receiveDataMsg()!!!! \n");
			post receiveDataMsg5(); //Receive task
		}
		else
		{
			dbg("SRTreeC","DataMsg enqueue failed!!! \n");
		}

		return msg;
	}

	event message_t* MSG6Receive.receive(message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;

		ReceivedMessage = msg ;

	//	dbg("SRTreeC", "### MSG6Receive.receive() start ##### \n");

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone = call MSG6ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
		//	dbg("SRTreeC","posting receiveDataMsg()!!!! \n");
			post receiveDataMsg6(); //Receive task
		}
		else
		{
			dbg("SRTreeC","DataMsg enqueue failed!!! \n");
		}

		return msg;
	}

	event message_t* MSG7Receive.receive(message_t* msg , void* payload , uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;

		ReceivedMessage = msg ;

	//	dbg("SRTreeC", "### MSG7Receive.receive() start ##### \n");

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone = call MSG7ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
		//	dbg("SRTreeC","posting receiveDataMsg()!!!! \n");
			post receiveDataMsg7(); //Receive task
		}
		else
		{
			dbg("SRTreeC","DataMsg enqueue failed!!! \n");
		}

		return msg;
	}

	// Receive related tasks

	task void receiveDataMsg1 ()
	{
		message_t tmp;
		uint8_t len , msource ;

		tmp = call MSG1ReceiveQueue.dequeue();
		len = call MSG1Packet.payloadLength(&tmp);
		msource = call MSG1AMPacket.source(ReceivedMessage); // Get the header of the message

		// processing of Packet
		if(len == sizeof(Message1))
		{
			Message1* mpkt = (Message1*) (call MSG1Packet.getPayload(&tmp,sizeof(Message1))); // Get the data of the message
			dataCounter = 0 ;

			while ((childrenVals[dataCounter].senderID != msource) && (dataCounter <= numOfChildren -1) && (childrenVals[dataCounter].senderID != 0)) // Find the child's position in the array if there is one
			{
				dataCounter++ ;
			}

			dbg("SRTreeC","Parent %u <== (Sum) = (%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->sum,msource);

			//Save children values to array
  		childrenVals[dataCounter].senderID = msource ;
			childrenVals[dataCounter].sum = mpkt->sum;
		}
		else
		{
				dbg("SRTreeC","receiveDataMsg1():Empty message!!! \n");
			return;
		}
	}

	task void receiveDataMsg2 ()
	{
		message_t tmp;
		uint8_t len , msource ;

		tmp = call MSG2ReceiveQueue.dequeue();
		len = call MSG2Packet.payloadLength(&tmp);
		msource = call MSG2AMPacket.source(ReceivedMessage); // Get the header of the message

		// processing of Packet
		if(len == sizeof(Message2))
		{
			Message2* mpkt = (Message2*) (call MSG2Packet.getPayload(&tmp,sizeof(Message2))); // Get the data of the message
			dataCounter = 0 ;

			while ((childrenVals[dataCounter].senderID != msource) && (dataCounter <= numOfChildren - 1) && (childrenVals[dataCounter].senderID != 0)) // Find the child's position in the array if there is one
			{
				dataCounter++ ;
			}

			//Save children values to array
			childrenVals[dataCounter].senderID = msource ;

			if (AggFunction1 == 2)
			{
				dbg("SRTreeC","Parent %u <== (Count) = (%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num,msource);
				childrenVals[dataCounter].count = mpkt->num;
			}
			else if (AggFunction1 == 3)
			{
				dbg("SRTreeC","Parent %u <== (Min) = (%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num,msource);
				childrenVals[dataCounter].min = mpkt->num;
			}
			else if (AggFunction1 == 4)
			{
				dbg("SRTreeC","Parent %u <== (Max) = (%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num,msource);
				childrenVals[dataCounter].max = mpkt->num;
			}
		}
		else
		{
				dbg("SRTreeC","receiveDataMsg2():Empty message!!! \n");
			return;
		}
	}

	task void receiveDataMsg3 ()
	{
		message_t tmp;
		uint8_t len , msource ;

		tmp = call MSG3ReceiveQueue.dequeue();
		len = call MSG3Packet.payloadLength(&tmp);
		msource = call MSG3AMPacket.source(ReceivedMessage); // Get the header of the message

		// processing of Packet
		if(len == sizeof(Message3))
		{
			Message3* mpkt = (Message3*) (call MSG3Packet.getPayload(&tmp,sizeof(Message3))); // Get the data of the message
			dataCounter = 0 ;

			while ((childrenVals[dataCounter].senderID != msource) && (dataCounter <= numOfChildren - 1) && (childrenVals[dataCounter].senderID != 0)) // Find the child's position in the array if there is one
			{
				dataCounter++ ;
			}

			//Save children values to array
			childrenVals[dataCounter].senderID = msource ;

			if (((AggFunction1 == 5) && (AggFunction2 == 0)) || ((AggFunction1 == 2) && (AggFunction2 == 5)) || ((AggFunction1 == 1) && (AggFunction2 == 5)) ||  ((AggFunction1 == 1) && (AggFunction2 == 2)))
			{
				dbg("SRTreeC","Parent %u <== (Sum,Count) = (%u,%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num1,mpkt->num2,msource);
				childrenVals[dataCounter].sum = mpkt->num1;
				childrenVals[dataCounter].count = mpkt->num2;
			}
			else if ((AggFunction1 == 1) && (AggFunction2 == 3))
			{
				dbg("SRTreeC","Parent %u <== (Sum,Min) = (%u,%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num1,mpkt->num2,msource);
				childrenVals[dataCounter].sum = mpkt->num1;
				childrenVals[dataCounter].min = mpkt->num2;
			}
			else if ((AggFunction1 == 1) && (AggFunction2 == 4))
			{
				dbg("SRTreeC","Parent %u <== (Sum,Max) = (%u,%u)  <== Child %u \n" ,TOS_NODE_ID,mpkt->num1,mpkt->num2,msource);
				childrenVals[dataCounter].sum = mpkt->num1;
				childrenVals[dataCounter].max = mpkt->num2;
			}

		}
		else
		{
				dbg("SRTreeC","receiveDataMsg3():Empty message!!! \n");
			return;
		}
	}

	task void receiveDataMsg4 ()
	{
		message_t tmp;
		uint8_t len , msource ;

		tmp = call MSG4ReceiveQueue.dequeue();
		len = call MSG4Packet.payloadLength(&tmp);
		msource = call MSG4AMPacket.source(ReceivedMessage); // Get the header of the message

		// processing of Packet
		if(len == sizeof(Message4))
		{
			Message4* mpkt = (Message4*) (call MSG4Packet.getPayload(&tmp,sizeof(Message4))); // Get the data of the message
			dataCounter = 0 ;

			while ((childrenVals[dataCounter].senderID != msource) && (dataCounter <= numOfChildren - 1) && (childrenVals[dataCounter].senderID != 0)) // Find the child's position in the array if there is one
			{
				dataCounter++ ;
			}

			dbg("SRTreeC","Parent %u <== (Sum_2,Sum,Count) = (%u,%u,%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num1,mpkt->num2,mpkt->num3,msource);

			//Save children values to array
			childrenVals[dataCounter].senderID = msource ;
			childrenVals[dataCounter].sum_2  = mpkt->num1;
			childrenVals[dataCounter].sum  = mpkt->num2;
			childrenVals[dataCounter].count  = mpkt->num3;
		}
		else
		{
				dbg("SRTreeC","receiveDataMsg4():Empty message!!! \n");
			return;
		}
	}

	task void receiveDataMsg5 ()
	{
		message_t tmp;
		uint8_t len , msource ;

		tmp = call MSG5ReceiveQueue.dequeue();
		len = call MSG5Packet.payloadLength(&tmp);
		msource = call MSG5AMPacket.source(ReceivedMessage); // Get the header of the message

		// processing of Packet
		if(len == sizeof(Message5))
		{
			Message5* mpkt = (Message5*) (call MSG5Packet.getPayload(&tmp,sizeof(Message5))); // Get the data of the message
			dataCounter = 0 ;

			while ((childrenVals[dataCounter].senderID != msource) && (dataCounter <= numOfChildren - 1) && (childrenVals[dataCounter].senderID != 0)) // Find the child's position in the array if there is one
			{
				dataCounter++ ;
			}

			//Save children values to array
			if ((AggFunction1 == 2) && (AggFunction2 == 3))
			{
				dbg("SRTreeC","Parent %u <== (Count,Min) = (%u,%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num1,mpkt->num2,msource);

				childrenVals[dataCounter].senderID = msource ;
				childrenVals[dataCounter].count  = mpkt->num1;
				childrenVals[dataCounter].min  = mpkt->num2;
			}
			else if ((AggFunction1 == 2) && (AggFunction2 == 4))
			{
				dbg("SRTreeC","Parent %u <== (Count,Max) = (%u,%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num1,mpkt->num2,msource);

				childrenVals[dataCounter].senderID = msource ;
				childrenVals[dataCounter].count  = mpkt->num1;
				childrenVals[dataCounter].max  = mpkt->num2;
			}
			else if ((AggFunction1 == 3) && (AggFunction2 == 4))
			{
				dbg("SRTreeC","Parent %u <== (Min,Max) = (%u,%u) <== Child %u \n" ,TOS_NODE_ID,mpkt->num1,mpkt->num2,msource);
				childrenVals[dataCounter].senderID = msource ;
				childrenVals[dataCounter].min  = mpkt->num1;
				childrenVals[dataCounter].max  = mpkt->num2;
			}
		}
		else
		{
				dbg("SRTreeC","receiveDataMsg5():Empty message!!! \n");
			return;
		}
	}

	task void receiveDataMsg6 ()
	{
		message_t tmp;
		uint8_t len , msource ;

		tmp = call MSG6ReceiveQueue.dequeue();
		len = call MSG6Packet.payloadLength(&tmp);
		msource = call MSG6AMPacket.source(ReceivedMessage); // Get the header of the message

		// processing of Packet
		if(len == sizeof(Message6))
		{
			Message6* mpkt = (Message6*) (call MSG6Packet.getPayload(&tmp,sizeof(Message6))); // Get the data of the message
			dataCounter = 0 ;

			while ((childrenVals[dataCounter].senderID != msource) && (dataCounter <= numOfChildren - 1) && (childrenVals[dataCounter].senderID != 0)) // Find the child's position in the array if there is one
			{
				dataCounter++ ;
			}

			//Save children values to array
			if ((AggFunction1 == 3) && (AggFunction2 == 5))
			{
				dbg("SRTreeC","Parent %u <== (Sum,Count,Min) = (%u,%u,%u) <== Child %u \n",TOS_NODE_ID,mpkt->num1,mpkt->num2,mpkt->num3,msource);

				childrenVals[dataCounter].senderID = msource ;
				childrenVals[dataCounter].sum  = mpkt->num1;
				childrenVals[dataCounter].count  = mpkt->num2;
				childrenVals[dataCounter].min  = mpkt->num3;
			}
			else if ((AggFunction1 == 4) && (AggFunction2 == 5))
			{
				dbg("SRTreeC","Parent %u <== (Sum,Count,Max) = (%u,%u,%u) <== Child %u \n",TOS_NODE_ID,mpkt->num1,mpkt->num2,mpkt->num3,msource);

				childrenVals[dataCounter].senderID = msource ;
				childrenVals[dataCounter].sum  = mpkt->num1;
				childrenVals[dataCounter].count  = mpkt->num2;
				childrenVals[dataCounter].max  = mpkt->num3;
			}
		}
		else
		{
				dbg("SRTreeC","receiveDataMsg6():Empty message!!! \n");
			return;
		}
	}

	task void receiveDataMsg7 ()
	{
		message_t tmp;
		uint8_t len , msource ;

		tmp = call MSG7ReceiveQueue.dequeue();
		len = call MSG7Packet.payloadLength(&tmp);
		msource = call MSG7AMPacket.source(ReceivedMessage); // Get the header of the message

		// processing of Packet
		if(len == sizeof(Message7))
		{
			Message7* mpkt = (Message7*) (call MSG7Packet.getPayload(&tmp,sizeof(Message7))); // Get the data of the message
			dataCounter = 0 ;

			while ((childrenVals[dataCounter].senderID != msource) && (dataCounter <= numOfChildren - 1) && (childrenVals[dataCounter].senderID != 0)) // Find the child's position in the array if there is one
			{
				dataCounter++ ;
			}

			//Save children values to array
			if((AggFunction1 == 3) && (AggFunction2 == 6))
			{
				dbg("SRTreeC","Parent %u <== (Sum^2,Sum,Count,Min) = (%u,%u,%u,%u) <== Child %u \n",TOS_NODE_ID,mpkt->num1,mpkt->num2,mpkt->num3,mpkt->num4,msource);

				childrenVals[dataCounter].senderID = msource ;
				childrenVals[dataCounter].sum_2  = mpkt->num1;
				childrenVals[dataCounter].sum  = mpkt->num2;
				childrenVals[dataCounter].count  = mpkt->num3;
				childrenVals[dataCounter].min  = mpkt->num4;
			}
			else if ((AggFunction1 == 4) && (AggFunction2 == 6))
			{
				dbg("SRTreeC","Parent %u <== (Sum^2,Sum,Count,Max) = (%u,%u,%u,%u) <== Child %u \n",TOS_NODE_ID,mpkt->num1,mpkt->num2,mpkt->num3,mpkt->num4,msource);

				childrenVals[dataCounter].senderID = msource ;
				childrenVals[dataCounter].sum_2  = mpkt->num1;
				childrenVals[dataCounter].sum  = mpkt->num2;
				childrenVals[dataCounter].count  = mpkt->num3;
				childrenVals[dataCounter].max  = mpkt->num4;
			}

		}
		else
		{
				dbg("SRTreeC","receiveDataMsg7():Empty message!!! \n");
			return;
		}
	}

	event void RoutingMsgTimer.fired()
	{
		message_t tmp;
		error_t enqueueDone;
		RoutingMsg_2_1* mrpkt1;
		RoutingMsg_2_2* mrpkt2;
		uint8_t temp1 = AggFunction1;
		uint8_t temp2 = AggFunction2;

	//	dbg("SRTreeC", "RoutingMsgTimer fired!  radioBusy = %s \n",(RoutingSendBusy)?"True":"False");

		if (TOS_NODE_ID==0)
		{
			dbg("SRTreeC", "\n \t \t \t ##################################### \n");
			dbg("SRTreeC", "#######   ROUND   %u    ############## \n", roundCounter);
			dbg("SRTreeC", "#####################################\n");

			//Choices (once)
			if (!Choice) // We choose all the decision parameters randomly
			{
				Choice = TRUE ;

				call Seed.init(randomSeed());
				choice_2_1_or_2_2 = (uint8_t) ((call Random.rand16()) % (2 - 1 + 1)) + 1 ; // 1 or 2

				if (choice_2_1_or_2_2 == 1) // 2.1
				{
						call Seed.init(randomSeed());
						choice_how_many_aggr = (uint8_t) ((call Random.rand16()) % (2 - 1 + 1)) + 1 ; // 1 or 2
						if (choice_how_many_aggr == 1)
						{
							call Seed.init(randomSeed());
							AggFunction1 = (uint8_t) ((call Random.rand16()) % (6 - 1 + 1)) + 1 ; // 1-6
						}
						else if (choice_how_many_aggr == 2)
						{
								call Seed.init(randomSeed());
								AggFunction1 = (uint8_t) ((call Random.rand16()) % (6 - 1 + 1)) + 1 ; // 1-6
								call Seed.init(randomSeed());
								AggFunction2 = (uint8_t) ((call Random.rand16()) % (6 - 1 + 1)) + 1 ; // 1-6

								while (AggFunction2 == AggFunction1) // Choices must be different
								{
									call Seed.init(randomSeed());
									AggFunction2 = (uint8_t) ((call Random.rand16()) % (6 - 1 + 1)) + 1 ; // 1-6
								}

								temp1 = AggFunction1;
								temp2 = AggFunction2;

								AggFunction1 = temp1 < temp2 ? temp1 : temp2 ; // min value
								AggFunction2 = temp1 > temp2 ? temp1 : temp2 ; // max value
						}
						dbg("SRTreeC" , "Question 2_1 with %u functions (Aggr1,Aggr2) = (%u,%u) \n",choice_how_many_aggr,AggFunction1,AggFunction2);
				}
				else if (choice_2_1_or_2_2 == 2) // TINA 2.2
				{
						call Seed.init(randomSeed());
						AggFunction1 = (uint8_t) ((call Random.rand16()) % (4 - 1 + 1)) + 1 ; // 1-4
						call Seed.init(randomSeed());
						TCT = (uint8_t) ((call Random.rand16()) % (100 + 1)) ; // [0-100]
						dbg("SRTreeC" , "Question 2_2 with (Aggr,TCT) = (%u,%u) \n",AggFunction1,TCT);

				}
			}
		}

			//choice_2_1_or_2_2 = 1 ; // DELETE
			//TCT = 50 ; // DELETE
			//AggFunction1 = 5 ; // DELETE
			//AggFunction2 = 6 ; // DELETE

			//call RoutingMsgTimer.startOneShot(TIMER_PERIOD_MILLI); // Run at next rounds

			//We create the struct of the routing message that we will send
			if (choice_2_1_or_2_2 == 1)
			{
						if(call Routing_2_1_SendQueue.full())
						{
							return;
						}

						mrpkt1 = (RoutingMsg_2_1 *) (call Routing_2_1_Packet.getPayload(&tmp,sizeof(RoutingMsg_2_1)));

						if(mrpkt1==NULL)
						{
							dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");
							return;
						}

						atomic
						{
									mrpkt1->depth = curdepth;

									if ((AggFunction1 == 1) && (AggFunction2 == 0))
										mrpkt1->choice = 1;
									else if ((AggFunction1 == 2) && (AggFunction2 == 0))
										mrpkt1->choice = 2;
									else if ((AggFunction1 == 3) && (AggFunction2 == 0))
										mrpkt1->choice = 3;
									else if ((AggFunction1 == 4) && (AggFunction2 == 0))
										mrpkt1->choice = 4;
									else if ((AggFunction1 == 5) && (AggFunction2 == 0))
										mrpkt1->choice = 5;
									else if ((AggFunction1 == 6) && (AggFunction2 == 0))
										mrpkt1->choice = 6;
									else if ((AggFunction1 == 1) && (AggFunction2 == 2))
										mrpkt1->choice = 7;
									else if ((AggFunction1 == 1) && (AggFunction2 == 3))
											mrpkt1->choice = 8;
									else if ((AggFunction1 == 1) && (AggFunction2 == 4))
											mrpkt1->choice = 9;
									else if ((AggFunction1 == 1) && (AggFunction2 == 5))
											mrpkt1->choice = 10;
									else if ((AggFunction1 == 1) && (AggFunction2 == 6))
											mrpkt1->choice = 11;
									else if ((AggFunction1 == 2) && (AggFunction2 == 3))
											mrpkt1->choice = 12;
									else if ((AggFunction1 == 2) && (AggFunction2 == 4))
											mrpkt1->choice = 13;
									else if ((AggFunction1 == 2) && (AggFunction2 == 5))
											mrpkt1->choice = 14;
									else if ((AggFunction1 == 2) && (AggFunction2 == 6))
											mrpkt1->choice = 15;
									else if ((AggFunction1 == 3) && (AggFunction2 == 4))
											mrpkt1->choice = 16;
									else if ((AggFunction1 == 3) && (AggFunction2 == 5))
											mrpkt1->choice = 17;
									else if ((AggFunction1 == 3) && (AggFunction2 == 6))
											mrpkt1->choice = 18;
									else if ((AggFunction1 == 4) && (AggFunction2 == 5))
											mrpkt1->choice = 19;
								  else if ((AggFunction1 == 4) && (AggFunction2 == 6))
											mrpkt1->choice = 20;
									else if ((AggFunction1 == 5) && (AggFunction2 == 6))
											mrpkt1->choice = 21;
						}

						//dbg("SRTreeC" , "Node %u sends: (Parent,Depth,Question,Aggr1,Aggr2) = (%u,%u,2_%u,%u,%u) \n",TOS_NODE_ID,parentID,curdepth,choice_2_1_or_2_2,AggFunction1,AggFunction2);
						//dbg("SRTreeC" , "Sending RoutingMsg_2_1... \n");
						call Routing_2_1_AMPacket.setDestination(&tmp,AM_BROADCAST_ADDR);
						call Routing_2_1_Packet.setPayloadLength(&tmp,sizeof(RoutingMsg_2_1));

						enqueueDone = call Routing_2_1_SendQueue.enqueue(tmp);

						if (enqueueDone==SUCCESS)
						{
							if (call Routing_2_1_SendQueue.size()==1)
							{
								post sendRoutingTask1();
							}

						//	dbg("SRTreeC","RoutingMsg enqueued successfully in Routing_2_1_SendQueue!!!\n");
						}
						else
						{
							dbg("SRTreeC","RoutingMsg failed to be enqueued in Routing_2_1_SendQueue!!!");
						}
			}
			else if (choice_2_1_or_2_2 == 2)
			{
						if(call Routing_2_2_SendQueue.full())
						{
							return;
						}

						mrpkt2 = (RoutingMsg_2_2 *) (call Routing_2_2_Packet.getPayload(&tmp,sizeof(RoutingMsg_2_2)));

						if(mrpkt2==NULL)
						{
							dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");
							return;
						}

						atomic
						{
									mrpkt2->depth = curdepth;
									mrpkt2->choice = AggFunction1;
									mrpkt2->TCT = TCT;
						}

					//	dbg("SRTreeC" , "Node %u sends: (Parent,Depth,Question,Aggr,TCT) = (%u,%u,2_%u,%u,%u) \n",TOS_NODE_ID,parentID,curdepth,choice_2_1_or_2_2,AggFunction1,TCT);
					//	dbg("SRTreeC" , "Sending RoutingMsg_2_2... \n");
						call Routing_2_2_AMPacket.setDestination(&tmp,AM_BROADCAST_ADDR);
						call Routing_2_2_Packet.setPayloadLength(&tmp,sizeof(RoutingMsg_2_2));

						enqueueDone=call Routing_2_2_SendQueue.enqueue(tmp);

						if (enqueueDone==SUCCESS)
						{
							if (call Routing_2_2_SendQueue.size()==1)
							{
								post sendRoutingTask2();
							}

						//	dbg("SRTreeC","RoutingMsg enqueued successfully in Routing_2_2_SendQueue!!!\n");
						}
						else
						{
							dbg("SRTreeC","RoutingMsg failed to be enqueued in Routing_2_2_SendQueue!!!");
						}
			}
		}

	uint16_t RoutingSource ;

	event void Routing_2_1_AMSend.sendDone(message_t * msg , error_t err)
	{
	//	dbg("SRTreeC", "A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");

		setRoutingSendBusy(FALSE);

		if(!(call Routing_2_1_SendQueue.empty()))
		{
			post sendRoutingTask1();
		}
	}

	event void Routing_2_2_AMSend.sendDone(message_t * msg , error_t err)
	{
	//	dbg("SRTreeC", "A Routing package sent... %s \n",(err==SUCCESS)?"True":"False");

		setRoutingSendBusy(FALSE);

		if(!(call Routing_2_2_SendQueue.empty()))
		{
			post sendRoutingTask2();
		}
	}

	task void sendRoutingTask1()
	{
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;

		if (call Routing_2_1_SendQueue.empty())
		{
			dbg("SRTreeC","sendRoutingTask1(): Q is empty!\n");
			return;
		}

		if(RoutingSendBusy)
		{
			dbg("SRTreeC","sendRoutingTask1(): RoutingSendBusy= TRUE!!!\n");
			setLostRoutingSendTask(TRUE);
			return;
		}

		radioRoutingSendPkt = call Routing_2_1_SendQueue.dequeue();

		mlen= call Routing_2_1_Packet.payloadLength(&radioRoutingSendPkt);
		mdest = call Routing_2_1_AMPacket.destination(&radioRoutingSendPkt);

		if (mlen!=sizeof(RoutingMsg_2_1))
		{
			dbg("SRTreeC","\t\tsendRoutingTask1(): Unknown message!!!\n");
			return;
		}

		//Send routing message
		sendDone = call Routing_2_1_AMSend.send(mdest,&radioRoutingSendPkt,mlen);

		if (sendDone== SUCCESS)
		{
	//		dbg("SRTreeC","sendRoutingTask1(): Send returned success!!!\n");
			setRoutingSendBusy(TRUE);
		}
		else
		{
			dbg("SRTreeC","RoutingMSG send failed!!!\n");
		}
	}

	task void sendRoutingTask2()
	{
		uint8_t mlen;
		uint16_t mdest;
		error_t sendDone;

		if (call Routing_2_2_SendQueue.empty())
		{
			dbg("SRTreeC","sendRoutingTask2(): Q is empty!\n");
			return;
		}

		if(RoutingSendBusy)
		{
			dbg("SRTreeC","sendRoutingTask2(): RoutingSendBusy= TRUE!!!\n");
			setLostRoutingSendTask(TRUE);
			return;
		}

		radioRoutingSendPkt = call Routing_2_2_SendQueue.dequeue();

		mlen= call Routing_2_2_Packet.payloadLength(&radioRoutingSendPkt);
		mdest=call Routing_2_2_AMPacket.destination(&radioRoutingSendPkt);

		if (mlen!=sizeof(RoutingMsg_2_2))
		{
			dbg("SRTreeC","\t\tsendRoutingTask2(): Unknown message!!!\n");
			return;
		}

		//Send routing message
		sendDone = call Routing_2_2_AMSend.send(mdest,&radioRoutingSendPkt,mlen);

		if (sendDone== SUCCESS)
		{
		//	dbg("SRTreeC","sendRoutingTask2(): Send returned success!!!\n");
			setRoutingSendBusy(TRUE);
		}
		else
		{
			dbg("SRTreeC","RoutingMSG send failed!!!\n");
		}
	}

	event message_t* Routing_2_1_Receive.receive(message_t * msg , void * payload, uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		RoutingSource = call Routing_2_1_AMPacket.source(msg);

	//	dbg("SRTreeC", "### Routing_2_1_Receive.receive() start ##### \n");
	//	dbg("SRTreeC", "Received RoutingMSG from %u \n",RoutingSource);

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone=call Routing_2_1_ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
			post receiveRoutingTask1();
		}
		else
		{
			dbg("SRTreeC","RoutingMsg enqueue failed!!! \n");
		}

	//	dbg("SRTreeC", "### Routing_2_1_Receive.receive() end ##### \n");
		return msg;
	}

	event message_t* Routing_2_2_Receive.receive(message_t * msg , void * payload, uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		RoutingSource = call Routing_2_2_AMPacket.source(msg);

		//dbg("SRTreeC", "### Routing_2_2_Receive.receive() start ##### \n");
		//dbg("SRTreeC", "Received RoutingMSG from %u \n",RoutingSource);

		atomic{memcpy(&tmp,msg,sizeof(message_t));}
		enqueueDone=call Routing_2_2_ReceiveQueue.enqueue(tmp);

		if(enqueueDone == SUCCESS)
		{
			post receiveRoutingTask2();
		}
		else
		{
			dbg("SRTreeC","RoutingMsg enqueue failed!!! \n");
		}

		//dbg("SRTreeC", "### Routing_2_2_Receive.receive() end ##### \n");
		return msg;
	}

	task void receiveRoutingTask1()
	{
		uint8_t len ;
		message_t radioRoutingRecPkt;

		radioRoutingRecPkt = call Routing_2_1_ReceiveQueue.dequeue();

		len= call Routing_2_1_Packet.payloadLength(&radioRoutingRecPkt);

		//dbg("SRTreeC","receiveRoutingTask1(): len=%u \n",len);

		//Get values from RoutingMSG
		if(len == sizeof(RoutingMsg_2_1))
		{
			RoutingMsg_2_1 * mpkt = (RoutingMsg_2_1*) (call Routing_2_1_Packet.getPayload(&radioRoutingRecPkt,len));
		//	dbg("SRTreeC" , "receiveRoutingTask1(): depth= %d \n", mpkt->depth);

			if ((parentID<0)||(parentID>63)) // 65535 (has no father yet)
			{
				parentID= call Routing_2_1_AMPacket.source(&radioRoutingRecPkt); //mpkt->senderID;
				curdepth= mpkt->depth + 1;
				choice_2_1_or_2_2 = 1;

				if (mpkt->choice == 1)
				{
					AggFunction1 = 1;
					AggFunction2 = 0;
				}
				else if (mpkt->choice == 2)
				{
					AggFunction1 = 2;
					AggFunction2 = 0;
				}
				else if (mpkt->choice == 3)
				{
					AggFunction1 = 3;
					AggFunction2 = 0;
				}
				else if (mpkt->choice == 4)
				{
					AggFunction1 = 4;
					AggFunction2 = 0;
				}
				else if (mpkt->choice == 5)
				{
					AggFunction1 = 5;
					AggFunction2 = 0;
				}
				else if (mpkt->choice == 6)
				{
					AggFunction1 = 6;
					AggFunction2 = 0;
				}
				else if (mpkt->choice == 7)
				{
					AggFunction1 = 1;
					AggFunction2 = 2;
				}
				else if (mpkt->choice == 8)
				{
					AggFunction1 = 1;
					AggFunction2 = 3;
				}
				else if (mpkt->choice == 9)
				{
					AggFunction1 = 1;
					AggFunction2 = 4;
				}
				else if (mpkt->choice == 10)
				{
					AggFunction1 = 1;
					AggFunction2 = 5;
				}
				else if (mpkt->choice == 11)
				{
					AggFunction1 = 1;
					AggFunction2 = 6;
				}
				else if (mpkt->choice == 12)
				{
					AggFunction1 = 2;
					AggFunction2 = 3;
				}
				else if (mpkt->choice == 13)
				{
					AggFunction1 = 2;
					AggFunction2 = 4;
				}
				else if (mpkt->choice == 14)
				{
					AggFunction1 = 2;
					AggFunction2 = 5;
				}
				else if (mpkt->choice == 15)
				{
					AggFunction1 = 2;
					AggFunction2 = 6;
				}
				else if (mpkt->choice == 16)
				{
					AggFunction1 = 3;
					AggFunction2 = 4;
				}
				else if (mpkt->choice == 17)
				{
					AggFunction1 = 3;
					AggFunction2 = 5;
				}
				else if (mpkt->choice == 18)
				{
					AggFunction1 = 3;
					AggFunction2 = 6;
				}
				else if (mpkt->choice == 19)
				{
					AggFunction1 = 4;
					AggFunction2 = 5;
				}
				else if (mpkt->choice == 20)
				{
					AggFunction1 = 4;
					AggFunction2 = 6;
				}
				else if (mpkt->choice == 21)
				{
					AggFunction1 = 5;
					AggFunction2 = 6;
				}

				dbg("SRTreeC" , "Child %u received RoutingMsg from Parent %u: (Depth,Question,Aggr1,Aggr2) = (%u,2_%u,%u,%u) \n",TOS_NODE_ID,parentID,curdepth,choice_2_1_or_2_2,AggFunction1,AggFunction2);

				if (TOS_NODE_ID!=0)
				{
					call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD); // Broadcast the routing message too
				}
			}
			else
			{
				if ((curdepth > mpkt->depth +1) || (RoutingSource==parentID)) // If you receive RoutingMSG from node closer to root , choose it as parent
				{
					parentID= call Routing_2_1_AMPacket.source(&radioRoutingRecPkt); //mpkt->senderID;
					curdepth= mpkt->depth + 1;
					choice_2_1_or_2_2 = 1;

					if (mpkt->choice == 1)
					{
						AggFunction1 = 1;
						AggFunction2 = 0;
					}
					else if (mpkt->choice == 2)
					{
						AggFunction1 = 2;
						AggFunction2 = 0;
					}
					else if (mpkt->choice == 3)
					{
						AggFunction1 = 3;
						AggFunction2 = 0;
					}
					else if (mpkt->choice == 4)
					{
						AggFunction1 = 4;
						AggFunction2 = 0;
					}
					else if (mpkt->choice == 5)
					{
						AggFunction1 = 5;
						AggFunction2 = 0;
					}
					else if (mpkt->choice == 6)
					{
						AggFunction1 = 6;
						AggFunction2 = 0;
					}
					else if (mpkt->choice == 7)
					{
						AggFunction1 = 1;
						AggFunction2 = 2;
					}
					else if (mpkt->choice == 8)
					{
						AggFunction1 = 1;
						AggFunction2 = 3;
					}
					else if (mpkt->choice == 9)
					{
						AggFunction1 = 1;
						AggFunction2 = 4;
					}
					else if (mpkt->choice == 10)
					{
						AggFunction1 = 1;
						AggFunction2 = 5;
					}
					else if (mpkt->choice == 11)
					{
						AggFunction1 = 1;
						AggFunction2 = 6;
					}
					else if (mpkt->choice == 12)
					{
						AggFunction1 = 2;
						AggFunction2 = 3;
					}
					else if (mpkt->choice == 13)
					{
						AggFunction1 = 2;
						AggFunction2 = 4;
					}
					else if (mpkt->choice == 14)
					{
						AggFunction1 = 2;
						AggFunction2 = 5;
					}
					else if (mpkt->choice == 15)
					{
						AggFunction1 = 2;
						AggFunction2 = 6;
					}
					else if (mpkt->choice == 16)
					{
						AggFunction1 = 3;
						AggFunction2 = 4;
					}
					else if (mpkt->choice == 17)
					{
						AggFunction1 = 3;
						AggFunction2 = 5;
					}
					else if (mpkt->choice == 18)
					{
						AggFunction1 = 3;
						AggFunction2 = 6;
					}
					else if (mpkt->choice == 19)
					{
						AggFunction1 = 4;
						AggFunction2 = 5;
					}
					else if (mpkt->choice == 20)
					{
						AggFunction1 = 4;
						AggFunction2 = 6;
					}
					else if (mpkt->choice == 21)
					{
						AggFunction1 = 5;
						AggFunction2 = 6;
					}

					if (TOS_NODE_ID!=0)
					{
						call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD); // Broadcast the routing message too
					}
				}
			}
		}
		else
		{
			dbg("SRTreeC","receiveRoutingTask1():Empty message!!! \n");
			setLostRoutingRecTask(TRUE);
			return;
		}
	}

	task void receiveRoutingTask2()
	{
		uint8_t len ;
		message_t radioRoutingRecPkt;

		radioRoutingRecPkt= call Routing_2_2_ReceiveQueue.dequeue();

		len= call Routing_2_2_Packet.payloadLength(&radioRoutingRecPkt);

		//dbg("SRTreeC","receiveRoutingTask2(): len=%u \n",len);
		//Get values from RoutingMSG
		if(len == sizeof(RoutingMsg_2_2))
		{
			RoutingMsg_2_2 * mpkt = (RoutingMsg_2_2*) (call Routing_2_2_Packet.getPayload(&radioRoutingRecPkt,len));
			//dbg("SRTreeC" , "receiveRoutingTask2(): depth= %d \n", mpkt->depth);

			if ( (parentID<0)||(parentID>63)) // 65535 (has no father yet)
			{
				parentID= call Routing_2_2_AMPacket.source(&radioRoutingRecPkt);	//mpkt->senderID;
				curdepth= mpkt->depth + 1;
				AggFunction1 = mpkt->choice ;
				AggFunction2 = 0 ;
				TCT =  mpkt->TCT;
				choice_2_1_or_2_2 = 2;

				dbg("SRTreeC" , "Node %u received RoutingMsg: (Parent,Depth,Question,Aggr,TCT) = (%u,%u,2_%u,%u,%u) \n",TOS_NODE_ID,parentID,curdepth,choice_2_1_or_2_2,AggFunction1,TCT);

				if (TOS_NODE_ID!=0)
				{
					call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD); // Broadcast the routing message too
				}
			}
			else
			{
				if ((curdepth > mpkt->depth +1) || (RoutingSource==parentID)) // Find a better father or the same one
				{
					parentID= call Routing_2_2_AMPacket.source(&radioRoutingRecPkt); //mpkt->senderID;
					curdepth = mpkt->depth + 1;
					AggFunction1 = mpkt->choice ;
					AggFunction2 = 0 ;
					TCT =  mpkt->TCT;
					choice_2_1_or_2_2 = 2;

					if (TOS_NODE_ID!=0)
					{
						call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD); // Broadcast the routing message too
					}
				}
			}
		}
		else
		{
			dbg("SRTreeC","receiveRoutingTask2():Empty message!!! \n");
			setLostRoutingRecTask(TRUE);
			return;
		}
	}
}
