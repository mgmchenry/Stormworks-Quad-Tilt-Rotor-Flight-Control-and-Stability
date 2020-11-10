--[[
https://steamcommunity.com/sharedfiles/filedetails/?id=1742882342&searchtext=lua+radar+lidar
Credit:
Vulonkiin


Also check
https://steamcommunity.com/sharedfiles/filedetails/?id=1942471545&searchtext=lua+radar+lidar
SAKYamoney FORWARD LOOKING LUA RADAR

https://steamcommunity.com/sharedfiles/filedetails/?id=1902507801&searchtext=lua+radar+lidar
Jajajtec Radar System LUA (V 1.0)


--]]

X = {}
Y = {}
I = {}
S = {}
cursor = 1
wait_timer = 0
zone_timers = {}
function onTick()
	array_size = property.getNumber("Data Points")
	
	Light_R = property.getNumber("Light R")
	Light_G = property.getNumber("Light G")
	Light_B = property.getNumber("Light B")
	
	Background_R = property.getNumber("Background R")
	Background_G = property.getNumber("Background G")
	Background_B = property.getNumber("Background B")
	Background_A = property.getNumber("Background A")
	
	Border_R = property.getNumber("Border R")
	Border_G = property.getNumber("Border G")
	Border_B = property.getNumber("Border B")
	Border_A = property.getNumber("Border A")
	
	Dot_1 = property.getNumber("Dot Scale 1")
	Dot_2 = property.getNumber("Dot Scale 2")
	Dot_3 = property.getNumber("Dot Scale 3")
	
	Fade_scaler = property.getNumber("Fade Scaler")
	
	if property.getBool("Spin") then
		Facing = (input.getNumber(1) + 0.25) * -6.28319 --save as radian
	else
		Facing = (input.getNumber(1) - 0.25) * 6.28319 --save as radian
	end
	
	Rad = property.getNumber("Display Radius")
	Line_1 = property.getNumber("Range Line 1") / Rad
	Line_2 = property.getNumber("Range Line 2") / Rad
	Line_3 = property.getNumber("Range Line 3") / Rad
	
	Dist_1 = clip(input.getNumber(2), 2000) / Rad
	Dist_1S = input.getNumber(5)
	Dist_2 = clip(input.getNumber(3), 2000) / Rad
	Dist_3 = clip(input.getNumber(4), 2000) / Rad
	
	Cooldown = property.getNumber("Cycle Cooldown")
	
	if wait_timer >= Cooldown then
		if Dist_1 > 0 and Dist_1 < 1 then
			addContact(getX(Dist_1, Facing), getY(Dist_1, Facing), Dist_1S * Dot_1)
		end
		
		if Dist_2 > 0 and Dist_2 < 1 then
			addContact(getX(Dist_2, Facing), getY(Dist_2, Facing), Dot_2)
		end
		
		if Dist_3 > 0 and Dist_3 < 1 then
			addContact(getX(Dist_3, Facing), getY(Dist_3, Facing), Dot_3)
		end
		wait_timer = 0
	end
	wait_timer = wait_timer + 1
	
	Zone_count = property.getNumber("Zone Count")
	Zone_cooldown = property.getNumber("Zone On Cycles")
	Zone_dist = property.getNumber("Zone Trigger Distance") / Rad	
	
	if (Dist_1 > 0 and Dist_1 < Zone_dist) or (Dist_2 > 0 and Dist_2 < Zone_dist) or (Dist_3 > 0 and Dist_3 < Zone_dist) then
		zone_timers[math.floor(((Facing / 6.28319) + 0.25) * Zone_count + math.floor(Zone_count/2 + 0.5))] = Zone_cooldown
	end
	
	outputZones()
end

function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()	
	
	screen.setColor(Border_R, Border_G, Border_B, Border_A)
	screen.drawClear()
	
	screen.setColor(Background_R, Background_G, Background_B, Background_A)
	screen.drawCircleF(w/2, h/2, math.min(w,h)/2)
	
	screen.setColor(Light_R, Light_G, Light_B)
	screen.drawLine(w/2, h/2, getX(math.min(w,h)/2, Facing) + w/2, getY(math.min(w,h)/2, Facing) + h/2)
	
	screen.setColor(Border_R, Border_G, Border_B, Border_A)
	screen.drawCircle(w/2, h/2, Line_1 * math.min(w,h)/2)
	screen.drawCircle(w/2, h/2, Line_2 * math.min(w,h)/2)
	screen.drawCircle(w/2, h/2, Line_3 * math.min(w,h)/2)
	
	drawContacts()	
end

function getX(dist, angle)
	return dist * math.cos(angle)
end

function getY(dist, angle)
	return dist * math.sin(angle)
end

function addContact(newX, newY, size)
	if cursor >= array_size then
		cursor = 1
	end
	X[cursor] = newX
	Y[cursor] = newY
	I[cursor] = 255
	S[cursor] = size
	cursor = cursor + 1
end

function drawContacts()
	for i = 1, #X do
		screen.setColor(Light_R, Light_G, Light_B, I[i])
		screen.drawCircleF((X[i] * math.min(w,h)/2) + w/2, (Y[i] * math.min(w,h)/2) + h/2, S[i] * math.min(w,h))
		I[i] = I[i] * Fade_scaler
	end
end
	
function outputZones()
	for i = 0, Zone_count, 1 do
		if zone_timers[i] == nil then
			zone_timers[i] = 0
		end
		if zone_timers[i] > 0 then
			zone_timers[i] = zone_timers[i] - 1
			output.setBool(i+1, true)
			output.setNumber(i+1, zone_timers[i])
		else
			output.setBool(i+1, false)
		end
	end
end

function clip(X, num)
	if X == num then
		return 0
	else
		return X
	end
end