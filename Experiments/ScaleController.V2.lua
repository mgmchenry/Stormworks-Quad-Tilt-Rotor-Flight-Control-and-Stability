local _i, _o, _s, _m = input, output, screen, math
local inN, outN, inB, dtb, tableUnpack =
  _i.getNumber, 
  _o.setNumber, 
  _i.getBool,
  _s.drawTextBox,
  table.unpack

local abs, sin, cos, mathmax, pi, pi2 =
  _m.abs, _m.sin, _m.cos, _m.max,
  _m.pi
pi2 = pi * 2

-- functions
local getN, clamp

getN = function(...)
    local r={}
    for i,v in ipairs({...}) do r[i]=inN(v) end
    return tableUnpack(r)
end
clamp = function(v,minVal,maxVal) 
	if v==nil then return nil end
	if v>maxVal then return maxVal end 
	if v<minVal then return minVal end 
	return v
end

bufferWidth = 5
bufferHead = bufferWidth+1
bufferDeltaPerSecond = 60 / bufferWidth

function shiftBuffer(buffer)
    for bufferIndex=1, bufferWidth do
      -- Shift values forward in buffer or initialize to zero if nil
      buffer[bufferIndex] = buffer[bufferIndex+1] or 0
    end
    buffer[bufferHead]=0
end

local buffers, bfTilt, bfDis, bfTiltRate, bfDis2
  ={},1,2,3,4,5,6
bufferList = {bfTilt, bfDis, bfTiltRate, bfDis2}
for i,v in pairs(bufferList) do
  buffers[v]={}
end
bfZeroVel={}
shiftBuffer(bfZeroVel)

local resX, resY, touch1X, touch1Y, touch2X, touch2Y, pressed1, pressed2,
inRps, inPitch, inDis, inTilt, inSpeed,
outPitch, outTrack,
inDis2

local tDis, tDis2, tiltRate, tiltAcc, disRate, tiltDir
tDis = 0
tDis2 = 0
local mode, curMode, prevMode = "?", "?", "?"

function getWeight(disB, disT) 
  return 1
end

function onTick()
  resX, resY, touch1X, touch1Y, touch2X, touch2Y = getN(1,2,3,4,5,6)
  pressed1, pressed2 = inB(1), inB(2)
  inRps, inPitch, inDis, inTilt, inSpeed, inDis2 = getN(7,8,9,10,11,12)

  inTilt = inTilt * 360
  outPitch = inPitch
  outTrack = 0
  outTrack2 = 0
  
  for i,v in pairs(bufferList) do
    shiftBuffer(buffers[v])
  end
  buffers[bfTilt][bufferHead] = inTilt
  tiltRate = (buffers[bfTilt][1] - inTilt) * bufferDeltaPerSecond

  buffers[bfTiltRate][bufferHead] = tiltRate
  tiltAcc = (buffers[bfTiltRate][1] - tiltRate) * bufferDeltaPerSecond

  buffers[bfDis][bufferHead] = inDis  
  disRate = (inDis - buffers[bfDis][1]) * bufferDeltaPerSecond
  buffers[bfDis2][bufferHead] = inDis2 
  disRate2 = (inDis2 - buffers[bfDis2][1]) * bufferDeltaPerSecond

  --[[
    Tilt faces right, so +tilt = right side up
    Track + faces right, so track target distance - inTilt * something will correct
    Tilt rate > 0 means right side going up
    Tilt Acc > 0 means moving toward right side going up
  ]]
  if tiltDir==nil then
    if tiltRate > 0 then
      tiltDir=1
    elseif tiltRate < 0 then
      tiltDir=-1
    end
  else
    if tiltRate*tiltDir < 0 then
      shiftBuffer(bfZeroVel)
      bfZeroVel[bufferHead] = inDis
      tiltDir = tiltDir*-1
    end
  end

  tiltSide = 1
  if inTilt < 0 then tiltSide = -1 end
  
  boost = (0.5 + abs(inTilt))
    * (1 + abs(tiltRate))
  if abs(inTilt) > 8 and abs(tiltAcc) < 0.5 
    and tiltRate * tiltSide < 0.25
    then
    tDis = tDis + (inTilt * 0.025)
    mode="Out of Bounds"
  --elseif abs(tDis - inDis) > 0.15 then
