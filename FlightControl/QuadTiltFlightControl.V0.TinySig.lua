-- Stormworks Quad Tilt Rotor Flight Control and Stability
-- TinySignals Refactor
-- VT 0.T11.24c Michael McHenry 2020-10-29
-- Minifies to 3988 characters as of S11.22d
-- Minifies to 3762 characters as of S11.22e 2020-10-18
-- Minifies to 4102 characters as of S11.23a 2020-10-19
-- Minifies to 4072 characters as of S11.23b 2020-10-19
-- Minifies to 4054 characters as of S11.23c 2020-10-20
-- Minifies to 3981 characters as of S11.23e 2020-10-23
-- Minifies to 3547 characters as of T11.24a 2020-10-27 549 free
-- Minifies to 3729 characters as of T11.24b 2020-10-29 397 free
--  (added graphics functions)
--  also testSim https://lua.flaffipony.rocks/?id=GQF9zV7Rp
sourceVT1124c="repl.it/@mgmchenry"

local G, prop_getText, gmatch, unpack
  , propPrefix
  , commaDelimited
  , empty, nilzies
  -- nilzies not assigned by design - it's just nil but minimizes to one letter

	= _ENV, property.getText, string.gmatch, table.unpack
  , "Ark"
  , '([^,\r\n]+)'
  , false

