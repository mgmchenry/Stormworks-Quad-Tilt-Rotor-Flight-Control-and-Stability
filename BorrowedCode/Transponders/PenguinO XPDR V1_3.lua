UB = {0,0,1,0,0,
	  0,1,1,1,0,
	  1,1,1,1,1}

DB = {1,1,1,1,1,
	  0,1,1,1,0,
	  0,0,1,0,0}	
U = {}
D = {}
Digit = {}
Expiry = 0
Expmax = 300
IDENT_sus = 5
IDENT = 0
XMITF = 1090000000
PATT = "          0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
TXT = {"", "", "", "", "", ""}
ACK = false
DispSQ = "1200"
InN = input.getNumber
InB = input.getBool
ExB = output.setBool
ExN = output.setNumber
function onTick()
	tX = InN(3)
	tY = InN(4)
	T1 = InB(1)
	
	PINGED = false
	XMITTING = false
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
		SQUAWK = 1200
		ExB(27, true)
		ExN(27, SQUAWK)
		DispSQ = "1200"
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
		U[i] = T1 and isInRect(tX, tY, 30-(i*5), 14, 5, 7)
		D[i] = T1 and isInRect(tX, tY, 30-(i*5), 24, 5, 7)
		Digit[i] = string.sub(string.format("%07.0f", SQUAWK), -i, -i)
	end
	
	if T0 and not T1 then
		for i = 1, 4 do
			if isInRect(tX, tY, 30-(i*5), 14, 5, 7) then
					Digit[i] = Digit[i] + 1
					Digit[i] = Digit[i] % 8
					
			elseif isInRect(tX, tY, 30-(i*5), 24, 5, 7) then
					Digit[i] = Digit[i] + 8
					Digit[i] = Digit[i] - 1
					Digit[i] = Digit[i] % 8

			end
		end
		
		SQUAWK = ""
		for i = 1, 4 do
			SQUAWK = string.format("%.0f", Digit[i])..SQUAWK
		end
		ExB(27, true)
		ExN(27, SQUAWK)
		DispSQ = SQUAWK
	else
		ExB(27, false)

	end

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
		ExN(30, XMITF)
		XMITTING = true
		ACK = true
		Expiry = 0

	else
		ExN(30, -1)
		XMITTING = false
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
		screen.drawRectF(1, 8, 8, 17)
	else
		screen.setColor(128, 128, 128, 255)
		screen.drawRectF(1, 8, 8, 17)
	end
	
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