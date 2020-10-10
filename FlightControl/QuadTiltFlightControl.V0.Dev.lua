-- Stormworks Quad Tilt Rotor Flight Control and Stability
-- V 0.10.20g Michael McHenry 2020-10-05
-- 0.6.09 min: Before 11,170 bytes After 4,052 bytes
sourceV1020h="https://repl.it/@mgmchenry/Stormworks"

--local strings = "test,test2,test3"
--for i in string.gmatch(strings, "([^,]*),") do
--   print(i)
--end

--[[
100, -950
0, -4750
--]]

local _i, _o, _m
--, nilzies
  = input
  , output
  , math
  --, _s
  --, screen

local inN, outN, input_GetBool, tableUnpack =
  _i.getNumber, 
  _o.setNumber, 
  _i.getBool,
  table.unpack
--, dtb
--  _s.drawTextBox,

local abs, sin, cos, mathmax, pi
   --, pi2 
 =
  _m.abs, _m.sin, _m.cos, _m.max,
  _m.pi
  --, _m.pi * 2

--function names to minify
local clamp, getN, negativeOneIf, ifVal
,shiftBuffer, sign, newRotor, trunc2
, trunc, getTokens, isValidNumber, numberOrZero
--, getSomeIndexValues


function ifVal(condition, ifTrue, ifFalse)
  return condition and ifTrue or ifFalse
end
function negativeOneIf(condition)
  return condition and -1 or 1
end
function isValidNumber(x,invalidValue)
  return x~=nilzies and type(x)=='number' and x~=invalidValue
end

function clamp(v,minVal,maxVal) 
  return isValidNumber(v) and
    (v>maxVal and maxVal or
      (v<minVal and minVal) or
      v
    )
    or nilzies
end

function getN(...)
    local r={}
    for i,v in ipairs({...}) do r[i]=inN(v) end
    return tableUnpack(r)
end


local _tokenId, state_boot, state_initOffset, state_waitRPS, state_hover 
  = 0,1,2,3,4
function getTokens(n, list, prefix)
  list, prefix
    = list or {}
    , prefix or "token_"
  for i=1,n do
    _tokenId = _tokenId + 1
    list[#list+1] = prefix .. _tokenId
  end
  return tableUnpack(list)
end

--[[
we're going to try local nilz to save a few bytes
Test with sourceV1020g
Before
17,380 bytes
After
3,876 bytes

local t_tokenList = "tokenorwhatever"

function newSet(tokenCount, set)
  set = set or {}
  set[t_tokenList] = getTokens(tokenCount, set[t_tokenList])
end
fruitSet = newSet(6)
fruitSet = {token1 = nil, token2 = nil, etc, token6 = nil}
local orange, banana, apple, cherry, melon, lemon = getTokens(fruitSet)

--]]



local altBuff, velBuff, accBuff, tgVelBuff, tgAccBuff
, _pitch, _accErr
 = getTokens(7)
 --"altBuff", "velBuff", "accBuff", "tgVelBuff", "tgAccBuff"
 --, "pitch", "accErr"

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

local luaTick, lastTick, state, forwardPitch, qr, 
  altTg, bufferWidth, bufferHead, bufferDeltaPerSecond =
  0, -- luaTick=
  -1, -- lastTick=
  state_boot, -- state=
  0 -- forwardPitch=
  --qr=
  ,{newRotor(),newRotor(),newRotor(),newRotor()}

bufferWidth = 5
bufferHead = bufferWidth+1
bufferDeltaPerSecond = 60 / bufferWidth
local buffers
  , bfRoll, bfPitch, bfYaw
  , bfTargetRoll, bfTargetPitch, bfTargetYaw
  , bfXPos,bfYPos
  , bufferList
  ={}
  --,getSomeIndexValues(8)
  ,1,2,3,4,5,6,7,8
bufferList = {bfRoll, bfPitch, bfYaw, bfTargetRoll, bfTargetPitch, bfTargetYaw
,bfXPos,bfYPos}
for i,v in pairs(bufferList) do
  buffers[v]={}
end

local signals
  , s_Xpos, s_Ypos, s_Heading
  , signalList
  = {}
  ,1,2,3
  , {}
signalList = {s_Xpos, s_Ypos, s_Heading}

--[[
signal (ex yaw) has:
value (could be nil?)
 valueBuffer
target (could be nil?)
 targetBuffer
difference () nil or zero?


]]

function shiftBuffer(buffer)
    for bufferIndex=1, bufferWidth do
      -- Shift values forward in buffer or initialize to zero if nil
      buffer[bufferIndex] = buffer[bufferIndex+1] or 0
    end
end

function sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

local pilotInputRoll,pitch,yaw,coll,axis5,axis6,
	sX,sY,sCompass,sPitch,sRoll,sTiltUp,
	rRPS,mcTick, yawRate, rollRate, pitchRate,
  qrAlt, throttleUp, rotorInputCount

function onTick()
	if inN(1) == nilzies then return false end -- safety check
	
	luaTick=luaTick+1
  --[[
	if luaTick==1 then --Init	
	end
  --]]

	pilotInputRoll,pitch,yaw,coll,axis5,axis6,
	sX,sY,sCompass,sPitch,sRoll,sTiltUp,
	rRPS,mcTick=getN(1,2,3,4,5,6,21,22,23,24,25,26,29,30)
	qrAlt,rotorInputCount=0,0

  -- so...
  throttleUp = 0 + ifVal(input_GetBool(1), 1, 0) - ifVal(input_GetBool(2), 1, 0)
	
  if sTiltUp<0 then
    sPitch = sPitch + (0.25 * sign(sTiltUp))
  end
  -- corrected roll =
  -- asin((sin(x*pi/180))/(sin((90-y)*pi/180)))*180/pi
  -- x is the roll angle from the sensor in degrees, and y is the pitch angle from the sensor in degrees
  -- according to jbaker from Stormworks lua discord

  for i,v in pairs(bufferList) do
    shiftBuffer(buffers[v])
  end
  buffers[bfYaw][bufferHead] = sCompass
  buffers[bfRoll][bufferHead] = sRoll
  buffers[bfPitch][bufferHead] = sPitch
  buffers[bfXPos][bufferHead] = sX
  buffers[bfYPos][bufferHead] = sY
  yawRate = sCompass - buffers[bfYaw][1]
  rollRate = (sRoll - buffers[bfRoll][1]) * bufferDeltaPerSecond
  pitchRate = (sPitch - buffers[bfYaw][1]) * bufferDeltaPerSecond
  if yawRate > .5 then yawRate = yawRate - 1 end
  if yawRate < -.5 then yawRate = yawRate + 1 end
  yawRate = yawRate * bufferDeltaPerSecond

  --[[ This will be helpful to add in
  xVel = (buffers[bfXPos][bufferHead] - buffers[bfXPos][1]) * bufferDeltaPerSecond
  yVel = (buffers[bfYPos][bufferHead] - buffers[bfYPos][1]) * bufferDeltaPerSecond
  velAngle = atan2(yVel, xVel) / pi2
  head = buffers[bfYaw][1] + 0.25
  --]]

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
	
	outN(9, qrAlt)
	outN(10, altTg)
  outN(11, outPitch)
  outN(12, outRoll)
end

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