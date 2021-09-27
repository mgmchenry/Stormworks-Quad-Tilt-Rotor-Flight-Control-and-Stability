--[[
Perseus Test Vehicle
Custom PID Controller Type-2
]]

controlVal = 0
_e = 0
__e = 0

function onTick()
	ce = input.getBool(1)

	setPoint = input.getNumber(1)
	processValue = input.getNumber(2)
	kp = input.getNumber(3)
	ki = input.getNumber(4)
	kd = input.getNumber(5)
	
	minOut = input.getNumber(6)
	maxOut = input.getNumber(7)
	
	e = setPoint - processValue
	
	pTerm = kp * (e - _e)
	iTerm = ki * (e)
	dTerm = kd * (e - 2 * _e + __e)
	
	controlInc = pTerm + iTerm + dTerm
	controlVal = controlVal + controlInc
	
	if controlVal > maxOut then
		controlVal = maxOut
	end
	
	if controlVal < minOut then
		controlVal = minOut
	end
	
	__e = _e
	_e = e
	
	output.setNumber(1, controlVal)
end


--FC Core Hover
gN=input.getNumber
sN=output.setNumber
gB=input.getBool
gPN=property.getNumber

heightTab={0,0,0}
upSpdTab={0,0,0}
pitchSpdTab={0,0,0}
rollSpdTab={0,0,0}
meTvcPitchTab={0,0,0}
meTvcRollTab={0,0,0}

dryMass=gPN("Mass")
heightKp=gPN("U/D Translation P")
heightKi=gPN("U/D Translation I")
heightKd=gPN("U/D Translation D")
udSpeed=gPN("Max U/D Translation Speed")
pitchSpdKp=gPN("Pitch Speed P")
pitchSpdKi=gPN("Pitch Speed I")
pitchSpdKd=gPN("Pitch Speed D")
rollSpdKp=gPN("Roll Speed P")
rollSpdKi=gPN("Roll Speed I")
rollSpdKd=gPN("Roll Speed D")
meTvcRatio=gPN("Main Engine TVC Ratio")
meTvcLimit=gPN("Main Engine TVC Limit")

_pitchSpdKp=pitchSpdKp*0.8
_pitchSpdKi=pitchSpdKi*1.5
_pitchSpdKd=pitchSpdKd*2
_rollSpdKp=rollSpdKp*0.8
_rollSpdKi=rollSpdKi*1.5
_rollSpdKd=rollSpdKd*2

