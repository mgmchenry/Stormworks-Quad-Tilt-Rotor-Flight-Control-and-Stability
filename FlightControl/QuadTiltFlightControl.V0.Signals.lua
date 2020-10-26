-- Stormworks Quad Tilt Rotor Flight Control and Stability
-- Signals Refactor
-- VS 0.S11.23e Michael McHenry 2020-10-26
-- Minifies to 3988 characters as of S11.22d
-- Minifies to 3762 characters as of S11.22e
-- Minifies to 4102 characters as of S11.23a
-- Minifies to 4072 characters as of S11.23b
-- Minifies to 4054 characters as of S11.23c
-- Minifies to 3981 characters as of S11.23e
sourceVS1123e="repl.it/@mgmchenry"

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
local _string, _math, _input, _output, _property
  , _tostring, _tonumber, ipairz, pairz
  , in_getNumber, in_getBool, out_setNumber
  , abs, sin, cos, max, min
  , atan2, sqrt, floor, pi
	= getTableValues(G,gmatch(prop_getText(propPrefix..0)..prop_getText(propPrefix..1), commaDelimited))

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
function getTokens(n, list, prefix)
  n, list, prefix
    = n or 1
    , list or {}
    , prefix or "token_"
  for i=#list+1,n do
    _tokenId = _tokenId + 1
    list[i] = prefix .. _tokenId
  end
  --__debug.AlertIf({"Tokens Assigned", unpack(list)})
  return unpack(list)
end

local t_tokenList
  -- signal functions
  , f_sAssignValues, f_sGetValues, f_sNewSignalSet, f_sAdvanceBuffer, f_sGetSmoothedValue, f_sAddSignals
  -- signal elements
  , t_Value, t_Velocity, t_Accel
  , t_targetValue, t_targetVel, t_targetAccel
  , t_buffers, t_modPeriod, t_modOffset
  , t_OutValue
  -- process functions
  , f_pRun
  = getTokens(18)
