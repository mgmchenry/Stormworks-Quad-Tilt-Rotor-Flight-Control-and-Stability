
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
--]]

*******************************

--[[
			
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