function onTick()
	ce=gB(7)
	if ce==false then
		Init()
		sN(1, 0)
		sN(2, 0)
		sN(3, 0)
		sN(4, 0)
		sN(8, 0)
		sN(9, 0)
		return
	end

	adCtl=gN(1)
	wsCtl=gN(2)
	lrCtl=gN(3)
	udCtl=gN(4)
	CruSpd=gN(5)
	
	ftSen=gN(6)
	ltSen=gN(7)
	utSen=gN(8)
	cpSen=gN(9)
	gxSen=gN(10)
	gySen=gN(11)
	alSen=gN(12)
	fsSen=gN(13)
	rsSen=gN(14)
	usSen=gN(15)
	paSen=gN(16)
	raSen=gN(17)
	yaSen=gN(18)
	dynamicLoad=gN(19)
	
	pitchTgt=gN(20)
	rollTgt=gN(21)
	pitchSpdTgt=gN(22)
	rollSpdTgt=gN(23)
	meThr=gN(24)
	
	cruseMode=gB(11)
	
	mass=dryMass+dynamicLoad
	
	if cruseMode==true then
		pid(pitchSpdTgt,paSen,_pitchSpdKp,_pitchSpdKi,_pitchSpdKd,-0.5*mass,0.5*mass,pitchSpdTab, 2)
		pid(rollSpdTgt,raSen,_rollSpdKp,_rollSpdKi,_rollSpdKd,-0.5*mass,0.5*mass,rollSpdTab, 2)
	else
		pid(pitchSpdTgt,paSen,pitchSpdKp,pitchSpdKi,pitchSpdKd,-0.5*mass,0.5*mass,pitchSpdTab, 2)
		pid(rollSpdTgt,raSen,rollSpdKp,rollSpdKi,rollSpdKd,-0.5*mass,0.5*mass,rollSpdTab, 2)
	end

	pid(udSpeed*udCtl,usSen,heightKp,heightKi,heightKd,-2*mass,2*mass,upSpdTab, 2)
	
	if cruseMode==true then
		baseThr=(mass+upSpdTab[3])/4.0
		pitchTvc=meTvcRatio*pitchSpdTab[3]
		rollTvc=meTvcRatio*rollSpdTab[3]
	else
		pid(alSen,alSen,heightKp,heightKi,heightKd,-2*mass,2*mass,heightTab, 5)
		baseThr=(mass+heightTab[3]+upSpdTab[3])/4.0
		pitchTvc=0
		rollTvc=0
	end
	
	if pitchTvc>meTvcLimit then pitchTvc=meTvcLimit end
	if pitchTvc<-meTvcLimit then pitchTvc=-meTvcLimit end
	if rollTvc>meTvcLimit then rollTvc=meTvcLimit end
	if rollTvc<-meTvcLimit then rollTvc=-meTvcLimit end
	if meThr<0 then tvcDir=-1 else tvcDir=1 end
	
	fThr=baseThr+pitchTab[3]-pitchSpdTab[3]
	bThr=baseThr-pitchTab[3]+pitchSpdTab[3]
	lThr=baseThr+rollTab[3]+rollSpdTab[3]
	rThr=baseThr-rollTab[3]-rollSpdTab[3]
	
	sN(1, fThr)
	sN(2, bThr)
	sN(3, lThr)
	sN(4, rThr)
	sN(8, baseThr)
	sN(9, pitchTvc*tvcDir)
	sN(10, rollTvc*tvcDir)
end

function Init()
	heightTab={0,0,0}
	upSpdTab={0,0,0}
	pitchTab={0,0,0}
	rollTab={0,0,0}
	pitchSpdTab={0,0,0}
	rollSpdTab={0,0,0}
end

function pid(setPoint, measure, kp, ki, kd, minOut, maxOut, vTab, base)
	e=setPoint - measure
	_e=vTab[1] 
	__e=vTab[2]
	cv=vTab[3]
	
	pTerm=kp*(e-_e)
	iTerm=ki*(e)*(base/(base+math.abs(e)))
	dTerm=kd*(e-2*_e+__e)
	cv=cv+pTerm+iTerm+dTerm
	
	if cv>maxOut then
		cv=maxOut
	elseif cv<minOut then
		cv=minOut
	end

	vTab[1]=e
	vTab[2]=_e
	vTab[3]=cv
end


--FC Core Translation
gN=input.getNumber
sN=output.setNumber
gB=input.getBool
gPN=property.getNumber

yawSpdTab={0,0,0}
fbTransSpdTab={0,0,0}
lrTransSpdTab={0,0,0}
mainEngineTab={0,0,0}

dryMass=gPN("Mass")
yawSpdKp=gPN("Yaw Speed P")
yawSpdKi=gPN("Yaw Speed I")
yawSpdKd=gPN("Yaw Speed D")
yawSpd=gPN("Max Yaw Angular speed(deg/s)")
fbSpdKp=gPN("F/B Translation Speed P")
fbSpdKi=gPN("F/B Translation Speed I")
fbSpdKd=gPN("F/B Translation Speed D")
fbSpeed=gPN("Max F/B Translation Speed")
lrSpdKp=gPN("L/R Translation Speed P")
lrSpdKi=gPN("L/R Translation Speed I")
lrSpdKd=gPN("L/R Translation Speed D")
lrSpeed=gPN("Max L/R Translation Speed")
cruseSpeedKp=gPN("Cruse speed P")
cruseSpeedKi=gPN("Cruse speed I")
cruseSpeedKd=gPN("Cruse speed D")
fyYawArm=gPN("Front L/R Translation Fan Yaw Right Arm Length")
byYawArm=gPN("Back L/R Translation Fan Yaw Left Arm Length")
cruiseLRTrans=gPN("Manage L/R Translation in Cruise Mode")
_lrSpdKp=lrSpdKp*1.2
_lrSpdKi=lrSpdKi*0.2
_lrSpdKd=lrSpdKd

