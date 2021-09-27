-- Stormworks Ark Display Calibration
-- V 00.01 Michael McHenry 2022-09-20
-- Minifies to 2452 ArkHudCal00x01a
source={"ArkHudCal00x01c","repl.it/@mgmchenry"}

local G, prop_getText, gmatch, unpack
  , ipairz, commaDelimited, empty
  , luaType_string, luaType_table, luaType_number
  , nilzies -- nilzies not assigned by design - it's just nil but minimizes to one letter

  , stringUnpack, getTableValues, clamp, plop -- deferred utility function definitions

	= _ENV, property.getText, string.gmatch, table.unpack
  , ipairs, '([^,\r\n]+)', false
  , "string", "table", "number"

function main()
  local abs, min, max, sqrt, ceil, floor, sin, cos, atan, pi
    = getTableValues(math, --prop_getText("ArkMF0")
    "abs,min,max,sqrt,ceil,floor,sin,cos,atan,pi")
  _ = floor(pi)==3 or pi() -- sanity check

  local radPerTurn, degPerTurn = pi * 2, 360

  local getNumber, getBool, setNumber, setBool, format, type, screenToMap, mapToScreen
    = getTableValues(G, --prop_getText("ArkGF0")
      "input.getNumber,input.getBool,output.setNumber,output.setBool,string.format,type,map.screenToMap,map.mapToScreen")

  local I, O, Ib, Ob -- composite input/output tables
    , tickCounter
    , screenCount, screensRendered, calibrationPoints, isCalibrating, touchDevices
    , lastTriggerClick
    , playerLookX, playerLookY, lookTrigger, triggerClick
    = {},{},{},{}
    , 0 -- tickCounter
    , 0, 0, {}, true, {}
    , {}
    
  local createTouchInput, updateTouchInput

  local function init()
    -- input channels(touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y,deviceID)
    touchDevices[1] = createTouchInput(1,9,10,11,12,13,14,15,16)
    touchDevices[2] = createTouchInput(3,25,26,23,24,25,26,27,28)
    touchDevices[3] = createTouchInput(2,17,18,17,18,19,10,21,22)
  end

  function onTick()  
    screenCount = screensRendered
    tickCounter = tickCounter + 1
    
    for i=1,32 do -- load composite input array and copy to output array for pass-through
      I[i]=getNumber(i);Ib[i]=getBool(i)
      O[i]=I[i];Ob[i]=Ib[i]
    end

    playerLookX, playerLookY = getTableValues(I, {9,10})
    lookTrigger, triggerClick = Ib[31], lookTrigger
    triggerClick = lookTrigger and not triggerClick
    if triggerClick then
      lastTriggerClick = {playerLookX, playerLookY}
    end
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
    local F, setColor, drawLine, drawCircle, drawCircleF
    , drawRectF,drawTriangleF,drawText,drawTextBox
    , screen_getWidth, screen_getHeight  
    = 255, getTableValues(screen,--prop_getText("ArkSF0")
      "setColor,drawLine,drawCircle,drawCircleF,drawRectF,drawTriangleF,drawText,drawTextBox,getWidth,getHeight")

    local cSolidWhite
      , cRed, cGreen, cBlue, cMagenta
      , cWhite, cBlack
      , screenWidth, screenHeight
      , currentDrawColor

      -- forward function references:
      , betterSetColor, betterSetAlpha, betterDrawRect, betterDrawLineRel
      , drawCursor

      = {F,F,F,F}, {F,0,0}, {0,F,0}, {0,0,F}, {F,0,F}
        , {F,F,F}, {0,0,0}

    function onDraw()
      screensRendered = screensRendered + 1
      screenCount = max(screensRendered, screenCount)
      screenWidth, screenHeight = screen_getWidth(), screen_getHeight()

      betterSetColor(cSolidWhite)
      drawRectF(0, 0, screenWidth/2, screenHeight/2)

      betterSetColor(cBlue)
      local posX, posY = 2, screenHeight / 2 + 1
      drawTextBox(posX, posY, 10, 10, format("%i/%i" ,screensRendered, screenCount))
      posY = posY+6

      do
        local touchDevice = touchDevices[screensRendered]
        local events, states, inputConfig, calibration = unpack(touchDevice or {})
        local deviceID, pixWidth, pixHeight, meterWidth, meterHeight, corners
        = unpack(calibration or {})      

        if pixWidth~=screenWidth or pixHeight~=screenHeight then
          --p rint("device not initialized")
        else
          -- corner format: {X,Y, avgLookX, avgLookY, {samples}}
          --[[ 
            corners = {
              {0.5,0.5,false,false,{}}
              , {0.5,pixWidth-1.5,false,false,{}}
              , {pixHeight-1.5,0.5,false,false,{}}
              , {pixHeight-1.5,pixWidth-1.5,false,false,{}}
            }
          ]]

          for i,corner in ipairz(corners) do
            betterDrawRect(corner[1]-.5,corner[2]-.5,1,1, cRed)
            betterDrawRect(corner[1]+.5,corner[2]-.5,1,1, cGreen)
            betterDrawRect(corner[1]-.5,corner[2]+.5,1,1, cBlue)
            betterDrawRect(corner[1]+.5,corner[2]+.5,1,1, cMagenta)
          end
          
          --local touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y = unpack(state[4])
          for i, coord in ipairz({events[1], events[2]}) do
            local touchIsPressed, touchWasPressed, touchX, touchY
              , touchTick, touchLookX, touchLookY
              = unpack(coord)
            if touchX then
              drawCursor(touchX, touchY, touchIsPressed)
            end
          end
          
        end
      end

      betterSetColor(lookTrigger and cGreen or cWhite)
      drawText(posX, posY, format("%.2f,%.2f", playerLookX*360, playerLookY*360))
      posY = posY+6
      if lastTriggerClick and lastTriggerClick[1] then
        drawText(posX, posY, format("%.2f,%.2f", lastTriggerClick[1]*360, lastTriggerClick[2]*360))
        posY = posY+6
      end
    end
    --[[ End onDraw]]

    function drawCursor(touch1X, touch1Y, touch1On)
      betterSetAlpha(128)
      betterDrawLineRel(touch1X-1,touch1Y-1,-2,0,cRed)
      betterDrawLineRel(touch1X-1,touch1Y-1,0,-2,cRed)
      betterDrawLineRel(touch1X+1,touch1Y+1,0,2,cMagenta)
      betterDrawLineRel(touch1X+1,touch1Y+1,2,0,cMagenta)
      betterDrawLineRel(touch1X-1,touch1Y+1,-2,2,cBlue)
      betterDrawLineRel(touch1X+1,touch1Y-1,2,-2,cGreen)
      if touch1On then
        betterDrawLineRel(touch1X-1,touch1Y,3,0,cWhite)
        betterDrawLineRel(touch1X,touch1Y-1,0,3,cWhite)
      end

      betterSetAlpha(F)
    end
    
    function betterSetAlpha(a)
      currentDrawColor[4] = a
      setColor(unpack(currentDrawColor))
    end

    function betterSetColor(r,g,b,a, local_packedColor)
      currentDrawColor = plop(
        type(r)==luaType_table and r
        or {r,g,b,a}
        , currentDrawColor)
      setColor(unpack(currentDrawColor))
    end

    function betterDrawLineRel(x,y,w,h,color,l_dis)
      if color then betterSetColor(color) end
      l_dis = sqrt(w*w + h*h)
      if l_dis<1 then
        w,h=x+w, y+h
          + h>0 and 1 or -1
      else
        w = x + w + w/l_dis
        h = y + h + h/l_dis
      end
      drawLine(x,y,w,h)
    end

    function betterDrawRect(x,y,w,h,color)
      if color then betterSetColor(color) end
      drawRectF(x,y,w,h)
    end

  end


  -- input channels(touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y)
  function createTouchInput(deviceID, ...)
    local newDevice = { --events, states, inputConfig, calibration
      {{},{}} -- events
      , {{},{},{},{}} -- states{T01,T02,Combo,raw,previous}      
      -- inputConfig: {touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y, }
      , {...} --inputConfig
      -- calibration
      , {deviceID}
    }
    return newDevice
  end

  function updateTouchInput(touchDevice)
    local events, state, config, calibration = unpack(touchDevice)

    local touchState = {getTableValues(I, config)}
    touchState[1] = Ib[config[1]]
    touchState[2] = Ib[config[2]]

    local touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y
      --, touch1, touch2 
      = unpack(touchState)
    --state[5] = state[4] or touchState
    --state[4] = touchState

    for i, updateState in ipairz(
    { {touch1On, touch1X, touch1Y}
    , {touch2On, touch2X, touch2Y}
    }) do
      local event, newOn, newX, newY, oldOn
        , lastPressEvent, lastReleaseEvent, newState
        = events[i], unpack(updateState)

      oldOn, lastPressEvent, lastReleaseEvent
        = event[1], event[8] or {}, event[9] or {}
      if newOn==oldOn then
        -- update old on, but nothing else changes
        event[2]=oldOn
      else
        -- there is a press state change
        newState = 
          {newOn, oldOn, newX, newY, tickCounter, playerLookX, playerLookY
          , {unpack(lastPressEvent,1,7)} 
          -- Truncate lastEvent[lastEvent] to prevent recursive history memory leak
          , {unpack(lastReleaseEvent,1,7)} }
        events[i] = newState
        if newOn then
          -- save a copy of event state as lastPressEvent
          event[8] = {unpack(newState)}
        else
          -- save a copy of event state as lastReleaseEvent
          event[9] = {unpack(newState)}
        end
      end
    end

    local deviceID, pixWidth, pixHeight, meterWidth, meterHeight, corners = unpack(calibration)
    if width>0 and (width%32)==0 -- this is a valid screen width
     and width~=pixWidth then -- new calibration dimensions need to be initialized
      pixWidth, pixHeight, meterWidth, meterHeight 
        = width, height
          , width/32, height/32
      corners = {
        {0.5,0.5,false,false,{}}
        , {0.5,pixWidth-1.5,false,false,{}}
        , {pixHeight-1.5,0.5,false,false,{}}
        , {pixHeight-1.5,pixWidth-1.5,false,false,{}}
      }
      plop(false,calibration,{deviceID, pixWidth, pixHeight, meterWidth, meterHeight, corners})
    end
  end

  return init
end

clamp, plop, stringUnpack, getTableValues =

function --[[clamp]](a,b,c) return b>a and b or c<a and c or a end--min(max(a,b),c) end
,
function --[[plop]](...) -- optionally plop(boolean_returnNewSource, returnTable, ...)
  local sources, result = {...}, {}
  if not sources[1] then
    result,sources = sources[2]
      , {unpack(sources,3)}
  end
  for i,v in ipairz(sources) do
    for i,v in ipairz(v) do
      result[i] = result[i] or v
    end
  end
  return result, unpack(result)
end
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
  getTableValues({this="a",that="b",other=2},"this,other")
  getTableValues(deepArray, "val1,val2,deep.val3,deep.deeper.val4")

  sourceTable = {replaceValue="newValue",insertValue="selectedValue",ignore="goingNowhere",1="a",2="b"}
  selectionList = {replaced="replaceValue", inserted="insertValue", 2,3} 
      -- vs {replaceValue,insertValue,2,3} or {"replaceValue,insertValue,2,3"}  
  destinationTable = {keeps="kept",replaced="oldValue"}
  getTableValues(sourceTable, selectionList, destinationTable
    returns unpack({keeps="kept", replaced=""})
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


note={"Unit tests start here"}
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