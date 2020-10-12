-- Stormworks Quad Tilt Rotor Flight Control and Stability
-- Signals Refactor
-- VS 0.S11.22a Michael McHenry 2020-10-10
-- 0.6.09 min: Before 11,170 bytes After 4,052 bytes
sourceVS1122a="https://repl.it/@mgmchenry/Stormworks"

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
  -- script scope function names to minify
  , ifVal
  , negativeOneIf
  , isValidNumber
  , baseOneModulo
  , sign
  , clamp
  , getInputNumbers
  , getTokens

  ,newSet, tableValuesAssign


  -- library functions
  = _m.abs, _m.sin, _m.cos, _m.max
  , _m.atan, _m.sqrt
  , _m.pi, _m.pi * 2
  -- script scope variable defs
  , 0 -- _tokenId

  

function ifVal(condition, ifTrue, ifFalse)
  return condition and ifTrue or ifFalse
end
function negativeOneIf(condition)
  return condition and -1 or 1
end
function isValidNumber(x,invalidValue)
  return x~=nilzies and type(x)=='number' and x~=invalidValue
end
function baseOneModulo(value, maxValue)
  -- example: for an array of 30 elements, but base 1 because lua 
  -- baseOneModulo(1,30) = 1
  -- baseOneModulo(30,30) = 30
  -- baseOneModulo(31,30) = 1
  -- baseOneModulo(0,30) = 30
  return (value - 1) % maxValue + 1
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
  , f_sAssignValues, f_sGetValues, f_sNewSignalSet, f_sAdvanceBuffer
  -- signal elements
  , t_Value, t_Velocity, t_Accel
  , t_targetValue, t_targetVel, t_targetAccel
  , t_buffers
  -- process functions
  , f_pRun
  = getTokens(13)

function newSet(tokenCount, set)
  -- Calling with an exisiting set will increase the token count
  set = set or {}
  set[t_tokenList] = {getTokens(tokenCount, set[t_tokenList])}
  return set
end
function tableValuesAssign(container, indexList, values)
  for i,v in ipairz(indexList) do
    container[v] = values[i]
  end
end

--[[
fruitSet = newSet(6)
local orange, banana, apple, cherry, melon, lemon = getTokens(fruitSet)
fruitSet[orange] = "juice fruit"
fruitSet[apple] = "pie fruit"
tableValuesAssign(fruitSet, 
  {banana, cherry, melon, lemon}, 
  {""})
--]]



local signals, signalLogic, processingLogic

