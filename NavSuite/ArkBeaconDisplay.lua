
-- Stormworks Ark NavSuite Emergency Beacon Dislay
-- V 01.01a Michael McHenry 2020-11-10
source={"ArkEBD01x01a","repl.it/@mgmchenry"}

local G, prop_getText, gmatch, unpack
  , propPrefix
  , commaDelimited
  , empty, nilzies
  -- nilzies not assigned by design - it's just nil but minimizes to one letter

	= _ENV, property.getText, string.gmatch, table.unpack
  , "Ark"
  , '([^,\r\n]+)'
  , false

local getTableValues, stringUnpack 
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
, -- stringUnpack
function(text, local_returnVals)
  local_returnVals = {}
  --__debug.AlertIf({"stringUnpack text:", text})
  for v in gmatch(text, commaDelimited) do
    --__debug.AlertIf({"stringUnpack value: ("..v..")"})
    local_returnVals[#local_returnVals+1]=v
  end
  return unpack(local_returnVals)
end

local M, S, I, O
  --= math, screen
  = getTableValues(G,gmatch("math,screen,input,output", commaDelimited))

local abs, min, max, sqrt
  , si, co, pi
  = getTableValues(M,gmatch("abs,min,max,sqrt,sin,cos,pi", commaDelimited))
  
local C, dL, drawCircle, drawCircleF
  , dRF, dTF, dTx, dTxB
  
  = getTableValues(S,gmatch("setColor,drawLine,drawCircle,drawCircleF, drawRectF,drawTriangleF,drawText,drawTextBox", commaDelimited))


local screenToMap, mapToScreen
  , getBool
  , format

  , clamp, getN, outN
  = map.screenToMap, map.mapToScreen
  , I.getBool
  , string.format


function clamp(a,b,c) return M.min(M.max(a,b),c) end
function getN(...)local a={}for b,c in ipairs({...})do a[b]=I.getNumber(c)end;return unpack(a)end
function outN(o, ...) for i,v in ipairs({...}) do O.setNumber(o+i-1,v) end end



local beaconPings, lastPingIndex, maxPings, hotSpots
  , hotSpotMaxScore
  , beaconPulse, lastBeaconPulse, lastBeaconDistance, beaconQuietCounter

  , getCircleIntersections, addBeaconPing
  , debug_beaconRadius -- beaconRadius is just for debug purposes

  = {}, 0, 10, {}
  , 1
  , false, false, 0, 0


getCircleIntersections = function (x1,y1,r1,x2,y2,r2)
  local distance
    , aSide, oSide, aX, aY, oX, oY
    = sqrt((x1-x2)^2 + (y1-y2)^2)

  if distance>r1+r2 then return end

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

  return {aX+oX,aY+oY}, {aX-oX,aY-oY}
end

addBeaconPing = function(gpsX,gpsY,distance)
  lastPingIndex = (lastPingIndex % maxPings) + 1

  local newPing 
    , x1, y1, r1, h1, h2
    , score, hsDistance
    = {gpsX, gpsY, distance}
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
    score = 0
    for i2, ping in ipairs(beaconPings) do
      hsDistance = ping[3] - sqrt(
        (ping[1]-hotSpot[1])^2 
        + (ping[2]-hotSpot[2])^2)
      score = score + max(0, 1 - abs(hsDistance/200))^3
    end
    hotSpot[3] = score^2
    hotSpotMaxScore = max(score^2, hotSpotMaxScore)
  end
end

addBeaconPing(100,100,3000)
addBeaconPing(0,3000,2300)
addBeaconPing(3000,0,2300)

function onTick()  

	t2 = getBool(1) -- also getBool(2) for touch 2
	W,H,tx,ty,tx2,ty2
    , gx,gy,gz,dir,swp -- 11-15
    , inputX, inputY
    , debug_beaconRadius
     = getN(1,2,3,4,5,6,11,12,13,14,15,16,17,18)
	if gx == nil then return true end
	if wx == nil then 
    if gx==0 then return true end 
    wx,wy,Fx,Fy,Fz = gx,gy,gx,gy,zoom 
  end
  
	beaconPulse = getBool(10)
	beaconQuietCounter = beaconQuietCounter + 1
  if beaconPulse and beaconPulse~=lastBeaconPulse then
		lastBeaconDistance = beaconQuietCounter * 45
		beaconQuietCounter = 0   

    lastBeaconDistance = debug_beaconRadius
    addBeaconPing(inputX, inputY, lastBeaconDistance)
  end
  lastBeaconPulse = beaconPulse
	O.setBool(20,beaconPulse)
	O.setNumber(20,lastBeaconDistance)
end


function onDraw()
	if wx==nil then return true end
	w=S.getWidth()
	h=S.getHeight()
	cx=w/2
	cy=h/2
	sz=SZ/H*h
	if w==W then
    mx,my,zo=wx,wy,zoom 
  else 
    -- current location
    mx,my,zo=gx,gy,zoom 
  end
	
	S.setMapColorOcean(10,10,15)
	S.setMapColorShallows(15,15,20)
	S.setMapColorLand(60,60,60)
	S.setMapColorGrass(40,60,40)
	S.setMapColorSand(55,55,50)
	S.setMapColorSnow(80,80,80)
    S.drawMap(mx,my,zo)
	x1,y1 = screenToMap(mx,my, zo, w,h, 0,h)
	x2,y2 = screenToMap(mx,my, zo, w,h, w,0)
	x1 = M.floor(x1/grid)*grid
	y1 = M.floor(y1/grid)*grid
  
  meterPixels = (mapToScreen(0, 0, zo, w, h, 1000, 0) - w/2) / 1000

  if inputX and inputY then
    C(200,0,0)
    bx,by = mapToScreen(mx,my,zo,w,h,inputX,inputY)
    br = 5
    drawCircle(bx,by,br)
    drawCircle(bx,by,beaconRadius*meterPixels)
  end

  for bi = 1, #beaconPings do

    local freshness
      , pingX, pingY, pingR
      = (5 - (lastPingIndex - bi) % maxPings) / 6
      , unpack(beaconPings[bi])

    C(200,0,0,max(freshness,0)^2 * 200)
    pingX, pingY = mapToScreen(mx,my,zo,w,h,pingX,pingY)
    drawCircle(pingX,pingY,3)
    drawCircle(pingX,pingY,pingR*meterPixels)
  end

  for bi = 1, #hotSpots do
    local pingX, pingY, score = unpack(hotSpots[bi])
    score = (score/hotSpotMaxScore)^2
    C(200,200,0,100 * score)
    pingX, pingY = mapToScreen(mx,my,zo,w,h,pingX,pingY)
    drawCircleF(pingX,pingY, 8 * score - 2)
  end