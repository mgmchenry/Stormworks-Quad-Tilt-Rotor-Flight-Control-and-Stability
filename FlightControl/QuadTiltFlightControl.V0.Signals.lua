-- Stormworks Quad Tilt Rotor Flight Control and Stability
-- Signals Refactor
-- VS 0.S11.22e Michael McHenry 2020-10-15
-- Minifies to 3988 characters as of S11.22d
-- Minifies to 3807 characters as of S11.22e
sourceVS1122d="https://repl.it/@mgmchenry/Stormworks"

-- I have this idea for putting string constant values in a text property so further cut down on code size
--local strings = "test,test2,test3"
--for i in string.gmatch(strings, "([^,]*),") do
--   print(i)
--end

local _i, _o, _m
  , nilzies
  = input
  , output
  , math
-- nilzies not assigned by design - it's just nil but minimizes to one letter

-- if I run out of upvalues again, can probably move input/output functions to processing logic scope
local 
  inN, outN, input_GetBool
  , tableUnpack, ipairz 
  = _i.getNumber
  , _o.setNumber 
  , _i.getBool
  , table.unpack
  , ipairs

local 
  -- library function names to minify
  abs, sin, cos, mathmax
  , atan2, sqrt
  , pi, pi2
  -- script scope variables with static defined starting value
  , _tokenId
  , ticksPerSecond
  -- script scope function names to minify

  , ifVal
  , negativeOneIf
  , isValidNumber
  , baseOneModulo
  , moduloCorrect
  , sign
  , clamp
  , getInputNumbers
  , getTokens

  --, newSet
  , tableValuesAssign


  -- library functions
  = _m.abs, _m.sin, _m.cos, _m.max
  , _m.atan, _m.sqrt
  , _m.pi, _m.pi * 2
  -- script scope variable defs
  , 0 -- _tokenId
  , 60 -- ticksPerSecond

  

function ifVal(condition, ifTrue, ifFalse)
  return condition and ifTrue or ifFalse
end
function negativeOneIf(condition)
  return condition and -1 or 1
end
function isValidNumber(x,invalidValue)
  return x~=nilzies and tonumber(x)==x and x~=invalidValue
end
function baseOneModulo(value, maxValue)
  -- example: for an array of 30 elements, but base 1 because lua 
  -- baseOneModulo(1,30) = 1
  -- baseOneModulo(30,30) = 30
  -- baseOneModulo(31,30) = 1
  -- baseOneModulo(0,30) = 30
  return (value - 1) % maxValue + 1
end
function moduloCorrect(value, period, offset)
  if period then
    offset = offset or 0
    return (value - offset) % period + offset
  else
    return value
  end
end
function sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

function clamp(v,minVal,maxVal) 
  return isValidNumber(v) and
    (v>maxVal and maxVal or
      (v<minVal and minVal) or
      v
    )
    or nilzies
end

function getInputNumbers(channelList, returnList)
  returnList=returnList or {}
  for i,v in ipairz(channelList) do returnList[i]=inN(v) end
  return returnList
end


-- _tokenId is initialized to 0 above
function getTokens(n, list, prefix)
  n, list, prefix
    = n or 1
    , list or {}
    , prefix or "token_"
  for i=1,n do
    _tokenId = _tokenId + 1
    list[#list+1] = prefix .. _tokenId
  end
  return tableUnpack(list)
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
function newSet(tokenCount, set, tokenList)
  -- Calling with an exisiting set will increase the token count
  set = set or {}
  set[t_tokenList] = tokenList and {tableUnpack(tokenList)} or {getTokens(tokenCount, set[t_tokenList])}
  return set
end
--]]
function tableValuesAssign(container, indexList, values)
  container = container or {}
  for i,v in ipairz(indexList) do
    container[v] = values[i]
  end
  return container
end

