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
  local abs, min, max, sqrt, ceil, floor, sin, cos, tan, atan, pi
    = getTableValues(math, --prop_getText("ArkMF0")
    -- added tan
    "abs,min,max,sqrt,ceil,floor,sin,cos,tan,atan,pi")
  _ = floor(pi)==3 or pi() -- sanity check

  local radPerTurn, degPerTurn = pi * 2, 360

  local getNumber, getBool, setNumber, setBool, format, type, screenToMap, mapToScreen
    = getTableValues(G, --prop_getText("ArkGF0")
      "input.getNumber,input.getBool,output.setNumber,output.setBool,string.format,type,map.screenToMap,map.mapToScreen")

  local I, O, Ib, Ob -- composite input/output tables
    , tickCounter
    , screenCount, screensRendered, uiState, isCalibrating, touchDevices
    , lastTriggerClick
    , playerLookX, playerLookY, lookTrigger, triggerClick
    = {},{},{},{}
    , 0 -- tickCounter
    , 0, 0, {}, true, {}
    , {}

  local verticalCalibration = {
    seatPosition = {0,0,0}
    , cameraPivot1 = {0,0,0}
    , cameraOffset1 = {0,0,0}
    , default = {
      top = {0,55.0480}
      , center = {0, -2.900}
      , bottom = {0, -60.6423}
      , verticalLaneMin = {-0.1983  -0.5817,0.1105}
      , verticalLaneMax = {0.1658  -0.5817,0.1105}
    }
    , samples = {
      definition = {
        deviceID = -1
        , touchX = -1
        , touchY = -1
        , touchLookX = empty
        , touchLookY = empty
        , touchTick = -1
      }
    }
  }

  local function averageTables(...)
    local avgTable = {}
    local sampleCounts = {}
    for i, sample in ipairz({...}) do
      for element, value in ipairz(sample) do
        avgTable[element] = (avgTable[element] or 0) + value
        sampleCounts[element] = (sampleCounts[element] or 0) + 1
      end
    end
    for element, value in ipairz(avgTable) do
      avgTable[element] = value / sampleCounts[element]
    end
    return avgTable
  end

  local function calibration_addSample(deviceID, touchX, touchY, touchLookX, touchLookY, touchTick)    
    local samples, newSample
      = verticalCalibration.samples
      , {
        deviceID = deviceID
        , touchH = touchY -- X/Y : H/V are swapped
        , touchV = touchX -- because monitor is rotated 90 degrees for TALL mode
        , touchLookX = touchLookX
        , touchLookY = touchLookY
        , touchTick = touchTick
        , slopeH = cos(touchLookY * pi * 2) -- was relX
        , slopeV = sin(touchLookY * pi * 2) -- was relY
        , ssCount = 1
      }
      
    --print("sample count: " .. #samples)
    --print("looking for sample with touchV: ", newSample.touchV)
    for i, foundSample in ipairz(samples) do
      --print("current sample: ", i, foundSample.touchV, unpack(foundSample))
      if foundSample.touchV == newSample.touchV then
        --print("found matching touchV")
        --print("current sample: ", i, foundSample.touchV, unpack(foundSample))
        local subSamples = foundSample.subSamples or {foundSample.touchLookY}
        newSample.subSamples = subSamples
        samples[i]=newSample

        subSamples[#subSamples + 1] = newSample.touchLookY
        for si = 1, #subSamples do
          newSample.touchLookY = newSample.touchLookY + subSamples[si]
        end
        newSample.touchLookY = newSample.touchLookY / (#subSamples + 1)
        newSample.ssCount = #subSamples
        break      
      elseif foundSample.touchV > newSample.touchV then
        --print("next sample touchV is larger at index", i, foundSample.touchV, "vs", newSample.touchV)
        --print("adding newSample at index: ", i)
        table.insert(samples,i,newSample)
        break
      elseif samples[i+1]==nil then
        --print("next sample is nil at index: ", i+1)
        table.insert(samples,i+1,newSample)
        break
      end
    end
    if #samples==0 then
      --print("sample table is empty. Adding first entry")
      samples[1]=newSample
    end
    --print("sample count: " .. #samples)
    
    -- this table should not need sorting any more. will see if I messed it up?
    --table.sort(samples, function (s1, s2) return (s1.touchLookY or 0) > (s2.touchLookY or 0) end)

    -- recalc midpoints
    local prevTouchV, prevTouchLookY, prevSlopeH, prevSlopeV = 0,0,0,0
    local prevIntercepts = {}
    for i, sample in ipairz(samples) do
      if i==1 then
        sample.midpoints = {}
      else
        -- y1 = x1 * sample.slopeH / sample.slopeV + sample.touchV
        -- y2 = x2 * prevSlopeH / prevSlopeV + prevTouchV
        -- so, intercept x is:
        -- x * sample.slopeH / sample.slopeV + sample.touchV = x * prevSlopeH / prevSlopeV + prevTouchV
        -- x * sample.slopeH / sample.slopeV = x * prevSlopeH / prevSlopeV + prevTouchV - sample.touchV
        -- sample.slopeH / sample.slopeV = prevSlopeH / prevSlopeV + (prevTouchV - sample.touchV) / x
        -- sample.slopeH / sample.slopeV - prevSlopeH / prevSlopeV = (prevTouchV - sample.touchV) / x
        -- x = (prevTouchV - sample.touchV) / (sample.slopeH / sample.slopeV - prevSlopeH / prevSlopeV)
        -- might be right?

        -- so linear algebra then
        --sample.interceptH = (prevTouchV - sample.touchV) / (sample.slopeH / sample.slopeV - prevSlopeH / prevSlopeV)
        --sample.interceptV = sample.interceptH * prevSlopeH / prevSlopeV + prevTouchV

        -- proven to work:
        -- daH2 = (tan(a2)*kd) / (tan(a2)-tan(a1))
        local kd, t1, t2, d2
          = prevTouchV - sample.touchV
          , tan(sample.touchLookY * pi * 2)
          , tan(prevTouchLookY * pi * 2)
        d2 = t2 * kd / (t2 - t1)
        sample.interceptV = prevTouchV - d2
        sample.interceptH = -d2 / t2

        sample.midpoints = {}
        table.insert(prevIntercepts, 1, {sample.interceptH, sample.interceptV})
        if #prevIntercepts>1 then
          table.insert(samples[i-1].midpoints,1
            ,averageTables(unpack(prevIntercepts,1,2))
          )
        end
        if #prevIntercepts>3 then
          table.insert(samples[i-2].midpoints,1
            ,averageTables(unpack(prevIntercepts,1,4))
          )
        end
        if #prevIntercepts>5 then
          table.insert(samples[i-3].midpoints,1
            ,averageTables(unpack(prevIntercepts,1,6))
          )
        end
        if #prevIntercepts>6 then
          table.remove(prevIntercepts)
        end
      end
      if i>1 then

      end
      prevTouchV, prevTouchLookY, prevSlopeH, prevSlopeV
        = sample.touchV, sample.touchLookY, sample.slopeH, sample.slopeV
    end
    
    for i, sample in ipairz(samples) do

    end
  end

      --[[

        name="Monitor 3x3"
        monitor_border="0.022" monitor_inset="0.012"

        name="HUD Large"
        monitor_border="0.02" monitor_inset="0.01"
		
		
      -- assuming: 
      -- CalibrationWall is in front of the viewer, and is perfectly vertical in our reference frame
      -- ViewHorizon is the horizontal plane at cameraLookY=0, also perpendicular to CalibrationWall
      -- p1 and p2 form a vertical line on CalibrationWall, so we will ignore lookX angle and x coordinates
      -- imagine p2 is above p1 (but it doesn't have to be)      
      -- p0 is the point below p1-p2 on CalibrationWall that intersects with ViewHorizon
      -- kd is the known vertical distance p2Y - p1Y

      -- cameraFP is unknown camera focal point somewhere on the viewHorizon plane, but an uknown distance away from p1 and p2
      -- there is a right triangle T1 from cameraFP along ViewHorizon to p0, with a right angle up CalibrationWall to p1
      -- daH1 is the distance above horizon from p0 to p1
      -- there is a right triangle T2 from cameraFP along ViewHorizon to p0, with a right angle up CalibrationWall to p2
      -- daH2 is the distance above horizon from p0 to p2

      -- p1LookY = a1 = the angle between cameraFP--P0 horizontal line and P1
      -- p2LookY = a2 = the angle between cameraFP--P0 horizontal line and P2
      -- dCamP0 is the distance from cameraFP to p0, the shared side of both triangles, adjacent to the look angle

      -- tan(a1) = opposite/adjacent = daH2 / dCamP0
      -- tan(a2) = opposite/adjacent = daH1 / dCamP0
      -- daH1 = daH2 - kd (known distance from p2Y-p1Y)
      -- the ratio tan(p2LookY)/tan(p1LookY) = daH2/daH1
      -- so also:  tan(p2LookY)/tan(p1LookY) = daH2/(daH2-kd)
      -- so also:  tan(p1LookY)/tan(p2LookY) = (daH2-kd) / daH2
      --                                     = daH2/daH2 - kd/daH2
      --     daH2 * tan(a1)/tan(a2) = 1 - kd
      --     daH2 * tan(a1) = tan(a2) - (kd * tan(a2))
      -- daH2 * tan(a1) / tan(a2) = daH2 - kd


      -- wait, how did I get this?
      -- daH2 = (tan(a2)*kd) / (tan(a2)-tan(a1))
	  
	        wallDistance is the unkown Z distance from cameraXY along the horizon line to the CalibrationWall
      --
      
      -- pointint up in  line is on a vertical 
      -- there is a line containing p1 and p2, and we know the distance between these two points
      
      -- given a plane that includes eye level, p1, p2
      -- p1 dist
	  
      ]]
      

  local function compareSamples(sample1, sample2)
    if sample1.deviceID==sample2.deviceID then
      -- ok, valid to compare pixel distance only


      --local 

    end
  end
    
  local createTouchInput, updateTouchInput, checkTouchStart

  local function init()
    -- input channels(touch1On, touch2On, width, height, touch1X, touch1Y, touch2X, touch2Y,deviceID)
    touchDevices[1] = createTouchInput(1,9,10,11,12,13,14,15,16)
    touchDevices[2] = createTouchInput(3,25,26,23,24,25,26,27,28)
    touchDevices[3] = createTouchInput(2,17,18,17,18,19,20,21,22)
    local testFuncs = {
      calibration_addSample = calibration_addSample --(deviceID, touchX, touchY, touchLookX, touchLookY, touchTick)
      , verticalCalibration = verticalCalibration 
    }
    return testFuncs
  end

  --[[ uiState:
    { lastDeviceTouched, lastCornerTouched}
  ]]

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
      local events, state, config, calibration
        = updateTouchInput(touchDevice)
      
      local deviceID, pixWidth, pixHeight, meterWidth, meterHeight, corners 
        = unpack(calibration)
      
      local touchResult = {}
      if deviceID==1 and pixWidth and checkTouchStart(touchDevice, 0, pixHeight/2, pixWidth, 2, touchResult) then
        local touchX, touchY, touchTick, touchLookX, touchLookY
          = unpack(touchResult, 3)
        calibration_addSample(deviceID, touchX, touchY, playerLookX, playerLookY, touchTick)
        -- touchLookX, touchLookY, touchTick)

      end        
      
      for j, corner in ipairz(corners or {}) do
        local cornerId, cornerX, cornerY, avgLookX, avgLookY, samples
          = unpack(corner)
          
        local touchResult = {}
        if checkTouchStart(touchDevice, cornerX, cornerY, 2, 2, touchResult) then          
          uiState[1], uiState[2], avgLookX, avgLookY
            = i, j, 0, 0

          --[[ event format: {touchIsPressed, touchWasPressed, touchX, touchY, touchTick, touchLookX, touchLookY, lastPressEvent{}, lastReleaseEvent{} } ]]
          local touchX, touchY, _, touchLookX, touchLookY
            = unpack(touchResult, 3)
          if #samples>5 then
            table.remove(samples, 1)
          end
          samples[#samples+1] = {touchX, touchY, touchLookX, touchLookY}
          for _, sample in ipairz(samples) do
            avgLookX, avgLookY
              = avgLookX + sample[3] / #samples
              , avgLookY + sample[4] / #samples
          end
          corner[4],corner[5] = avgLookX, avgLookY
        end
      end
    end

    for i=1,32 do -- load composite input array and copy to output array for pass-through
      I[i]=getNumber(i);Ib[i]=getBool(i)
      O[i]=I[i];Ob[i]=Ib[i]
    end

    screensRendered = 0
  end

  do -- screen api available inside this block
    local F, setColor, drawLine, drawCircle, drawCircleF
    , drawRect, drawRectF,drawTriangleF,drawText,drawTextBox
    , screen_getWidth, screen_getHeight  
    = 255, getTableValues(screen,--prop_getText("ArkSF0")
      "setColor,drawLine,drawCircle,drawCircleF,drawRect,drawRectF,drawTriangleF,drawText,drawTextBox,getWidth,getHeight")

    local cSolidWhite
      , cRed, cGreen, cBlue, cMagenta
      , cWhite, cBlack
      , screenWidth, screenHeight
      , currentDrawColor, textPosX, textPosY

      -- forward function references:
      , betterSetColor, betterSetAlpha, betterDrawRect, betterDrawLine, betterDrawLineRel
      , drawCursor

      = {F,F,F,F}, {F,0,0}, {0,F,0}, {0,0,F}, {F,0,F}
        , {F,F,F}, {0,0,0}

    function printText(text, color)
      drawText(textPosX, textPosY, text)
      textPosY = textPosY+6
    end

    function onDraw()
      screensRendered = screensRendered + 1
      screenCount = max(screensRendered, screenCount)
      screenWidth, screenHeight = screen_getWidth(), screen_getHeight()

      betterSetColor(cSolidWhite)
      betterSetAlpha(.5)
      drawRectF(0, 0, screenWidth/2, screenHeight/2)

      betterSetAlpha(1)
      betterSetColor(cBlue)
      textPosX, textPosY = 2, 4
      printText(format("Screen %i/%i" ,screensRendered, screenCount))
      betterSetColor(lookTrigger and cGreen or cWhite)
      printText(format("%.2f,%.2f", playerLookX*360, playerLookY*360))
      
      if lastTriggerClick and lastTriggerClick[1] then
        printText( format("%.2f,%.2f", lastTriggerClick[1]*360, lastTriggerClick[2]*360))
      end

      do
        local touchDevice = touchDevices[screensRendered]
        local events, states, inputConfig, calibration = unpack(touchDevice or {})
        local deviceID, pixWidth, pixHeight, meterWidth, meterHeight, corners
        = unpack(calibration or {})      

        local lastDeviceTouched, lastCornerTouched = unpack(uiState)

        if pixWidth~=screenWidth or pixHeight~=screenHeight then
          --p rint("device not initialized")
        else
          for i, coord in ipairz({events[1], events[2]}) do
            local touchIsPressed, touchWasPressed, touchX, touchY
              , touchTick, touchLookX, touchLookY
              = unpack(coord)
            if touchX then
              drawCursor(touchX, touchY, touchIsPressed)
            end
          end

          local surfaceOffset = pixHeight - 10

          for i, sample in ipairz(verticalCalibration.samples) do
            --w = 
            local r,g,b
              = max(0, (pixWidth - sample.touchV) / pixWidth * F * 1.0 - (F*0.35))
              , abs(sample.touchH/pixHeight - 0.5) * 2 * (F-32)
              , max(0, sample.touchV / pixWidth * F * 1.5 - (F*0.5))

            betterSetColor(r,g,b,255)
            if deviceID == 1 then
              betterDrawRect(sample.touchV, sample.touchH, 1, 1)
              betterDrawLineRel(sample.touchV, pixHeight / 2 + 3, 0, 5) -- 1, abs(sample.touchLookX) * pixWidth / 2)
              betterDrawRect(sample.touchV, pixHeight / 2 + 10, 1, pixWidth * abs(sample.touchLookY) / 2)
            elseif deviceID > 1 then
              local slopeH, slopeV, len
                --= cos(sample.touchLookY * pi * 2) * -1
                --, sin(sample.touchLookY * pi * 2)
                = sample.slopeH * -1
                , sample.slopeV
              len = 1 / abs(slopeH) * pixHeight * 0.7

              betterSetAlpha(0.5)
              betterDrawRect(sample.touchV, 3, 1, 1)
              betterDrawRect(sample.touchV, surfaceOffset + 2, 1, 1)
              betterDrawLineRel(sample.touchV, surfaceOffset, slopeV * len, slopeH * len)
            end
          end

          betterSetColor(cSolidWhite)
          local sampleCount, nod 
            = #verticalCalibration.samples
          if sampleCount>5 then
            nod = floor(tickCounter/5) % (sampleCount * 2)
            for i = 0,4 do
              local trail = abs(abs(nod - i * min(4, floor(sampleCount / 10))) - sampleCount)
              local sample = verticalCalibration.samples[trail + 1]
              if sample and deviceID > 1 then
                local slopeH, slopeV, len
                  = sample.slopeH * -1, sample.slopeV
                len = 1 / abs(slopeH) * pixHeight * 0.8
                
                betterSetAlpha(1- i/5)
                betterDrawRect(sample.touchV, surfaceOffset + 2, 1, 1)
                betterDrawLineRel(sample.touchV, surfaceOffset, slopeV * len, slopeH * len)
                if i==0 and trail>0 then
                  betterDrawLineRel(sample.interceptV, surfaceOffset - sample.interceptH, slopeH * 50, slopeV * -50)
                  betterDrawLineRel(sample.interceptV, surfaceOffset - sample.interceptH, slopeH * -50, slopeV * 50)
                end
              end
            end

            local nextSample
            for i, sample in ipairz(verticalCalibration.samples) do
              betterSetAlpha(0.5)
              if deviceID > 1 and i > 1 then
                local nextSample, slopeH, slopeV
                  , len, midH, midV
                  = verticalCalibration.samples[i+1]                  
                  , sample.slopeH * -1  --= cos(sample.touchLookY * pi * 2) * -1
                  , sample.slopeV       --, sin(sample.touchLookY * pi * 2)
                --len = 1 / abs(slopeH) * pixHeight * 0.8

                if nextSample then
                  betterSetColor(cGreen)
                  betterDrawLineRel(
                    sample.interceptV
                    , surfaceOffset - sample.interceptH
                    , nextSample.interceptV - sample.interceptV
                    , sample.interceptH - nextSample.interceptH)

                  midH = (sample.interceptH + nextSample.interceptH) / 2
                  midV = (sample.interceptV + nextSample.interceptV) / 2

                  if sample.midpoints and #sample.midpoints>0 then
                    midH, midV = unpack(sample.midpoints[1])
                  end

                  local r,g,b
                    = max(0, (pixWidth - sample.touchV) / pixWidth * F * 1.0 - (F*0.35))
                    , abs(sample.touchH/pixHeight - 0.5) * 2 * (F-32)
                    , max(0, sample.touchV / pixWidth * F * 1.5 - (F*0.5))
                  betterSetColor(r,g,b)
                  betterDrawLineRel(midV, surfaceOffset - midH, slopeH * 60, slopeV * -60)
                  betterDrawLineRel(midV, surfaceOffset - midH, slopeH * -60, slopeV * 60)
                end
              end
            end

          end
          
          for i,corner in ipairz(corners) do
            local textWidth, cornerId, cornerX, cornerY, avgLookX, avgLookY, samples
              = 5 * 5 + 2
              , unpack(corner)

            if screensRendered==lastDeviceTouched and lastCornerTouched==i then
              printText(format("corner: %i,%i", cornerId[1], cornerId[2]))              
              printText(format("lookX: %.4f", avgLookX*360))
              printText(format("lookY: %.4f", avgLookY*360))
              betterSetAlpha(.5)
              betterDrawRect(cornerX-.5,cornerY-2.5,2,6, cGreen)    
              betterDrawRect(cornerX-2.5,cornerY-.5,6,2, cGreen)
            end            
            
            if #samples>0 then            
              betterSetAlpha(min(#samples/4,1))
              betterDrawRect(cornerX-1.5,cornerY-1.5,4,4, cWhite)
            end
            betterSetAlpha(1)
            betterDrawRect(cornerX-.5,cornerY-.5,1,1, cRed)
            betterDrawRect(cornerX+.5,cornerY-.5,1,1, cGreen)
            betterDrawRect(cornerX-.5,cornerY+.5,1,1, cBlue)
            betterDrawRect(cornerX+.5,cornerY+.5,1,1, cMagenta)

            --[[
            betterDrawRect(
              cornerX-.5 - (cornerId[1]+1) * textWidth / 2              
              , cornerY-.5 + ( (max(2,cornerId[2]+2)-2.5) * -5.5*2 - 3.5)
              , textWidth, 7, cBlue)
            betterSetColor(cWhite)
            drawTextBox(
              cornerX-.5 - (cornerId[1]+1) * textWidth / 2              
              , cornerY-.5 + ( (max(2,cornerId[2]+2)-2.5) * -5.5*2 - 3.5)
              , textWidth, 7
              , format("%i,%i", cornerId[1], cornerId[2])
              )
            ]]
          end
          
          
        end
      end

    end
    --[[ End onDraw]]

    function drawCursor(touchX, touchY, touchOn)
      betterSetAlpha(.5)
      --[[betterDrawLineRel(touch1X-1,touch1Y-1,-2,0,cRed)
      betterDrawLineRel(touch1X-1,touch1Y-1,0,-2,cRed)
      betterDrawLineRel(touch1X+1,touch1Y+1,0,2,cMagenta)
      betterDrawLineRel(touch1X+1,touch1Y+1,2,0,cMagenta)
      betterDrawLineRel(touch1X-1,touch1Y+1,-2,2,cBlue)
      betterDrawLineRel(touch1X+1,touch1Y-1,2,-2,cGreen)
      ]]
      betterDrawLineRel(touchX,touchY,0,0,cWhite)
      if touchOn then
        betterDrawLineRel(touchX-1,touchY-1,2,2,cWhite)
        betterDrawLineRel(touchX-1,touchY+1,2,-2,cWhite)
      end

      betterSetAlpha(1)
    end
    
    function betterSetAlpha(a)
      currentDrawColor[4] = a * F
      setColor(unpack(currentDrawColor))
    end

    function betterSetColor(r,g,b,a, local_packedColor)
      currentDrawColor = plop(
        type(r)==luaType_table and r
        or {r,g,b,a}
        , currentDrawColor)
      setColor(unpack(currentDrawColor))
    end

    function betterDrawLine(x,y,x2,y2,color)
      betterDrawLineRel(x,y,x2-x,y2-y,color)
    end

    function betterDrawLineRel(x,y,w,h,color,l_dis)
      if color then betterSetColor(color) end
      l_dis = sqrt(w*w + h*h)
      if l_dis<1 then
        w,h=x+w, y+h
          + (h>0 and 1 or -1)
      else
        w = x + w + w/l_dis
        h = y + h + h/l_dis
      end
      drawLine(x,y,w,h)
    end

    function betterDrawRect(x,y,w,h,color,filled)
      if color then betterSetColor(color) end
      if filled or w<2 or h<2 then
        drawRectF(x,y,w,h)
      else
        drawRect(x,y,w-1,h-1)
      end
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

  -- forward function declarations:
  local initCalibration

  function checkTouchStart(touchDevice, left, top, width, height, result)
    local events, state, config, calibration = unpack(touchDevice)

    --[[ touchEvent format
      {touchIsPressed, touchWasPressed, touchX, touchY, touchTick, touchLookX, touchLookY,
          , lastPressEvent{} 
          , lastReleaseEvent{} }
    ]]
    for i, coord in ipairz({events[1], events[2]}) do    
      local touchIsPressed, touchWasPressed, touchX, touchY = unpack(coord)
      if touchIsPressed and not touchWasPressed then
        -- this is new press this tick
        if touchX>=left-0.5 and touchX<left+width-0.5
          and touchY>=top-0.5 and touchY<top+height-0.5 then
          -- this event is inside the hitbox. Return full copy of lastPressEvent
          return plop(false, result, coord[8])

        end
      end
    end
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

    
    initCalibration(calibration, width, height)

    for i, updateState in ipairz(
        { {touch1On, touch1X, touch1Y}
        , {touch2On, touch2X, touch2Y}
        }
      ) do
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
          newState[8] = {unpack(newState)}
        else
          -- save a copy of event state as lastReleaseEvent
          newState[9] = {unpack(newState)}
        end
      end
    end

    return events, state, config, calibration
  end

  function initCalibration(calibration, deviceWidth, deviceHeight)
    --local events, state, config, calibration = unpack(touchDevice)

    local deviceID, pixWidth, pixHeight, meterWidth, meterHeight, corners = unpack(calibration)
    if deviceWidth==0 or (deviceWidth%32)~=0 -- invalid screen width values
      or deviceHeight==0 or (deviceHeight%32)~=0 -- invalid screen height values
      or deviceWidth==pixWidth -- already initialized for this width
      or deviceHeight==pixHeight -- already initialized for this height
      then return -- nothing to do here
    end

    pixWidth, pixHeight, meterWidth, meterHeight 
      = deviceWidth, deviceHeight
        , deviceWidth/32, deviceWidth/32
    corners = {} --[[
      { {-1,-1},0.5,pixWidth*0+1-0.5,false,false,{}}
      , {-1,0},0.5,pixWidth*0.5+0-0.5,false,false,{}}
      , {-1,1},0.5,pixWidth*1-1-0.5,false,false,{}}
      , etc
    ]]
    for y = -1,1 do
      for x = -1,1 do
        -- if deviceWidth = 32 then corners at 
        -- 0,1     - 15,16    - 30,31
        -- 0.5     - 15.5     - 30.5
        -- 0+1-0.5 - 16+0-0.5 - 32-1-0.5 

        corners[x+5 + y*3] = 
        -- {cornerId{}, cornerX, cornerY, avgLookX, avgLookX, samples{} }
        {
          {x,y}
          , deviceWidth * (x+1)/2 - x - 0.5
          , deviceHeight * (y+1)/2 - y - 0.5
          , false, false, {}
        }
      end
    end

    plop(false,calibration,{deviceID, pixWidth, pixHeight, meterWidth, meterHeight, corners})

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

local testFuncs = main()()


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
  
  inBools[10] = true
  inValues[15] = 1
  inValues[16] = 1
  
  runTest(function() onTick() end, "onTick with calibration input")
  runTest(function() onDraw() end, "onDraw")

  
  --calibration_addSample(deviceID, touchX, touchY, touchLookX, touchLookY, touchTick)
  runTest(function()
    testFuncs.calibration_addSample(1, 143, 80, -0.6596 / 360, -4.2249 / 360, 1234)
    testFuncs.calibration_addSample(1, 1, 80, -0.367 / 360, 65.8817 / 360, 1235)
    testFuncs.calibration_addSample(1, 273, 80, -0.367 / 360, -59.8817 / 360, 1236)
  end, "adding 3 test samples")
  
  runTest(function()
    testFuncs.calibration_addSample(1, 143, 80, -0.6596 / 360, -4.3039 / 360, 1237)
    testFuncs.calibration_addSample(1, 143, 80, -0.367 / 360, -4.4829 / 360, 1238)
    testFuncs.calibration_addSample(1, 143, 80, -0.367 / 360, -4.3841 / 360, 1239)
  end, "adding 3 refined samples")

  runTest(function()    
    testFuncs.calibration_addSample(1, 5, 80, -0.367 / 360, 60.8817 / 360, 1243)
    testFuncs.calibration_addSample(1, 40, 80, -0.6596 / 360, 45.2249 / 360, 1244)
    testFuncs.calibration_addSample(1, 75, 80, -0.6596 / 360, 30.2249 / 360, 1245)
    testFuncs.calibration_addSample(1, 100, 80, -0.6596 / 360, 15.2249 / 360, 1246)
    testFuncs.calibration_addSample(1, 130, 80, -0.6596 / 360, -2.2249 / 360, 1247)
  end, "adding samples between")

  --print("verticalCalibration:")
  --expand(testFuncs.verticalCalibration,5)

  
  runTest(function() onTick() end, "onTick before 3 draws")
  runTest(function() onDraw() end, "onDraw 1")
  runTest(function() onDraw() end, "onDraw 2")
  runTest(function() onDraw() end, "onDraw 3")
end