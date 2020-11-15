-- Stormworks Ark NavSuite Emergency Beacon Dislay
-- V 01.03a Michael McHenry 2020-11-10
-- Minifies to 2452 ArkNavB01x02a
--             2912 ArkNavB01x04d
--             3310 ArkNavB01x05a
--             3646 ArkNavB01x06a
--             3703 ArkNavB01x06d
source={"ArkNavB01x06e","repl.it/@mgmchenry"}

local G, prop_getText, gmatch, unpack
  , commaDelimited
  , empty, nilzies
  -- nilzies not assigned by design - it's just nil but minimizes to one letter

	= _ENV, property.getText, string.gmatch, table.unpack
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

local abs, min, max, sqrt
  , ceil, floor
  , sin, cos, atan, pi
  = getTableValues(math,gmatch(
    "abs,min,max,sqrt,ceil,floor,sin,cos,atan,pi"
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
  , format

  , clamp

  = getTableValues(G,gmatch(
    prop_getText("ArkGF0")
    --"map.screenToMap,map.mapToScreen,input.getNumber,input.getBool,output.setNumber,output.setBool,string.format"
    , commaDelimited))
   

function clamp(a,b,c) return min(max(a,b),c) end

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
  , getCircleIntersections, addBeaconPing

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
    return s1[elementIndex] > s2[elementIndex] end) -- > reverse sort, largest first
end

function getCircleIntersections(x1,y1,r1,x2,y2,r2)
  local distance
    , aSide, bSide, oSide, aX, aY, oX, oY, p1, p2
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

  if abs(abs(r1-r2) - distance) < 400 then
    -- this creates a huge smear effect where a smaller circle 
    -- is touching the edge of the larger circle it is inside
    p1 = {aX,aY}
    p2 = {aX,aY}
  else
    p1, p2 = {aX+oX,aY+oY}, {aX-oX,aY-oY}
  end

  return p1, p2
end

addBeaconPing = function(gpsX,gpsY,distance)

  local newPing, oldPing, blobs, nearBlob
    , pingDistance
    , x1, y1, r1, h1, h2
    , score, hsDistance
    = {gpsX, gpsY, distance}
    , beaconPings[lastPingIndex]
    , {}

  if oldPing then
    pingDistance 
      = getDistance2d(newPing,oldPing)
      -- = sqrt((newPing[1]-oldPing[1])^2 + (newPing[2]-oldPing[2])^2)
    if pingDistance<200 then return end
  end

  -- let's keep some older pings around as "extra pings"
  if lastPingIndex==maxPings then
    extraPingIndex = (extraPingIndex % extraPingMax) + 1
    beaconPings[maxPings+extraPingIndex] = beaconPings[lastPingIndex]
  end

  lastPingIndex = (lastPingIndex % maxPings) + 1
  beaconPings[lastPingIndex] = newPing

  hotSpots, hotSpotMaxScore = {}, 1
  for b1 = 1, #beaconPings do
    x1, y1, r1
      = unpack(beaconPings[b1])
    for b2 = b1+1, #beaconPings do
      --local x2, y2, r2 = unpack(beaconPings[b2])
      h1, h2 = getCircleIntersections(x1, y1, r1, unpack(beaconPings[b2]))      
      
      -- if h1 is nil, the array length doesn't increase anyway
      hotSpots[#hotSpots+1] = h1
      hotSpots[#hotSpots+1] = h2
    end
  end
  for i, hotSpot in ipairs(hotSpots) do
    score = -2 
    -- Every hotspot should have 2 pings it matches perfectly
    -- which will raise the score to 0
    for i2, ping in ipairs(beaconPings) do
      hsDistance = ping[3] - getDistance2d(ping,hotSpot)
      --sqrt(
      --  (ping[1]-hotSpot[1])^2 
      --  + (ping[2]-hotSpot[2])^2)
      --score = score + max(0, 1 - abs(hsDistance/200))^3
      hsDistance = max(100, abs(hsDistance))
      score = score + 100/hsDistance
    end
    hotSpot[3] = score --^2
    hotSpotMaxScore = max(score, hotSpotMaxScore)
  end
  reverseSortTableOnElement(hotSpots,3) -- > reverse sort, largest first on score
  for i, hotSpot in ipairs(hotSpots) do
    if hotSpot[3]*2>hotSpotMaxScore then
      nearBlob={100000,0,0,0,0,200,1}
      for i, blob in ipairs(blobs)  do
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
  

  for i, boi in ipairs(strongBois) do
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

--[ [
addBeaconPing(100,100,3000)
addBeaconPing(0,3000,2300)
addBeaconPing(3000,0,2300)
addBeaconPing(200,200,2900)
addBeaconPing(200,200,29000)
--] ]

function onTick()  
  for i=1,32 do
    I[i]=getNumber(i)
    O[i]=I[i]
    Ib[i]=getBool(i)
    Ob[i]=Ib[i]
  end


	W,H,tx,ty,tx2,ty2 -- 1-6
    , _, _, _, _ -- 7-10 pilot input axes
    , gx,gy,alt,dir,_ -- 11-14, 15=forwardSpeed
    , inputX, inputY -- 16,17
    , mapX, mapY, mapZoom -- 18-20
    , _, _, _, _, _ -- 21-25
    , _ -- 26
    , buoyData[1], buoyData[2], buoyData[3] -- 27 - 29
    = unpack(I)

	if gx == nil then return true end
  
  buoyData[4] = getDistance2d(buoyData, {gx, gy})
  buoyData[5] = getDistance3d(buoyData, {gx, gy, alt})

  
  -- detectors[] layout
  -- {inputChannel, pulseOn}
  -- detectors at init:
  -- , {{26},{27}}

	beaconPulse = Ib[26]
	
  if beaconPulse then
    if beaconQuietCounter>0 then
      lastBeaconDistance = beaconQuietCounter * 50 - 200
      lastBeaconTicks = beaconQuietCounter

      lastGroundDistance = sqrt(lastBeaconDistance^2 - alt^2)

      if lastBeaconDistance > 300 then
        --addBeaconPing(gx, gy, lastBeaconDistance)
        addBeaconPing(gx, gy, lastGroundDistance)
      end
    end  
		beaconQuietCounter = 0     
  else
    beaconQuietCounter = beaconQuietCounter + 1
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
    drawCircle(x,y+5,r)
    --r = min(r,200)
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
    if mapZoom<4 then
      C(0,0,0,150)
      dTx(pingX + 3, pingY, format("%.0f", score))
    end
  end
  

  text = format("beacon range: %.0f ticks: %i\nground distance: %.0f"
    , lastBeaconDistance, lastBeaconTicks
    , lastGroundDistance )
  
  if buoyData[1]~=0 or buoyData[2]~=0 then
    text = text .. format("\nbuoy dist2d: %.0f\nbuoy dist3d: %.0f\nbuoy x/y/z: %.0f %.0f %.0f"
    , buoyData[4], buoyData[5]
    , buoyData[1], buoyData[2], buoyData[3])
  end
  C(200,200,200,200)
  dTx(96,20,text)
end


