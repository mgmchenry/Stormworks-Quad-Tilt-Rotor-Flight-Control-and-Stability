-- Ark Rail Pulse Controller
sourceV0104="https://repl.it/@mgmchenry/Stormworks"

local _i, _o, _s, _m = input, output, screen, math
local getNumber, setNumber, getBool, setBool, dtb, tableUnpack =
  _i.getNumber, 
  _o.setNumber, 
  _i.getBool,
  _o.setBool,
  _s.drawTextBox,
  table.unpack

local isValidNumber, clamp
  , setOutput

function isValidNumber(x,invalidValue)
  -- this evaluated correctly
  -- local x,y = 1,nil; print(x~=nil and type(x)=='number' and (y==nil or x~=y))
  --return x~=nil and type(x)=='number' and (invalidValue==nil or x~=invalidValue)
  -- this should work just as well and is a tad shorter:
  return x~=nil and type(x)=='number' and x~=invalidValue
end

function clamp(v,minVal,maxVal) 
  --[[
	if v==nil then return nil end
	if v>maxVal then return maxVal end 
	if v<minVal then return minVal end 
	return v
  --]]
  return isValidNumber(v) and
    (v>maxVal and maxVal or
      (v<minVal and minVal) or
      v
    )
    or nil
end

local outBools, outNumbers, updates
  , tickCount, fireTick
  , frontWave, rearWave, velocity
  , r, g, b
  , maxMessages
  , maxBlocks
  = {},{},{}
  , 0, -1
  , 0, 0, 0
  , 1, 0.5, 1
  , 10
  , 30

function setOutput(channel, value)
  if not isValidNumber(channel) 
    or channel~=math.floor(channel) 
    or channel < 1 then
    return
  end

  local boolVal = false
  if isValidNumber(value) then
    boolVal = value > 0
  elseif value then
    value = 1
    boolVal = true
  else
    value = 0
  end
  if outNumbers[channel] ~= value then
    table.insert(updates, {channel, value})
    outBools[channel] = boolVal
    outNumbers[channel] = value
  end
end



-- Tick function that will be executed every logic tick
function onTick()
  local triggerIsOn
    , speed
    , ticksPerUpdate
    , pulseLength
    = getBool(1)
    , getNumber(1)
    , clamp(getNumber(2),1,100)
    , clamp(math.floor(getNumber(3)),1,100)

  setNumber(1, pulseLength)
  setNumber(2, r)
  setNumber(3, g)
  setNumber(4, b)

  if triggerIsOn and fireTick < 0 then
    fireTick = 0
    tickCount = 0
    frontWave, velocity 
      = 0, 1
  end

  if fireTick >= 0 then
    tickCount = tickCount + 1
  end

  if tickCount >= ticksPerUpdate then
    tickCount = 0
    fireTick = fireTick + 1

    if speed > 0 then
      local oldFront = math.floor(frontWave)
      frontWave = frontWave + velocity
      velocity = velocity + speed
      local front = math.floor(frontWave)
      for i=front, front+pulseLength do
        setOutput(i, 1)
      end
      for i=oldFront, oldFront+pulseLength do
        if i < front then
          setOutput(i, 0)
        end
      end
      if oldFront > 70 then
        tickCount, fireTick = -1, -1
      end
    else
      for i =1, # outNumbers do
        local value = outNumbers[i]
        if value > 0 then
          value = clamp(value - (1/pulseLength),0,1)
          if value < (1/pulseLength) then
            setOutput(i, 0)
          else
            outNumbers[i] = value
          end
        end
      end

      if fireTick >= 1 and fireTick <= 3 then
        setOutput(fireTick, 1)
        --setOutput(fireTick-1, 0)
      elseif fireTick > 40 then
        tickCount = -1
        fireTick = -1
      else
        local activeBlock = (fireTick - 4) * 2 + 4
        setOutput(activeBlock, 1)
        setOutput(activeBlock + 1, 1)
        --setOutput(activeBlock - 1, 0)
        --setOutput(activeBlock - 2, 0)
      end
    end
  end

  outChannel = 5
  for i = 1, maxMessages do
    local id, value, pair = -1, -1, {}

    if (# updates) > 0 then
      pair = table.remove(updates, 1)
      id = pair[1]
      value = pair[2]
    end
    setNumber(outChannel - 2  + i * 2, id)
    setNumber(outChannel - 1  + i * 2, value)
  end

end

--[[
function onDraw()
end
--]]