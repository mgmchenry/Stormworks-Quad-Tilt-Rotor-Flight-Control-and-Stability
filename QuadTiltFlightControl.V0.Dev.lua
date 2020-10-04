-- Stormworks Quad Tilt Rotor Flight Control and Stability
-- V 0.6.12 Michael McHenry 2019-06-07
-- 0.6.09 min: Before 11,170 bytes After 4,052 bytes
sourceV0612="https://repl.it/@mgmchenry/Stormworks-Quad-Tilt-Rotor-Flight-Control-and-Stability"

local i, o, s, m = input, output, screen, math
local inN, outN, input_GetBool, dtb =
  i.getNumber, 
  o.setNumber, 
  i.getBool,
  s.drawTextBox

local abs, sin, cos, mathmax, pi, pi2 =
  m.abs, m.sin, m.cos, m.max,
  m.pi
pi2 = pi * 2

local function clamp(v,minVal,maxVal) 
	if v==nil then return nil end
	if v>maxVal then return maxVal end 
	if v<minVal then return minVal end 
	return v
end

local function getN(...)
    local r={}
    for i,v in ipairs({...}) do r[i]=inN(v) end
    return table.unpack(r)
end

local function negativeOneIf(condition)
	if condition then return -1 end
	return 1
end
local function ifVal(condition, ifTrue, ifFalse)
  if condition then return ifTrue end
  return ifFalse
end

local altBuff, velBuff, accBuff, tgVelBuff, tgAccBuff
, _pitch, _accErr
 = "altBuff", "velBuff", "accBuff", "tgVelBuff", "tgAccBuff"
 , "pitch", "accErr"

local function newRotor()
	local rotor = {
		ofs=nil,
		alt=0,
		tilt=0,
		vel=0,
		rot=0,
		pC=nil,pP=0,pR=0
	}
  rotor[_accErr] = nil
  rotor[_pitch] = 0.25
	rotor[altBuff] = {}
	rotor[velBuff] = {}
	rotor[accBuff] = {}
	rotor[tgVelBuff] = {}
	rotor[tgAccBuff] = {}
	return rotor
end

local state_boot, state_waitRPS, state_hover = 1,2,3
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
local buffers, bfRoll, bfPitch, bfYaw,
  bfTargetRoll, bfTargetPitch, bfTargetYaw, bufferList
  ={},1,2,3,4,5,6
bufferList = {bfRoll, bfPitch, bfYaw, bfTargetRoll, bfTargetPitch, bfTargetYaw}
for i,v in pairs(bufferList) do
  buffers[v]={}
end

local function shiftBuffer(buffer)
    for bufferIndex=1, bufferWidth do
      -- Shift values forward in buffer or initialize to zero if nil
      buffer[bufferIndex] = buffer[bufferIndex+1] or 0
    end
end

local function sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

local roll,pitch,yaw,coll,axis5,axis6,
	sX,sY,sCompass,sPitch,sRoll,sTiltUp,
	rRPS,mcTick, yawRate, rollRate, pitchRate,
  qrAlt, throttleUp

