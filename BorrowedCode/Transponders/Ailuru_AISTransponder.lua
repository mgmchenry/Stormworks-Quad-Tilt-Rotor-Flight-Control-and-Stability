--[[
[AIS] Transponder
Ailurus's Workshop - May 16, 2019 @ 11:54p
https://steamcommunity.com/sharedfiles/filedetails/?id=1743381723
https://steamcommunity.com/sharedfiles/filedetails/?id=1743401099

This is an Automatic Identification System Transponder Microcontroller for vessels. As vessels get near your ship it will create and display a transponder on the monitor with information of other ships.

In upcoming updates, I will be removing the map to replace with a better transponder-like interface.
Right now other details of the vessel aren't displayed yet.

Shows other vessels on the map that are broadcasting on the transponders frequency. Does not lock onto a composite line so that every vessel gets a chance to communicate with each other.

Setup is pretty easy. Simply place the microcontroller, connect an antenna, gps, compass, linear speed, tilt sensor, throttle, and monitor.
]]

local MyGPS, MySpeed, MyHeading, MyTilt, MyThrottle, MyIdentifier
local Cache = {}
local Remove = {}
local Threshold = 5
local Timer = 0
local TransponderRadius = 2
local Zoom = 0.9
local Debug = false
math.randomseed(math.random(1,9999))
MyIdentifier = math.random(1, 9999)

local function GetDistance(GPS1, GPS2)
	local X1, Y1 = GPS1.X, GPS1.Y
	local X2, Y2 = GPS2.X, GPS2.Y
	
	X = math.abs(X1 - X2)
	Y = math.abs(Y1 - Y2)
	
	return math.sqrt( (X * X) + (Y * Y) )
end

local function GetEntry(Identifier)
	local Entry
	for i=1, #Cache do
		local v = Cache[i]
		if v and v.Identifier == Identifier then
			Entry = i
			break
		end
	end
	
	return Entry
end

local function IsValidGPS(GPS)
	local ValidX, ValidY
	if GPS.X ~= 0 then ValidX = true end
	if GPS.Y ~= 0 then ValidY = true end
	
	return ValidX and ValidY
end

-- Tick function that will be executed every logic tick
function onTick()
	Timer = Timer + 1/60

	local GPS = {}
	GPS["X"] = input.getNumber(1)
	GPS["Y"] = input.getNumber(2)
	GPS["LastUpdated"] = 0

	local Speed = input.getNumber(3) -- Curent Speed
	local Heading = input.getNumber(4) -- Current Heading
	local Tilt = input.getNumber(5) -- Current Tilt
	local Throttle = input.getNumber(6) -- Throttle Position
	local Identifier = input.getNumber(7) -- Unique Identifier for the boat
	
	GPS["Identifier"] = Identifier
	
	local EntryIndex = GetEntry(Identifier)
	if IsValidGPS(GPS) and not EntryIndex and Identifier ~= MyIdentifier then
		Cache[#Cache+1] = GPS
	elseif IsValidGPS(GPS) and EntryIndex and Identifier ~= MyIdentifier then
		Cache[EntryIndex] = GPS
	end
	
	MyGPS = {}
	MyGPS["X"] = input.getNumber(8)
	MyGPS["Y"] = input.getNumber(9)
	
	MySpeed = math.floor(input.getNumber(10))
	MyHeading = math.floor(input.getNumber(11))
	MyTilt = math.floor(input.getNumber(12))
	MyThrottle = math.floor(input.getNumber(13))
	
	if Timer >= 1 then
		Timer = Timer - 1
		
		for i=1, #Cache do
			local v = Cache[i]
			if v and v.LastUpdated > 10 then
				table.remove(Cache, i)
			elseif v then
				v.LastUpdated = v.LastUpdated + 1
			end
		end
	end
	
	output.setNumber(1, MyGPS.X)
	output.setNumber(2, MyGPS.Y)
	output.setNumber(3, MySpeed)
	output.setNumber(4, MyHeading)
	output.setNumber(5, MyTilt)
	output.setNumber(6, MyThrottle)
	output.setNumber(7, MyIdentifier)
	
	--output.setNumber(1, value * 10)		-- Write a number to the script's composite output
end

local function AddTransponder(GPS, Center)
	if not GPS or not Center or not IsValidGPS(GPS) then return end
	screen.setColor(237, 187, 7)
	
	local Scale = (screen.getHeight() / 2) / GetDistance(GPS, MyGPS)
	
	--local X = math.floor(Center.X + GPS.X * Scale)
	--local Y = math.floor(Center.Y + GPS.Y * Scale)
	
	local TX, TY = map.mapToScreen(MyGPS.X, MyGPS.Y, Zoom, w, h, GPS.X, GPS.Y)
	
	screen.drawCircleF(TX, TY, TransponderRadius)
end

-- Draw function that will be executed when this script renders to a screen
function onDraw()
	w = screen.getWidth()				  -- Get the screen's width and height
	h = screen.getHeight()					
	--screen.setColor(10, 10, 10)			 -- Set draw color to green
	--screen.drawCircleF(w / 2, h / 2, 30)   -- Draw a 30px radius circle in the center of the screen
	--screen.drawRectF(0, 0, w, h)
	
	local CenterW = w/2
	local CenterH = h/2
	
	--screen.setColor(255,255,255)
	--screen.drawCircleF(CenterW, CenterH, 10)
	
	screen.drawMap(MyGPS.X, MyGPS.Y, Zoom)
	
	screen.setColor(255, 0, 0)
	screen.drawCircleF(CenterW, CenterH, TransponderRadius)
	
	for i=1, #Cache do
		AddTransponder(Cache[i], {X=CenterW, Y=CenterH})
	end
	
	if Debug then
		screen.setColor(12,12,12)
		screen.drawTextBox(0, 0, w, h, "MyIdentifier: " .. MyIdentifier .. " {" .. MyGPS["X"] .. "," .. MyGPS["Y"] .. "}, Speed: " .. MySpeed .. ", Heading: " .. MyHeading .. " Tilt: " .. MyTilt .. ", Throttle: " .. MyThrottle .. "Entries: " .. #Cache, 0.1, 0.5)
	end
end