local getTableValues, stringUnpack 
= 
function(container, iterator, local_returnVals, local_context)
	local_returnVals = {}
	for key in iterator do
    local_context = container
    --__debug.AlertIf({"key["..key.."]"})
    for subkey in gmatch(key,'([^. ]+)') do
      --__debug.AlertIf({"subkey["..subkey.."]"})
      local_context = local_context[subkey]
      --__debug.AlertIf({"context:", string.sub(tostring(local_context),1,20)})
    end
    local_returnVals[#local_returnVals+1] = local_context
	end
	return unpack(local_returnVals)
end
, -- stringUnpack
function(text, local_returnVals)
  local_returnVals = {}
  --__debug.AlertIf({"stringUnpack text:", text})
  for v in gmatch(text, commaDelimited) do
    --__debug.AlertIf({"stringUnpack value: ("..v..")"})
    local_returnVals[#local_returnVals+1]=v
  end
  return unpack(local_returnVals)
end
--[[
getTableValues, stringUnpack =  
function(c,d,e,f)e={}for g in d do f=c;for h in gmatch(g,'([^. ]+)')do f=f[h]end;e[#e+1]=f end;return unpack(e)end,function(i,e)e={}for j in gmatch(i,commaDelimited)do e[#e+1]=j end;return unpack(e)end

local a,b,c,d,e,f,g,h=_ENV,property.getText,string.gmatch,table.unpack,"Ark",'([^,\r\n]+)',false;local i,j=function(k,l,m,n)m={}for o in l do n=k;for p in c(o,'([^. ]+)')do n=n[p]end;m[#m+1]=n end;return d(m)end,function(q,m)m={}for r in c(q,f)do m[#m+1]=r end;return d(m)end
--]]

--[[
propValues["Ark0"] =
[ [
string,math,input,output,property,screen
,tostring,tonumber,ipairs,pairs,string.format
,input.getNumber,input.getBool
] ]
propValues["Ark1"] =
[ [
,output.setNumber
,screen.drawTextBox,screen.drawLine,screen.getWidth,screen.getHeight,screen.setColor
] ] 
propValues["Ark2"] =
[ [
,math.abs,math.sin,math.cos,math.max,math.min
,math.atan,math.sqrt,math.floor,math.pi
] ] 
--]]
local _string, _math, _input, _output, _property, _screen
  , _tostring, _tonumber, ipairz, pairz, s_format
  , in_getNumber, in_getBool, out_setNumber
  , drawTextBox, drawLine, s_getWidth, s_getHeight, setColor
  , abs, sin, cos, max, min
  , atan2, sqrt, floor, pi
	= getTableValues(G,gmatch(prop_getText(propPrefix..0)..prop_getText(propPrefix..1)..prop_getText(propPrefix..2), commaDelimited))

-- sanity check that the function set loaded properly. Die on pi() if not
--_ = floor(pi)~=3 and pi()
-- shorter:
_tostring(floor(pi))

local
  pi2
  -- script scope variables with static defined starting value
  , _tokenId
  , ticksPerSecond
  -- script scope function names to minify

  , ifVal
  , isValidNumber
  , moduloCorrect
  , sign
  , clamp
  , getInputNumbers
  , getTokens

  --, newSet
  , tableValuesAssign


  -- library functions
  = pi * 2
  -- script scope variable defs
  , 0 -- _tokenId
  , 60 -- ticksPerSecond

  

function ifVal(condition, ifTrue, ifFalse)
  return condition and ifTrue or ifFalse
end
-- stormworks has no type() function, but
-- tonumber(x)==x gets the right answer for:
-- - numbers, strings, nil, booleans, tables, and functions
-- pass 0 as an invalidValue if that should also be rejected
function isValidNumber(x,invalidValue)
  return _tonumber(x)==x and x~=invalidValue
end
function moduloCorrect(value, period, offset)
  --[[ what a sane person would write:
  if period then
    offset = offset or 1
    return (value - offset) % period + offset
  else
    return value
  end
  --]]
  --minified ternary form:
  offset = offset or 1
  return 
    period and ( (value - offset) % period + offset )
    or value
end
function sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

-- will return false if v is not a number
function clamp(v,minVal,maxVal) 
  return max(min(v,maxVal),minVal)
  --[[
  return isValidNumber(v) and
    (v>maxVal and maxVal or
      (v<minVal and minVal) or
      v
    )
  --]]
end

function getInputNumbers(channelList, returnList)
  returnList=returnList or {}
  for i,v in ipairz(channelList) do returnList[i]=in_getNumber(v) end
  return returnList
end


-- _tokenId is initialized to 0 above
function getTokens(n, prefix, returnList)
  prefix, returnList
    = prefix or "token_"
    , {}
  for i=1,n do
    _tokenId = _tokenId + 1
    returnList[i] = prefix .. _tokenId
  end
  --__debug.AlertIf({"Tokens Assigned", unpack(list)})
  return unpack(returnList)
end

local t_tokenList
  -- signal elements
  , t_Value, t_Velocity, t_Accel
  , t_targetValue, t_targetVel, t_targetAccel
  , t_buffers, t_modPeriod, t_modOffset
  , t_OutValue
  , t_signalElements
  -- process functions
  , f_pRun
  = getTokens(13)
--[[
stringUnpack(
[ [
t_tokenList
,t_Value,t_Velocity,t_Accel
,t_targetValue,t_targetVel,t_targetAccel
,t_buffers,t_modPeriod,t_modOffset
,t_OutValue
,f_pRun
] ])
__debug.AlertIf(f_pRun~="f_pRun", "missing tokens - tokenList/pRun:", t_tokenList, f_pRun)
__debug.AlertIf(f_pRun~="f_pRun" and {t_Value, t_Velocity, t_Accel, t_targetValue, t_targetVel, t_targetAccel, t_buffers, t_modPeriod, t_modOffset, t_OutValue})
__debug.AlertIf(f_pRun~="f_pRun" and justDie())
--]]
--__debug.AlertIf(not f_pRun and justDie()) -- make sure last token requested was assigned
--__debug.AlertIf(not f_pRun=="token_".._tokenId and justDie()) -- make sure last token requested was assigned

function tableValuesAssign(container, indexList, values)
  container = container or {}
  for i,v in ipairz(indexList) do
    container[v] = values[i]
  end
  return container
end

  -- signal functions
  --, f_sAssignValues, f_sGetValues, f_sAdvanceBuffer, f_sGetSmoothedValue, f_sAddSignals

local bufferLength, bufferPosition
  , defaultSignalElements
  , signalTable, processingLogic
  , graphInfo
  -- signal processing function names:
  , getSignalValues
  , setSignalValues
  , addSignalNames
  , getSmoothedValue
  , advanceSignalBuffer
  =
  60, 0 
  , { -- signal elements
      t_Value, t_Velocity, t_Accel
      , t_targetValue, t_targetVel, t_targetAccel
    }

-- deferred definition is expanded below with
-- processingLogic = processingLogic()
function processingLogic()
  local this
    , compositeInSignalChannels
    , compositeSignalNames
    , computedSignalNames
    , rotors
    , rotorSignalNames
    , rotorOutputNames
    -- and some functions
    , runRotorLogic

    = {}
    -- the 13 composite channel indices for number inputs:
    , {
      1,2,3,4            -- pilot inputs: roll, pitch, yaw, updown
      ,5,6               -- pilot inputs: axis5, axis6
      ,21,22,23,24,25,26 -- sensors: gpsX, gpxY, compass, tilt pitch, roll, up
      ,29                -- sensor: rotor RPS
      }
    -- 13 number inputs are defined
    --, addSignalNames(compositeSignalNames
    , {getTokens(13
      --[[    
      ,{"t_pilotRoll", "t_pilotPitch", "t_pilotYaw", "t_pilotUpdown"
      , "t_pilotAxis5", "t_pilotAxis6"
      , "t_gpsX", "t_gpsY", "t_compass", "t_tiltPitch", "t_tiltRoll", "t_tiltUp"
      , "t_rotorRPS"} 
      --]]
      )}
    --)

    -- computed signal set (5 elements) 
    -- heading, sideDrift, forwardDrift, sideAcc, forwardAcc, rotorAltitude
    -- and I prob don't need heading
    , 
      {getTokens(6
      --[[
      , {"heading", "sideDrift", "forwardDrift", "sideAcc", "forwardAcc", "rotorAltitude"}
      --]]
      )}

    -- rotors
    , {}


  -- index tokens for all 13 compositeInSignalNames:
  local t_pilotRoll, t_pilotPitch, t_pilotYaw, t_pilotUpdown
    , t_pilotAxis5, t_pilotAxis6
    , t_gpsX, t_gpsY, t_compass, t_tiltPitch, t_tiltRoll, t_tiltUp
    , t_rotorRPS
    = unpack(compositeSignalNames)

  local t_heading, t_sideDrift, t_forwardDrift, t_sideAcc, t_forwardAcc, t_rotorAltitude
    = unpack(computedSignalNames)
  
  -- processing.run() function:
  this[f_pRun] = function()
    advanceSignalBuffer()
    --signalLogic[f_sAssignValues](
    setSignalValues(getInputNumbers(compositeInSignalChannels), compositeSignalNames)

    local sRotorAlt
      -- raw values from these signals:
      , pilotRoll, pilotPitch, pilotYaw, pilotUpdown
      , pilotAxis5, pilotAxis6
      , sGpsX, sGpsY, sCompass, sTiltPitch, sTiltRoll, sTiltUp
      , sRPS

      = 0
      , getSignalValues(compositeSignalNames)

    --[[
      compositeSignalNames
      t_pilotRoll, t_pilotPitch, t_pilotYaw, t_pilotUpdown
    , t_pilotAxis5, t_pilotAxis6
    , t_gpsX, t_gpsY, t_compass, t_tiltPitch, t_tiltRoll, t_tiltUp
    , t_rotorRPS
    ]]        

    -- rotor altitude sensors - average from all 4
    for i,v in ipairz(getInputNumbers({9,12,15,18})) do
      sRotorAlt = sRotorAlt + (v or 0) / 4
    end

    -- signal value corrections:
    if sTiltUp < 0 then
      sTiltPitch = sTiltPitch + (0.25 * sign(sTiltUp))
    end

    -- update corrected values
    setSignalValues({sTiltPitch}, {t_tiltPitch})

    -- rate of change (t_Velocity) from these signals
    local yawRate, rollRate, pitchRate, xVel, yVel
      = getSignalValues({t_compass, t_tiltRoll, t_tiltPitch, t_gpsX, t_gpsY}, t_Velocity)
      
    local xAcc, yAcc
      = getSignalValues({t_gpsX, t_gpsY}, t_Accel)

    -- corrected roll =
    -- asin((sin(x*pi/180))/(sin((90-y)*pi/180)))*180/pi
    -- x is the roll angle from the sensor in degrees, and y is the pitch angle from the sensor in degrees
    -- according to jbaker from Stormworks lua discord
    
    local heading
      , velAngle
      , xyVel
      , accAngle
      , xyAcc

      , sideDrift, forwardDrift
      , sideAcc, forwardAcc

      = sCompass + 0.25
      , atan2(yVel, xVel) / pi2 -- velAngle
      , sqrt(xVel*xVel + yVel*yVel) --xyVel
      , atan2(yAcc, xAcc) / pi2 -- accAngle
      , sqrt(xAcc*xAcc + yAcc*yAcc) --xyAcc

    sideDrift, forwardDrift, sideAcc, forwardAcc
      = sin(pi2 * (velAngle - heading)) * -xyVel
      , cos(pi2 * (velAngle - heading)) * xyVel
      , sin(pi2 * (accAngle - heading)) * -xyAcc
      , cos(pi2 * (accAngle - heading)) * xyAcc    

    setSignalValues({heading, sideDrift, forwardDrift, sideAcc, forwardAcc, sRotorAlt}, computedSignalNames)
    
    local altTarget, soon
      , altSoon
      , altClimbRate, altClimbRateTarget, altClimbRateSoon
      , altClimbAcc, altClimbAccTarget, altClimbAccSoon
      , targetClimbAcc

      -- get current altTarget
      = getSignalValues({t_rotorAltitude}, t_targetValue)
      -- assign if it's nil
      or sRotorAlt>0 and (sRotorAlt + 0.5)

      -- soon is .2 seconds from now
      , .2


    altClimbRate, altClimbAcc 
      = getSignalValues({t_rotorAltitude}, t_Velocity )
      , getSignalValues({t_rotorAltitude}, t_Accel )

    altClimbRateSoon = altClimbRate + altClimbAcc * soon
    altSoon = sRotorAlt + (altClimbRate + altClimbRateSoon) / 2 * soon

    altClimbRateTarget = pilotUpdown * 10
    altTarget = 
      sRotorAlt~=0 and abs(pilotUpdown)+abs(pilotPitch)>0.03 and (
      -- there is nonZero rotor alt and pilot input - update altTarget
        altSoon + altClimbRateTarget * soon
      ) or -- we have zero alt reading from rotors
        altTarget


    --[[
      abs(pilotUpdown)>0.3 and pilotUpdown * 10
      or altTarget and sRotorAlt and clamp((altTarget - sRotorAlt) / soon / 2,-10,10)
      or 0
    --]]

    targetClimbAcc = (altClimbRateTarget - altClimbRateSoon) / soon

    --[[
    runRotorLogic(
      targetClimbAcc
      , pilotPitch -- - sTiltPitch
      , pilotRoll
      , altTarget)
    --]]

    
    --function runRotorLogic(targetClimbAcc, targetPitchAcc, targetRollAcc, targetAlt)
    for i=1,4 do    
    
      rotorSignalNames, rotorOutputNames = unpack(rotors[i])

      local rotorInputChannels
        , t_rAlt, t_rTiltPitch, t_rThrust
        -- rotor sensors: rotor.alt, rotor.tilt, rotor.vel
        , roTargetAcc, roRotorPitchOut, roPitch41G, roRotorTilt
        , climbThrustAdjust
        = {i*3+6, i*3+7, i*3+8}
        , unpack(rotorSignalNames)
        
      local
        t_roTargetAcc, t_roRotorPitchOut, t_roPitch41G, t_roRotorTilt
        = unpack(rotorOutputNames)

      graphInfo = graphInfo or {
        {t_roRotorPitchOut, t_OutValue, {255,0,0}, -1, 2}
        ,{t_roTargetAcc, t_OutValue, {0,255,0}, -20, 40}
        ,{t_rAlt, t_Accel, {0,0,255}, -20, 40}
      }

      setSignalValues(getInputNumbers(rotorInputChannels), rotorSignalNames)

      -- raw values from these signals:
      local rAlt, rTilt, rVelocity, rAcc
        = getSignalValues(rotorSignalNames)
      
      roTargetAcc, roRotorPitchOut, roPitch41G, roRotorTilt
        = getSignalValues(rotorOutputNames, t_OutValue)

      rAcc 
        = getSignalValues({t_rThrust}, t_Velocity)

      --[[
      rotorAngle = rotor.tilt * pi * 2
			tiltThrustX = cos(rotorAngle)
			tiltThrustY = sin(rotorAngle)
			tiltThrustPctY = tiltThrustY / (tiltThrustX + abs(tiltThrustY))
			climbThrustAdjust = 1 / tiltThrustY
			-- so, if we knew the vertical thrust needed, total thrust would be:
			-- local thrustNeeded = verticalThrustNeeded * climbThrustAdjust
      --]]

      climbThrustAdjust = 
        -- 1 / tiltThrustY
        -- 1 / sin(rotorAngle)
        -- 1 / sin(rTilt * pi * 2)
        ( 1 / sin(rTilt * pi * 2) )
        * 
        ( -- climb thrust diminishes with high rotor tilt
          abs(rTilt) < 0.06 and 0
          or abs(rTilt) < 0.11 and
          --(
            -- rotor angle is quite forward.
            -- increasing thrust to gain altitude is likely to hurt more than it helps
            -- Between 0.110 and 0.06, taper climbThrustAdjust down to zero
            max(abs(rTilt)-0.06,0) * (1/0.05)
            
            -- Wolfram alpha graph: Plot[{Sin[2 Pi x/360], 1/Sin[2 Pi x/360],Min[{1/Sin[2 Pi x/360], 1.66}],Min[{1, Max[{0, Abs[x/360]-0.06}] * (1/(0.110-0.06)) }], Min[{1, Max[{0, Abs[x/360]-0.06}] * (1/(0.110-0.06)) }] * 1/Sin[2 Pi x/360]}, {x, -90, 90}]
          --)
          or 1
        )
      
      roTargetAcc = (targetClimbAcc
      --+ targetPitchAcc 
      + pilotPitch -- - sTiltPitch
      --rotorAxisPolarity = negativeOneIf(i < 3)
      * ifVal(i<3, -1, 1)
      ) * climbThrustAdjust
      
      roRotorPitchOut = clamp((roRotorPitchOut or 0) + (roTargetAcc - rAcc) / 20 / ticksPerSecond, -1, 1)

      roRotorTilt = 0

      setSignalValues({roTargetAcc, roRotorPitchOut, roPitch41G, roRotorTilt}, rotorOutputNames, t_OutValue)

      out_setNumber(i,roRotorPitchOut)
      out_setNumber(i+4,roRotorTilt)
    end
    -- End rotor logic loop



    --for i=1, #outVars do
    for i,v in ipairz( 
      {
        sRotorAlt, altTarget --9,10
        , pilotPitch, pilotRoll
        , sideDrift, forwardDrift
        , sideAcc, forwardAcc --15,16
      }) do
      out_setNumber(i+9, v)
      --tonumber( string.format("%.4f", v) ))
    end

  end
  -- End of processing.run


  --[[
    - if newSignalElements is nil, defaults will be used
  --]]
  addSignalNames = function(newSignalNames, newSignalElements, l_SetTokenList, l_newBuffers, l_newSignal)
    --__debug.AlertIf(isValidNumber(newSignalNames), "getting x signal tokens:", newSignalNames)
    
    newSignalElements
      , signalTable    

    = newSignalElements or defaultSignalElements
      , signalTable or tableValuesAssign(nilzies
          , {t_tokenList}
          , {{}}
        )
        
    l_SetTokenList = signalTable[t_tokenList]

    --__debug.AlertIf({"Using signal elements:", unpack(newSignalElements)})

    for i,signalName in ipairz(newSignalNames) do
      l_SetTokenList[#l_SetTokenList+1] = signalName

      l_newSignal, l_newBuffers
      = {}, {}     

      -- stick the new signal and buffers where they go
      signalTable[signalName]
        , l_newSignal[t_signalElements]
        , l_newSignal[t_buffers]

      = l_newSignal
        , newSignalElements
        , l_newBuffers

      for ei, element in ipairz(newSignalElements) do
        l_newSignal[element] = empty
        l_newBuffers[element] = {}
        -- initialize the buffers for this signal element to complete size
        for bi = 1,bufferLength do
          l_newBuffers[element][bi] = empty
        end
      end
    end
  end

  advanceSignalBuffer = function(l_Signal, l_SignalElements)
    bufferPosition = moduloCorrect(bufferPosition + 1, bufferLength)
    
    for i,signalName in ipairz(signalTable[t_tokenList]) do
      l_Signal = signalTable[signalName]
      l_SignalElements = l_Signal[t_signalElements] or defaultSignalElements
      -- let's clear buffer values at this position
      for ei, element in ipairz(l_SignalElements) do
        l_Signal[t_buffers][element][bufferPosition] = empty
      end
    end
  end

  -- multiple assign values list to elements of list of signal signalKeys
  -- defaults if nil/omitted:
  -- elementKey = t_Value
  -- signalKeys list is all signals in the set (t_tokenList)
  -- propogates derived values (velocity from value, acceleration from velocity)
  setSignalValues = function(values, signalKeys, elementKey)
    elementKey = elementKey or t_Value

    --[[
    __debug.AlertIf({"assign values count", #values, "element:"..elementKey, "signalKeys count:", #signalKeys})
    __debug.AlertIf({"assign values", unpack(values)})
    __debug.AlertIf({"assign to keys", unpack(signalKeys)})
    __debug.AlertIf({"all signal names:", unpack(signalTable[t_tokenList])})
    --]]

    for i,signalKey in ipairz(signalKeys) do 
      local signal
        , cascadeMap
        , valueBuffer
        , cascadeElement
        , currentValue, previousValue, delta

      = signalTable[signalKey]
        -- cascadeMap contruction - value delta is velocity. velocity delta is accel
        , tableValuesAssign(nilzies, {t_Value, t_Velocity}, {t_Velocity, t_Accel})
      
      valueBuffer = signal[t_buffers] -- firt get buffer container for this signal
      valueBuffer = valueBuffer[elementKey] -- inside, buffer for this element

      currentValue = moduloCorrect(values[i],signal[t_modPeriod],signal[t_modOffset])

      signal[elementKey] = currentValue
      valueBuffer[bufferPosition] = currentValue
      cascadeElement = cascadeMap[elementKey]

      if cascadeElement then
        currentValue = getSmoothedValue(signalKey, elementKey, 4)
        -- smoothed over 4 ticks should be decent, 8 ticks ago
        previousValue = getSmoothedValue(signalKey, elementKey, 4, 8)

        delta = moduloCorrect(
          currentValue - previousValue
          ,signal[t_modPeriod],signal[t_modOffset]
          ) * ticksPerSecond / 8

        -- propogate delta values to next element
        setSignalValues({delta}, {signalKey}, cascadeElement)        
      end
    end
  end

  getSignalValues = function(signalKeys, elementKey, returnList)
    elementKey, returnList 
      = elementKey or t_Value
      , returnList or {}

    --[[
    __debug.AlertIf({"get values keyCount count", #signalKeys, "element:"..elementKey})
    __debug.AlertIf({"assign to keys", unpack(signalKeys)})
    __debug.AlertIf({"all signal names:", unpack(signalTable[t_tokenList])})
    --]]

    for i,v in ipairz(signalKeys) do
      --__debug.AlertIf(not __debug.IsTable(signalSet), "signalSet is not a table", signalSet)
      --__debug.AlertIf(signalSet[v]==nilzies and {"signalKey", i , v, "missing from set", __debug.TableContents(signalSet[t_tokenList], "signalSet t_tokenList")},"huh")
      --__debug.AlertIf(signalSet[v]==nilzies and {__debug.TableContents(signalKeys, "signalKeys list passed to GetValues")})
      --__debug.AlertIf(__debug.IsTable(v) and {"signalKey is a table", __debug.TableContents(v, "signalKey")})
      --__debug.AlertIf(not __debug.IsTable(signalSet[v]), "signal is not a table - signalName:", v, "value", signalSet[v])
      --__debug.AlertIf(signalSet[v][elementKey]==nilzies and {"Signal element is nil. SignalKey:", v, "ElementKey:", elementKey, __debug.TableContents(signalSet[v],"signal elements")})

      returnList[i] = signalTable[v][elementKey]
    end
    return unpack(returnList)
  end

  getSmoothedValue = function(signalKey, elementKey, smoothTicks, delayTicks)
    elementKey
      , smoothTicks
      , delayTicks 

      = elementKey or t_Value
      , smoothTicks or 3
      , delayTicks or 0
    
    local signal
      , diffSum

      , valueBuffer
      , sample
      , baseValue

      = signalTable[signalKey]
      -- should be: signalTable[signalKey][t_buffers][elementKey]
      -- but split the value buffer retrieval into discrete steps for debugging purposes for now
      , 0 -- avg default. nil values will coalesce to 0

    -- valueBuffer = signalTable[signalKey][t_buffers][elementKey]:
    valueBuffer = signal[t_buffers][elementKey]

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
          ,signal[t_modPeriod],signal[t_modOffset])
        or 0)
    end
    return 
    moduloCorrect(
      diffSum / smoothTicks + (baseValue or 0)
      ,signal[t_modPeriod],signal[t_modOffset])
  end

  --[[
    Signal set init begins - this might get moved into onTick loop
  --]]

  
  addSignalNames(compositeSignalNames)

  -- set wrap around period and offset for compass:
  -- tableValuesAssign(container, indexList, values)
  tableValuesAssign(
    signalTable[t_compass]
    , {t_modPeriod, t_modOffset}
    , {1, -0.5}
    )

  addSignalNames(computedSignalNames)

  
  for i=1,4 do
    rotorSignalNames = {getTokens(3,"R"..i)}
      --"thrust", "alt", "tilt"}
    rotorOutputNames = {getTokens(4,"RO"..i)}
      --, {"t_roTargetAcc", "t_roRotorPitchOut", "t_roPitch41G", "t_roRotorTilt"}
      
    rotors[i] = {rotorSignalNames, rotorOutputNames}
    addSignalNames(rotorSignalNames)
    addSignalNames(rotorOutputNames, {t_OutValue}, rotors[i])
  end
  
  return this
end

-- deferred function creates separate scope to reduce upvalue count in other scopes
-- expanded below using signalLogic = signalLogic()
--[[
signal Set structure:
signalTable = {
  t_tokenList = {yaw, pitch, roll, whatever}
  , t_bufferLength = 60ish
  , t_bufferPosition = 1
  -- signals have a value element and derived elements like rate of change. I might include the element list in the signalTable in the future
  , t_signalElements = {value, velocity, acceleration, etc?}
  -- the signal set table contains a signal table entry for each signal key from t_tokenList
  , yaw = {
    -- each signal table contains a value entry for each "signal element type"
    t_Value= 0.2
    , t_Velocity = 0.1
    , t_Accel = 0.01
    , etc reminaing elements of signal
    -- the signal table contains a buffer container table
    , t_buffers = {
      -- the buffer container table contains a rolling history  of t_bufferLength values for each signal element
      t_Velocity = {1,2,3..bufferLength}
      , t_Accel = {1,2,3..bufferLength}
      , etc remaining elements of signal      
    }
  }
  , pitch {etc other signals from tokenList}
}

--]]

-- Actual Init for deferred logic definitions
processingLogic = processingLogic()


function onTick()
	--__debugSimulate()
  -- abort if 
	return in_getNumber(1)
    and	
    processingLogic[f_pRun]()
end

--[[
local sim = {}
sim.alt = 10.2

function __debugSimulate()
	
	
	rotorAlts = {9,12,15,18}
    --for i=1, #outVars do
    for i,v in ipairz( 
      {
      	sim.alt, sim.alt, sim.alt, sim.alt
      }) do
      devinput.setNumber(rotorAlts[i], v)
      --tonumber( string.format("%.4f", v) ))
    end
end
--]]

--trunc(n) if n==nill then return "nil" end return string.format("%.f", n) end
--function trunc2(n) if n==nill then return "nil" end return string.format("%.2f", n) end

--[[
function drawCircle(x,y,r,stp)
    local xa,ya,xb,yb
    stp=stp or 20
    for i=1,stp do
        xa=x-cos(pi*(i-1)/(stp/2))*r
        ya=y-sin(pi*(i-1)/(stp/2))*r
        xb=x-cos(pi*i/(stp/2))*r
        yb=y-sin(pi*i/(stp/2))*r
        screenDrawLine(xa,ya,xb,yb)
    end
end

function drawArc(x,y,r,stp,a,b)
    local xa,ya,xb,yb,inc
    stp=stp or 20
    inc=(b-a)/stp
    for i=1,stp do
        xa=x-sin(pi2*(i-1)*inc)*r
        ya=y-cos(pi2*(i-1)*inc)*r
        xb=x-sin(pi2*i*inc)*r
        yb=y-cos(pi2*i*inc)*r
        screenDrawLine(xa,ya,xb,yb)
    end
end

function actualFreakingLineForFSake(x1,y1,x2,y2)
  --local xAdj,yAdj =
  --  ifVal(x2>x1,0.5, -0.5),
  --  ifVal(y2>y1,0.5, -0.5)
  --  screenDrawLine(x1-xAdj,y1-yAdj,x2+xAdj,y2+yAdj)
  screenDrawLine(x1,y1,x2,y2)
  screenDrawLine(x2,y2,x1,y1)
end
--]]

function onDraw()
	--if mcTick==nil then return false end -- safety
		
  local screenWidth, screenHeight
	  = s_getWidth()
    , s_getHeight()					
  

  setColor(0, 0, 255)

  --[[
      graphInfo = graphInfo or {
        {t_roRotorPitchOut, t_OutValue, {1,0,0}, -1, 2}
        ,{t_roTargetAcc, t_OutValue, {0,1,0}, -20, 40}
        ,{t_rAlt, t_Accel, {0,0,1}, -20, 40}
      }
  --]]
  for i,lineDef in ipairz(graphInfo) do
    for xi=1, bufferLength do
      local tickXStart
        , tickXEnd
        , lKey, lElement, lColor, lMin, lRange
        , lVal0, lVal1 

        = screenWidth * (xi - 1) / bufferLength
        , screenWidth * xi / bufferLength
        , unpack(lineDef)
      --lRange = lMax - lMin
      --getSmoothedValue = function(signalKey, elementKey, smoothTicks, delayTicks)
      lVal0 = clamp((getSmoothedValue(lKey, lElement, 1, xi-1) - lMin)/lRange,0,1) 
        * screenHeight
      lVal1 = clamp((getSmoothedValue(lKey, lElement, 1, xi) - lMin)/lRange,0,1) 
        * screenHeight
      setColor(unpack(lColor))
      drawLine(tickXStart, lVal0, tickXEnd, lVal1)
    end
  end



  --actualFreakingLineForFSake(displayX,displayY,displayX+xa,displayY+ya)

  --drawCircle(displayX,displayY,tickWidth * 5,32)
    
  --[[
	local function pVal(l,v)
		if ty+10>h then
			ty=10
			tx=tx+tw*2.5
		end
		dtb(tx, ty, tw, 6, l, 1, 0)
		dtb(tx+tw+4, ty, tw*2, 6, v, -1, 0)
		ty=ty+6
	end
  --]]
	
	--tDiff=luaTick-mcTick
	--pVal("State",state)
	--pVal("TickDiff",trunc2(tDiff))

	
end