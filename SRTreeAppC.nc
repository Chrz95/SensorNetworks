#include "SimpleRoutingTree.h"

configuration SRTreeAppC @safe() { }
implementation{
	components SRTreeC;

#if defined(DELUGE) //defined(DELUGE_BASESTATION) || defined(DELUGE_LIGHT_BASESTATION)
	components DelugeC;
#endif

#ifdef PRINTFDBG_MODE
		components PrintfC;
#endif
	components MainC, ActiveMessageC;
	components new TimerMilliC() as RoutingMsgTimerC;
	components new TimerMilliC() as EpochTimerC;
	components new TimerMilliC() as LostTaskTimerC;
	components new TimerMilliC() as WaitforWakeUpTimerC;
	components new TimerMilliC() as LevelTimerC;
	components new TimerMilliC() as ChildrenTimerC;
	components new TimerMilliC() as CalcValTimerC ;
	components RandomC ;
	components RandomMlcgC;

	components new AMSenderC(AM_ROUTINGMSG_2_1) as RoutingSender_2_1C;
	components new AMReceiverC(AM_ROUTINGMSG_2_1) as RoutingReceiver_2_1C;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueue_2_1C;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueue_2_1C;

	components new AMSenderC(AM_ROUTINGMSG_2_2) as RoutingSender_2_2C;
	components new AMReceiverC(AM_ROUTINGMSG_2_2) as RoutingReceiver_2_2C;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueue_2_2C;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueue_2_2C;

	components new AMSenderC(AM_MSG1) as MSG1SenderC;
	components new AMReceiverC(AM_MSG1) as MSG1ReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MSG1SendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MSG1ReceiveQueueC;

	components new AMSenderC(AM_MSG2) as MSG2SenderC;
	components new AMReceiverC(AM_MSG2) as MSG2ReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MSG2SendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MSG2ReceiveQueueC;

	components new AMSenderC(AM_MSG3) as MSG3SenderC;
	components new AMReceiverC(AM_MSG3) as MSG3ReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MSG3SendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MSG3ReceiveQueueC;

	components new AMSenderC(AM_MSG4) as MSG4SenderC;
	components new AMReceiverC(AM_MSG4) as MSG4ReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MSG4SendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MSG4ReceiveQueueC;

	components new AMSenderC(AM_MSG5) as MSG5SenderC;
	components new AMReceiverC(AM_MSG5) as MSG5ReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MSG5SendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MSG5ReceiveQueueC;

	components new AMSenderC(AM_MSG6) as MSG6SenderC;
	components new AMReceiverC(AM_MSG6) as MSG6ReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MSG6SendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MSG6ReceiveQueueC;

	components new AMSenderC(AM_MSG7) as MSG7SenderC;
	components new AMReceiverC(AM_MSG7) as MSG7ReceiverC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MSG7SendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MSG7ReceiveQueueC;

	SRTreeC.Boot->MainC.Boot;
	SRTreeC.RadioControl -> ActiveMessageC;
	SRTreeC.Random->RandomC;
	SRTreeC.Seed->RandomMlcgC.SeedInit;

	//Timers wiring

	SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;
	SRTreeC.LostTaskTimer->LostTaskTimerC;
	SRTreeC.EpochTimer->EpochTimerC;
	SRTreeC.WaitforWakeUpTimer->WaitforWakeUpTimerC;
	SRTreeC.LevelTimer->LevelTimerC;
	SRTreeC.ChildrenTimer->ChildrenTimerC;
	SRTreeC.CalcValTimer->CalcValTimerC;

	// Message components wiring

	SRTreeC.Routing_2_1_SendQueue->RoutingSendQueue_2_1C;
	SRTreeC.Routing_2_1_ReceiveQueue->RoutingReceiveQueue_2_1C;
	SRTreeC.Routing_2_1_Packet->RoutingSender_2_1C.Packet;
	SRTreeC.Routing_2_1_AMPacket->RoutingSender_2_1C.AMPacket;
	SRTreeC.Routing_2_1_AMSend->RoutingSender_2_1C.AMSend;
	SRTreeC.Routing_2_1_Receive->RoutingReceiver_2_1C.Receive;

	SRTreeC.Routing_2_2_SendQueue->RoutingSendQueue_2_2C;
	SRTreeC.Routing_2_2_ReceiveQueue->RoutingReceiveQueue_2_2C;
	SRTreeC.Routing_2_2_Packet->RoutingSender_2_2C.Packet;
	SRTreeC.Routing_2_2_AMPacket->RoutingSender_2_2C.AMPacket;
	SRTreeC.Routing_2_2_AMSend->RoutingSender_2_2C.AMSend;
	SRTreeC.Routing_2_2_Receive->RoutingReceiver_2_2C.Receive;

	SRTreeC.MSG1SendQueue->MSG1SendQueueC;
	SRTreeC.MSG1ReceiveQueue->MSG1ReceiveQueueC;
	SRTreeC.MSG1Packet->MSG1SenderC.Packet;
	SRTreeC.MSG1AMPacket->MSG1SenderC.AMPacket;
	SRTreeC.MSG1AMSend->MSG1SenderC.AMSend;
	SRTreeC.MSG1Receive->MSG1ReceiverC.Receive;

	SRTreeC.MSG2SendQueue->MSG2SendQueueC;
	SRTreeC.MSG2ReceiveQueue->MSG2ReceiveQueueC;
	SRTreeC.MSG2Packet->MSG2SenderC.Packet;
	SRTreeC.MSG2AMPacket->MSG2SenderC.AMPacket;
	SRTreeC.MSG2AMSend->MSG2SenderC.AMSend;
	SRTreeC.MSG2Receive->MSG2ReceiverC.Receive;

	SRTreeC.MSG3SendQueue->MSG3SendQueueC;
	SRTreeC.MSG3ReceiveQueue->MSG3ReceiveQueueC;
	SRTreeC.MSG3Packet->MSG3SenderC.Packet;
	SRTreeC.MSG3AMPacket->MSG3SenderC.AMPacket;
	SRTreeC.MSG3AMSend->MSG3SenderC.AMSend;
	SRTreeC.MSG3Receive->MSG3ReceiverC.Receive;

	SRTreeC.MSG4SendQueue->MSG4SendQueueC;
	SRTreeC.MSG4ReceiveQueue->MSG4ReceiveQueueC;
	SRTreeC.MSG4Packet->MSG4SenderC.Packet;
	SRTreeC.MSG4AMPacket->MSG4SenderC.AMPacket;
	SRTreeC.MSG4AMSend->MSG4SenderC.AMSend;
	SRTreeC.MSG4Receive->MSG4ReceiverC.Receive;

	SRTreeC.MSG5SendQueue->MSG5SendQueueC;
	SRTreeC.MSG5ReceiveQueue->MSG5ReceiveQueueC;
	SRTreeC.MSG5Packet->MSG5SenderC.Packet;
	SRTreeC.MSG5AMPacket->MSG5SenderC.AMPacket;
	SRTreeC.MSG5AMSend->MSG5SenderC.AMSend;
	SRTreeC.MSG5Receive->MSG5ReceiverC.Receive;

	SRTreeC.MSG6SendQueue->MSG6SendQueueC;
	SRTreeC.MSG6ReceiveQueue->MSG6ReceiveQueueC;
	SRTreeC.MSG6Packet->MSG6SenderC.Packet;
	SRTreeC.MSG6AMPacket->MSG6SenderC.AMPacket;
	SRTreeC.MSG6AMSend->MSG6SenderC.AMSend;
	SRTreeC.MSG6Receive->MSG6ReceiverC.Receive;

	SRTreeC.MSG7SendQueue->MSG7SendQueueC;
	SRTreeC.MSG7ReceiveQueue->MSG7ReceiveQueueC;
	SRTreeC.MSG7Packet->MSG7SenderC.Packet;
	SRTreeC.MSG7AMPacket->MSG7SenderC.AMPacket;
	SRTreeC.MSG7AMSend->MSG7SenderC.AMSend;
	SRTreeC.MSG7Receive->MSG7ReceiverC.Receive;

}
