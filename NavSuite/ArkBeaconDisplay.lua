-- Stormworks Ark NavSuite Emergency Beacon Dislay
-- V 01.03a Michael McHenry 2020-11-10
-- Minifies to 2452 ArkNavB01x02a
--             2912 ArkNavB01x04d
--             3310 ArkNavB01x05a
--             3646 ArkNavB01x06a
--             3703 ArkNavB01x06d
--             4139 ArkNavB01x06e (4094 without source id)
source={"ArkNavB01x07a","repl.it/@mgmchenry"}

local G, prop_getText, gmatch, unpack
  , ipairz
  , commaDelimited
  , empty, nilzies
  -- nilzies not assigned by design - it's just nil but minimizes to one letter

	= _ENV, property.getText, string.gmatch, table.unpack
  , ipairs
  , '([^,\r\n]+)'
  , false

local getTableValues--, stringUnpack 
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
--[[, -- stringUnpack
function(text, local_returnVals)
  local_returnVals = {}
  --__debug.AlertIf({"stringUnpack text:", text})
  for v in gmatch(text, commaDelimited) do
    --__debug.AlertIf({"stringUnpack value: ("..v..")"})
    local_returnVals[#local_returnVals+1]=v
  end
  return unpack(local_returnVals)
end
--]]

local tableType
  , abs, min, max, sqrt
  , ceil, floor
  , sin, cos, atan, pi

  = "table"
  , getTableValues(math,gmatch(
    prop_getText("ArkMF0")
    --"abs,min,max,sqrt,ceil,floor,sin,cos,atan,pi"
    , commaDelimited))
  
local C, drawLine, drawCircle, drawCircleF
  , dRF, dTF, dTx, dTxB
  , getWidth, getHeight
  
  = getTableValues(screen,gmatch(
    prop_getText("ArkSF0")
    --"setColor,drawLine,drawCircle,drawCircleF,drawRectF,drawTriangleF,drawText,drawTextBox,getWidth,getHeight"
    , commaDelimited))


local screenToMap, mapToScreen
  , getNumber, getBool
  , setNumber, setBool
  , format, type

  , clamp, inject

  = getTableValues(G,gmatch(
    prop_getText("ArkGF0")
    --"map.screenToMap,map.mapToScreen,input.getNumber,input.getBool,output.setNumber,output.setBool,string.format,type"
    , commaDelimited))
   

function clamp(a,b,c) return min(max(a,b),c) end
function inject(destination, ...)
  destination = destination or {}
  for i, stuffing in ipairz({...}) do
    stuffing = type(stuffing)==tableType and stuffing or {stuffing}
    for i2=1,#stuffing do
      destination[#destination+1] = stuffing[i2]
    end
  end
  return destination
end

local I, O, Ib, Ob -- input/output tables
  , mapX, mapY, mapZoom

  = {},{},{},{}
  , 0, 0, 1

local beaconPings, lastPingIndex, maxPings, hotSpots
  , strongBois, buoyData
  , detectors
  , extraPingIndex, extraPingMax
  , hotSpotMaxScore
  , beaconPulse, lastBeaconDistance, beaconQuietCounter, lastBeaconTicks
  , lastGroundDistance

  , getDistance2d, getDistance3d
  , reverseSortTableOnElement
  , getCircleIntersections, addBeaconPing, adjustHotspots

  = {}, 0, 10, {}
  , {}, {}
  -- detectors[] layout
  -- {inputChannel, pulseOn}
  , {{26},{27}}
  , 0, 5
  , 1
  , false, 0, 0, 0
  , 0

function getDistance2d(p1, p2)
  return sqrt((p1[1]-p2[1])^2 + (p1[2]-p2[2])^2)
end
function getDistance3d(p1, p2)
  return sqrt((p1[1]-p2[1])^2 + (p1[2]-p2[2])^2 + (p1[3]-p2[3])^2)
end
function reverseSortTableOnElement(someTable, elementIndex)
  table.sort(someTable, function (s1, s2) 
    return (s1[elementIndex] or 0) > (s2[elementIndex] or 0) end) -- > reverse sort, largest first
end

function getCircleIntersections(x1,y1,r1,x2,y2,r2)
  -- or ({x1,y1,r1},{x2,y2,r2})
  if type(x1)==tableType then
    x2, y2, r2 = unpack(y1)
    x1, y1, r1 = unpack(x1)
  end

  local distance
    , returnSpots
    , aSide, bSide, oSide, aX, aY, oX, oY
    --= sqrt((x1-x2)^2 + (y1-y2)^2)
    = getDistance2d({x1,y1},{x2,y2})

  if distance>r1+r2 -- they are too far apart
    or distance<abs(r1-r2) -- one is inside the other
    then return end -- no intersections for you

  -- distance from xy1 to xy2 = aSide+bSide. 
  -- aSide is distance from xy1 to intersection line. 
  -- b is distance from xy2 to intersection line
  -- from xy1, h = hypotenuse = r1
  -- aSide is adjacent side of right triangle
  -- oSide is opposite side or right triangle. Intersections are at +/- o
  aSide = (r1^2 - r2^2 + distance^2) / distance / 2
  oSide = sqrt(r1^2 - aSide^2)
  aX = x1 + (x2-x1) * aSide / distance
  aY = y1 + (y2-y1) * aSide / distance

  oX = ( y1 - y2 ) * oSide / distance
  oY = ( x2 - x1 ) * oSide / distance

  -- calculated intersection points:
  returnSpots = {{aX+oX,aY+oY}, {aX-oX,aY-oY}}

  if abs(abs(r1+r2) - distance) < 150 then
    -- this creates a huge smear effect where a smaller circle 
    -- is touching the edge of the larger circle it is inside
    -- adding double spots for the center which is more likely correct
    inject(returnSpots, {{aX,aY}, {aX,aY}})
  end

  return returnSpots
end

adjustHotspots = function(gpsX, gpsY, beaconRange, specificSpots, ageRate)
  hotSpotMaxScore = 1

  if specificSpots then
    -- adjusting a subset of spots
    ageRate = ageRate or 0
  else    
    specificSpots = hotSpots
    ageRate = ageRate or 1
  end

  for i, hotSpot in ipairz(specificSpots) do
    local x1, y1, score, age, valueWeight, x2, y2
      , newScore, errorRange, hsDistance
      = unpack(hotSpot)

    score, age, valueWeight
      = score or 2 -- default score
      , (age or 0) + ageRate -- increase age
      , valueWeight or 2

    errorRange = 200
    hsDistance = getDistance2d({gpsX, gpsY},hotSpot)
    newScore = -- maxes if beacon range is within 200m, falls off from there
      errorRange /
      (max(errorRange, abs(beaconRange - hsDistance)))

    if newScore > 0.5 then
      valueWeight = valueWeight + newScore
      x2 = gpsX + (hotSpot[1] - gpsX) / hsDistance * beaconRange
      y2 = gpsY + (hotSpot[2] - gpsY) / hsDistance * beaconRange

      x1, y1
        = x1 + (x2-x1) * newScore / valueWeight
        , y1 + (y2-y1) * newScore / valueWeight

      hotSpot[1], hotSpot[2], hotSpot[5]
        = x1, y1, valueWeight
    end
      
    score = score + newScore - 0.5
    hotSpot[3], hotSpot[4] 
      = score
      , age

    hotSpotMaxScore = max(score, hotSpotMaxScore)
  end

  if hotSpots~=specificSpots then return end

  for i, hotSpot, otherSpot, valueWeight in ipairz(specificSpots) do
    for i2=i+1, #specificSpots do
      otherSpot = specificSpots[i2]
      if getDistance2d(hotSpot, otherSpot) < 100 then
        -- x1, y1, score, age, weight = unpack(hotSpot)
        valueWeight = hotSpot[5] + otherSpot[5]
        hotSpot[1] = (hotSpot[1] + (otherSpot[1] - hotSpot[1]) * otherSpot[5]) / valueWeight
        hotSpot[2] = (hotSpot[2] + (otherSpot[2] - hotSpot[2]) * otherSpot[5]) / valueWeight
        hotSpot[5] = valueWeight
        hotSpot[3] = hotSpot[3] + otherSpot[3]
        hotSpot[4] = 0 -- reset age so it sticks around
        otherSpot[4] = 100 -- reset age so it sticks around
        otherSpot[5] = 0
        otherSpot[3] = 0
      end
    end
  end
end

addBeaconPing = function(gpsX,gpsY,beaconRange)

  local newPing
    , oldPing
    , blobs, newSpots
    , oldHotSpotCount

    , nearBlob
    , x1, y1, r1, h1, h2
    , score, oldestAge, hotspotCutoff

    = {gpsX, gpsY, beaconRange}
    , beaconPings[lastPingIndex]
    , {}, {}
    , #hotSpots

  if oldPing then
    if getDistance2d(newPing,oldPing)<200 
    -- if stationary but beacon distance changes dramatically:
    or abs(beaconRange-oldPing[3])>400 then 
      adjustHotspots(gpsX, gpsY, beaconRange)
      return
    end
  end

  -- let's keep some older pings around as "extra pings"
  if lastPingIndex==maxPings then
    extraPingIndex = (extraPingIndex % extraPingMax) + 1
    beaconPings[maxPings+extraPingIndex] = beaconPings[lastPingIndex]
  end

  lastPingIndex = (lastPingIndex % maxPings) + 1
  beaconPings[lastPingIndex] = newPing

  hotSpotMaxScore = 1
  
  for i, otherPing in ipairz(beaconPings) do
    -- skip over the current ping, compare to all the rest
    if i~=lastPingIndex then
      inject(newSpots, getCircleIntersections(newPing, otherPing))
    end
  end
  
  inject(hotSpots, newSpots)
  
  for i, otherPing in ipairz(beaconPings) do
    -- skip over the current ping, compare to all the rest
    if i~=lastPingIndex then
      adjustHotspots(otherPing[1], otherPing[2], otherPing[3], newSpots)
    end
  end
  
  adjustHotspots(gpsX, gpsY, beaconRange)
  reverseSortTableOnElement(hotSpots,4) -- > reverse sort on age, oldest first

  --oldestAge = hotSpots[1][4]
  hotspotCutoff = 1
  while hotSpots[hotspotCutoff] 
    and #hotSpots > 20
    and hotSpots[hotspotCutoff][4] > 15 
    --and hotSpot[hotspotCutoff][4] = oldestAge
    do hotspotCutoff = hotspotCutoff + 1
  end
  hotSpots = {unpack(hotSpots, hotspotCutoff)}


  reverseSortTableOnElement(hotSpots,3) -- > reverse sort on score, largest first

  --[[
  while #hotSpots > 30 do
    hotSpots[#hotSpots]=nil
  end
  --]]

  --[[
  for i, hotSpot in ipairz(hotSpots) do
    if hotSpot[3]*2>hotSpotMaxScore then
      nearBlob={100000,0,0,0,0,200,1}
      for i, blob in ipairz(blobs)  do
        -- find the blob closest to this hotspot
        blob[6] = getDistance2d(hotSpot,blob)
        if blob[6]<nearBlob[6] then
          nearBlob=blob
        end
      end
      if nearBlob[3]==0 then 
        blobs[#blobs+1] = nearBlob
      end
      -- add weighted score and location to blob
      nearBlob[3]=nearBlob[3]+hotSpot[3]
      nearBlob[4]=nearBlob[4]+hotSpot[1]*hotSpot[3]
      nearBlob[5]=nearBlob[5]+hotSpot[2]*hotSpot[3]
      -- find new blob center
      nearBlob[1]=nearBlob[4]/nearBlob[3]
      nearBlob[2]=nearBlob[5]/nearBlob[3]
      nearBlob[8]=nearBlob[3] -- need a second copy of score for aging
    end
  end
  --]]

  for i, boi in ipairz(strongBois) do
    -- add to boi age
    boi[7] = boi[7] + 1
    -- reduce score with age
    boi[3] = boi[8] * (0.9 ^ (boi[7]-3))
  end

  reverseSortTableOnElement(blobs,3)
  reverseSortTableOnElement(strongBois,3)
  while #strongBois > 8 do strongBois[#strongBois]=nil end
  for i=1,3 do
    strongBois[#strongBois+1]=blobs[i]
  end
end

--[[
function beaconDistance(ticksElapsed)
  return ticksElapsed * 50 - 200
end
--]]

--[[
based function by illy:
  meters = ticks * 50 - 200
confirmed by adata from woeken_up:

minTicks	maxTicks	Meters	min*50-200	max*50-200	avg illy method
9	9	100	250	250	250
9	9	200	250	250	250
9	10	250	250	300	275
9	11	300	250	350	300
11	14	400	350	500	425
13	16	500	450	600	525
22	26	1000	900	1100	1000
42	46	2000	1900	2100	2000
60	68	3000	2800	3200	3000
79	90	4000	3750	4300	4025
100	108	5000	4800	5200	5000
200	209	10000	9800	10250	10025
--]]

--[[
addBeaconPing(100,100,3000)
addBeaconPing(0,3000,2300)
addBeaconPing(3000,0,2300)
addBeaconPing(200,200,2900)
addBeaconPing(200,200,29000)
--]]

function onTick()  
  for i=1,32 do
    I[i]=getNumber(i)
    O[i]=I[i]
    Ib[i]=getBool(i)
    Ob[i]=Ib[i]
  end


	--W,H,tx,ty,tx2,ty2 -- 1-6
  --  , _, _, _, _ -- 7-10 pilot input axes
    gx,gy,alt,dir,_ -- 11-14, 15=forwardSpeed
    , _, _ -- 16,17
    , mapX, mapY, mapZoom -- 18-20
    , _, _, _, _, _ -- 21-25
    , _ -- 26
    --, buoyData[1], buoyData[2], buoyData[3] -- 27 - 29
    = unpack(I, 11)

	if gx == nil then return true end
  
  --[[
  buoyData[4] = getDistance2d(buoyData, {gx, gy})
  buoyData[5] = getDistance3d(buoyData, {gx, gy, alt})
  --]]

  
  -- detectors[] layout
  -- {inputChannel, pulseOn, quietCounter, lastTickCount, lastDistance}
  -- detectors at init:
  -- , {{26},{27}}

	beaconPulse = Ib[26]
  -- actually, let's have lots of beacon detectors:

  for i, detector in ipairz(detectors) do
    local channel, pulseOn, quietCounter, pingTickCount, pingDistance
      = unpack(detector)
    pulseOn = Ib[channel]
    quietCounter = quietCounter or 0
    detector[2] = pulseOn
    if pulseOn then
      if quietCounter>0 then
        pingDistance = quietCounter * 50 - 200
        pingTickCount = quietCounter
        
        lastBeaconDistance = pingDistance
        lastBeaconTicks = pingTickCount
        lastGroundDistance = sqrt(lastBeaconDistance^2 - alt^2)

        detector[4], detector[5]
          = pingTickCount, pingDistance

        if lastBeaconDistance > 300 then
          --addBeaconPing(gx, gy, lastBeaconDistance)
          addBeaconPing(gx, gy, lastGroundDistance)
        end
        quietCounter = 0
      end
    else
      quietCounter = quietCounter + 1
    end
    detector[3] = quietCounter
  end
	
  -- already done:
  --Ob[26] = beaconPulse
  O[26] = lastBeaconDistance
  
  for i=1,32 do
    setNumber(i, O[i])
    setBool(i, Ob[i])
  end
end


function onDraw()
	if gx==nil then return true end
	w=getWidth()
	h=getHeight()
	cx=w/2
	cy=h/2

  mx,my,zo=mapX,mapY,mapZoom
  
  local meterPixels = (mapToScreen(0, 0, zo, w, h, 1000, 0) - w/2) / 1000

  --[ [
  local betterCircle = function(x,y,r,steps)
    --drawCircle(x,y+5,r)
    steps = min(2000, floor(steps or (r*2)))
    --print(" ** Circle steps: ", steps)
    if x+r<0 or x-r>w
      or y+r<0 or y-r>h then 
      --print(" ** Aborting circle. x, y, r, steps", x, y, r, steps)
      return 
    end

    local x1, y1
      , x2, y2, aRadians
      = x, y-r
    for i=1, steps do
      aRadians = i/steps * pi * 2
      x2, y2 = x + sin(aRadians) * r
        , y - cos(aRadians) * r

      --No visual improvement from aligning the circle points to 
      --drawLine(floor(x1)-5,floor(y1),floor(x2)-5,floor(y2))
      --drawLine(floor(x1)+0.5,floor(y1)-4.5,floor(x2)+0.5,floor(y2)-4.5)
      drawLine(x1,y1,x2,y2)
      x1, y1 = x2, y2 -- because I'm not *stupid*
    end
  end

--] ]

  --[[
  C(200,200,0,200)
    dRF(15,h-15,w-15,16)
    dTxB(20,h-19,w-20,20,format("wtf %.2f scale:%.1f",meterPixels,zo),-1,1)
  --]]
  --[[
  if inputX and inputY then
    C(200,0,0)
    bx,by = mapToScreen(mx,my,zo,w,h,inputX,inputY)
    br = 5
    drawCircle(bx,by,br)
    drawCircle(bx,by,beaconRadius*meterPixels)
  end
  --]]

  for bi = 1, #beaconPings do

    local freshness
      , pingX, pingY, pingR
      = (5 - (lastPingIndex - bi) % maxPings) / 6
      , unpack(beaconPings[bi])

    C(200,0,0,max(freshness,0)^2 * 150)
    pingX, pingY = mapToScreen(mx,my,zo,w,h,pingX,pingY)
    --drawCircle(pingX,pingY,3)
    --drawCircle(pingX,pingY,pingR*meterPixels)
    betterCircle(pingX,pingY,3)
    betterCircle(pingX,pingY,pingR*meterPixels)
  end

  for bi = 1, #hotSpots do
    local pingX, pingY, score = unpack(hotSpots[bi])
    score = (score/hotSpotMaxScore)^2
    C(200,200,0,50 * score)
    pingX, pingY = mapToScreen(mx,my,zo,w,h,pingX,pingY)
    drawCircleF(pingX,pingY, 8 * score - 2)
  end

  for bi = 1, #strongBois do
    local pingX, pingY, score = unpack(strongBois[bi])
    C(0,255,0,255)
    pingX, pingY = mapToScreen(mx,my,zo,w,h,pingX,pingY)
    drawCircle(pingX,pingY, 3)
    C(255,0,0,255)
		drawLine(pingX-2,pingY,pingX+2,pingY)
    drawLine(pingX,pingY-2,pingX,pingY+2)
    if mapZoom<4 and w > 16 then
      C(0,0,0,150)
      dTx(pingX + 3, pingY, format("%.0f", score))
    end
  end
  

  text = format("beacon range: %.0f ticks: %i\nground distance: %.0f"
    , lastBeaconDistance, lastBeaconTicks
    , lastGroundDistance )
  
  --[[
  if buoyData[1]~=0 or buoyData[2]~=0 then
    text = text .. format("\nbuoy dist2d: %.0f\nbuoy dist3d: %.0f\nbuoy x/y/z: %.0f %.0f %.0f"
    , buoyData[4], buoyData[5]
    , buoyData[1], buoyData[2], buoyData[3])
  end
  --]]
  C(200,200,200,200)
  dTx(96,20,text)
end


