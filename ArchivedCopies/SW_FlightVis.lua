-- Stormworks Quad Tilt Rotor Flight Control and Stability
-- V 0.6.14 Michael McHenry 2019-06-07
-- 0.6.09 min: Before 11,170 bytes After 4,052 bytes
sourceV0614="https://repl.it/@mgmchenry/Stormworks-Quad-Tilt-Rotor-Flight-Control-and-Stability"

--local strings = "test,test2,test3"
--for i in string.gmatch(strings, "([^,]*),") do
--   print(i)
--end

local _i, _o, _s, _m = input, output, screen, math
local inN, outN, input_GetBool, 
  dtb, screenDrawLine, setColor,
  tableUnpack =
  _i.getNumber, 
  _o.setNumber, 
  _i.getBool,
  _s.drawTextBox,
  _s.drawLine,
  _s.setColor,
  table.unpack

local abs, sin, cos, mathmax, mathmin, sqrt, atan2,
  pi, pi2 =
  _m.abs, _m.sin, _m.cos, _m.max, _m.min, _m.sqrt, _m.atan,
  _m.pi
pi2 = pi * 2

--function names to minify
local clamp, getN, negativeOneIf, ifVal,
shiftBuffer, sign, newRotor, trunc2, trunc, getTokens, drawCircle, drawArc, actualFreakingLineForFSake

function clamp(v,minVal,maxVal) 
	if v==nil then return nil end
	if v>maxVal then return maxVal end 
	if v<minVal then return minVal end 
	return v
end

function getN(...)
    local r={}
    for i,v in ipairs({...}) do r[i]=inN(v) end
    return tableUnpack(r)
end

function negativeOneIf(condition)
	if condition then return -1 end
	return 1
end
function ifVal(condition, ifTrue, ifFalse)
  if condition then return ifTrue end
  return ifFalse
end

local state_boot, state_waitRPS, state_hover, _tokenId 
  = 1,2,3, 0
function getTokens(n, list)
  list = {}
  for i=1,n do
    _tokenId = _tokenId + 1
    list[i] = "token_".._tokenId
  end
  return tableUnpack(list)
end

local altBuff, velBuff, accBuff, tgVelBuff, tgAccBuff
, _pitch, _accErr
 = getTokens(7)
 --"altBuff", "velBuff", "accBuff", "tgVelBuff", "tgAccBuff"
 --, "pitch", "accErr"

function newRotor()
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
local buffers, bufferList
  ={},{1,2,3,4,5,6,7,8,9}
local
  bfRoll, bfPitch, bfYaw,
  bfTargetRoll, bfTargetPitch, bfTargetYaw, 
  bfXPos, bfYPos, bfCompass
  = tableUnpack(bufferList)
--bufferList = {bfRoll, bfPitch, bfYaw, bfTargetRoll, bfTargetPitch, bfTargetYaw, bfXPos, bfYPos, bfCompass}
for i,v in pairs(bufferList) do
  buffers[v]={}
end

function shiftBuffer(buffer)
    for bufferIndex=1, bufferWidth do
      -- Shift values forward in buffer or initialize to zero if nil
      buffer[bufferIndex] = buffer[bufferIndex+1] or 0
    end
end