-- deferred definition is expanded below with
-- processingLogic = processingLogic()
-- but signalLogic must be expanded first
function processingLogic()
  local this
    , compositeInSignalChannels
    , compositeInSignalSet
    , computedSignalSet
    = {}
    -- the 13 composite channel indices for number inputs:
    , {
      1,2,3,4            -- pilot inputs: roll, pitch, yaw, updown
      ,5,6               -- pilot inputs: axis5, axis6
      ,21,22,23,24,25,26 -- sensors: gpsX, gpxY, compass, tilt pitch, roll, up
      ,29                -- sensor: rotor RPS
      }
    -- 13 number inputs are defined
    , signalLogic[f_sNewSignalSet](13)
    -- computed signal set (3 elements) headDrift, sideDrift, heading
    , signalLogic[f_sNewSignalSet](2)


    -- index tokens for all 13 compositeInSignalSet elements:
  local t_pilotRoll, t_pilotPitch, t_pilotYaw, t_pilotUpdown
    , t_pilotAxis5, t_pilotAxis6
    , t_gpsX, t_gpsY, t_compass, t_tiltPitch, t_tiltRoll, t_tiltUp
    , t_rotorRPS
    = tableUnpack(compositeInSignalSet[t_tokenList])

  local t_heading, t_sideDrift, t_headDrift
    = tableUnpack(computedSignalSet[t_tokenList])
    
    -- processing.run() function:
    this[f_pRun] = function()
      signalLogic[f_sAssignValues](
        compositeInSignalSet
        ,getInputNumbers(compositeInSignalChannels)
      )
      -- todo: non-signal input mcTick is on channel 30

      -- raw values from these signals:
      local sTiltPitch, sTiltUp, sGpsX, sGpsY, sCompass
        -- (and some locals to assign later)
        , heading, velAngle, xyVel
        , sideDrift, forwardDrift

        = signalLogic[f_sGetValues](compositeInSignalSet
        , {t_tiltPitch, t_tiltUp, t_gpsX, t_gpsY, t_compass})

      -- signalLogic[f_sGetValues] = function(signalSet, signalKeys, elementKey, list)
      -- rate of change (t_Velocity) from these signals
      local yawRate, rollRate, pitchRate, xVel, yVel
        = signalLogic[f_sGetValues](
          compositeInSignalSet
          , {t_compass, t_tiltRoll, t_tiltPitch, t_gpsX, t_gpsY}
          , t_Velocity
        )

      -- signal value corrections:
      if sTiltUp < 0 then
        sTiltPitch = sTiltPitch + (0.25 * sign(sTiltUp))
      end
      -- wishful thinking maybe - I don't think this wrap around correction will work any more
      if yawRate > .5 then yawRate = yawRate - 1 end
      if yawRate < -.5 then yawRate = yawRate + 1 end

      heading, velAngle, xyVel
        = sCompass + 0.25
        , atan2(yVel, xVel) / pi2
        , sqrt(xVel*xVel + yVel*yVel)

      sideDrift, forwardDrift--, sideAcc, headAcc
        = sin(pi2 * (velAngle - heading)) * -xyVel
        , cos(pi2 * (velAngle - heading)) * xyVel
        --, sin(pi2 * (velAngle - heading)) * -xyVel
        --, cos(pi2 * (velAngle - heading)) * xyVel
      
      -- corrected roll =
      -- asin((sin(x*pi/180))/(sin((90-y)*pi/180)))*180/pi
      -- x is the roll angle from the sensor in degrees, and y is the pitch angle from the sensor in degrees
      -- according to jbaker from Stormworks lua discord

      -- signalLogic[f_sAssignValues] = function(signalSet, values, elementKey, signalKeys)
      signalLogic[f_sAssignValues](
        compositeInSignalSet
        , {sPitch}, t_Value
        , {t_tiltPitch}
        )
	
  
      outN(9, qrAlt)
      outN(10, altTg)
      outN(11, outPitch)
      outN(12, outRoll)
      outN(13, sideDrift)
      outN(14, forwardDrift)
      outN(15, xAcc)
      outN(16, yAcc)
    end

  -- signals (can?) have value, velocity (value delta), acceleration (velocity delta)
  -- targetValue, targetVelocity, targetAcceleration
  -- errorValue, errorVelocity, errorAcceleration
  
  return this
end

-- deferred function creates separate scope to reduce upvalue count in other scopes
-- expanded below using signalLogic = signalLogic()
function signalLogic()
  local this
    , signalElements
    , t_bufferPosition, t_bufferLength
    = {}
    , 
    { -- signal elements
      t_Value, t_Velocity, t_Accel
      , t_targetValue, t_targetVel, t_targetAccel
    }
  this[f_sNewSignalSet] = function(signalCount, bufferLength)
    bufferLength = bufferLength or 60
    local signalSet, buffers, newSignal
      = newSet(signalCount)
    tableValuesAssign(signalSet
      , {t_bufferLength,t_bufferPosition}
      , {bufferLength, 1}
      )
    for i,v in ipairz(signalSet[t_tokenList]) do
      newSignal, buffers={}, {}
      for ei, element in ipairz(signalElements) do
        buffers[element] = {}        
        -- initialize the buffers for this signal element to complete size
        for bi = 1,bufferLength do
          buffers[element][bi] = nilzies
        end
        newSignal[element],
        newSignal[t_buffers] 
        = nilzies
        , buffers
      end

      signalSet[v] = newSignal
    end
    return signalSet
  end

  this[f_sAssignValues] = function(signalSet, values, elementKey, signalKeys)
    elementKey, signalKeys 
      = elementKey or t_Value
      , signalKeys or signalSet[t_tokenList]
    local currentIndex, signal
      = signalSet[t_bufferPosition]
    
    for i,v in ipairz(signalKeys ) do 
      signal = signalSet[v]
      signal[elementKey] = values[i]
      -- mock up for velocities being assigned
      signal[t_Velocity] = values[i]
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

  this[f_sAdvanceBuffer] = function(signalSet)
    local currentIndex = signalSet[t_bufferPosition] or 0


  end

  return this
