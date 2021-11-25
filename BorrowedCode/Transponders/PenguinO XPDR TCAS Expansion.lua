MY_CODE = -1
MY_X = 0
MY_Y = 0
MY_ALT = 0
MY_DIR = 0
MY_GS = 0
MY_VS = 0
MY_AGE = 100
MINALT = 300
RATE = 15 --seconds
MAXD = 600
Expiry = 1500
SENSE = 350
DC = {}
DX = {}
DY = {}
DA = {}
DD = {}
DS = {}
DV = {}
DE = {}
ADVICE = "NORMAL"
DRAWT = 0
--DBG = 0

function onTick()
	MY_AGE = MY_AGE +1
	if input.getNumber(11) > 0 and input.getBool(30) then --receive own data
		MY_DIR = math.atan(input.getNumber(13) - MY_Y, input.getNumber(12) - MY_X) --radian
		MY_GS = math.sqrt((input.getNumber(13) - MY_Y)^2 + (input.getNumber(12) - MY_X)^2) * 60 / MY_AGE --m/s
		MY_X = input.getNumber(12)
		MY_Y = input.getNumber(13)

		MY_VS = (input.getNumber(14) - MY_ALT) * 60 / MY_AGE --m/s
		MY_ALT = input.getNumber(14) --m
		
		MY_AGE = 0
		MY_CODE = input.getNumber(11)
	end
	--DBG = MY_GS
	
	isEXIST = false
	ALARM = false
	for k,v in pairs(DC) do
		DE[k] = DE[k] +1
		
		if DE[k] > Expiry then
			table.remove(DC, k)
			table.remove(DX, k)
			table.remove(DY, k)
			table.remove(DA, k)
			table.remove(DD, k)
			table.remove(DS, k)
			table.remove(DV, k)
			table.remove(DE, k)
		end
				
		if DC[k] == input.getNumber(26) then --update
			isEXIST = true
			DD[k] = math.atan(input.getNumber(23) - DY[k], input.getNumber(22) - DX[k])
			DS[k] = math.sqrt((input.getNumber(23) - DY[k])^2 + (input.getNumber(22) - DX[k])^2) * 60 / DE[k]
			DX[k] = input.getNumber(22)
			DY[k] = input.getNumber(23)
			DV[k] = (input.getNumber(24) - DA[k]) * 60 / DE[k]
			DA[k] = input.getNumber(24)
			DE[k] = 0
		end

	end
	
	if not isEXIST and input.getNumber(26) > 0 and input.getNumber(24) > MINALT and input.getNumber(26) ~= MY_CODE then
		table.insert(DC, input.getNumber(26))
		table.insert(DX, input.getNumber(22))
		table.insert(DY, input.getNumber(23))
		table.insert(DA, input.getNumber(24))
		table.insert(DD, 0)
		table.insert(DS, 0)
		table.insert(DV, 0)
		table.insert(DE, 0)
	end
	
	NEAREST = SENSE
	for i = 0, MAXD, RATE do
		X_CHK = MY_X + (MY_GS * i * math.cos(MY_DIR))
		Y_CHK = MY_Y + (MY_GS * i * math.sin(MY_DIR))
		A_CHK = MY_ALT + (MY_VS * i)

		for k,v in pairs(DC) do
			TX = DX[k] + (DS[k] * i * math.cos(DD[k]))
			TY = DY[k] + (DS[k] * i * math.sin(DD[k]))
			TA = DA[k] + (DV[k] * i)

			TEST = math.sqrt((X_CHK - TX)^2 + (Y_CHK - TY)^2 + (A_CHK - TA)^2)

			if TEST < NEAREST then
				NEAREST = TEST 
				ALARM = true
				if MY_ALT >= DA[k] or A_CHK <= MINALT then
				--A_CHK >= TA or A_CHK <= MINALT
					ADVICE = "CLIMB"
				else
					ADVICE = "DESCEND"
				end
			end
		end

		if ALARM then break end
	end
	
	ENABLE =input.getBool(11)
	if ENABLE and ALARM then
		output.setBool(11, true)		
	elseif ENABLE then
		ADVICE = "NORMAL"
		output.setBool(11, false)
	else
		ADVICE = "-OFF-"
		output.setBool(11, false)
	end
	output.setNumber(1, #DC)
end


function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()
	screen.setColor(0, 0, 0)
	screen.drawClear()

	if not ENABLE then
		screen.setColor(32, 32, 32, 200)
		screen.drawText(2, 12, ADVICE)

	elseif ENABLE and not ALARM then
		screen.setColor(0, 255, 0, 200)
		screen.drawText(2, 12, ADVICE)
		
	elseif ENABLE and ALARM then
		DRAWT = DRAWT +0.5
		if DRAWT > w/2 then DRAWT = -w/2 end
		screen.setColor(255, 0, 0, 255)
		screen.drawText(-DRAWT, 12, ADVICE)
		if ADVICE == "CLIMB" then
			screen.drawTriangleF(2, 10, w/2, 2, w-2, 10)
		else
			screen.drawTriangleF(2, 18, w/2, 26, w-2, 18)
		end
		screen.drawRectF(0, h-7, w, 7)
	end
	
	screen.setColor(255, 255, 255, 200)
	screen.drawText(4, h-6, "TCAS")
	--screen.drawText(4, h-6, DBG)
	
	for i = 1, #DC, 1 do
		screen.drawRectF(22+i*2, h-2, 1, 1)
	end
end