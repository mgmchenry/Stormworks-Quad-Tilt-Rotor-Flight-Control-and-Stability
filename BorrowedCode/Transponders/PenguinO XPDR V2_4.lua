--[[
https://steamcommunity.com/sharedfiles/filedetails/?id=1990775553&searchtext=transponder
PenguinO's Workshop - Sep 9, 2020 @ 12:53am
XPDR Air Type Transponder v2.4

This XPDR requires only 1 antenna to function since it's built for half-duplex operation.
It may miss some "ping" during sending "ack". (Limitation of being half-duplex)
Don't worry because the SSR will retry in next few ticks.


This device default start with squawk code 1200 for general aviation.
Set your assigned squawk code, the device will announce itself every few seconds when not getting a ping from any SSR station.
This device response with GPS data and altitude when pinged with assigned squawk code.
(also include 6-char aircraft type in reply)
The "ID" button for "IDENT" will send the "IDENT" signal when response to ping.
The "ID" button will stay glow for a short duration and reset itself.


2020/02/12 This device is now with built-in memory to save callsign assigned by SSR station.
2020/09/03 Default Callsign and Default Squawk code are now configurable from workbench.
2020/09/09 Lowercase in default callsign does not show to ATC → fixed forced CAPS now.



Has receive and transmit indicator on screen

*This XPDR never report heading or speed*
Heading and speed will be calculated by ATC controller on ground (SSR)



Due to being forced to use new antenna, the V1 requires 2 antennae to keep full-duplex mode functioning.

See XPDR v1 for Full-duplex built
https://steamcommunity.com/sharedfiles/filedetails/?id=1775297695

Logic connections
Col1
  XPDR In composite
  GPS X In number
  Altimeter In number
Col2
  XPDR Response out composite
  GPS Y in number
  Touchscreen composite in
Col3
  XMIT Signal bool out
  Frequency number out
  Monitor video out

Freq locked to 1030mhz rcv, 1090mhz snd
runs on 2 lua modules
]]

--[[
  lua module for txmit logic:
  bool[1] - trigger to send default callsign
]]

PATT = "          0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

function onTick()
	if input.getBool(1) then
		NICK = string.upper(property.getText("Default Callsign"))
		TXT = {"", "", "", ""}

		for i = 1, math.min(string.len(NICK), 12), 1 do
			CHR = string.find(PATT, string.sub(NICK, i, i))
			if CHR == nil then CHR = "00" end
			TXT[((i-1)%4)+1] = TXT[((i-1)%4)+1]..string.format("%02.0f", CHR)
		end

		
		output.setNumber(1, TXT[1])
		output.setNumber(2, TXT[2])
		output.setNumber(3, TXT[3])
		output.setNumber(4, TXT[4])
		output.setBool(1, true)
			
	else
		output.setNumber(1, 0)
		output.setNumber(2, 0)
		output.setNumber(3, 0)
		output.setNumber(4, 0)
		output.setBool(1, false)
	end
end

--[[
  lua module for main logic
  composite carrier from XPDR in

  n_in[1-6]: Touch w,h,x1,y1,x2,y2
  n_in[11-13]: GPSX, GPSY, Alt
  n_in[16-19]: Stored callsign
  n_in[27]: stored squawk

  b_in[1-2]: Touch t1, t2

  n_out[16-19]: Callsign out
  b_out[16]: Store Callsign
  b_out[30]: XMIT control

  

  mem storage for lua out squawk n_out[27] is disconnected for some(?) reason
]]

UB = {0,0,1,0,0,
	  0,1,1,1,0,
	  1,1,1,1,1}

DB = {1,1,1,1,1,
	  0,1,1,1,0,
	  0,0,1,0,0}	
U = {}
D = {}
Expiry = 0
Expmax = 300
IDENT_sus = 5
IDENT = 0
PATT = "          0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
TXT = {"", "", "", "", "", ""}
ACK = false
DispSQ = "1200"
XMITTING = false

