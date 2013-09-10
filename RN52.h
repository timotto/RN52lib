/*
 * Virtual C++ Class for RovingNetworks RN-52 Bluetooth modules
 * Copyright (C) 2013  Tim Otto
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 *  Created on: Jun 21, 2013
 */

#ifndef RN52_H_
#define RN52_H_
#include <configuration.h>

namespace RN52 {

class RN52driver {
public:
	enum BtProfile { IAP, SPP, A2DP, HFP };
	enum Mode { COMMAND, DATA };
	enum Error { TIMEOUT, OVERFLOW, NOTCONNECTED, PROTOCOL };
	enum AVCRP { PLAYPAUSE, NEXT, PREV, VOLUP, VOLDOWN, PLAY, PAUSE };

	RN52driver();
	virtual ~RN52driver(){}

	int fromUART(const char c);
	int fromUART(const char *data, int size);
	int toSPP(const char c);
	int toSPP(const char *data, int size);

	bool isA2DPConnected() { return a2dpConnected; }
	bool isSPPConnected() { return sppConnected; }
	bool isStreamingAudio() { return streamingAudio; }

	void reconnectLast();
	void disconnect();
	void visible(bool visible);
	int sendAVCRP(AVCRP cmd);

protected:
	void refreshState();
	int queueCommand(const char *cmd);

private:
	Mode mode;
	bool enterCommandMode;
	bool enterDataMode;
	int state;
	int profile;
	bool a2dpConnected;
	bool sppConnected;
	bool streamingAudio;

	char sppTxBuffer[SPP_TX_BUFFER_SIZE];
	int sppTxBufferPos;
	char cmdRxBuffer[CMD_RX_BUFFER_SIZE];
	int cmdRxBufferPos;

	const char *currentCommand;
	const char *commandQueue[CMD_QUEUE_SIZE];
	int commandQueuePos;

	void prepareCommandMode();
	void prepareDataMode();
	int parseCmdResponse(const char *data, int size);
	void parseQResponse(const char data[4]);

	virtual void onStateChange(int state, int profile) {};
	virtual void onProfileChange(BtProfile profile, bool connected) {};
	virtual void onStreaming(bool streaming) {};
	virtual void toUART(const char* c, int len) = 0;
	virtual void fromSPP(const char* c, int len) = 0;
	virtual void setMode(Mode mode) = 0;
	virtual void debug(const char *c) {};
	virtual void onError(int location, Error error) {};
};

} /* namespace RN52 */
#endif /* RN52_H_ */
