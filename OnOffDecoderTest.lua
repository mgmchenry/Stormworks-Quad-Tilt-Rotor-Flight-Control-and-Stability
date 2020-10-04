-- Stormworks OnOff Controller - 10 signals
sourceV0101="https://repl.it/@mgmchenry/Stormworks"

local _i, _o, _s, _m = input, output, screen, math
local getNumber, setNumber, getBool, setBool, dtb, tableUnpack =
  _i.getNumber, 
  _o.setNumber, 
  _i.getBool,
  _o.setBool,
  _s.drawTextBox,
  table.unpack

local isValidNumber, setOutput

local outBools, outNumbers
  , tickCount
  , r, g, b
  = {},{}
  , 0
  , 1, 1, 1

for i=1,10 do
  outBools[i] = false
  outNumbers[i+00] = 0
  outNumbers[i+10] = 0
  outNumbers[i+20] = 0
end

function isValidNumber(x,invalidValue)
  -- this evaluated correctly
  -- local x,y = 1,nil; print(x~=nil and type(x)=='number' and (y==nil or x~=y))
  --return x~=nil and type(x)=='number' and (invalidValue==nil or x~=invalidValue)
  -- this should work just as well and is a tad shorter:
  return x~=nil and type(x)=='number' and x~=invalidValue
end

function setOutput(channel, value)
  local boolVal, scale = false, 0
  if isValidNumber(value) then
    scale = value
    boolVal = value > 0
  elseif value then
    scale = 1
    boolVal = true
  end
  outBools[channel] = boolVal
  outNumbers[channel+00] = r * scale
  outNumbers[channel+10] = g * scale
  outNumbers[channel+20] = b * scale  
end


-- property.getNumber("")
-- Tick function that will be executed every logic tick
function onTick()
  tickCount = (tickCount % 100) + 1
  -- Boolean output is delayed one tick because it needs a composite read
  -- Number output is direct
  -- lua has to delay number output one tick to compensate

  -- send previous tick number values
  for i=1,10 do
    setNumber(i+00, outNumbers[i+00])
    setNumber(i+10, outNumbers[i+10])
    setNumber(i+20, outNumbers[i+20])

    litVal = tickCount/10 + 1 - i
    if litVal < 0 or litVal > 1 then
      litVal = 0
    end
    --print("i, litVal, range", i, litVal, (tickCount/10 + 1 - i))
    setOutput(i, litVal)

    setBool(i, outBools[i])
  end

end

--[[
function onDraw()
end
--]]