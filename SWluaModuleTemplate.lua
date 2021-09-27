-- Stormworks Ark Display Calibration
-- V 00.01 Michael McHenry 2022-09-20
-- Minifies to 2452 ArkHudCal00x01a
source={"ArkHudCal00x01c","repl.it/@mgmchenry"}

local G, prop_getText, gmatch, unpack
  , ipairz, commaDelimited, empty
  , luaType_string, luaType_table, luaType_number
  , nilzies -- nilzies not assigned by design - it's just nil but minimizes to one letter
  , stringUnpack, getTableValues, clamp -- deferred utility function definitions

	= _ENV, property.getText, string.gmatch, table.unpack
  , ipairs, '([^,\r\n]+)', false
  , "string", "table", "number"

function main()
  local abs, min, max, sqrt, ceil, floor, sin, cos, atan, pi
    = getTableValues(math, --prop_getText("ArkMF0")
    "abs,min,max,sqrt,ceil,floor,sin,cos,atan,pi")
  _ = floor(pi)==3 or pi() -- sanity check

  local getNumber, getBool, setNumber, setBool, format, type, screenToMap, mapToScreen
    = getTableValues(G, --prop_getText("ArkGF0")
      "input.getNumber,input.getBool,output.setNumber,output.setBool,string.format,type,map.screenToMap,map.mapToScreen")

  local I, O, Ib, Ob -- composite input/output tables
    = {},{},{},{}
    
  local 
    -- module global values (onTick and onDraw)
    screenCount, screensRendered, calibrationPoints, isCalibrating, touchDevices
    , playerLookX, playerLookY
    -- module forward function references:  
    , createTouchInput, updateTouchInput
    
    = 0, 0, {}, true, {}

  local function init()
    -- input channels(touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y)
    touchDevices[1] = createTouchInput(9,10,11,12,13,14,15,16)
  end

  function onTick()  
    screenCount = screensRendered
    
    for i=1,32 do -- load composite input array and copy to output array for pass-through
      I[i]=getNumber(i);Ib[i]=getBool(i)
      O[i]=I[i];Ob[i]=Ib[i]
    end

    playerLookX, playerLookY = getTableValues(I, {9,10})
    for i, touchDevice in ipairz(touchDevices) do
      updateTouchInput(touchDevice)
    end

    for i=1,32 do -- load composite input array and copy to output array for pass-through
      I[i]=getNumber(i);Ib[i]=getBool(i)
      O[i]=I[i];Ob[i]=Ib[i]
    end

    screensRendered = 0
  end

  do -- screen api available inside this block
    local setColor, drawLine, drawCircle, drawCircleF
    , drawRectF,drawTriangleF,drawText,drawTextBox
    , screen_getWidth, screen_getHeight  
    = getTableValues(screen,--prop_getText("ArkSF0")
      "setColor,drawLine,drawCircle,drawCircleF,drawRectF,drawTriangleF,drawText,drawTextBox,getWidth,getHeight")

    local screenWidth, screenHeight

    function onDraw()
      screensRendered = screensRendered + 1
      screenWidth, screenHeight = screen_getWidth(), screen_getHeight()

      setColor(255,255,255,255)
      drawRectF(0.5, 0.5, screenWidth/2, screenHeight/2)
      setColor(200,200,200,255)      
      drawRectF(0, 0, 6, 6)
      setColor(255,255,255,255)
      drawRectF(1,1,4,4)
      setColor(0,0,0,255)
      drawRectF(2,2,2,2)

      for i, touchDevice in ipairz(touchDevices) do
        local events, state = unpack(touchDevice)
        local touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y = unpack(state[4])

        if touch1X then
          setColor(255,0,0,255)
          drawRectF(touch1X-0.5, touch1Y-0.5, -2, -2)
          setColor(0,255,0,255)
          drawRectF(touch1X+0.5, touch1Y+0.5, 2, 2)
          setColor(0,0,255,255)
          drawRectF(touch1X+1.5, touch1Y-1.5, 1, 1)
          setColor(255,0,255,255)
          drawLine(touch1X-1.5, touch1Y+1.5, touch1X-2.5, touch1Y+2.5)
        end
        
        if touch2X then
          setColor(255,255,255,255)
          drawRectF(touch2X-1, touch2Y-1, 3, 3)
          setColor(255,0,0,255)
          drawRectF(touch2X, touch2Y-1, 1, 3)
          setColor(0,255,0,255)
          drawRectF(touch2X-1, touch2Y, 3, 1)
          setColor(0,0,255,255)
          drawRectF(touch2X, touch2Y, 1, 1)
          setColor(255,0,255,255)
          drawLine(touch2X-1, touch2Y-1, touch2X, touch2Y)
        end

      end
    end

  end


  -- input channels(touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y)
  function createTouchInput(...)
    local newDevice = {
      {}, -- events
      {{},{},{},{}}, -- states{T01,T02,Combo,raw,previous}
      {...} --config
      -- config: {touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y}
    }
    return newDevice
  end

  function updateTouchInput(touchDevice)
    local events, state, config = unpack(touchDevice)

    local touchState = {getTableValues(I, config)}
    touchState[1] = Ib[config[1]]
    touchState[2] = Ib[config[2]]

    local touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y = unpack(touchState)
    state[5] = state[4] or touchState
    state[4] = touchState
  end

  return init
