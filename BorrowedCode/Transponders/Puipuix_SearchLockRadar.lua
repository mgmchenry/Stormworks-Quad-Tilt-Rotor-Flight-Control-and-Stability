gb = input.getBool
gn = input.getNumber
sb = output.setBool
sn = output.setNumber
pgb = property.getBool
pgn = property.getNumber

L = pgb('Default Mode') -- mode
P = 0 -- Current position
OP = 0 -- Old pos (2 tick before)
OBL = false -- old button state
OBR = false -- old button state
OBI = false -- old button state
DS = {0,0,0,0,0} -- Distances
PS = {0,0,0,0,0} -- Powers
YS = {0,0,0,0,0} -- Yaws
CI = 1 -- current echo index
ON = pgb('Default On/Off')

RGS = {pgn('Range 1'),pgn('Range 2'),pgn('Range 3'),pgn('Range 4')} -- ranges
RG = pgn('Default Range')
-- cache
TMPD = 0 -- dist
TMPC = 0 -- count
TMPAY = 0 -- yaw angle
TMPB = false -- detection when radar backward ?

_T = 0.016/pgn('Rotate Duration') -- local tick duration to rotate the radar in 'Rotate Duration' second (0.016 = 60fps)
_FOV = pgn('Tracking FOV')
_ILC = pgb('Loot Crates')
_IP = pgb('Players')
_IS = pgb('Sharks')
_IM = pgb('Megalodon')

function onTick()
	-- Copy input to output
	for i = 1, 10 do
		sb(i, gb(i))
		sn(i, gn(i))
	end
	
	-- screen q click
	M = gb(1)
	MX = gn(1)
	MY = gn(2)
	-- or screen e click
	if not M then
		M = gb(2)
		MX = gn(3)
		MY = gn(4)
	end
	BR = M and click(MX, MY, 1, 24, 5, 7) -- button Range pressed
	BL = M and click(MX, MY, 7, 24, 5, 7) -- button Lock pressed
	BI = M and click(MX, MY, 13, 24, 17, 7) -- button Lock pressed
	sb(1, BR)
	sb(2, BL)
	sb(3, BI)
	sb(30, false)

-- lock toggle ?
	if (not M) and OBL then 
		L = not L
		sb(30, true)
	end
	OBL = BL
	sb(4, L)
		
	-- change range ?
	if (not M) and OBR then
		RG = (RG%4)+1
		sb(30, true)
	end
	OBR = BR
	sn(29, RGS[RG])

	-- change idle ?
	if (not M) and OBI then
		ON = not ON
		sb(30, true)
	end
	OBI = BI
	sb(32, ON)

	-- if enabled
	if ON then
		-- radar input
		DV = gn(5)
		DH = gn(6)
		PV = gn(7)
		PH = gn(8)
		SV = gn(9)
		SH = gn(10)
		
		-- average distance and strength
		d = 0
		c = 0
		s = 0
		if DV > 1 and L then
			d = d + DV
			s = s + SV
			c = c + 1
		end
		if DH > 1 then
			d = d + DH
			s = s + SH
			c = c + 1
		end
		if c > 0 then
			d = d/c
			s = s/c
			m = d*s
			if (_ILC and bet(m,395,405)) or (_IP and bet(m,5,30)) or (_IS and bet(m,500,1300)) or (_IM and bet(m,55000,65000)) then
				d = 0
				s = 0
			end
		end
		sn(27,d)
		sn(28,s)
		if L then
			-- we look forward to lock 1 target
			sn(30,0)
			sn(31, _FOV)
			sn(32, _FOV)
		else
			-- rotate
			sn(30,P)
			sn(31, 0.125)
			sn(32, 0.01)
			
			-- if echo
			if d > 0 then
				-- save radar data in cache
			
				TMPD = TMPD + d
				TMPC = TMPC + 1
				TMPAY = TMPAY + OP
			
				-- Correction in case we are looking backward
				-- (Angle change from 0.5 to -0.5 so the avg position will be incorrect)
				if TMPB then
					TMPAY = TMPAY + 1
				end
			
				-- if we will looking backward
				if OP > 0 and P < 0 then
					TMPB = true
				end
			
				-- store avg
				DS[CI] = TMPD / TMPC
				PS[CI] = 3
				tmp = TMPAY / TMPC
				-- Keep an angle between -0.5 and 0.5
				if tmp > 0.5 then
					tmp = tmp - 1
				end
				YS[CI] = tmp
			
				elseif TMPC > 0 then
				-- echo end			
				-- change index
				CI = (CI % 5) + 1
			
				-- reset
				TMPD = 0
				TMPC = 0
				TMPAY = 0
				TMPB = false 
			else
			-- idle
			end
			
			OP = P
			P = P + _T
			if P > 0.5 then
				P = -0.5
			end
			
			-- copy echo data to composite
			for i = 1, 5 do
				if DS[i] > 1 then
					--if will be updated in less than 2 tick
					if YS[i] > P and YS[i] < P + _T*2 then
						-- clear
						DS[i] = 0
						PS[i] = 0
						YS[i] = 0
					else
						PS[i] = PS[i]-_T*3
					end
				end
				sn(10+i, DS[i])
				sn(15+i, PS[i])
				sn(20+i, YS[i])
			end
		end
	end
