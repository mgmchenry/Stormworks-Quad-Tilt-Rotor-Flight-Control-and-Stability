--[[
Perseus Flight Controller
FC Core Envelope
--]]
gN=input.getNumber
sN=output.setNumber
gB=input.getBool
gPN=property.getNumber

pitchKp=gPN("Pitch P")
rollKp=gPN("Roll P")
maxPtichSpd=gPN("Max Pitch Angular speed(deg/s)")/360.0
maxRollSpd=gPN("Max Roll Angular speed(deg/s)")/360.0

function onTick()
	ce=gB(7)
	
	if ce==false then
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
	fsSen=gN(13)
	
	paSen=gN(16)
	raSen=gN(17)
	
	cruiseMode=gB(11)
	
	if cruiseMode==true then
		pitchSpd=wsCtl*maxPtichSpd
		rollSpd=adCtl*maxRollSpd
	else
		pitchTgt=0
		pitchErr=ftSen-pitchTgt
		if pitchErr>0 then pitchErrSign=1 else pitchErrSign=-1 end
		pitchSpd=pitchKp*pitchErrSign*2*math.abs(pitchErr)^1.2
		if pitchSpd>maxPtichSpd then pitchSpd=maxPtichSpd end
		if pitchSpd<-maxPtichSpd then pitchSpd=-maxPtichSpd end
		
		rollTgt=0
		rollErr=rollTgt-ltSen
		if rollErr>0 then rollErrSign=1 else rollErrSign=-1 end
		rollSpd=rollKp*rollErrSign*2*math.abs(rollErr)^1.2
		if rollSpd>maxRollSpd then rollSpd=maxRollSpd end
		if rollSpd<-maxRollSpd then rollSpd=-maxRollSpd end
	end
	
	sN(1, pitchSpd)
	sN(2, rollSpd)
end