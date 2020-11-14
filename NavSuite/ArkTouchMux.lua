-- Stormworks Ark TouchMux touchscreen multiplexer
-- V 01.01a Michael McHenry 2020-11-13
-- Minifies to 785 ArkTMux1x01a
source={"ArkTMux1x01a","repl.it/@mgmchenry"}

local G, prop_getText, gmatch, unpack
  , commaDelimited
  , empty, nilzies
  -- nilzies not assigned by design - it's just nil but minimizes to one letter

	= _ENV, property.getText, string.gmatch, table.unpack
  , '([^,\r\n]+)'
  , false

local getTableValues--, stringUnpack 
= 
function(container, iterator, local_returnVals, local_context)
	local_returnVals = {}
	for key in iterator do
    local_context = container
    --__debug.AlertIf({"key["..key.."]"})
    for subkey in gmatch(key,'([^. ]+)') do
      --__debug.AlertIf({"subkey["..subkey.."]"})
      local_context = local_context[subkey]
      --__debug.AlertIf({"context:", string.sub(tost
      ring(local_context),1,20)})
    end
    local_returnVals[#local_returnVals+1] = local_context
	end
	return unpack(local_returnVals)
end

local abs, min, max, sqrt
  , ceil, floor
  , si, co, atan, pi
  = getTableValues(math,gmatch(
    "abs,min,max,sqrt,ceil,floor,sin,cos,atan,pi"
    , commaDelimited))
  
local C, dL, drawCircle, drawCircleF
  , dRF, dTF, dTx, dTxB
  , getWidth, getHeight
  
  = getTableValues(screen,gmatch(
    prop_getText("ArkSF0")
    --"setColor,drawLine,drawCircle,drawCircleF,drawRectF,drawTriangleF,drawText,drawTextBox,getWidth,getHeight"
    , commaDelimited))

local screenToMap, mapToScreen
  , getNumber, getBool
  , setNumber, setBool
  , format

  , clamp

  = getTableValues(G,gmatch(
    prop_getText("ArkGF0")
    --"map.screenToMap,map.mapToScreen,input.getNumber,input.getBool,output.setNumber,output.setBool,string.format"
    , commaDelimited))
   

function clamp(a,b,c) return min(max(a,b),c) end

local I, O, Ib, Ob -- input/output tables
  , selectedInput
  , lastI, lastIb
  = {},{},{},{}
  , {}, {}
  , 1

function onTick()
  local channel

  lastI = {unpack(I)}
  lastIb = {unpack(Ib)}
  for i=1,32 do
    I[i]=getNumber(i)
    --O[i]=I[i]
    Ib[i]=getBool(i)
    --Ob[i]=Ib[i]
  end

  for i=5,1,-1 do
    -- check for input changes
    -- reverse order so first input takes priority
    for c=1,6 do
      channel = 6*i+c-6
      if I[channel]~=lastI[channel] or Ib[channel]~=lastIb[channel] then
        selectedInput = i
      end
    end
  end
  
  for c=1,6 do
    channel = 6*selectedInput+c-6
    O[c] = I[channel]
    Ob[c] = Ib[channel]
  end

  for i=1,32 do
    setNumber(i, O[i])
    setBool(i, Ob[i])
  end
end


function onDraw()
end