end

function bet(x,min,max)
	return min <= x and x <= max
end

function click(x, y, rectX, rectY, rectW, rectH)
	return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end

function onDraw() 
	
end

--[[
  small display:
]]

gb = input.getBool
gn = input.getNumber
sb = output.setBool
sn = output.setNumber
pgb = property.getBool
pgn = property.getNumber
sc=screen.setColor
dl=screen.drawLine
dc=screen.drawCircle
ON = false
L = false
DV = 0
DH = 0
PV = 0
PH = 0
BLINK = false
P = 0
RG = 1000
BR = false
BL = false
BI = false
D = 0
_R = pgn('Display R')
_G = pgn('Display G')
_B = pgn('Display B')
_SDS = pgb('Small Display Scan')
DS = {0,0,0,0,0} -- Distances
PS = {0,0,0,0,0} -- Powers
YS = {0,0,0,0,0} -- Yaws

function onTick()
	ON = gb(32)
	L = gb(4)
	DV = gn(5)
	DH = gn(6)
	PV = gn(7)
	PH = gn(8)
	P = gn(30)
	D = gn(27)
	RG = gn(29)
	BLINK = gb(31)
	BR = gb(1)
	BL = gb(2)
	BI = gb(3)
	
	for i = 1, 5 do
		DS[i] = gn(10+i)
		PS[i] = gn(15+i)
		YS[i] = gn(20+i)
	end
end