function onTick()
	ce=gB(7)
	if ce==false then
		sN(5, 0)
		sN(6, 0)
		sN(7, 0)
		sN(14, 0)
		
		Init()
		return
	end

	adCtl=gN(1)
	wsCtl=gN(2)
	lrCtl=gN(3)
	udCtl=gN(4)
	CruSpd=gN(5)
	
	ftSen=gN(6)
	ltSen=gN(7)
	utSen=gN(8)
	cpSen=gN(9)
	gxSen=gN(10)
	gySen=gN(11)
	alSen=gN(12)
	fsSen=gN(13)
	rsSen=gN(14)
	usSen=gN(15)
	paSen=gN(16)
	raSen=gN(17)
	yaSen=gN(18)
	dynamicLoad=gN(19)
	
	cruiseMode=gB(11)
	
	mass=dryMass+dynamicLoad
	
	if cruiseMode==true then
		pid(CruSpd,fsSen,cruseSpeedKp,cruseSpeedKi,cruseSpeedKd,-3*mass,5*mass,mainEngineTab, 5)
		fbTransSpdTab={0,0,0}

		if cruiseLRTrans==true then
			pid(adCtl*lrSpeed,rsSen,_lrSpdKp,_lrSpdKi,_lrSpdKd,-0.5*mass,0.5*mass,lrTransSpdTab, 2)
		else
			lrTransSpdTab={0,0,0}
		end
	else
		if CruSpd==0 then
			pid(wsCtl*fbSpeed,fsSen,fbSpdKp,fbSpdKi,fbSpdKd,-0.5*mass,0.5*mass,fbTransSpdTab, 5)
		else
			pid(math.min(CruSpd,fbSpeed),fsSen,fbSpdKp,fbSpdKi,fbSpdKd,-0.5*mass,0.5*mass,fbTransSpdTab, 5)
		end
		
		mainEngineTab={0,0,0}

		pid(adCtl*lrSpeed,rsSen,lrSpdKp,lrSpdKi,lrSpdKd,-0.5*mass,0.5*mass,lrTransSpdTab, 2)
	end
	
	pid(lrCtl*yawSpd/360.0,yaSen,yawSpdKp,yawSpdKi,yawSpdKd,-0.5*mass,0.5*mass,yawSpdTab, 0.5)
	
	lrUnit=lrTransSpdTab[3]/(fyYawArm+byYawArm)
	fyThr=lrUnit*byYawArm+yawSpdTab[3]
	byThr=lrUnit*fyYawArm-yawSpdTab[3]
	tfThr=fbTransSpdTab[3]
	mainEngineThr=mainEngineTab[3]
	
	sN(5, tfThr)
	sN(6, fyThr)
	sN(7, byThr)
	
	sN(14, mainEngineThr)
end

function Init()
	yawSpdTab={0,0,0}
	fbTransSpdTab={0,0,0}
	lrTransSpdTab={0,0,0}
	mainEngineTab={0,0,0}
end

function pid(setPoint, measure, kp, ki, kd, minOut, maxOut, vTab, base)
	e=setPoint - measure
	_e=vTab[1] 
	__e=vTab[2]
	cv=vTab[3]
	
	pTerm=kp*(e-_e)
	iTerm=ki*(e)*(base/(base+math.abs(e)))
	dTerm=kd*(e-2*_e+__e)
	cv=cv+pTerm+iTerm+dTerm
	
	if cv>maxOut then
		cv=maxOut
	elseif cv<minOut then
		cv=minOut
	end

	vTab[1]=e
	vTab[2]=_e
	vTab[3]=cv
end