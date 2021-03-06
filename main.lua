-- Stormworks Lua module Test Helper Example Thing
-- V 0.4 Michael McHenry 2019-06-07
os.execute("clear")

--
-- strict.lua
-- checks uses of undeclared global variables
-- All global variables must be 'declared' through a regular assignment
-- (even assigning nil will do) in a main chunk before being used
-- anywhere or assigned to inside a function.
--
local mt = getmetatable(_G)
if mt == nil then
  mt = {}
  setmetatable(_G, mt)
end

__STRICT =
   true
  -- false
  
mt.__declared = {}

mt.__newindex = function (t, n, v)
  if __STRICT and not mt.__declared[n] then
    local w = debug.getinfo(2, "S").what
    if w ~= "main" and w ~= "C" then
      --error
      print("assign to undeclared variable '"..n.."'", 2)
    end
    mt.__declared[n] = true
  end
  rawset(t, n, v)
end
  
mt.__index = function (t, n)
  if not mt.__declared[n] and debug.getinfo(2, "S").what ~= "C" then
    --error
    print("variable '"..n.."' is not declared", 2)
  end
  return rawget(t, n)
end

function global(...)
   for _, v in ipairs{...} do mt.__declared[v] = true end
end


inValues, outValues, inBools, outBools = {}, {}, {}, {}
table.unpack = table.unpack or unpack

-- Set up SW environment
dofile("Stormworks_Stub.lua")

propValues["BaseIndex"] = 1
--[[
propValues["Ark0"] =
[ [
string,math,input,output,property
,tostring,tonumber,ipairs,pairs
,input.getNumber,input.getBool,output.setNumber
] ]
propValues["Ark1"] =
[ [
,math.abs,math.sin,math.cos,math.max,math.min
,math.atan,math.sqrt,math.floor,math.pi
] ] 
--]]
propValues["Ark0"] =
[[
string,math,input,output,property,screen
,tostring,tonumber,ipairs,pairs,string.format
,input.getNumber,input.getBool,output.setNumber
]]
propValues["Ark1"] =
[[
,screen.drawTextBox,screen.drawLine,screen.getWidth,screen.getHeight,screen.setColor
]] 
propValues["Ark2"] =
[[
,math.abs,math.sin,math.cos,math.max,math.min
,math.atan,math.sqrt,math.floor,math.pi
]] 
propValues["ArkSF0"] =
[[
setColor,drawLine,drawCircle,drawCircleF,drawRectF,drawTriangleF,drawText,drawTextBox,getWidth,getHeight
]]
propValues["ArkGF0"] = 
"map.screenToMap,map.mapToScreen,input.getNumber,input.getBool,output.setNumber,output.setBool,string.format,type"
propValues["ArkMF0"] =
"abs,min,max,sqrt,ceil,floor,sin,cos,atan,pi"

--dofile("QuadFlightControl.V0.07.15.lua")
--dofile("ScaleController.V2.lua")
--dofile("QuadFlightControl.V0.09.18.lua")

--dofile("FlightControl/QuadTiltFlightControl.V0.TinySig.lua")
--dofile("Experiments/keyInputAxisInfo.lua")
--dofile("Experiments/seatSensitivityVisualizer.lua")
dofile("NavSuite/ArkBeaconDisplay.lua")
--dofile("FlightControl/QuadTiltFlightControl.V0.Dev.lua")
--dofile("FlightControl/QuadTiltFlightControl.V0.Signals.lua")
--dofile("FlightControl/QuadTiltFlightControl.V0.Signals.PreMinify.lua")
--dofile("FlightControl/SW_FlightVis.lua")
--dofile("RailPulseEncoder.lua")
--dofile("OnOffDecoder.lua")

--runTest(function() onTick() end, "onTick")
--runTest(function() onDraw() end, "onDraw")
-- Those return without doing anything because inValues are nil

-- Set an inValue so it continues to the error:
inValues[1] = 0
-- actually, set them all :P
for i=1,32 do
	inValues[i]= 0
end

runTest(function() onTick() end, "onTick")
runTest(function() onDraw() end, "onDraw")

-- Set rps high enough to trigger hover code
inValues[29] = 80
for i=5,26 do
	inValues[i]= 0
end
inValues[5] = 3
inValues[6] = 0.75
inBools[1] = true

runTest(function() onTick() end, "onTick")
runTest(function() onDraw() end, "onDraw")

for i=1,32 do
	inValues[i]=1
end
inValues[29] = 80

runTest(function() onTick() end, "onTick")
runTest(function() onDraw() end, "onDraw")

--os.execute("clear")