function sign(x)
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
  --print("buffer count: "..#buffers)
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

	for i,rotor in pairs(qr) do
		local r=rotor

		local inputOffset=(i-1)*3 + 9
		rotor.alt, rotor.tilt, rotor.vel =
		  getN(inputOffset, inputOffset+1, inputOffset+2)
		
		for bufI,buffer in pairs({altBuff,velBuff,accBuff,tgVelBuff,tgAccBuff}) do
      -- Shift values forward in buffer or initialize to zero if nil
      shiftBuffer(rotor[buffer])
		end
		rotor.acc = rotor.vel - rotor[velBuff][1]
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
	
	local defPitch, dAltTG, dRotorTilt, outPitch, outRoll
	defPitch=0

  outPitch = pitch + (sPitch + axis5) * 2
  outRoll = roll + (sRoll) * -2
				
end

 trunc(n) if n==nill then return "nil" end return string.format("%.f", n) end
function trunc2(n) if n==nill then return "nil" end return string.format("%.2f", n) end


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

function onDraw()
	if mcTick==nil then return false end -- safety
	
	w = _s.getWidth()
	h = _s.getHeight()					
	
  local tickWidth, 
    displayX, displayY, xa, ya, xb, yb, d2Offs, head,
    xVel, yVel, xyVel, velAngle, xyFactor
    = 5

  xVel = (buffers[bfXPos][bufferHead] - buffers[bfXPos][1]) * bufferDeltaPerSecond
  yVel = (buffers[bfYPos][bufferHead] - buffers[bfYPos][1]) * bufferDeltaPerSecond
  velAngle = atan2(yVel, xVel) / pi2
  head = buffers[bfYaw][1] + 0.25

  local drawStats = function(polarOffset, displayX, displayY)
    xa=-sin(pi2*(head-polarOffset))*tickWidth*5
    ya=-cos(pi2*(head-polarOffset))*tickWidth*5
    setColor(0, 0, 255)
    actualFreakingLineForFSake(displayX,displayY,displayX+xa,displayY+ya)

    xa=-sin(pi2*(head + yawRate - polarOffset))*tickWidth*4
    ya=-cos(pi2*(head + yawRate - polarOffset))*tickWidth*4
    setColor(128, 128, 255)
    actualFreakingLineForFSake(displayX,displayY,displayX+xa,displayY+ya)
      
    setColor(255, 255, 255) 
    for i= -4, 4 do
      xa = displayX + tickWidth * i
      ya = displayY + tickWidth * i
      actualFreakingLineForFSake(xa,displayY-1,xa,displayY+1)
      actualFreakingLineForFSake(displayX-1,ya,displayX+1,ya)
    end
    drawCircle(displayX,displayY,tickWidth * 5,32)
    
    setColor(128, 128, 128)
    drawArc(displayX,displayY,tickWidth * 5 - 3,16, -0.12, 0.12)
    drawArc(displayX,displayY,tickWidth * 5 - 3,16, -0.37, -0.13)
    setColor(255, 0, 0)
    drawArc(displayX,displayY,tickWidth * 5 - 3,16, 0, sRoll * 2)
    setColor(255, 255, 0)
    drawArc(displayX,displayY,tickWidth * 5 - 3,16, -0.25, sPitch * 2 - 0.25)

    xyVel = sqrt(xVel*xVel + yVel*yVel)
    xyFactor = mathmin(1, 10 / xyVel)
    
    setColor(0, 255, 0)
    --xa = displayX+xVel*xyFactor*(tickWidth/2)
    --ya = displayY+yVel*xyFactor*(tickWidth/2)
    --if polarOffset ~= 0 then
    xa = displayX - sin(pi2 * (velAngle - polarOffset)) * mathmin(10, xyVel)*(tickWidth/2)
    ya = displayY - cos(pi2 * (velAngle - polarOffset)) * mathmin(10, xyVel)*(tickWidth/2)
    --end
    actualFreakingLineForFSake(xa,displayY-2,xa,displayY+2)
    actualFreakingLineForFSake(displayX-2,ya,displayX+2,ya)
    actualFreakingLineForFSake(displayX,displayY,xa,ya)

    
    for i= 0, 3 do
      xa = -sin(pi2 * (0.25*i - polarOffset))
      ya = -cos(pi2 * (0.25*i - polarOffset))
      xb = displayX + (tickWidth * 5 + 1) * xa
      yb = displayY + (tickWidth * 5 + 1) * ya
      xa = displayX + (tickWidth * 5 - 1) * xa
      ya = displayY + (tickWidth * 5 - 1) * ya
      actualFreakingLineForFSake(xa,ya,xb,yb)
    end
  end

  
  d2Offs = tickWidth * 8
  displayX = tickWidth * 5 + 3 
  displayY = displayX

  drawStats(0, displayX+d2Offs, displayY+d2Offs)
  drawStats(head, displayX, displayY)
  setColor(255, 0, 0)
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
	--pVal("State",state)
	--pVal("TickDiff",trunc2(tDiff))
	--pVal("Roll",trunc2(roll))
	--pVal("Pitch",trunc2(pitch))
	--pVal("Yaw",trunc2(yaw))
	--pVal("Coll",trunc2(coll))
	--pVal("rRPS",trunc2(rRPS))
	--pVal("qrAlt",trunc2(qrAlt))
	--pVal("AltTg",trunc2(altTg))
	--pVal("dAlt",trunc2(dAlt))
  --pVal("sCompass", trunc2(sCompass))
  --pVal("yawRate", trunc2(yawRate))
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