end

-- Actual Init for deferred logic definitions
signalLogic = signalLogic()
processingLogic = processingLogic()

function newRotor()
  local rotor = {
    ofs=nilzies,
    alt=0,
    tilt=0,
    vel=0,
    rot=0,
    pC=nilzies,pP=0,pR=0
  }
  rotor[_accErr] = nilzies
  rotor[_pitch] = 0.25
  rotor[altBuff] = {}
  rotor[velBuff] = {}
  rotor[accBuff] = {}
  rotor[tgVelBuff] = {}
  rotor[tgAccBuff] = {}
  return rotor
end

-- Tajin pid code
function pid(p,i,d)
    return{p=p,i=i,d=d,E=0,D=0,I=0,
		run=function(s,sp,pv)
			local E,D,A
			E = sp-pv
			D = E-s.E
			A = math.abs(D-s.D)
			s.E = E
			s.D = D
			s.I = A<E and s.I +E*s.i or s.I*0.5
			return E*s.p +(A<E and s.I or 0) +D*s.d
		end
	}
end

--[[ Tajin pid example
pid1 = pid(0.01,0.0005, 0.05)
pid2 = pid(0.1,0.00001, 0.005)
function onTick()
	setpoint = input.getNumber(1)
	pv1 = input.getNumber(2)
	pv2 = input.getNumber(3)
	output.setNumber(1,pid1:run(setpoint,pv1))
	output.setNumber(2,pid2:run(setpoint,pv2))
end
--]]

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


  --[[
  
	for i,rotor in pairs(qr) do
		--local r=rotor
		local inputOffset=(i-1)*3 + 9
		rotor.alt, rotor.tilt, rotor.vel =
		  getN(inputOffset, inputOffset+1, inputOffset+2)
		--rotor.hasData = false

		for bufI,buffer in pairs({altBuff,velBuff,accBuff,tgVelBuff,tgAccBuff}) do
      -- Shift values forward in buffer or initialize to zero if nil
      shiftBuffer(rotor[buffer])
		end

		if isValidNumber(rotor.alt,0) and isValidNumber(rotor.tilt) and isValidNumber(rotor.vel) then
			--rotor.hasData = true
      rotorInputCount = rotorInputCount + 1
      --adjusting the alt by the offset here is not the right thing to do
      -- that only applies to setting the target alt
      --rotor.altRaw = rotor.alt
      --rotor.alt = rotor.alt - (rotor.ofs or 0)     
      qrAlt = qrAlt + rotor.alt
      rotor.v2 = (rotor.alt - rotor[altBuff][1]) * bufferDeltaPerSecond
      
      rotor.acc = rotor.vel - rotor[velBuff][1]
      rotor.velErr = rotor.vel - rotor[tgVelBuff][1]
      rotor[_accErr] = rotor.acc - rotor[tgAccBuff][1]
    else
      rotor.acc, rotor.velErr, rotor[_accErr] 
        = nilzies, nilzies, nilzies
		end
  
    rotor[altBuff][bufferHead] = rotor.alt
    rotor[velBuff][bufferHead] = rotor.vel
    rotor[accBuff][bufferHead] = rotor.acc
    -- tgVelBuff,tgAccBuff are assigned in second rotor pass
    -- after pilot input processing
	end
	
	local defPitch, dAltTG, dRotorTilt, outPitch, outRoll
	--defPitch=0
	if state==state_boot then
		--defPitch=0.25
		state=state_initOffset
	end

  -- default pitch will be based on raw pilot input
  defPitch = coll
  -- Abort control code if we're not getting sensor input?
  if rotorInputCount~=4 then 
    --return false
  -- Long term, a manual override seems safer
    --defPitch = coll
  else
    -- OK, we have 4 valid rotor input sets
	  qrAlt=qrAlt/rotorInputCount
    
    if state==state_initOffset then
      state=state_waitRPS
			for i,r in pairs(qr) do
				r.ofs=r.alt-qrAlt
			end
      -- would be better if we check pitch and roll first
      -- and also sanity check the offests against tilt later
      -- in case the MC is initialized with the quad rotor 
      -- at an angle
    end
    
    if altTg==nilzies then -- and rotorInputCount==4
      altTg=qrAlt
    end

    if state==state_waitRPS then
      if rRPS>25 then 
        state=state_hover
        altTg=qrAlt+0.25
        for i,r in pairs(qr) do
          r.tg=r.ofs+altTg
          -- I now don't remember what these abbreviations mean:
          r.pC=0.25
          r.conf=0
          r.tv=0
        end
      end
    end

  end





	-- control input
	dAltTG = (coll*10)^2 * ifVal(coll<0,-1,1)
	--altTg=altTg+(dAltTG/60)
  if abs(coll) > 0.05 then
    altTg = qrAlt
  end
	
  --dRotorTilt = (yaw*10)^2 * ifVal(yaw<0,-1,1)
	--forwardPitch=forwardPitch+(dRotorTilt/60)
  forwardPitch = clamp(forwardPitch + throttleUp / (60 * 3), 0, 1)

  --if abs(coll) > 0.1 then
  --  altTg = qrAlt
  --end

  outPitch = pitch + (sPitch + axis5) * 2
  outRoll = pilotInputRoll + (sRoll) * -2


			
	for i,rotor in pairs(qr) do

    local yawTwist, tiltYawTaper 
      = clamp( (yaw + yawRate*4) * 0.25, -.25, .25)
      -- tilt for yaw should taper off between .25 and .5 forwardPitch
      -- tiltYawTaper =
      , clamp(2 - forwardPitch * 4,0,1)
    if i==2 or i==4 then yawTwist = -yawTwist end

		rotor.rot = forwardPitch 
      + (yawTwist * tiltYawTaper)
      -- trying yaw with pitch diff instead of tilt diff

				
		if state~=state_hover then
		  rotor[_pitch] = defPitch
    else
			-- Target velocity (m/s) will be based on...
			local rotorAngle, tiltThrustX, tiltThrustY, tiltThrustPctY, climbThrustAdjust,
      tgVelClimb, tgAccClimb, tgVelRollPitch, tgAccRollPitch, maxAltHoldVelocity,
      climbRate, climbVel, rotorAxisPolarity, pTiltCorrection, pitchLevelTarget, newPitch, pitchChange

			rotorAngle = rotor.tilt * pi * 2
			tiltThrustX = cos(rotorAngle)
			tiltThrustY = sin(rotorAngle)
			tiltThrustPctY = tiltThrustY / (tiltThrustX + abs(tiltThrustY))
			climbThrustAdjust = 1 / tiltThrustY
			-- so, if we knew the vertical thrust needed, total thrust would be:
			-- local thrustNeeded = verticalThrustNeeded * climbThrustAdjust
			
			
			if abs(rotor.tilt) < 0.06 then
				climbThrustAdjust = 0
			else
				if abs(rotor.tilt) < 0.11 then
					-- rotor angle is quite forward.
					-- increasing thrust to gain altitude is likely to hurt more than it helps
					-- Between 0.110 and 0.06, taper climbThrustAdjust down to zero
					climbThrustAdjust = climbThrustAdjust * mathmax(abs(rotor.tilt)-0.06,0) * (1/0.05)
					
					-- Wolfram alpha graph: Plot[{Sin[2 Pi x/360], 1/Sin[2 Pi x/360],Min[{1/Sin[2 Pi x/360], 1.66}],Min[{1, Max[{0, Abs[x/360]-0.06}] * (1/(0.110-0.06)) }], Min[{1, Max[{0, Abs[x/360]-0.06}] * (1/(0.110-0.06)) }] * 1/Sin[2 Pi x/360]}, {x, -90, 90}]
				end
			end
			
			-- Average altitude climb rate from the last 0.8ish seconds:
			climbRate = rotor.v2
			  -- (based on rotor.v2 = (rotor.alt - rotor.[altBuff][1]) * bufferDeltaPerSecond)
			-- current velocity may be a better prediction
			climbVel = rotor.vel * tiltThrustY
			  --   rotor.vel from sensor is speed in the direction of the rotor
			  --   * tiltThrustY gets Y portion corrected for rotor tilt
			
      
			--rotor.tg = altTg + rotor.ofs
      rotor.tg = rotor.alt + (altTg-qrAlt )
      
			maxAltHoldVelocity = 8 -- capping this low right now
			-- Target climb distance to cover
			-- Target velocity - attempt to close tgClimb in one second
			tgVelClimb = clamp((
				rotor.tg -- Altitude we are trying to reach
				- rotor.alt -- Minus where we already are
				- climbRate * 0.5 -- How far we'll have be half a second from now
        ) * climbThrustAdjust -- Adjust for tilt of 
        , -maxAltHoldVelocity, maxAltHoldVelocity)

      if abs(coll) > 0.05 then
        tgVelClimb = coll * 40
      end

    	-- rotor.pC is the approximate pitch needed for a hover
			-- In a hover, this means accelerating about 9.8m/s per second ish to hold altitude against gravity
      -- max pC is 0.6, leaving room for roll/pitch control
      -- hopefully, this leaves 2m/s for altHold and 2m/s for roll/pitch
      -- clamp acceleration requested to 2
      tgAccClimb = clamp(tgVelClimb - rotor.vel
        , -10, 10)
      tgVelClimb = rotor.vel + tgAccClimb

			-- Target velocity - attempt to close tgClimb in one second
			rotor.tv = tgVelClimb


			-- Add in pitch control/correction contribution to target velocity
			rotorAxisPolarity = negativeOneIf(i < 3) -- Front rotors are negative
      pTiltCorrection = 40 --ifVal(abs(pitch)<0.5,12,0)
      pitchLevelTarget = sPitch + axis5
      
      tgVelRollPitch = clamp(
			  (pitch * 10 + pitchLevelTarget * pTiltCorrection) * rotorAxisPolarity
				- rotor.vel * 0.5 -- How far we'll have be half a second from now. Should cut down on oversteer
			  , -4, 12)
      tgAccRollPitch = clamp(tgVelRollPitch - rotor.vel
        , -10, 10)
      tgVelRollPitch = rotor.vel + tgAccRollPitch
			
			-- Add in roll control/correction contribution to target velocity
			rotorAxisPolarity = negativeOneIf(i==2 or i==4) -- Right rotors are negative
      local rTiltCorrection = 40 --ifVal(abs(pilotInputRoll)<0.5,8,0)
			
      tgVelRollPitch = clamp(
			  (pilotInputRoll * 10 - sRoll*rTiltCorrection) * rotorAxisPolarity -- sRoll points left, so positive values need negative correction
				- rotor.vel * 0.5 -- How far we'll have be half a second from now. Should cut down on oversteer
			  , -4, 12)
        + tgVelRollPitch -- existing contribution from pitch

      tgAccRollPitch = clamp(tgVelRollPitch - rotor.vel
        , -10, 10)
      tgVelRollPitch = rotor.vel + tgAccRollPitch

			-- Target velocity - attempt to close tgClimb in one second + 
			rotor.tv = tgVelClimb + tgAccRollPitch
      --  + coll * 10 -- 10m/s for climb too much? IDK
			  
			rotor.tgAcc = clamp((rotor.tv - rotor.vel)
				--* bufferDeltaPerSecond -- We will attempt to reach the target velocity in 1/12 of a second (assuming bufferWidth=5)
				, -40, 40)
			
      newPitch = clamp( rotor.pC * climbThrustAdjust 
				+ (rotor.pC * 0.1 * rotor.tgAcc)
        + (forwardPitch * axis6), -1, 1)
      if forwardPitch>0.5 then
        yp = yaw * negativeOneIf(i==2 or i==4)
        newPitch = newPitch + yp
      end
      --]]


      --[[
        I tried the usual way of quad rotor yaw of increasing torque in two opposite corners, but it was not very effective or consistent when tested in game

      -- yawTwist isn't on axis with yaw pitch differential as defined above:
      yawTwist, tiltYawTaper 
      = clamp( (yaw 
        --+ yawRate*4
          ) * 4
          * rotor.pC * 0.1
          * negativeOneIf(i==1 or i==4)
          , -.5, .5)
      -- tilt for yaw should taper off between .25 and .5 forwardPitch
      -- tiltYawTaper =
      , clamp(2 - forwardPitch * 4,0,1)
      --if i==2 or i==4 then yawTwist = -yawTwist end
      yawTwist = clamp(yawTwist * ifVal(yawTwist < 0,0.25, 1),-0.2,0.5)
      newPitch = newPitch + yawTwist * tiltYawTaper

      --]]
      --[[

			pitchChange = clamp(newPitch - rotor[_pitch], -0.2, 0.2) 
			rotor[_pitch] = rotor[_pitch] + pitchChange

			rotor[tgVelBuff][bufferHead] = rotor.tv
			rotor[tgAccBuff][bufferHead] = rotor.tgAcc
			
			-- These were already calculated above:
			--rotor.velErr = rotor.vel - rotor.tgVelBuff[1]
			--rotor.accErr = rotor.acc - rotor.tgAccBuff[1]
			
			if rotor[_accErr]<-1 then
				rotor.pC=clamp(
          rotor.pC+0.001*abs(rotor[_accErr])*0.5,
          0.1, 0.6)
				rotor.conf=rotor.conf-0.01
			end
			if rotor[_accErr]>4 then
				rotor.pC=clamp(
          rotor.pC-0.001*rotor[_accErr]*0.5,
          0.1, 0.6)
				rotor.conf=rotor.conf-0.01
			end
			if --abs(rotor.tg-rotor.alt)<0.02 and 
			  abs(rotor[_accErr])<0.5 then
				rotor.conf=rotor.conf+0.01
			end
			
		end
		
		outN(i,rotor[_pitch])
		outN(i+4,rotor.rot)
	end
  --]]
	
  
