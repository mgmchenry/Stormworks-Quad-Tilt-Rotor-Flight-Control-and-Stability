--[[
map.mapToScreen =
function(mapX, mapY, zoom, screenW, screenH, worldX, worldY)
  screenW = math.max(screenW, 1)
  screenH = math.max(screenH, 1)
  zoom = math.min(math.max(zoom, 0.1), 50) * 1000 / screenH * 2
  screenX, screenY = (worldX - mapX) / zoom + screenW / 2, screenH / 2 - (worldY - mapY) / zoom
  return screenX, screenY
end

map.screenToMap =
function(mapX, mapY, zoom, screenW, screenH, pixelX, pixelY) 

  screenW = math.max(screenW, 1)
  screenH = math.max(screenH, 1)
  zoom = math.min(math.max(zoom, 0.1), 50) * 1000 / screenH * 2
  worldX, worldY = (pixelX - screenW / 2) * zoom + mapX, (screenH / 2 - pixelY) * zoom + mapY
  return worldX, worldY
end
--]]

-- Stormworks Ark NavSuite Emergency Beacon Dislay
-- V 01.03a Michael McHenry 2020-11-10
-- Minifies to 2452 ArkNavB01x02a
source={"ArkNavB01x03a","repl.it/@mgmchenry"}

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

--[[
local Math, S, I, O
  --= math, screen
  = getTableValues(G,gmatch(
    "math,screen,input,output"
    , commaDelimited))
--]]

local abs, min, max, sqrt
  , ceil, floor
  , si, co, atan, pi
  = getTableValues(math,gmatch(
    "abs,min,max,sqrt,ceil,floor,sin,cos,atan,pi"
    , commaDelimited))
  
local C, dL, drawCircle, drawCircleF
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

  , clamp, getN, outN
  , dPoi

  = getTableValues(G,gmatch(
    prop_getText("ArkGF0")
    --"map.screenToMap,map.mapToScreen,input.getNumber,input.getBool,output.setNumber,output.setBool,string.format"
    , commaDelimited))
   


function clamp(a,b,c) return min(max(a,b),c) end
--function getN(...)local a={}for b,c in ipairs({...})do a[b]=getNumber(c)end;return unpack(a)end
--function outN(o, ...) for i,v in ipairs({...}) do setNumber(o+i-1,v) end end

local I, O, Ib, Ob -- input/output tables
  , zoom, tz, zooms
  , grids, grid
  , sis, SZ, wp, sel
  , wayInfo, selX, selY
  , triMarkerSize
  , mapX, mapY, mapZoom

  = {},{},{},{}
  , 1, 5*32*0.11, {0.3,2,5,10,30,50}
  , {10,100,500,1000,2500,5000}, 100
  , {5,4,3,2,1,1}, 4, {}, 0
  , {}, 0, 0
  , 15
  , 0, 0, 1


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

  local newPing, oldPing
    , pingDistance
    , x1, y1, r1, h1, h2
    , score, hsDistance
    = {gpsX, gpsY, distance}
    , beaconPings[lastPingIndex]

  if oldPing then
    pingDistance = sqrt((newPing[1]-oldPing[1])^2 + (newPing[2]-oldPing[2])^2)
    if pingDistance<400 then return end
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
    score = -2 -- Every hotspot should have 2 pings it matches perfectly
    for i2, ping in ipairs(beaconPings) do
      hsDistance = ping[3] - sqrt(
        (ping[1]-hotSpot[1])^2 
        + (ping[2]-hotSpot[2])^2)
      --score = score + max(0, 1 - abs(hsDistance/200))^3
      hsDistance = max(200, abs(hsDistance))
      score = score + 200/hsDistance
    end
    hotSpot[3] = score^2
    hotSpotMaxScore = max(score^2, hotSpotMaxScore)
  end
end

--[[
addBeaconPing(100,100,3000)
addBeaconPing(0,3000,2300)
addBeaconPing(3000,0,2300)
--]]


function dPoi(xx,yy,s,r,...) 
  local a,x,y=...,0,0 a=(a or 30)*pi/360;
  x=xx+s/2*si(r);
  y=yy-s/2*co(r);
  xx=xx-s/4*si(r);
  yy=yy+s/4*co(r);
  dTF(xx,yy,x,y,x-s*si(r+a),y+s*co(r+a))
  dTF(xx,yy,x,y,x-s*si(r-a),y+s*co(r-a)) 
end

function onTick()  
  for i=1,32 do
    I[i]=getNumber(i)
    O[i]=I[i]
    Ib[i]=getBool(i)
    Ob[i]=Ib[i]
  end


	W,H,tx,ty,tx2,ty2 -- 1-6
    , _, _, _, _ -- 7-10 pilot input axes
    , gx,gy,gz,dir,_ -- 11-14, 15=forwardSpeed
    , inputX, inputY -- 16,17
    , mapX, mapY, mapZoom -- 18-20
    , _, _, _, _, _ -- 21-25
    , debug_beaconRadius -- 26
    = unpack(I)

	if gx == nil then return true end
	if wx == nil then 
    if gx==0 then return true end 
    wx,wy,Fx,Fy,Fz = gx,gy,gx,gy,zoom 
  end
    
	beaconPulse = Ib[26]
	beaconQuietCounter = beaconQuietCounter + 1
  if beaconPulse and beaconPulse~=lastBeaconPulse then
		lastBeaconDistance = beaconQuietCounter * 45
		beaconQuietCounter = 0   

    --lastBeaconDistance = debug_beaconRadius
    if lastBeaconDistance > 460 then
      addBeaconPing(gx, gy, lastBeaconDistance)
    end
  end
  lastBeaconPulse = beaconPulse

  -- already done:
  --Ob[26] = beaconPulse
  O[26] = lastBeaconDistance
  
  for i=1,32 do
    setNumber(i, O[i])
    setBool(i, Ob[i])
  end
end


function onDraw()
	if wx==nil then return true end
	w=getWidth()
	h=getHeight()
	cx=w/2
	cy=h/2
	sz=SZ/H*h

  mx,my,zo=mapX,mapY,mapZoom
  
  meterPixels = (mapToScreen(0, 0, zo, w, h, 1000, 0) - w/2) / 1000

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
    drawCircle(pingX,pingY,3)
    drawCircle(pingX,pingY,pingR*meterPixels)
  end

  for bi = 1, #hotSpots do
    local pingX, pingY, score = unpack(hotSpots[bi])
    score = (score/hotSpotMaxScore)^2
    C(200,200,0,50 * score)
    pingX, pingY = mapToScreen(mx,my,zo,w,h,pingX,pingY)
    drawCircleF(pingX,pingY, 8 * score - 2)
  end

end