-- Draw function that will be executed when this script renders to a screen
function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()

	if ON then
		if L then
			screen.setColor(_R*0.5,_G*0.5,_B*0.5,255)
			screen.drawTriangle(-1,-1,w/2,h,w+1,-1)
			screen.setColor(_R*0.5,_G*0.5,_B*0.5,15)
			screen.drawTriangleF(-1,-1,w/2,h,w+1,-1)
		
			if D > 0 then
				x = w*(0.5-PV*4)
				y = h-h*D/RG -- avg distance
				screen.setColor(_R*0.33,_G*0.33,_B*0.33,255)
				screen.drawLine(w/2,h,x,y)
				
				screen.setColor(_R,_G,_B,255)
				if (DV > 1 and DH > 1) or BLINK then
					screen.drawRect(x-3,y-3,6,6)
				end
			end
		else
			if _SDS then -- draw circular scan
				for i = 1, 5 do
					if DS[i] > 1 and RG > 0 then
						screen.setColor(_R,_G,_B,clamp(255*PS[i],0,255))
						x,y = rotate(0,-(DS[i]/RG)*(w/2),-YS[i])
						screen.drawCircleF(w/2-x,h/2+y,2)
					end
				end
		
				screen.setColor(_R*0.5,_G*0.5,_B*0.5,255)
				x,y = rotate(0,-0.5 * math.max(w,h),P)
				screen.drawLine(w/2,h/2,(w/2)+x,(h/2)+y)
			else -- draw flat scan
				screen.setColor(_R,_G,_B,255)
				x = w*(0.5+P)
				screen.drawLine(x,0,x,h)
			
				for i = 1, 5 do
					if DS[i] > 1 and RG > 0 then
						screen.setColor(_R,_G,_B,clamp(255*PS[i],0,255))
						x,y = w*(0.5+YS[i]),h-h*DS[i]/RG
						screen.drawCircleF(x,y,2)
					end
				end
			end
		end
	end
	-- buttons
	if BR then
		screen.setColor(_R*0.25,_G*0.25,_B*0.25,255)
	else
		screen.setColor(63,63,63,255)
	end
	screen.drawRectF(1, 24, 5, 7)
		
	if BL then
		screen.setColor(_R*0.25,_G*0.25,_B*0.25,255)
	else
		screen.setColor(63,63,63,255)
	end
	screen.drawRectF(7, 24, 5, 7)
	
	if BI then
		screen.setColor(_R*0.25,_G*0.25,_B*0.25,255)
	else
		screen.setColor(63,63,63,255)
	end
	screen.drawRectF(13, 24, 17, 7)
		
	screen.setColor(191,191,191,255)
	dst(2, 25,'R')
	dst(8, 25,'T')
	if ON then
		dst(14,25,'SCAN')
	else
		dst(14,25,'IDLE')
	end
	r = RG
	m = 'm'
	if r >= 1000 then
		r = r / 1000
		m = 'km'
	end
	screen.drawText(1, 1,'R:' .. string.format('%d', r//1) .. m)
end

function clamp(x,min,max)
	if x < min then
		return min
	elseif x > max then
		return max
	else
		return x
	end
end	

--draw small text (x, y, text)
function dst(x,y,t)
	l=string.len(t)
	for i=1,l do
		s=t:sub(i,i)
		if s=="A" then
			dc(x+1,y+1,1)
			dl(x,y+1,x,y+5)
			dl(x+2,y+1,x+2,y+5)
		elseif s=="C" then
			dl(x+1,y,x+3,y)
			dl(x+1,y+4,x+3,y+4)
			dl(x,y+1,x,y+4)
		elseif s=="D" then
			dl(x,y,x+2,y)
			dl(x,y+4,x+2,y+4)
			dl(x,y,x,y+5)
			dl(x+2,y+1,x+2,y+4)
		elseif s=="E" then
			dl(x,y,x+3,y)
			dl(x,y+2,x+2,y+2)
			dl(x,y+4,x+3,y+4)
			dl(x,y,x,y+5)
		elseif s=="I" then
			dl(x,y,x+3,y)
			dl(x,y+4,x+3,y+4)
			dl(x+1,y,x+1,y+5)
		elseif s=="L" then
			dl(x,y+4,x+3,y+4)
			dl(x,y,x,y+5)
		elseif s=="N" then
			dl(x,y,x+3,y)
			dl(x,y,x,y+5)
			dl(x+2,y,x+2,y+5)
		elseif s=="R" then
			dc(x+1,y+1,1)
			dl(x,y,x,y+5)
			dl(x+2,y+3,x+2,y+5)
		elseif s=="S" then
			dl(x+1,y,x+3,y)	
			dl(x,y+4,x+2,y+4)
			dl(x,y+1,x+3,y+4)
		elseif s=="T" then
			dl(x,y,x+3,y)
			dl(x+1,y,x+1,y+5)
		end
		x=x+4
	end
end

function rotate(x,y,a) 
	cos = math.cos(a*3.1415*2)
	sin = math.sin(a*3.1415*2)
	return (cos*x-sin*y), (sin*x + cos*y) 
end

--[[ large display ]]

gb = input.getBool
gn = input.getNumber
sb = output.setBool
sn = output.setNumber
pgb = property.getBool
pgn = property.getNumber

ON = false
DS = {0,0,0,0,0} -- Distances
PS = {0,0,0,0,0} -- Powers
YS = {0,0,0,0,0} -- Yaws
L = false
DV = 0
DH = 0
PV = 0
PH = 0
BLINK = false
P = 0
RG = 1000
OD = 0 -- old distance
D = 0
S = 0
_SCX = pgn('HUD Scale X')
_SCY = pgn('HUD Scale Y')
_TX = pgn('HUD Translate X')
_TY = pgn('HUD Translate Y')

_R = pgn('HUD R')
_G = pgn('HUD G')
_B = pgn('HUD B')

_LRS = pgn('HUD Lock Rect Size')
_SCAN = pgb('Display Scan On HUD')

function onTick()
	ON = gb(32)
	L = gb(4)
	DV = gn(5)
	DH = gn(6)
	PV = gn(7)
	PH = gn(8)
	P = gn(30)
	RG = gn(29)
	D = gn(27)
	S = gn(28)
	BLINK = gb(31)
	for i = 1, 5 do
		DS[i] = gn(10+i)
		PS[i] = gn(15+i)
		YS[i] = gn(20+i)
	end
end

-- Draw function that will be executed when this script renders to a screen
function onDraw()
	if ON then
		w = screen.getWidth()
		h = screen.getHeight()
		if L then
			screen.setColor(_R,_G,_B,255)
			if D < 1 then
				if BLINK then
					screen.drawLine(w*0.125, h*0.125, w*0.25, h*0.125)
					screen.drawLine(w*0.125, h*0.125, w*0.125, h*0.25)
				
					screen.drawLine(w*0.875, h*0.125, w*0.75, h*0.125)
					screen.drawLine(w*0.875, h*0.125, w*0.875, h*0.25)
				
					screen.drawLine(w*0.125, h*0.875, w*0.25, h*0.875)
					screen.drawLine(w*0.125, h*0.875, w*0.125, h*0.75)
				
					screen.drawLine(w*0.875, h*0.875, w*0.75, h*0.875)
					screen.drawLine(w*0.875, h*0.875, w*0.875, h*0.75)
					
					screen.drawRectF(w/2-1,h/2-1,2,2)
				end
			elseif D > 1 and (BLINK or (DV > 1 and DH > 1)) then
				x = clamp(w*(0.5-PV*4*_SCX)+_TX,0,w)
				y = clamp(h*(0.5-PH*4*_SCY)+_TY,0,h)
				screen.drawRect(x-_LRS/2,y-_LRS/2,_LRS,_LRS)
				
				if D > 0 then
					screen.drawText(x-_LRS/2,y+_LRS/2+3,string.format('%.2f',D/1000)..'km')
					screen.drawText(x-_LRS/2,y+_LRS/2+9,string.format('%d',((D-OD)/0.016)//1)..'m/s')
					screen.drawText(x-_LRS/2,y+_LRS/2+15,string.format('%.2f', (D*S)/1000)..'T')
				end
				OD = D
			end
		elseif _SCAN then
			
			for i = 1, 5 do
				if DS[i] > 1 and RG > 0 then
					screen.setColor(_R,_G,_B,clamp(255*PS[i],0,255))
					x,y = rotate(0,-(DS[i]/RG)*(w/2),-YS[i])
					screen.drawCircleF(w/2-x,h/2+y,2)
				end
			end
		
			screen.setColor(_R*0.5,_G*0.5,_B*0.5,255)
			x,y = rotate(0,-0.5 * math.max(w,h),P)
			screen.drawLine(w/2,h/2,(w/2)+x,(h/2)+y)
		end
	else
		-- idle
	end
end

function clamp(x,min,max)
	if x < min then
		return min
	elseif x > max then
		return max
	else
		return x
	end
end
	
function rotate(x,y,a) 
	cos = math.cos(a*3.1415*2)
	sin = math.sin(a*3.1415*2)
	return (cos*x-sin*y), (sin*x + cos*y) 
end