--[[
function trunc(n) if n==nil then return "nil" end return string.format("%.f", n) end
function trunc2(n) if n==nil then return "nil" end return string.format("%.2f", n) end
--]]
--[[
function trunc(n) return n==nil and "nil" or string.format("%.f", n) end
function trunc2(n) return n==nil and "nil" or string.format("%.2f", n) end

function onDraw()
	if mcTick==nil then return false end -- safety
	
	w = _s.getWidth()
	h = _s.getHeight()					
	
   
  
	_s.setColor(255, 0, 0)
	tw=5*10
	--tx=w-tw*2-5
	tx=20
	ty=10
	local function pVal(l,v)
		if ty+10>h then
			ty=10
			tx=tx+tw*2.5
		end
		dtb(tx, ty, tw, 6, l, 1, 0)
		dtb(tx+tw+4, ty, tw*2, 6, v, -1, 0)
		ty=ty+6
	end
	
	tDiff=luaTick-mcTick
	pVal("State",state)
	pVal("TickDiff",trunc2(tDiff))
	--pVal("Roll",trunc2(pilotInputRoll))
	--pVal("Pitch",trunc2(pitch))
	--pVal("Yaw",trunc2(yaw))
	--pVal("Coll",trunc2(coll))
	pVal("rRPS",trunc2(rRPS))
	pVal("qrAlt",trunc2(qrAlt))
	--pVal("AltTg",trunc2(altTg))
	--pVal("dAlt",trunc2(dAlt))
  pVal("sCompass", trunc2(sCompass))
  pVal("yawRate", trunc2(yawRate))
	--pVal("sPitch",trunc2(sPitch))
	--pVal("sRoll",trunc2(sRoll))
	
	for i,r in pairs(qr) do
		--pVal(trunc(i).."pColl",trunc2(r.pC))
		--pVal(trunc(i).."Confdnc",trunc2(r.conf))
		--pVal("Rotor",trunc(i))
		--pVal("Alt"..trunc(i),trunc2(r.alt))
		--pVal("Ofs",trunc2(r.ofs))
		--pVal("Tilt",trunc2(r.tilt))
		--pVal("Vel",trunc2(r.vel))
		--pVal("Vel2",trunc2(r.v2))
		--pVal("TG",trunc2(r.tg))
		--pVal("TVel",trunc2(r.tv))
		--pVal("TAcc",trunc2(r.tgAcc))
		--pVal("vErr",trunc2(r.velErr))
		--pVal("aErr",trunc2(r[_accErr]))

		--pVal(trunc(i).."Pitch",trunc2(r[_pitch]))
	end
	
end 
--]]