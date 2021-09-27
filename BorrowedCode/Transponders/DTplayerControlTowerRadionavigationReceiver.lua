--[[
from DTplayer Control Tower Radionavigation Receiver
]]

freqLow = 500
freqHigh = 600

maxDelay = 10
delay = maxDelay

RFreq = freqLow
TFreq = freqLow

zoom = 15

objects = {}

selected = 0

function onTick()
	
	
	gpsX = input.getNumber(13)
	gpsY = input.getNumber(14)
	
	if input.getBool(1) then
		local found = false
		
		for i = 1, #objects do
			if RFreq == objects[i].freq then
				objects[i].x = input.getNumber(1)
				objects[i].y = input.getNumber(2)
				objects[i].alt = input.getNumber(3) * 3.28084
				objects[i].spd = input.getNumber(4) * 1.943844
				found = true
			end
		end
		if not found then
			
			local name = ""
			for i = 5, 12 do
				name = name .. string.char(input.getNumber(i))
			end
			
			table.insert(objects, {freq = RFreq, x = input.getNumber(1), y = input.getNumber(2), alt = input.getNumber(3) * 3.28084, spd = input.getNumber(4) * 1.943844, call = name})
			
			
		end
		
	end
	
	for i = 1, #objects do
		if RFreq == objects[i].freq and not input.getBool(1) then
			table.remove(objects, i)
			if selected > #objects then
				selected = 0
			end
			break
		end
	end
	
	
	RFreq = RFreq + 1
	if RFreq > freqHigh then RFreq = freqLow end
	
	output.setNumber(1, RFreq)
	
	
	if input.getBool(2) then
		selected = selected + 1
		if selected > #objects then
			selected = 0
		end
	end
	
	
		
end