--[[
local fruitSet = newSet(6)
local t_orange, t_banana, t_apple, t_cherry, t_melon, t_lemon = tableUnpack(fruitSet[t_tokenList])
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
    , computedSignalSet
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
    , signalLogic[f_sNewSignalSet](13
      --[[    
      , nilzies, {"t_pilotRoll", "t_pilotPitch", "t_pilotYaw", "t_pilotUpdown"
      , "t_pilotAxis5", "t_pilotAxis6"
      , "t_gpsX", "t_gpsY", "t_compass", "t_tiltPitch", "t_tiltRoll", "t_tiltUp"
      , "t_rotorRPS"} )
      --]]
      )

    -- computed signal set (5 elements) 
    -- heading, sideDrift, forwardDrift, sideAcc, forwardAcc, rotorAltitude
    -- and I prob don't need heading
    , signalLogic[f_sNewSignalSet](6
      --[[
      , nilzies, {"heading", "sideDrift", "forwardDrift", "sideAcc", "forwardAcc", "rotorAltitude"})
      --]]
      )

    -- rotors
    , {}

    -- rotor signal names
    , {getTokens(3)}
      --"thrust", "alt", "tilt"}

    -- rotor output elements:
    , {getTokens(3)}
      --"t_roTargetAcc", "t_roRotorPitchOut", "t_roPitch41G", "t_roRotorTilt"}

    , signalLogic[f_sGetValues]
    , signalLogic[f_sAssignValues]

  -- index tokens for all 13 compositeInSignalSet elements:
  local t_pilotRoll, t_pilotPitch, t_pilotYaw, t_pilotUpdown
    , t_pilotAxis5, t_pilotAxis6
    , t_gpsX, t_gpsY, t_compass, t_tiltPitch, t_tiltRoll, t_tiltUp
    , t_rotorRPS
    = tableUnpack(compositeInSignalSet[t_tokenList])

  local t_heading, t_sideDrift, t_forwardDrift, t_sideAcc, t_forwardAcc, t_rotorAltitude
    = tableUnpack(computedSignalSet[t_tokenList])
  
  -- rotor signals
  local 
    t_rAlt, t_rTiltPitch, t_rThrust    

    = tableUnpack(rotorSignalNames)

  local
    t_roTargetAcc, t_roRotorPitchOut, t_roPitch41G, t_roRotorTilt
    = tableUnpack(rotorOutputNames)
  
  -- set wrap around period and offset for compass:
  -- tableValuesAssign(container, indexList, values)
  tableValuesAssign(
    compositeInSignalSet[t_compass]
    , {t_modPeriod, t_modOffset}
    , {1, -0.5}
    )

  
  for i=1,4 do
    -- def: signalLogic[f_sNewSignalSet] = function(newSignalNames, newSignalElements, signalSet, bufferLength)
    rotors[i]
      = signalLogic[f_sNewSignalSet](rotorSignalNames)
    -- def: signalLogic[f_sNewSignalSet] = function(newSignalNames, newSignalElements, signalSet, bufferLength)
    signalLogic[f_sNewSignalSet](rotorOutputNames, {t_OutValue}, rotors[i])
  end

  function runRotorLogic(targetClimbAcc)
    for i=1,4 do        
      local rotorSignalSet
        , rotorInputChannels
        -- rotor sensors: rotor.alt, rotor.tilt, rotor.vel
        , roTargetAcc, roRotorPitchOut, roPitch41G, roRotorTilt
        = rotors[i]
        , {i*3+6, i*3+7, i*3+8}

      setSValues(
        rotorSignalSet
        , getInputNumbers(rotorInputChannels), nilzies
        , rotorSignalNames
      )

      -- raw values from these signals:
      local rAlt, rTilt, rVelocity      
        = getSValues(rotorSignalSet, rotorSignalNames)

      setSValues(
        rotorSignalSet
        , {roTargetAcc, roRotorPitchOut, rPitch41G, roRotorTilt}, t_OutValue
        , rotorOutputNames
      )



      outN(i,roRotorPitchOut)
      outN(i+4,roRotorTilt)

        
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
      computedSignalSet
      , {sideDrift, forwardDrift, sideAcc, forwardAcc}, t_Value
      , {t_heading, t_sideDrift, t_forwardDrift, t_sideAcc, t_forwardAcc}
      )
    
    -- dealing with alt/climb
    setSValues(computedSignalSet
      , {sRotorAlt}, t_Value
      , {t_rotorAltitude})
    
    local altTarget, soon
      , altSoon
      , altClimbRate, altClimbRateTarget, altClimbRateSoon
      , altClimbAcc, altClimbAccTarget, altClimbAccSoon
      , targetClimbAcc

      -- get current altTarget
      = getSValues(computedSignalSet
      , {t_rotorAltitude}, t_targetValue)
      -- assign if it's nil
      or sRotorAlt>0 and (sRotorAlt + 0.5)

      -- soon is .2 seconds from now
      , .2


    altClimbRate, altClimbAcc 
      = getSValues(computedSignalSet, {t_rotorAltitude}, t_Velocity )
      , getSValues(computedSignalSet, {t_rotorAltitude}, t_Accel )

    altClimbRateSoon = altClimbRate + altClimbAcc * soon
    altSoon = sRotorAlt + (altClimbRate + altClimbRateSoon) / 2 * soon

    altTarget = 
      sRotorAlt~=0 and abs(pilotUpdown)+abs(pilotPitch)>0.03 and (
      -- there is nonZero rotor alt and pilot input - update altTarget
        altSoon
      ) or -- we have zero alt reading from rotors
        altTarget


    altClimbRateTarget = 
      abs(pilotUpdown)>0.3 and pilotUpdown * 10
      or altTarget and sRotorAlt and clamp((altTarget - sRotorAlt) / soon / 2,-10,10)
      or 0

    targetClimbAcc = (altClimbRateTarget - altClimbRateSoon) / soon

    runRotorLogic(targetClimbAcc)

    local outVars = {
      sGpsX, xVel, xAcc
      , sGpsY, yVel, yAcc
      , xyVel, xyAcc --7,8
      , sCompass, heading, yawRate -- 9,10,11
      , 60277 --12
      , sideDrift, forwardDrift
      , sideAcc, forwardAcc
      }

    for i=1, #outVars do      
      outN(i, --tonumber( string.format("%.4f", outVars[i]) ))
        outVars[i])
    end

    --[[
    outN(9, qrAlt)
    outN(10, altTg)
    outN(11, outPitch)
    outN(12, outRoll)
    --]]

    signalLogic[f_sAdvanceBuffer](compositeInSignalSet)
    signalLogic[f_sAdvanceBuffer](computedSignalSet)
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
  -- constructor for new signalSet  
  this[f_sNewSignalSet] = function(signalCount, bufferLength, tokenList)
    bufferLength = bufferLength or 60
    local signalSet, newBuffers, newSignal
      = newSet(signalCount, nilzies, tokenList)
    tableValuesAssign(signalSet
      , {t_bufferLength,t_bufferPosition}
      , {bufferLength, 1}
      )

    for i,signalName in ipairz(signalSet[t_tokenList]) do
      newSignal, newBuffers
        = {}, {}     

      -- stick the new signal and buffers where they go
      signalSet[signalName]
        , newSignal[t_buffers]

        = newSignal
        , newBuffers

      for ei, element in ipairz(defaultSignalElements) do
        newSignal[element] = nilzies
        newBuffers[element] = {}
        -- initialize the buffers for this signal element to complete size
        for bi = 1,bufferLength do
          newBuffers[element][bi] = nilzies
        end
      end

    end
    return signalSet
  end
  --]]

  --old:
  --this[f_sAddSignals] = function(signalSet, newSignalNames, newSignalElements)
  --this[f_sNewSignalSet] = function(signalCount, bufferLength, tokenList)
  --new:
  -- function(signalCount) -or-
  -- function(newSignalNames, newSignalElements, signalSet, bufferLength)
  this[f_sNewSignalSet] = function(newSignalNames, newSignalElements, signalSet, bufferLength, l_NewSet, l_SetTokenList, l_newBuffers, l_newSignal)

    newSignalNames
      , newSignalElements
      , l_NewSet

    = isValidNumber(newSignalNames) and {getTokens(newSignalNames)} or newSignalNames
      -- elements could be a number and should be replaced with nil
      , newSignalElements or defaultSignalElements
      , tableValuesAssign(nilzies
          , {t_tokenList, t_bufferLength, t_bufferPosition}
          , {{}, bufferLength or 60, 1}
        )

    signalSet = signalSet or l_NewSet

    bufferLength
      , localSetTokenList
    = signalSet[t_bufferLength]
      , signalSet[t_tokenList]

    for i,signalName in ipairz(newSignalNames) do
      localSetTokenList[#localSetTokenList+1] = signalName

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
        l_newSignal[element] = nilzies
        l_newBuffers[element] = {}
        -- initialize the buffers for this signal element to complete size
        for bi = 1,bufferLength do
          l_newBuffers[element][bi] = nilzies
        end
      end
    end

    return signalSet
  end

  this[f_sAdvanceBuffer] = function(signalSet)
    local currentIndex
      , signalElements
      , signal
      
      = baseOneModulo(signalSet[t_bufferPosition] + 1, signalSet[t_bufferLength])

    signalSet[t_bufferPosition] = currentIndex
    
    for i,signalName in ipairz(signalSet[t_tokenList]) do
      signal = signalSet[signalName]
      signalElements = signal[t_signalElements] or defaultSignalElements
      -- let's clear buffer values at this position
      for ei, element in ipairz(signalElements) do
        signal[t_buffers][element][currentIndex] = nilzies
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
    --print("assign keys", tableUnpack(signalKeys))
    --print("signal tokens", tableUnpack(signalSet[t_tokenList]))

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
        currentValue = this[f_sGetSmoothedValue](signalSet, signalKey, elementKey, 3)
        -- smoothed over 3 ticks should be decent
        previousValue = this[f_sGetSmoothedValue](signalSet, signalKey, elementKey, 3, 1)

        delta = moduloCorrect(
          currentValue - previousValue
          ,signal[t_modPeriod],signal[t_modOffset]
          ) * ticksPerSecond

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
      list[i] = signalSet[v][elementKey]
    end
    return tableUnpack(list)
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
      sampleIndex = baseOneModulo(currentIndex - delayTicks - i , bufferLength)
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
	if inN(1) == nilzies then return false end -- safety check
	
	luaTick=luaTick+1
  --[[
	if luaTick==1 then --Init	
	end
  --]]

  processingLogic[f_pRun]()

end