end

clamp, stringUnpack, getTableValues =

function --[[clamp]](a,b,c) return b>a and b or c<a and c or a end--min(max(a,b),c) end
,
-- stringUnpack("string1,string2")
-- returns unpacked list of strings from comma delimited list
-- stringUnpack("string1,string2", existingArray)
-- same, but also appends the values to the supplied table
function(text, local_returnVals)
  local_returnVals = local_returnVals or {}
  for v in gmatch(text, commaDelimited) do
    local_returnVals[#local_returnVals+1]=v
  end
  return unpack(local_returnVals)
end
,
--[[
  getTableValues({1,2,"a","b"},{1,4}):
    returns unpack({1,"b"})
  getTableValues({this="a",that="b",other=2},"this,other")
    returns unpack({"a",2})
  getTableValues(deepArray, "val1,val2,deep.val3,deep.deeper.val4")
    returns unpack({
      deepArray.val1,
      deepArray.val2,
      deepArray.deep.val3,
      deepArray.deep.deeper.val4
    })
  existingArray = {keeps="kept",replaced="oldValue"}
  getTableValues(
    {replaceValue="newValue",insertValue="selectedValue",ignore="goingNowhere",1="a",2="b"},
    {
      replaced="replaceValue",
      inserted="insertValue",
      2,3
    }, -- vs {replaceValue,insertValue,2,3} or {"replaceValue,insertValue,2,3"}
    existingArray
    )
    returns unpack({keeps="kept", replaced=""})
-- I think I can overload pairs to work like ipairs for numeric arrays but return filtered dictionary otherwise
-- needs testing for edge cases, but passing nil inside the valuelist is bound to have weird consequences
]]
function --[[getTableValues]](container, valueList, local_returnVals, local_startIndex, local_context)
  valueList, local_returnVals = 
    type(valueList)==luaType_string and {stringUnpack(valueList)}
    or valueList
    , local_returnVals or {}
  local_startIndex = #local_returnVals
	for returnValsIndex,containerKey in pairs(valueList) do    
    if type(containerKey)==luaType_number then
      local_context = container[containerKey]
    else
      local_context = container
      for subkey in gmatch(containerKey,'([^. ]+)') do
        local_context = local_context[subkey]
      end
    end
    returnValsIndex = 
      type(returnValsIndex)==luaType_number and local_startIndex + returnValsIndex
      or returnValsIndex
    local_returnVals[returnValsIndex] = local_context
	end
	return unpack(local_returnVals)
end

main()()

function onTest(inValues, outValues, inBools, outBools, runTest)
  for i=1,32 do
    inValues[i]=0
    outValues[i]=0
    inBools[i]=false
    outBools[i]=false
  end

  onTick()
  onDraw()

  runTest(function() onTick() end, "onTick")
  runTest(function() onDraw() end, "onDraw")

  inBools[9] = true
  inValues[11] = 96
  inValues[12] = 96
  inValues[13] = 13
  inValues[14] = 14
  
  runTest(function() onTick() end, "onTick with touch input")
  runTest(function() onDraw() end, "onDraw")
end