function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()
	
	if w > 280  then
	
		screen.setMapColorOcean(0, 0, 0)
		screen.setMapColorShallows(3, 3, 3)
		screen.setMapColorLand(20, 20, 20)
		screen.setMapColorGrass(15, 15, 15)
		screen.setMapColorSand(15, 15, 15)
		screen.setMapColorSnow(15, 15, 15)
		
		screen.drawMap(gpsX, gpsY, zoom)
		
		screen.setColor(255, 255, 255)
		screen.drawText(1, 1, "Objects Tracked: " .. #objects)
		
		
		if selected > 0 then screen.setColor(50, 50, 50) end
		
		for i = 1, #objects do
			local object = objects[i]
			x, y = map.mapToScreen(gpsX, gpsY, zoom, w, h, object.x, object.y)
			
			screen.drawText(x+3, y-2, object.call)
			screen.drawText(x+3, y+4, math.floor(object.alt + 0.5))
			
			screen.drawRectF(x, y, -2, 2)
		end
		
		if selected > 0 then
			x, y = map.mapToScreen(gpsX, gpsY, zoom, w, h, objects[selected].x, objects[selected].y)
			
			screen.setColor(0, 200, 0)
			screen.drawText(x+3, y-2, objects[selected].call)
			screen.drawText(x+3, y+4, math.floor(objects[selected].alt + 0.5))
			screen.drawText(x+3, y+10, math.floor(objects[selected].spd + 0.5))
			
			screen.drawRectF(x, y, -2, 2)
			
			screen.drawText(1, 7, objects[selected].call)
			screen.drawText(1, 13, "Altitude " .. math.floor(objects[selected].alt + 0.5) .. " ft")
			screen.drawText(1, 19, "Speed " .. math.floor(objects[selected].spd + 0.5) .. " kias")
			screen.drawText(1, 25, "Frequency " .. objects[selected].freq - 5)
		end
	else
		
		screen.setColor(10, 10, 20)
		screen.drawRectF(0, 0, w, 8)
		for i = 2, 12 do
			screen.setColor(0, 0, 0)
			if i % 2 == 0 then screen.setColor(2, 2, 2) end
			
			screen.drawRectF(0, (i-1) * 8, w, 8)
			
		end
		
		screen.setColor(255, 255, 255)
		screen.drawText(2, 1, "Aircraft")
		screen.drawText(48, 1, "Altitude ft")
		screen.drawText(109, 1, "Speed kias")
		
		screen.drawLine(45, 7, 45, h)
		screen.drawLine(106, 7, 106, h)
		
		for i = 1, math.min(#objects, 11) do
			screen.drawText(2, (i * 8) + 1, objects[i].call)
			screen.drawText(48, (i * 8) + 1, math.floor(objects[i].alt + 0.5))
			screen.drawText(109, (i * 8) + 1, math.floor(objects[i].spd + 0.5))
		end
		
		if selected > 0 and selected < 12 then
			screen.setColor(0, 200, 0)
			
			screen.drawText(2, (selected * 8) + 1, objects[selected].call)
			screen.drawText(48, (selected * 8) + 1, math.floor(objects[selected].alt + 0.5))
			screen.drawText(109, (selected * 8) + 1, math.floor(objects[selected].spd + 0.5))
		end
	end
end

--[[
Weather info module:
  
]]

zoom = 2.5

gpsX = 0
gpsY = 0

windSpd = 0
windDir = 0

rain = 0
humid = 0
time = 0

formattedTime = ""
weather = ""
visibility = ""


function onTick()

	gpsX = input.getNumber(1)
	gpsY = input.getNumber(2)
	
	windSpd = input.getNumber(3)
	windDir = input.getNumber(4)
	
	rain = input.getNumber(5)
	humid = input.getNumber(6)
	time = input.getNumber(7)
	
	compassDir = input.getNumber(8) * -1
	
end


function onDraw()
	
	--wind direction
	local newWindDir = windDir + compassDir
	newWindDir = newWindDir - math.floor(newWindDir)
	
	
	--time
	local minutes = math.floor((1440 * time) % 60)
	local hours = math.floor(24 * time)
	
	if minutes < 10 then minutes = '0' .. minutes end
	if hours < 10 then hours = '0' .. hours end
	
	formattedTime = hours .. ':' .. minutes
	
	--weather
	if rain < 0.01 then weather = 'No Rain'
	elseif rain < 0.50 then weather = 'Light Rain'
	elseif rain < 0.70 then weather = 'Rainy'
	elseif rain < 0.90 then weather = 'Heavy Rain'
	else weather = 'Stormy' end
	
	--visibility
	if humid < 0.10 then visibility = 'Good'
	elseif humid < 0.40 then visibility = 'Moderate'
	else visibility = 'Poor' end
	
	--screen
	w = screen.getWidth()
	h = screen.getHeight()
	
	screen.drawMap(gpsX - 350, gpsY, zoom)
	
	screen.setColor(10, 10, 11)
	screen.drawRectF(0, 0, 52, h)
	screen.setColor(255, 255, 255)
	screen.drawLine(52, 0, 52, h)
	screen.drawLine(0, 16, 52, 16)
	screen.drawLine(0, 75, 52, 75)
	
	
	screen.drawText(1, 2, formattedTime)
	screen.drawText(1, 9, weather)
	screen.drawText(1, 19, 'Wind')
	screen.drawText(1, 26, math.floor((windSpd * 1.943844) + 0.5) .. ' kias')
	screen.drawText(1, 33, math.floor((newWindDir * 360) + 0.5) .. ' deg')
	screen.drawText(1, 80, 'Visibility')
	screen.drawText(1, 87, visibility)
	
	screen.drawRectF(25, 53, 3, 3)
	screen.setColor(0, 200, 0)
	
	newWindDir = newWindDir * 6.283185
	screen.drawLine(26, 53, 26 + (math.sin(newWindDir) * math.min(windSpd, 15)), 53 + (math.cos(newWindDir) * math.min(windSpd, 15) * -1))
	
end