function onTick()
	if inN(1) == nil then return false end -- safety check
	
	luaTick=luaTick+1
	if luaTick==1 then --Init
	
	end
	
	roll,pitch,yaw,coll,axis5,axis6,
	sX,sY,sCompass,sPitch,sRoll,sTiltUp,
	rRPS,mcTick=getN(1,2,3,4,5,6,21,22,23,24,25,26,29,30)
	qrAlt=0
  --
  throttleUp = 0 + ifVal(input_GetBool(11), 1, 0) - ifVal(input_GetBool(12), 1, 0)
	
  if sTiltUp<0 then
    sPitch = sPitch + (0.25 * sign(sTiltUp))
  end

  for i,v in pairs(bufferList) do
    shiftBuffer(buffers[v])
  end
  buffers[bfYaw][bufferHead] = sCompass
  buffers[bfRoll][bufferHead] = sRoll
  buffers[bfPitch][bufferHead] = sPitch
  yawRate = sCompass - buffers[bfYaw][1]
  rollRate = (sRoll - buffers[bfRoll][1]) * bufferDeltaPerSecond
  pitchRate = (sPitch - buffers[bfYaw][1]) * bufferDeltaPerSecond
  if yawRate > .5 then yawRate = yawRate - 1 end
  if yawRate < -.5 then yawRate = yawRate + 1 end
  yawRate = yawRate * bufferDeltaPerSecond

	for i,rotor in pairs(qr) do
		local r=rotor

		local inputOffset=(i-1)*3 + 9
		rotor.alt, rotor.tilt, rotor.vel =
		  getN(inputOffset, inputOffset+1, inputOffset+2)
		
		for bufI,buffer in pairs({altBuff,velBuff,accBuff,tgVelBuff,tgAccBuff}) do
      -- Shift values forward in buffer or initialize to zero if nil
      shiftBuffer(rotor[buffer])
		end
		rotor.acc = rotor.vel - rotor.velBuff[1]
		rotor.velErr = rotor.vel - rotor[tgVelBuff][1]
		rotor[_accErr] = rotor.acc - rotor[tgAccBuff][1]
		
		rotor[altBuff][bufferHead] = rotor.alt
		rotor[velBuff][bufferHead] = rotor.vel
		rotor[accBuff][bufferHead] = rotor.acc
		
		if rotor.ofs==nil and rotor.alt~=0 then
			-- should also be checking for sPitch and sRoll==0 here
			rotor.ofs = rotor.alt
		end
		qrAlt = qrAlt + rotor.alt
		rotor.v2 = (rotor.alt - rotor[altBuff][1]) * bufferDeltaPerSecond
		
	end
	
	qrAlt=qrAlt/4
	
	if altTg==nil then
		if qrAlt==0 then return false end
		altTg=qrAlt
	end
	local defPitch, dAltTG, dRotorTilt, outPitch, outRoll
	defPitch=0

	if state==state_boot then
		defPitch=0.25
		state=state_waitRPS
	end
	if state==state_waitRPS then
		defPitch=0.10
		if rRPS>25 then 
      state=state_hover
			altTg=qrAlt+1
			for i,r in pairs(qr) do
				r.ofs=r.alt-qrAlt
				r.tg=r.ofs+altTg
				r.pC=0.25
				r.conf=0
				r.tv=0
			end
    end
	end

	-- control input
	dAltTG = (coll*10)^2 * ifVal(coll<0,-1,1)
	
  --dRotorTilt = (yaw*10)^2 * ifVal(yaw<0,-1,1)
	--forwardPitch=forwardPitch+(dRotorTilt/60)
  forwardPitch = clamp(forwardPitch + throttleUp / (60 * 3), 0, 1)
	altTg=altTg+(dAltTG/60)

  --if abs(coll) > 0.1 then
  --  altTg = qrAlt
  --end

  outPitch = pitch + (sPitch + axis5) * 2
  outRoll = roll + (sRoll) * -2
			
	for i,rotor in pairs(qr) do

    local yawTwist = clamp( (yaw + yawRate*4) * 0.25, -.25, .25)
    if i==2 or i==4 then yawTwist = -yawTwist end
		rotor.rot = forwardPitch + yawTwist
				
		if state~=state_hover then
		  rotor[_pitch] = defPitch
    else
			-- Target velocity (m/s) will be based on...
			local rotorAngle, tiltThrustX, tiltThrustY, tiltThrustPctY, climbThrustAdjust,
      tgVelClimb, tgAccClimb, tgVelRollPitch, tgAccRollPitch, maxAltHoldVelocity,
      climbRate, climbVel, rotorAxisPolarity, pTiltCorrection, pitchLevelTarget, newPitch, pitchChange

			rotorAngle = rotor.tilt * pi2
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

    	-- rotor.pC is the approximate pitch needed for a hover
			-- In a hover, this means accelerating about 9.8m/s per second ish to hold altitude against gravity
      -- max pC is 0.6, leaving room for roll/pitch control
      -- hopefully, this leaves 2m/s for altHold and 2m/s for roll/pitch
      -- clamp acceleration requested to 2
      tgAccClimb = clamp(tgVelClimb - rotor.vel
        , -2, 2)
      tgVelClimb = rotor.vel + tgAccClimb

			-- Target velocity - attempt to close tgClimb in one second
			rotor.tv = tgVelClimb


			-- Add in pitch control/correction contribution to target velocity
			rotorAxisPolarity = negativeOneIf(i < 3) -- Front rotors are negative
      pTiltCorrection = 36 --ifVal(abs(pitch)<0.5,12,0)
      pitchLevelTarget = sPitch + axis5
      
      tgVelRollPitch = clamp(
			  (pitch * 6 + pitchLevelTarget * pTiltCorrection) * rotorAxisPolarity
				- rotor.vel * 0.5 -- How far we'll have be half a second from now. Should cut down on oversteer
			  , -1, 12)
      tgAccRollPitch = clamp(tgVelRollPitch - rotor.vel
        , -2, 2)
      tgVelRollPitch = rotor.vel + tgAccRollPitch
			
			-- Add in roll control/correction contribution to target velocity
			rotorAxisPolarity = negativeOneIf(i==2 or i==4) -- Right rotors are negative
      local rTiltCorrection = 36 --ifVal(abs(roll)<0.5,8,0)
			
      tgVelRollPitch = clamp(
			  (roll * 6 - sRoll*rTiltCorrection) * rotorAxisPolarity -- sRoll points left, so positive values need negative correction
				- rotor.vel * 0.5 -- How far we'll have be half a second from now. Should cut down on oversteer
			  , -1, 8)
        + tgVelRollPitch -- existing contribution from pitch

      tgAccRollPitch = clamp(tgVelRollPitch - rotor.vel
        , -2, 2)
      tgVelRollPitch = rotor.vel + tgAccRollPitch

			-- Target velocity - attempt to close tgClimb in one second + 
			rotor.tv = tgVelClimb + tgAccRollPitch
      --  + coll * 10 -- 10m/s for climb too much? IDK
			  
			rotor.tgAcc = clamp((rotor.tv - rotor.vel)
				--* bufferDeltaPerSecond -- We will attempt to reach the target velocity in 1/12 of a second (assuming bufferWidth=5)
				, -10, 10)
			
      newPitch = rotor.pC * climbThrustAdjust 
				+ (rotor.pC * 0.1 * rotor.tgAcc)
        + (forwardPitch * axis6)
			pitchChange = clamp(newPitch - rotor[_pitch], -0.05, 0.05) 
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

local function trunc(n) if n==nill then return "nil" end return string.format("%.f", n) end
local function trunc2(n) if n==nill then return "nil" end return string.format("%.2f", n) end



function onDraw()
	if mcTick==nil then return false end -- safety
	
	w = screen.getWidth()
	h = screen.getHeight()					
	
   
  
	screen.setColor(255, 0, 0)
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
	--pVal("Roll",trunc2(roll))
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
		pVal(trunc(i).."pColl",trunc2(r.pC))
		pVal(trunc(i).."Confdnc",trunc2(r.conf))
		--pVal("Rotor",trunc(i))
		--pVal("Alt"..trunc(i),trunc2(r.alt))
		--pVal("Ofs",trunc2(r.ofs))
		--pVal("Tilt",trunc2(r.tilt))
		pVal("Vel",trunc2(r.vel))
		pVal("Vel2",trunc2(r.v2))
		--pVal("TG",trunc2(r.tg))
		--pVal("TVel",trunc2(r.tv))
		--pVal("TAcc",trunc2(r.tgAcc))
		pVal("vErr",trunc2(r.velErr))
		pVal("aErr",trunc2(r[_accErr]))

		--pVal(trunc(i).."Pitch",trunc2(r[_pitch]))
	end
	
end