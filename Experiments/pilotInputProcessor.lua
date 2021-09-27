-- for Ark Pilot Input Combiner V3x03
local _i, _o, _s, _m
  , _tonumber, unpack, ipairz
  = input, output, string, math
  , tonumber, table.unpack, ipairs

local i_getNumber, i_getBool
  , min, max, floor
  , format
  = _i.getNumber, _i.getBool
  , _m.min, _m.max, _m.floor
  , string.format

local outLines
  , displayLine
  , isPressed, isHeld

  , valueBuffers
  , bufferLength, bufferPosition

  , pilotInputs, pilotOutputs

  -- minified function names
  , writeLine, expand
  , isValidNumber, clamp, moduloCorrect, getSmoothedValue
  = {}
  , 1
  , false, false

  , { -- {R,G,B}, min, range
      {lineDef={{255,0,0,255},-1,2}} -- axisInput
    , {lineDef={{0,255,0,128},-2,4}} -- axisVel
    , {lineDef={{0,0,255,64},-2,4}} -- sustain
    --, {lineDef={{255,255,0,32},-5,10}} -- sustain
    , {lineDef={{255,0,255},-1,2}} -- keyStatRaw
    , {lineDef={{255,255,255},-1,2}} -- axisKeyState
    , {lineDef={{255,128,128},-1,2}}  -- customAxisValue
    }
  , 30, 0

  , {}, {} -- seatInputs, pilotOutputs
  
writeLine = function(text)
	text = text or ""
	local lineNum = #outLines+1
	outLines[lineNum] = format("%i", lineNum) .. "|" .. text
end

function isValidNumber(x,invalidValue)
  return _tonumber(x)==x and x~=invalidValue
end
function clamp(v,minVal,maxVal) 
  return max(min(v,maxVal),minVal)
end
function moduloCorrect(value, period, offset)
  offset = offset or 1
  return 
    period and ( (value - offset) % period + offset )
    or value
end

getSmoothedValue = function(valueBuffer, smoothTicks, delayTicks)
  smoothTicks
    , delayTicks 

    = smoothTicks or 1
    , delayTicks or 0
  
  local diffSum
    , sample
    , baseValue

    = 0 -- avg default. nil values will coalesce to 0

  -- no more delay ticks than we have on hand. Leave room for one sample. minimum 0
  delayTicks = clamp(delayTicks, 0, bufferLength - 1)
  -- make sure we get at least 1 tick, but no more ticks than the buffer contains or wrapping back to current
  smoothTicks = clamp(smoothTicks, 1, bufferLength - delayTicks)
  
  for i = 0, smoothTicks - 1 do
    --sampleIndex = moduloCorrect(bufferPosition - delayTicks - i , bufferLength)
    --sample = valueBuffer[sampleIndex]
    sample = valueBuffer[--sampleIndex
      moduloCorrect(bufferPosition - delayTicks - i , bufferLength)]

    baseValue = baseValue or sample
    diffSum = diffSum + (
      isValidNumber(sample) and 
      moduloCorrect(sample - baseValue
        , nil, nil)
      or 0)
  end
  return 
  moduloCorrect(
    diffSum / smoothTicks + (baseValue or 0)
    ,nil ,nil)
endww

function getSeatConfig(seatId)
end

function onTick()
  local seat
  for i = 1, 4 do
    seat = 
  end

	local screenX
    , screenY
    , inputX
    , inputY
    , touch01
    , axis01, axis02, axis03, axis04
    , prevIndex
    , axisKeyState, customAxisValue

	= i_getNumber(1)
	  , i_getNumber(2)
	  , i_getNumber(3)
	  , i_getNumber(4)
	  , i_getBool(1)
    , i_getNumber(9)
    , i_getNumber(10)
    , i_getNumber(11)
    , i_getNumber(12)


  bufferPosition = (bufferPosition % bufferLength) + 1
  prevIndex = ((bufferPosition-1) % bufferLength) + 1

  -- axis
  valueBuffers[1][bufferPosition] = axis04
  -- velocity (value delta)
  valueBuffers[2][bufferPosition] = (getSmoothedValue(valueBuffers[1],1,0)
    - getSmoothedValue(valueBuffers[1],1,1)) * 60
  -- sustain
  valueBuffers[3][bufferPosition] = (getSmoothedValue(valueBuffers[1],1,0)
    / getSmoothedValue(valueBuffers[1],1,1))

  -- axis Keypress State
  axisKeyState = (
    -- currentValue
    getSmoothedValue(valueBuffers[1],1,0)    
    -- subtract base value - prev tick axis value after 0.99 decay
    - (getSmoothedValue(valueBuffers[1],1,1) * 0.99)
    )

  valueBuffers[4][bufferPosition] = axisKeyState
  axisKeyState = floor(axisKeyState * 1000 + 0.5) / 10
  valueBuffers[5][bufferPosition] = axisKeyState

  customAxisValue = (getSmoothedValue(valueBuffers[6],1,1) or 0) * 0.99
    + axisKeyState * 0.01
  valueBuffers[6][bufferPosition] = customAxisValue



	isPressed = touch01 and not isHeld
	isHeld = touch01

  
	outLines = {}
	writeLine("Ax1- " .. format("%f", axis04))
	writeLine("Sus-" .. format("%f", valueBuffers[3][bufferPosition]))
	writeLine("raw-" .. format("%f", valueBuffers[4][bufferPosition]))
	writeLine("key-" .. format("%f", valueBuffers[5][bufferPosition]))
	writeLine("cus-" .. format("%f", valueBuffers[6][bufferPosition]))
	if isPressed then
		isPressed = false
		displayLine = (displayLine % (# outLines)) + 1
		if displayLine == 1 then
		  outLines = {}
		end
	end
end

function setC(r,g,b)
	S.setColor(r*0.4,g*0.4,b*0.4,255)
end

function onDraw()
	S=screen

  local screenWidth, screenHeight
    , xMargin, yMargin
    = S.getWidth()
    , S.getHeight()

  --if not isHeld then return end
  xMargin = clamp(20, 0, screenWidth-30)
  yMargin = clamp(10, 0, screenHeight-21)
	setC(200,200,200)
	
	--S.drawClear()
	
  for i,valueBuf in ipairz(valueBuffers) do
    for xi=1, bufferLength do
      local tickXStart
        , tickXEnd
        , lColor, lMin, lRange
        , lVal0, lVal1 

        = (screenWidth-xMargin) * (xi - 1) / bufferLength
        , (screenWidth-xMargin) * xi / bufferLength
        , unpack(valueBuf.lineDef)
      --lRange = lMax - lMin
      --getSmoothedValue = function(signalKey, elementKey, smoothTicks, delayTicks)
      lVal0 = clamp((getSmoothedValue(valueBuf, 1, xi-1) - lMin)/lRange,0,1) 
        * (screenHeight-yMargin)
      lVal1 = clamp((getSmoothedValue(valueBuf, 1, xi) - lMin)/lRange,0,1) 
        * (screenHeight-yMargin)
      setC(unpack(lColor))
      S.drawLine(
          xMargin + tickXStart
        , screenHeight - lVal0
        , xMargin + tickXEnd
        , screenHeight - lVal1)
    end
  end

	setC(0,0,0)
	maxLines = math.floor(screenHeight / 6)
	for i=0,maxLines do
		text = outLines[i - 1 + displayLine] or ""
		S.drawText(1,6 * i, text)
	end
end