--[[
stringUnpack(
[ [
t_tokenList
,f_sAssignValues,f_sGetValues,f_sNewSignalSet,f_sAdvanceBuffer,f_sGetSmoothedValue,f_sAddSignals
,t_Value,t_Velocity,t_Accel
,t_targetValue,t_targetVel,t_targetAccel
,t_buffers,t_modPeriod,t_modOffset
,t_OutValue
,f_pRun
] ])
__debug.AlertIf(f_pRun~="f_pRun", "missing tokens - tokenList/pRun:", t_tokenList, f_pRun)
__debug.AlertIf(f_pRun~="f_pRun" and {f_sAssignValues, f_sGetValues, f_sNewSignalSet, f_sAdvanceBuffer, f_sGetSmoothedValue, f_sAddSignals})
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

--[[
function newSet(tokenCount, set, tokenList)
  -- Calling with an exisiting set will increase the token count
  set = set or {}
  set[t_tokenList] = tokenList and {unpack(tokenList)} or {getTokens(tokenCount, set[t_tokenList])}
  return set
end
--]]
--[[
local fruitSet = newSet(6)
local t_orange, t_banana, t_apple, t_cherry, t_melon, t_lemon = unpack(fruitSet[t_tokenList])
fruitSet[t_orange] = "juice fruit"
fruitSet[t_apple] = "pie fruit"
tableValuesAssign(fruitSet, 
  {t_banana, t_cherry, t_melon, t_lemon}, 
  {"snack", "pie fruit", "picnic fruit", "too sour fruit"})
--]]


local signals, signalLogic, processingLogic, rotorLogic

-- deferred definition is expanded below with
-- processingLogic = processingLogic()
-- but signalLogic must be expanded first
function processingLogic()
  local this
    , compositeInSignalChannels
    , compositeInSignalSet
    --, computedSignalSet
    , computedSignalNames
    , rotors
    , rotorSignalNames
    , rotorOutputNames
    -- and some functions
    , getSValues
    , setSValues
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
    , signalLogic[f_sNewSignalSet]({getTokens(13
      --[[    
      ,{"t_pilotRoll", "t_pilotPitch", "t_pilotYaw", "t_pilotUpdown"
      , "t_pilotAxis5", "t_pilotAxis6"
      , "t_gpsX", "t_gpsY", "t_compass", "t_tiltPitch", "t_tiltRoll", "t_tiltUp"
      , "t_rotorRPS"} 
      --]]
      )})

    -- computed signal set (5 elements) 
    -- heading, sideDrift, forwardDrift, sideAcc, forwardAcc, rotorAltitude
    -- and I prob don't need heading
    , --signalLogic[f_sNewSignalSet](6
      {getTokens(6
      --[[
      , {"heading", "sideDrift", "forwardDrift", "sideAcc", "forwardAcc", "rotorAltitude"}
      --]]
      )}

    -- rotors
    , {}

    -- rotor signal names
    , {getTokens(3)}
      --"thrust", "alt", "tilt"}

    -- rotor output elements:
    , {getTokens(4
      --, {"t_roTargetAcc", "t_roRotorPitchOut", "t_roPitch41G", "t_roRotorTilt"}
    )}

    , signalLogic[f_sGetValues]
    , signalLogic[f_sAssignValues]

  -- index tokens for all 13 compositeInSignalSet elements:
  local t_pilotRoll, t_pilotPitch, t_pilotYaw, t_pilotUpdown
    , t_pilotAxis5, t_pilotAxis6
    , t_gpsX, t_gpsY, t_compass, t_tiltPitch, t_tiltRoll, t_tiltUp
    , t_rotorRPS
    = unpack(compositeInSignalSet[t_tokenList])

  local t_heading, t_sideDrift, t_forwardDrift, t_sideAcc, t_forwardAcc, t_rotorAltitude
    = --unpack(computedSignalSet[t_tokenList])
    unpack(computedSignalNames)
  
  -- rotor signals
  local 
    t_rAlt, t_rTiltPitch, t_rThrust    

    = unpack(rotorSignalNames)

  local
    t_roTargetAcc, t_roRotorPitchOut, t_roPitch41G, t_roRotorTilt
    = unpack(rotorOutputNames)
  
  -- set wrap around period and offset for compass:
  -- tableValuesAssign(container, indexList, values)
  tableValuesAssign(
    compositeInSignalSet[t_compass]
    , {t_modPeriod, t_modOffset}
    , {1, -0.5}
    )
  -- def: signalLogic[f_sNewSignalSet] = function(newSignalNames, newSignalElements, signalSet, bufferLength)
  signalLogic[f_sNewSignalSet](computedSignalNames, nilzies, compositeInSignalSet)

  
  for i=1,4 do
    -- def: signalLogic[f_sNewSignalSet] = function(newSignalNames, newSignalElements, signalSet, bufferLength)
    rotors[i]
      = signalLogic[f_sNewSignalSet](rotorSignalNames)
    -- def: signalLogic[f_sNewSignalSet] = function(newSignalNames, newSignalElements, signalSet, bufferLength)
    signalLogic[f_sNewSignalSet](rotorOutputNames, {t_OutValue}, rotors[i])
  end

  function runRotorLogic(targetClimbAcc, targetPitchAcc, targetRollAcc, targetAlt)
    for i=1,4 do        
      local rotorSignalSet
        , rotorInputChannels
        -- rotor sensors: rotor.alt, rotor.tilt, rotor.vel
        , roTargetAcc, roRotorPitchOut, roPitch41G, roRotorTilt
        , climbThrustAdjust
        = rotors[i]
        , {i*3+6, i*3+7, i*3+8}

      -- signalLogic [f_sAssignValues] = function(signalSet, values, elementKey, signalKeys, elementKeyList)
      setSValues(
        rotorSignalSet
        , getInputNumbers(rotorInputChannels), t_Value
        , rotorSignalNames
      )

      -- raw values from these signals:
      local rAlt, rTilt, rVelocity, rAcc
        = getSValues(rotorSignalSet, rotorSignalNames)
      
      roTargetAcc, roRotorPitchOut, roPitch41G, roRotorTilt
        = getSValues(rotorSignalSet, rotorOutputNames, t_OutValue)

      rAcc 
        = getSValues(rotorSignalSet, {t_rThrust}, t_Velocity)

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
      + targetPitchAcc 
      --rotorAxisPolarity = negativeOneIf(i < 3)
      * ifVal(i<3, -1, 1)
      ) * climbThrustAdjust
      
      roRotorPitchOut = clamp((roRotorPitchOut or 0) + (roTargetAcc - rAcc) / 20 / ticksPerSecond, -1, 1)

      roRotorTilt = 0

      setSValues( --signal SetValues
        rotorSignalSet
        , {roTargetAcc, roRotorPitchOut, roPitch41G, roRotorTilt}, t_OutValue
        , rotorOutputNames
      )

      out_setNumber(i,roRotorPitchOut)
      out_setNumber(i+4,roRotorTilt)

        
      signalLogic[f_sAdvanceBuffer](rotorSignalSet)

    end

  end

  -- processing.run() function:
  this[f_pRun] = function()
    --signalLogic[f_sAssignValues](
    setSValues(
      compositeInSignalSet
      , getInputNumbers(compositeInSignalChannels)
    )

    -- todo: non-signal input mcTick is on channel 30

    local sRotorAlt
      -- raw values from these signals:
      , sTiltPitch, sTiltUp, sGpsX, sGpsY, sCompass
      , pilotRoll, pilotPitch, pilotYaw, pilotUpdown

      = 0
      , getSValues(compositeInSignalSet
        , {t_tiltPitch, t_tiltUp, t_gpsX, t_gpsY, t_compass
        , t_pilotRoll, t_pilotPitch, t_pilotYaw, t_pilotUpdown})

    -- rotor altitude sensors - average from all 4
    for i,v in ipairz(getInputNumbers({9,12,15,18})) do
      sRotorAlt = sRotorAlt + (v or 0) / 4
    end

    -- signal value corrections:
    if sTiltUp < 0 then
      sTiltPitch = sTiltPitch + (0.25 * sign(sTiltUp))
    end

    -- update corrected values
    setSValues(compositeInSignalSet
      , {sTiltPitch}, t_Value
      , {t_tiltPitch})

    -- rate of change (t_Velocity) from these signals
    local yawRate, rollRate, pitchRate, xVel, yVel
      = getSValues(compositeInSignalSet
        , {t_compass, t_tiltRoll, t_tiltPitch, t_gpsX, t_gpsY}, t_Velocity)
      
    local xAcc, yAcc
      = getSValues(compositeInSignalSet
        , {t_gpsX, t_gpsY}, t_Accel)


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

    --[[ from flightvis    
    sideDrift = sin(pi2 * (velAngle - polarOffset)) * -xyVel
    headDrift = cos(pi2 * (velAngle - polarOffset)) * xyVel 
    --]]

    sideDrift, forwardDrift, sideAcc, forwardAcc
      = sin(pi2 * (velAngle - heading)) * -xyVel
      , cos(pi2 * (velAngle - heading)) * xyVel
      , sin(pi2 * (accAngle - heading)) * -xyAcc
      , cos(pi2 * (accAngle - heading)) * xyAcc    

    -- signalLogic[f_sAssignValues] = function(signalSet, values, elementKey, signalKeys)
    setSValues(
      compositeInSignalSet
      , {heading, sideDrift, forwardDrift, sideAcc, forwardAcc, sRotorAlt}, t_Value
      , computedSignalNames 
      --{t_heading, t_sideDrift, t_forwardDrift, t_sideAcc, t_forwardAcc, t_rotorAltitude}
      -- {"heading", "sideDrift", "forwardDrift", "sideAcc", "forwardAcc", "rotorAltitude"}
      )
    
    local altTarget, soon
      , altSoon
      , altClimbRate, altClimbRateTarget, altClimbRateSoon
      , altClimbAcc, altClimbAccTarget, altClimbAccSoon
      , targetClimbAcc

      -- get current altTarget
      = getSValues(compositeInSignalSet
      , {t_rotorAltitude}, t_targetValue)
      -- assign if it's nil
      or sRotorAlt>0 and (sRotorAlt + 0.5)

      -- soon is .2 seconds from now
      , .2


    altClimbRate, altClimbAcc 
      = getSValues(compositeInSignalSet, {t_rotorAltitude}, t_Velocity )
      , getSValues(compositeInSignalSet, {t_rotorAltitude}, t_Accel )

    altClimbRateSoon = altClimbRate + altClimbAcc * soon
    altSoon = sRotorAlt + (altClimbRate + altClimbRateSoon) / 2 * soon

    altTarget = 
      sRotorAlt~=0 and abs(pilotUpdown)+abs(pilotPitch)>0.03 and (
      -- there is nonZero rotor alt and pilot input - update altTarget
        altSoon
      ) or -- we have zero alt reading from rotors
        altTarget


    altClimbRateTarget = pilotUpdown * 10
    --[[
      abs(pilotUpdown)>0.3 and pilotUpdown * 10
      or altTarget and sRotorAlt and clamp((altTarget - sRotorAlt) / soon / 2,-10,10)
      or 0
    --]]

    targetClimbAcc = (altClimbRateTarget - altClimbRateSoon) / soon

    runRotorLogic(
      targetClimbAcc
      , pilotPitch -- - sTiltPitch
      , pilotRoll
      , altTarget)

      --[[
      --dubug outs
    local outVars = {
      sGpsX, xVel, xAcc
      , sGpsY, yVel, yAcc
      , xyVel, xyAcc --7,8
      , sCompass, heading, yawRate -- 9,10,11
      , 60277 --12
      , sideDrift, forwardDrift
      , sideAcc, forwardAcc
    }
      --]]

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

    signalLogic[f_sAdvanceBuffer](compositeInSignalSet)
  end

  
  return this
end

-- deferred function creates separate scope to reduce upvalue count in other scopes
-- expanded below using signalLogic = signalLogic()
--[[
signal Set structure:
signalSet = {
  t_tokenList = {yaw, pitch, roll, whatever}
  , t_bufferLength = 60ish
  , t_bufferPosition = 1
  -- signals have a value element and derived elements like rate of change. I might include the element list in the signalSet in the future
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
function signalLogic()
  local this
    , defaultSignalElements
    , t_bufferPosition, t_bufferLength, t_signalElements
    = {}
    , 
    { -- signal elements
      t_Value, t_Velocity, t_Accel
      , t_targetValue, t_targetVel, t_targetAccel
    }
    , getTokens(3)

  --[[
    function f_sNewSignalSet - Returns a table of signals with initialized buffers

    Return new set with x generic token signal names with default elements and buffer length:
    f_sNewSignalSet(signalCount) 

    or pass in a set of signal names:
    f_sNewSignalSet(newSignalNames, newSignalElements, signalSet, bufferLength)
    - if newSignalElements and bufferLength are nil, defaults will be used
    - if an existing signalSet is passed in, it will be expanded with new signals
  --]]
  this[f_sNewSignalSet] = function(newSignalNames, newSignalElements, signalSet, bufferLength, l_NewSet, l_SetTokenList, l_newBuffers, l_newSignal)

    --__debug.AlertIf(isValidNumber(newSignalNames), "getting x signal tokens:", newSignalNames)
    --__debug.AlertIf(not isValidNumber(newSignalNames), "assigning tokens:", unpack(newSignalNames) )

    newSignalNames
      , newSignalElements
      , l_NewSet    

    = isValidNumber(newSignalNames) and {getTokens(newSignalNames)} or newSignalNames
      , newSignalElements or defaultSignalElements
      , tableValuesAssign(nilzies
          , {t_tokenList, t_bufferLength, t_bufferPosition}
          , {{}, bufferLength or 60, 1}
        )

    signalSet = signalSet or l_NewSet

    bufferLength
      , l_SetTokenList
    = signalSet[t_bufferLength]
      , signalSet[t_tokenList]

    --__debug.AlertIf({"Using signal elements:", unpack(newSignalElements)})

    for i,signalName in ipairz(newSignalNames) do
      l_SetTokenList[#l_SetTokenList+1] = signalName

      l_newSignal, l_newBuffers
      = {}, {}     

      -- stick the new signal and buffers where they go
      signalSet[signalName]
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

    return signalSet
  end

  this[f_sAdvanceBuffer] = function(signalSet)
    local currentIndex
      , signalElements
      , signal
      
      = moduloCorrect(signalSet[t_bufferPosition] + 1, signalSet[t_bufferLength])

    signalSet[t_bufferPosition] = currentIndex
    
    for i,signalName in ipairz(signalSet[t_tokenList]) do
      signal = signalSet[signalName]
      signalElements = signal[t_signalElements] or defaultSignalElements
      -- let's clear buffer values at this position
      for ei, element in ipairz(signalElements) do
        signal[t_buffers][element][currentIndex] = empty
      end
    end
  end

  -- multiple assign values list to elements of list of signal signalKeys
  -- defaults if nil/omitted:
  -- elementKey = t_Value
  -- signalKeys list is all signals in the set (t_tokenList)
  -- propogates derived values (velocity from value, acceleration from velocity)
  this[f_sAssignValues] = function(signalSet, values, elementKey, signalKeys, elementKeyList)
    elementKeyList
      , signalKeys
      , elementKey
      = elementKeyList or {elementKey or t_Value}
      , signalKeys or signalSet[t_tokenList]
      , elementKey or t_Value

    --print("assign Values", #values, "element:"..elementKey, "signalKeys:", #signalKeys, # elementKeyList)
    --print("assign keys", unpack(signalKeys))
    --print("signal tokens", unpack(signalSet[t_tokenList]))

    for i,signalKey in ipairz(signalKeys) do 
      local bufferPosition
        , signal
        , cascadeMap
        , valueBuffer
        , cascadeElement
        , currentValue, previousValue, delta

      = signalSet[t_bufferPosition]
        , signalSet[signalKey]
        -- cascadeMap contruction - value delta is velocity. velocity delta is accel
        , tableValuesAssign(nilzies, {t_Value, t_Velocity}, {t_Velocity, t_Accel})
      
      valueBuffer = signal[t_buffers] -- firt get buffer container for this signal
      valueBuffer = valueBuffer[elementKey] -- inside, buffer for this element

      currentValue = moduloCorrect(values[i],signal[t_modPeriod],signal[t_modOffset])

      signal[elementKey] = currentValue
      valueBuffer[bufferPosition] = currentValue
      cascadeElement = cascadeMap[elementKey]

      if cascadeElement then
        -- def: this[f_sGetSmoothedValue] = function(signalSet, signalKey, elementKey, smoothTicks, delayTicks)
        currentValue = this[f_sGetSmoothedValue](signalSet, signalKey, elementKey, 4)
        -- smoothed over 4 ticks should be decent, 8 ticks ago
        previousValue = this[f_sGetSmoothedValue](signalSet, signalKey, elementKey, 4, 8)

        delta = moduloCorrect(
          currentValue - previousValue
          ,signal[t_modPeriod],signal[t_modOffset]
          ) * ticksPerSecond / 8

        --signal[cascadeElement] = delta
        -- ^ doesn't cut it because velocity won't cascade to accel that way
        -- so:
        -- def: this[f_sAssignValues] = function(signalSet, values, elementKey, signalKeys)
        this[f_sAssignValues](signalSet, {delta}, cascadeElement, {signalKey})
        
      end
    end
  end

  this[f_sGetValues] = function(signalSet, signalKeys, elementKey, list)
    elementKey, list 
      = elementKey or t_Value
      , list or {}

    for i,v in ipairz(signalKeys) do
      --__debug.AlertIf(not __debug.IsTable(signalSet), "signalSet is not a table", signalSet)
      --__debug.AlertIf(signalSet[v]==nilzies and {"signalKey", i , v, "missing from set", __debug.TableContents(signalSet[t_tokenList], "signalSet t_tokenList")},"huh")
      --__debug.AlertIf(signalSet[v]==nilzies and {__debug.TableContents(signalKeys, "signalKeys list passed to GetValues")})
      --__debug.AlertIf(__debug.IsTable(v) and {"signalKey is a table", __debug.TableContents(v, "signalKey")})
      --__debug.AlertIf(not __debug.IsTable(signalSet[v]), "signal is not a table - signalName:", v, "value", signalSet[v])
      --__debug.AlertIf(signalSet[v][elementKey]==nilzies and {"Signal element is nil. SignalKey:", v, "ElementKey:", elementKey, __debug.TableContents(signalSet[v],"signal elements")})

      list[i] = signalSet[v][elementKey]
    end
    return unpack(list)
  end

  this[f_sGetSmoothedValue] = function(signalSet, signalKey, elementKey, smoothTicks, delayTicks)
    elementKey
      , smoothTicks
      , delayTicks 

      = elementKey or t_Value
      , smoothTicks or 3
      , delayTicks or 0
    
    local currentIndex
      , bufferLength
      , signal
      , diffSum

      , valueBuffer
      , sample
      , sampleIndex
      , baseValue

      = signalSet[t_bufferPosition]
      , signalSet[t_bufferLength]
      -- should be: signalSet[signalKey][t_buffers][elementKey]
      , signalSet[signalKey] --[t_buffers][elementKey]
      -- but split the value buffer retrieval into discrete steps for debugging purposes for now
      , 0 -- avg default. nil values will coalesce to 0

    -- valueBuffer = signalSet[signalKey][t_buffers][elementKey]:
    valueBuffer = signal[t_buffers][elementKey]

    -- no more delay ticks than we have on hand. Leave room for one sample. minimum 0
    delayTicks = clamp(delayTicks, 0, bufferLength - 1)
    -- make sure we get at least 1 tick, but no more ticks than the buffer contains or wrapping back to current
    smoothTicks = clamp(smoothTicks, 1, bufferLength - delayTicks)
    
    for i = 0, smoothTicks - 1 do
      sampleIndex = moduloCorrect(currentIndex - delayTicks - i , bufferLength)
      sample = valueBuffer[sampleIndex]
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

  return this
end

-- Actual Init for deferred logic definitions
signalLogic = signalLogic()
--rotorLogic = rotorLogic()
processingLogic = processingLogic()

local luaTick, lastTick
  = 0 -- luaTick=
  , -1 -- lastTick=

function onTick()
	if in_getNumber(1) == nilzies then return end -- safety check
	
	luaTick=luaTick+1
  --[[
	if luaTick==1 then --Init	
	end
  --]]

  processingLogic[f_pRun]()

end