InN = input.getNumber
InB = input.getBool
ExB = output.setBool
ExN = output.setNumber
function onTick()
	tX = InN(3)
	tY = InN(4)
	T1 = InB(1)
	
	PINGED = false
	GPS_X = InN(11)
	GPS_Y = InN(12)
	ALT = InN(13)
	TYPE = string.upper(property.getText("Aircraft Type"))
	
	C1 = InN(16)
	C2 = InN(17)
	C3 = InN(18)
	C4 = InN(19)
	
	SQUAWK = InN(27)
	if SQUAWK == nil then
		SQUAWK = property.getNumber("Default Squawk Code")
		ExB(27, true)
		ExN(27, SQUAWK)
		--DispSQ = "1200"
	else
		ExB(27, false)	
	end
	
	if InN(21) == 6 and InN(26) == SQUAWK then
		PINGED = true 
		if InN(7) > 0 then
			ExB(16, true)
			ExN(16, InN(7))
			ExN(17, InN(8))
			ExN(18, InN(9))
			ExN(19, InN(10))
		else
			ExB(16, false)
			ExN(16, 0)
			ExN(17, 0)
			ExN(18, 0)
			ExN(19, 0)
		end
	else
		ExB(16, false)
		ExN(16, 0)
		ExN(17, 0)
		ExN(18, 0)
		ExN(19, 0)
		ACK = false
	end
	
	if TXT[1] == "" then
		for i = 1, math.min(string.len(TYPE), 6), 1 do
			CHR = string.find(PATT, string.sub(TYPE, i, i))
			if CHR == nil then CHR = "00" end
			TXT[((i-1)%2)+1] = TXT[((i-1)%2)+1]..string.format("%02.0f", CHR)
		end
	end
	
	for i = 1, 4 do
		U[i] = T1 and isInRect(tX, tY, 30-(i*5), 13, 5, 7)
		D[i] = T1 and isInRect(tX, tY, 30-(i*5), 24, 5, 7)
	end
	
	if T0 and not T1 then
		for i = 1, 4 do
			if isInRect(tX, tY, 30-(i*5), 13, 5, 7) then
					ExB((i*2) - 1, true)
					
			elseif isInRect(tX, tY, 30-(i*5), 24, 5, 7) then
					ExB(i*2, true)
			end
		end
		
		--[[
		Stupid-Desync Fixed by PenguinO on v2.2
		Thanks to everyone for feedbacks and bug reports
		]]
		ExB(27, true)
		ExN(27, SQUAWK)

	else
		ExB(27, false)
		for i = 1, 8 do
			ExB(i, false)
		end
	end
	DispSQ = string.format("%04.0f", SQUAWK)
	
	if T1 and isInRect(tX, tY, 1, 8, 8, 17) then
		IDENT = IDENT_sus
	end
		
	if Expiry > Expmax or (PINGED and not ACK) then
		if PINGED then CODE = 7 else CODE = 1 end
		ExN(7, C1)
		ExN(8, C2)
		ExN(9, C3)
		ExN(10, C4)
		
		ExN(21, CODE)
		ExN(22, GPS_X)
		ExN(23, GPS_Y)
		ExN(24, ALT)
		ExN(25, TXT[1])
		ExN(29, TXT[2])
		ExN(26, SQUAWK)
		if IDENT > 0 then
			ExN(28, SQUAWK)
			IDENT = IDENT - 1
		else
			ExN(28, 0)
		end
		XMITTING = true
		ACK = true
		Expiry = 0
		ExB(30, XMITTING)
	else
		XMITTING = false
		ExB(30, XMITTING)
	end

	Expiry = Expiry + 1
	T0 = T1
end

function isInRect(x, y, rectX, rectY, rectW, rectH)
	return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end

function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()
	screen.setColor(0, 0, 0, 255)
	screen.drawClear()
	screen.setColor(255, 255, 255, 255)
	screen.drawTextBox(2, 2, w-4, 5, "XPDR", 0, -1)
	
	if IDENT > 0 then
		screen.setColor(255, 64, 0, 255)
	else
		screen.setColor(128, 128, 128, 255)
	end
	screen.drawRectF(1, 8, 8, 17)
	
	if PINGED then
		screen.setColor(0, 255, 0, 255)
		screen.drawText(16, 8, "R")
	end
	
	if XMITTING then
		screen.setColor(255, 0, 128, 255)
		screen.drawText(24, 8, "X")
	end

	screen.setColor(0, 0, 0, 255)
	screen.drawTextBox(2, 10, 6, 13, "ID", 0, 0)
	screen.drawRectF(1, 8, 1, 1)
	screen.drawRectF(8, 8, 1, 1)
	screen.drawRectF(1, 24, 1, 1)
	screen.drawRectF(8, 24, 1, 1)
	
	screen.setColor(255, 64, 0, 255)	
	screen.drawTextBox(8, 20, w-10, 5, DispSQ, 1, -1)
	
	for i = 1, 4 do
		if U[i] then screen.setColor(255, 64, 0, 255) else screen.setColor(255, 255, 255, 16) end
		PenguinDraw(30-(i*5),16,5,UB)

		if D[i] then screen.setColor(255, 64, 0, 255) else screen.setColor(255, 255, 255, 16) end
		PenguinDraw(30-(i*5),26,5,DB)
	end
end
	
function PenguinDraw(s,y,w,BM)
	x = s
	for i=1, #BM do
		if BM[i] == 1 then screen.drawRectF(x, y, 1, 1) end
		x = x + 1
		if i%w == 0 then x = s y = y + 1 end
	end
end



