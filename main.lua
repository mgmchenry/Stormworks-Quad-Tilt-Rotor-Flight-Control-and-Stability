-- Stormworks Lua module Test Helper Example Thing
-- V 0.4 Michael McHenry 2019-06-07
os.execute("clear")

-- why is repl.it on Lua 5.1 still?
pack = pack or function(...)
  return { n = select("#", ...), ... }
end

_ENV = _G

writeLine = print
expand = function(list, depth, prefix)
  depth = depth or 1
  prefix = (prefix or "") .. "->"
  for k,v,sv in pairs(list) do
    sv = string.sub(tostring(v),1,20)
    --print("key",k, "value", v)
    writeLine(prefix .. string.format("key: %s Value: %s Type: %s", k, sv, type(v)))
    if depth>1 and type(v)=="table" then
	    if v~=_ENV and v~=list then
        writeLine(prefix .. string.format("  %s table values", k))
		    expand(v, depth-1, prefix)
      else
        writeLine(prefix .. string.format("  %s is a nested table", k))
	    end
    end
  end
  if # list > 0 then
    writeLine("Array part size: "..tostring(# list))
    for i,v in ipairs(list) do
      v = string.sub(tostring(v),1,20)
      writeLine(" i:".. string.format("%02i",i) .." Value: "..v)
    end
  end
end


local function getStackInfo(levelsUp)
    local inspectLevel = 1 + (levelsUp or 1)
    local info, stackInfo = {}, {}

    while info do
      info = debug.getinfo(inspectLevel+1)
      if not info then
        --print("End of stack: " .. tostring(inspectLevel))
      else
        inspectLevel = inspectLevel + 1
        local infoText = string.format(
          info.currentline > 0 and "%s:%s " or "%s:(%s) "
          , info.short_src, tostring(info.currentline)
        )
           
        infoText = infoText .. "in "
          .. (
          info.what=="main" and "main chunk " 
            or info.what=="Lua" and info.name==nil and "lua "
            or info.what=="Lua" and ""
            or (info.what .. " ")
          ) .. (
          info.namewhat=="" and ""
            or info.namewhat=="upvalue" and "local "
            or (info.namewhat .. " ") 
          )

        infoText = infoText ..
          type(info.func) .. (
            info.name==nil and ""
            or (" " .. info.name)
          ) .. (
            type(info.func)=="function" and "()"
            or ""
          )
          
        infoText = infoText .. string.format(
          info.linedefined>0 and " [lines %i-%i]" or ""
          , info.linedefined, info.lastlinedefined
        )
        stackInfo[#stackInfo+1] = infoText
        --print(infoText)
      end
    end
    return stackInfo
end

local function printStackInfo(levelsUp, levelsSkipped)
    local stackInfo = getStackInfo(levelsUp)
    for level=2,#stackInfo-(levelsSkipped or 0) do
      print(stackInfo[level])
    end
end
--writeLine("_G global values")
--expand(_G, 3)
--die()

local __STRICT = false
local function enableStrictLua()
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

  __STRICT = true
    
  mt.__declared = {}

  mt.__newindex = function (t, n, v)
    if __STRICT and not mt.__declared[n] then
      local callerInfo = debug.getinfo(2, "S")
      if callerInfo==nil then
        if string.sub(n,1,7)=="_PROMPT" then
          --print("setting prompt on exit is normal")
        else
          print("attempt to assign undeclared variable and callerInfo is nil")
          --print(debug.traceback())
          printStackInfo(1,0)
          print(t,n,v)
        end
      elseif callerInfo.what ~= "main" and callerInfo.what ~= "C" then
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
      printStackInfo(1,0)
    end
    return rawget(t, n)
  end

  local function global(...)
    for _, v in ipairs{...} do mt.__declared[v] = true end
  end
end


inValues, outValues, inBools, outBools = {}, {}, {}, {}
table.unpack = table.unpack or unpack

enableStrictLua()
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
--dofile("Experiments/monitorCalibrationWithCubes.lua")
dofile("Experiments/loaderMC.lua")
--dofile("Experiments/CompositeDebugDisplay.lua")
--dofile("Experiments/SWGlobals.lua")
--dofile("NavSuite/ArkBeaconDisplay.lua")
--dofile("FlightControl/QuadTiltFlightControl.V0.Dev.lua")
--dofile("FlightControl/QuadTiltFlightControl.V0.Signals.lua")
--dofile("FlightControl/QuadTiltFlightControl.V0.Signals.PreMinify.lua")
--dofile("FlightControl/SW_FlightVis.lua")
--dofile("RailPulseEncoder.lua")
--dofile("OnOffDecoder.lua")

onTest(inValues, outValues, inBools, outBools, runTest)
--runTest(function() onTick() end, "onTick")
--runTest(function() onDraw() end, "onDraw")
-- Those return without doing anything because inValues are nil

-- Set an inValue so it continues to the error:

--[[
inValues[1] = 0
-- actually, set them all :P
for i=1,32 do
	inValues[i] = 0
  inBools[i] = false
end

runTest(function() onTick() end, "onTick")
runTest(function() onDraw() end, "onDraw")
]]


--[[
for run=1,52 do
	inValues[1] = inValues[1] + 0.5422
  inValues[2] = inValues[2] + 0.0032122
  inValues[3] = inValues[3] + 0.000232122
  inBools[1] = run > 25
  inValues[31] = run > 25 and 10 or 0
  runTest(function() onTick() end, "onTick")
  runTest(function() onDraw() end, "onDraw")
end
--]]

--[[
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
]]

__STRICT = false
return 0
--os.execute("clear")
--[[
Test call: onDraw
    ... 13 additional calls to drawText ...
 --> function call: drawText ( 3 parameters)
 --> f(number(185), number(7), string( 1.0))
 --> function call: getWidth ( 0 parameters)
 --> return number(98)
 --> function call: getHeight ( 0 parameters)
 --> return number(98)
 --> function call: drawText ( 3 parameters)
 --> f(number(1), number(0), string(#01 0.000000))
 --> function call: drawText ( 3 parameters)
 --> f(number(29), number(0), string( 0.0))
No Errors: Success!

PANIC: unprotected error in call to Lua API ([string "<eval>"]:57: attempt to index a nil value)
repl process died unexpectedly: exit status 1
]]