--    tDis = tDis
    --mode="catching up"
    if abs(tDis2 - inDis2) < 0.25 
    and abs(tiltRate) < 0.5 
    and abs(inTilt) > 8 then
      if tDis > 10 then
        tDis2 = tDis2 + 2.5
        tDis = 0
      elseif tDis < -10 then
        tDis2 = tDis2 - 2.5
        tDis = 0
      end
    end
  else
    mode="adjusting"
    tRate = clamp(-inTilt - tiltRate * 0.05,
      -1, 1)
    tAcc = clamp(tRate - tiltRate - tiltAcc * 0.05,
      -0.5, 0.5)
    accError = clamp(tAcc - tiltAcc,
      -2, 2)
    --tDis = tDis - accError * 0.01 * boost * 0.05
    if tiltRate * tiltSide > 0 then
      -- going wrong direction
      if -tiltAcc * tiltSide > 0.25 then
        -- starting to turn around
        tAcc = 0
        mode=mode..":slowing"
      else
        tAcc = ((tiltRate+tiltSide) * (tiltRate+tiltSide)-tiltSide) * 0.01
        tDis = tDis + tAcc
        mode=mode..":reversing"
      end
    else
      -- going right direction - keep it slow
      if abs(tiltRate) > 0.5 then
        -- too fast. Try to slow
        tAcc = (abs(tiltRate)+1) * tiltRate * 0.01
        tDis = tDis + tAcc
        mode = mode..":braking"
      else
        -- keep acceleration down
        mode = mode..":dampening"
        if tiltAcc > 0 then
          tAcc = ((tiltAcc+1)*(tiltAcc+1)-1)
        else
          tAcc = ((tiltAcc-1)*(tiltAcc-1)-1)
        end
        tAcc = tAcc /60
        tDis = tDis + tAcc
      end
    end
  
    --tDis = tDis + (inTilt * 0.0005)
    --mode="centering"
  end
  tDis = clamp(tDis,inDis-0.3,inDis+0.3)
  tDis = clamp(tDis,-10.5,10.5)

  tDis2 = clamp(tDis2,-17.5,17.5)

  outTrack = (tDis - inDis
    -- Predict ahead a little bit
    -- - disRate * 0.25
    )
    -- This will help it push a little harder when it's far from center:
    --* boost

  outTrack2 = (tDis2 - inDis2
    -- Predict ahead a little bit
    - disRate2 * 0.25)

  if mode~=curMode then
    prevMode = curMode
    curMode = mode
  end

	outN(1, outPitch)
	outN(2, outTrack)
	outN(3, tDis)
	outN(4, outTrack2)
end


function trunc(n) if n==nil then return "nil" end return string.format("%.f", n) end
function trunc2(n) if n==nil then return "nil" end return string.format("%.2f", n) end
function trunc4(n) if n==nil then return "nil" end return string.format("%.4f", n) end

function onDraw()
	w = _s.getWidth()
	h = _s.getHeight()					
  
	_s.setColor(255, 0, 0)
	tw=5*10
	--tx=w-tw*2-5
	tx=20
	ty=5
	local function pVal(l,v)
		if ty+10>h then
			ty=5
			tx=tx+tw*2.5
		end
		dtb(tx, ty, tw, 6, l, 1, 0)
		dtb(tx+tw+4, ty, tw*2, 6, v, -1, 0)
		ty=ty+6
	end
  pVal("Distance",trunc2(inDis))
  pVal("tDist",trunc2(tDis))
  --pVal("disrate",trunc2(disRate))
  --pVal("track",trunc2(outTrack))
  pVal("Tilt",trunc4(inTilt))
  pVal("TiltRate",trunc4(tiltRate))
  pVal("TiltAcc",trunc4(tiltAcc))
  pVal("tRate",trunc4(tRate))
  pVal("tAcc",trunc4(tAcc))
  pVal("accError",trunc2(accError))
  pVal("Mode:", mode)
  --pVal("Prev Mode:", prevMode)

  local avg=0
  for i=bufferHead,1,-1 do
    avg=avg+bfZeroVel[i]/bufferHead
    if i < 5 then
      pVal("Dis"..i, trunc4(bfZeroVel[i]))
    end
  end
  pVal("Avg",trunc4(avg))
end