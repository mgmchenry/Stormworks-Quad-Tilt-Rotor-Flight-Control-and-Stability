-- Stormworks OnOff Controller - 10 signals
sourceV0102="https://repl.it/@mgmchenry/Stormworks"

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
  , indexCount
  , messageChannel, maxMessages
  , tickCount
  , r, g, b

  = {},{}
  , 10
  , 5, 10
  , 0
  , 1, 0.5, 1

for i=1,indexCount do
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

-- Tick function that will be executed every logic tick
function onTick()
  local pulseLength
    = clamp(math.floor(getNumber(1)),1,100)

  --[[
  r,g,b =
    getNumber(2)
    ,getNumber(3)
    ,getNumber(4)
  --]]

  tickCount = (tickCount % 100) + 1
  -- Boolean output is delayed one tick because it needs a composite read
  -- Number output is direct
  -- lua has to delay number output one tick to compensate

  -- send previous tick number values
  for i=1, indexCount do
    setNumber(i+00, outNumbers[i+00])
    setNumber(i+10, outNumbers[i+10])
    setNumber(i+20, outNumbers[i+20])
  end

  local baseIndex
  baseIndex = property.getNumber("BaseIndex")  
  
  for i = 1, maxMessages do
    local id, value, pair = -1, -1, {}

    id = getNumber(messageChannel - 2  + i * 2)
    value = getNumber(messageChannel - 1  + i * 2)

    if isValidNumber(id) and isValidNumber(value) then
      id = math.floor(id - baseIndex + 1)
      if id >= 1 and id <= indexCount then
        setOutput(id, value)
      end
    end
  end

  -- send current tick bool values
  for i=1, indexCount do
    setBool(i, outBools[i])
  end

end

--[[
function onDraw()
end
--]]