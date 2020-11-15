local beaconTest

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

-- Stormworks Ark NavSuite MapUI Controller
-- V 01.03a Michael McHenry 2020-11-10
-- Minifies to 3,793 ArkNav01x02a
-- Pony IDE testSim https://lua.flaffipony.rocks/?id=_uM_iSyvu
-- Adapted from Tajin's excellent navigation map to allow additional overlays
-- and to be usable on 2x2 monitors
source={"ArkNav01x03a","repl.it/@mgmchenry"}

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
  , sin, co, atan, pi
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

-- screen/map functions as they should be:
-- identical to and compatible with Stormworks implementation in game
--[[
screenToMap =
function(mapX, mapY, zoom, screenW, screenH, pixelX, pixelY) 
  screenW = max(screenW, 1)
  screenH = max(screenH, 1)
  zoom = min(max(zoom, 0.1), 50) * 1000 / screenW -- screenH * 2
  worldX, worldY = (pixelX - screenW / 2) * zoom + mapX, (screenH / 2 - pixelY) * zoom + mapY
  return worldX, worldY
end

mapToScreen =
function(mapX, mapY, zoom, screenW, screenH, worldX, worldY)
  screenW = max(screenW, 1)
  screenH = max(screenH, 1)
  zoom = min(max(zoom, 0.1), 50) * 1000 / screenW -- screenH * 2
  screenX, screenY = (worldX - mapX) / zoom + screenW / 2, screenH / 2 - (worldY - mapY) / zoom
  return screenX, screenY
end
--]]

--[[
-- screen map functions that tracked with the old Pony IDE displayed map
screenToMap =
function(mapX, mapY, zoom, screenW, screenH, pixelX, pixelY) 
  screenW = max(screenW, 1)
  screenH = max(screenH, 1)
  zoom = min(max(zoom, 0.1), 50) * 1000 / screenH * 2
  worldX, worldY = (pixelX - screenW / 2) * zoom + mapX, (screenH / 2 - pixelY) * zoom + mapY
  return worldX, worldY
end

mapToScreen =
function(mapX, mapY, zoom, screenW, screenH, worldX, worldY)
  screenW = max(screenW, 1)
  screenH = max(screenH, 1)
  zoom = min(max(zoom, 0.1), 50) * 1000 / screenH * 2
  screenX, screenY = (worldX - mapX) / zoom + screenW / 2, screenH / 2 - (worldY - mapY) / zoom
  return screenX, screenY
end
--]]

function clamp(a,b,c) return min(max(a,b),c) end
--function getN(...)local a={}for b,c in ipairs({...})do a[b]=getNumber(c)end;return unpack(a)end
--function outN(o, ...) for i,v in ipairs({...}) do setNumber(o+i-1,v) end end

local I, O, Ib, Ob -- input/output tables
  , zoom, tz, zooms
  , grids, grid
  , sis, SZ, wp, sel
  , wayInfo, selX, selY
  , triMarkerSize
  , homeButtonHeight, centerOnGPS
  , lastTouchTick
  , lastInputX, lastInputY
  , inputX, inputY
  , outDis, outCourse


  = {},{},{},{}
  , 1, 5*32*0.11, {0.3,2,5,10,30,50}
  , {10,100,500,1000,2500,5000}, 100
  , {5,4,3,2,1,1}, 4, {}, 0
  , {}, 0, 0
  , 15
  , 7, true
  , 0 -- lastTouchTick
  , 0, 0
  , 0, 0

--[[
zoom = 1
tz = 5*32*0.11
zooms = {0.3,2,5,10,30,50}
grids = {10,100,500,1000,2500,5000}
grid = 100
sis = {5,4,3,2,1,1}
SZ = 4
wp = {}
sel = 0
--]]

function dPoi(xx,yy,s,r,...) 
  local a,x,y=...,0,0 a=(a or 30)*pi/360;
  x=xx+s/2*sin(r);
  y=yy-s/2*co(r);
  xx=xx-s/4*sin(r);
  yy=yy+s/4*co(r);
  dTF(xx,yy,x,y,x-s*sin(r+a),y+s*co(r+a))
  dTF(xx,yy,x,y,x-s*sin(r-a),y+s*co(r-a)) 
end

function onTick()  
  for i=1,32 do
    I[i]=getNumber(i)
    O[i]=I[i]
    Ib[i]=getBool(i)
    Ob[i]=Ib[i]
  end

	t2 = Ib[1] -- also getBool(2) for touch 2
  --[[
	W,H,tx,ty,tx2,ty2
    , gx,gy,gz,dir,swp -- 11-15
    , inputX, inputY
     = getN(1,2,3,4,5,6,11,12,13,14,15,16,17)
  --]]
	W,H,tx,ty,tx2,ty2 -- 1-6
    , _, _, _, _ -- 7-10 pilot input axes
    , gx,gy,gz,dir,_ -- 11-14, 15=forwardSpeed
    , inputX, inputY -- 16,17
    = unpack(I)

	if gx == nil then return true end
	if wx == nil then 
    if gx==0 then return true end 
    wx,wy,Fx,Fy,Fz = gx,gy,gx,gy,zoom 
  end

	--if swp>0 and swp<=#wp then sel=swp end

	lastTouchTick = lastTouchTick + 1
  
			
	if t2 and not t then
    -- if ty < 13 find selected nav index
    ttx = ty<13 and
      ceil((tx-11)/13)
      or 0

    -- if ttx is greater than max nav items +1 (for add waypoint button) set to 0
    ttx = ttx>(#wp +1)      
      and 0
      or ttx

		if tx < 10 and ty < homeButtonHeight then
      -- if already using centerOnGPS set selected waypoint to 0
      sel = centerOnGPS and 0 or sel
      centerOnGPS = true
    elseif tx < 10 then
			tz = ty - homeButtonHeight
			Fz = sin((tz/(h-homeButtonHeight))^2*pi/2)*50
      --sin((tz/H-homeButtonHeight)^2*pi/2)*50
			i = 1
			while Fz>zooms[i] do i=i+1 end
			grid = grids[i]
			SZ = sis[i]
		elseif ttx >0 then
      centerOnGPS = false
			if ttx == #wp+1 then
				sel=#wp+1
				wp[sel] = {x=wx,y=wy}
			elseif sel == ttx then
        table.remove(wp,sel)
        -- leave map in scroll mode (sel==-1)
        sel = -1
        ttx = 0
      else
        sel = ttx
        Fx,Fy = wp[sel].x,wp[sel].y
        selX, selY = Fx, Fy
			end
		else
      centerOnGPS = false
      sel = -1
			Fx,Fy = screenToMap(wx,wy,zoom,W,H,tx,ty)
		end

    lastTouchTick = 0
	end

  if sel==-1 and lastTouchTick > 60*10 then
    sel = 0
    centerOnGPS = true
  end

  if inputX~=lastInputX or inputY~=lastInputY then
    sel = -1
    centerOnGPS = false
    Fx,lastInputX = inputX, inputX
    Fy,lastInputY = inputY, inputY

    lastTouchTick = 0
  end

  if centerOnGPS then
    Fx,Fy = gx, gy
  end

	wx = wx+(Fx-wx)*0.1
	wy = wy+(Fy-wy)*0.1

	zoom = zoom+(Fz-zoom)*0.1
	t = t2
	
  if sel<1 then    
    selX, selY = gx, gy
    outDis, outCourse = 0, 0
  else  
    --selX = wp[sel].x
    --selY = wp[sel].y
    outDis = sqrt((gx-selX)^2 + (gy-selY)^2)

    outCourse = atan(selX-gx,selY-gy) / pi / -2
    outCourse = ((dir - outCourse + .5) % 1 - .5) * 360
  end
  wayInfo = {sel,selX,selY,outDis,outCourse}
  
  for i,v in ipairs(
    {wx,wy,zoom,unpack(wayInfo)}) do
    O[17+i]=v -- MapX starts at channel 18
  end

  for i=1,32 do
    setNumber(i, O[i])
    setBool(i, Ob[i])
    devInput.setNumber(i, O[i])
    devInput.setBool(i, Ob[i])
  end

  beaconTest.onTick()
end

--[[
local 
  black
  , white
  , yellow
  , red
  , setColor
  = {0,0,0,200} -- black
  , {255,255,255} -- white
  , {255,150,0} -- yellow
  , {200,0,0} -- red

function setColor(rgba,a,r,g,b)
  rgba = rgba or black
  r,g,b = unpack(rgba)
  a = a or rgba[4]
  C(r,g,b,a)
end
--]]

function onDraw()
	if wx==nil then return true end
	w=getWidth()
	h=getHeight()
	cx=w/2
	cy=h/2
	sz=SZ/H*h

  mx,my,zo=wx,wy,zoom
  --[[
	if w==W then
    mx,my,zo=wx,wy,zoom 
  else 
    -- current location
    mx,my,zo=gx,gy,zoom 
  end
  --]]
  
  
  local S=screen

	S.setMapColorOcean(10,10,15)
	S.setMapColorShallows(15,15,20)
	S.setMapColorLand(60,60,60)
	S.setMapColorGrass(40,60,40)
	S.setMapColorSand(55,55,50)
	S.setMapColorSnow(80,80,80)
  S.drawMap(mx,my,zo) --mapX,mapY,mapZoom)

  
  beaconTest.onDraw()
	
	x1,y1 = screenToMap(mx,my, zo, w,h, 0,h)
	x2,y2 = screenToMap(mx,my, zo, w,h, w,0)
	x1 = floor(x1/grid)*grid
	y1 = floor(y1/grid)*grid
	
  
  --meterPixels = (mapToScreen(0, 0, zo, w, h, 1000, 0) - w/2) / 1000

	C(0,0,0,20)
  --setColor(black,20)
	for xx=x1,x2,grid do
		x,y = mapToScreen(mx,my,zo, w,h, xx,y1)
		dL(x,0,x,h)
	end
	for yy=y1,y2,grid do
		x,y = mapToScreen(mx,my,zo, w,h, x1,yy)
		dL(0,y,w,y)		
	end

  -- boxes are at 13 and 50
  local hereBoxX, thereBoxX = 60, 13
  if centerOnGPS then
    hereBoxX, thereBoxX = thereBoxX, hereBoxX
  end

  if w==W then
    dRF(8,0,2,h)
    C(0,0,0,200)
    --setColor() -- black is default
    dRF(0,homeButtonHeight,8,h)
    dRF(58,h-19,45,16)
    dRF(11,h-19,45,16)
    dTxB(105,h-19,w-110,15,format("grid:%.0f  scale:%.1f",grid,zo),-1,1)

    C(255,150,0)
    --setColor(yellow)
    dL(1,tz+homeButtonHeight,7,tz+homeButtonHeight)
    dTxB(105,h-20,w-110,15,format("grid:%.0f  scale:%.1f",grid,zo),-1,1)
    dTxB(thereBoxX,h-20,45,15,format("x:%.0f\ny:%.0f",wx,wy),-1,1)

    -- draw home button in green (gps follow) or grey(click for gps follow)
		C(0,sel==0 and 150 or 0,0,220)
		dRF(0, 0, 8, homeButtonHeight-2)
  end
	
	vx,vy = mapToScreen(mx,my,zo,w,h,gx,gy)
	r = dir*pi*-2
	
	if vx<10 or vx>w or vy<0 or vy>h then
		C(200,0,0)
    --setColor(red)
		vx = clamp(vx,12,w-3)
		vy = clamp(vy,5,h-3)
		r=atan(gx-mx,gy-my)
		dPoi(vx,vy,triMarkerSize,r,40)
	else
		vy1 = vy-(gz/10)/(zo+1)
		if gz<0 then
			C(0,50,200)
			dPoi(vx,vy1,triMarkerSize,r,50)
			C(0,50,100,100)
			dL(vx,vy+5,vx,vy1)
			C(0,0,0,100)
      --setColor(black,100)
			dPoi(vx,vy,triMarkerSize,r,50)
		else
			C(0,0,0,100)
      --setColor(black,100)
			dPoi(vx,vy,triMarkerSize,r,50)
			C(100,0,0,100)
			dL(vx,vy-4,vx,vy1)
      --setColor(red)
			C(200,0,0)
			dPoi(vx,vy1,triMarkerSize,r,50)
		end
	end

  dTx(13,h-26,format("d:%.0f c:%.0f",outDis,outCourse))

  if w==W then
    C(0,0,0,50)
    --setColor(black,50)
    dL(10,cy+1,cx-5,cy+1)
    dL(cx+1,0,cx+1,cy-5)
    dL(cx+6,cy+1,w,cy+1)
    dL(cx+1,cy+6,cx+1,h)
    C(255,255,255,50)
    --setColor(white,50)
    dL(10,cy,cx-5,cy)
    dL(cx,0,cx,cy-5)
    dL(cx+6,cy,w,cy)
    dL(cx,cy+6,cx,h)
    --setColor(red)
    C(200,0,0)

    dTxB(hereBoxX,h-20,45,15,format("x:%.0f\ny:%.0f",gx,gy),-1,1)
  end

	i = 1
	while i<=#wp do
		lx,ly=ox,oy
		ox,oy = mapToScreen(mx,my,zo,w,h,wp[i].x,wp[i].y)
		C(0,100,0,220)
		if i==sel then dL(ox,oy,vx,vy) end
		C(0,0,0,150)
		if i<=sel then C(0,0,0,20) end
		drawCircle(ox,oy+1,sz)
		if i>1 then	dL(ox,oy,lx,ly) end
		C(0,i==sel and 150 or 0,0,220)
		drawCircle(ox,oy,sz)
		if w==W then
			dRF(-2+i*13,2,10,10)
			C(255,255,255)
      --setColor(white)
			dTx((i>9 and -2 or 1)+i*13,4,i)
		end
		i=i+1
	end
	if w==W then
		C(0,0,0,200)
    --setColor(black)
		dRF(-2+i*13,2,10,10)
		C(255,255,255)
    --setColor(white)
		dL(i*13-1,6,6+i*13,6)
		dL(2+i*13,3,2+i*13,10)
	end

end


--[[
Composite inputs
io 01 W
io 02 H
io 03 tx
io 04 ty
io 05 tx2
io 06 ty2
io 07 axis1
io 08 axis2
io 09 axis3
io 10 axis4
io 11 GPSx
io 12 GPSy
io 13 altitude
io 14 compass - dir
io 15 Forward Speed -was  selected waypoint - swp
io 16 keypad inputX
io 17 keypad inputY
io 18 map X
io 19 map Y
io 20 map zoom
io 21 selected waypoin6
io 22 waypoint X
io 23 waypoint Y
io 24 waypoint distance
io 25 angle to waypoint
 o 26 beacon Distance
i  27 buoy X
i  28 buoy Y
i  29 buoy Alt 
 
Bools
01 touch1
02 touch3
26 beacon pulse

--]]

--[[
  ****
  **** Nav Section ***
  ****
--]]

beaconTest = 
function()
  local onTick, onDraw

  --- ****
  --- Insert here:
  --- ***

  -- Stormworks Ark NavSuite Emergency Beacon Dislay
-- V 01.03a Michael McHenry 2020-11-10
-- Minifies to 2452 ArkNavB01x02a
--             2912 ArkNavB01x04d
--             3310 ArkNavB01x05a
--             3646 ArkNavB01x06a
source={"ArkNavB01x06a","repl.it/@mgmchenry"}

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
    , gx,gy,gz,dir,_ -- 11-14, 15=forwardSpeed
    , inputX, inputY -- 16,17
    , mapX, mapY, mapZoom -- 18-20
    , _, _, _, _, _ -- 21-25
    , _ -- 26
    , buoyData[1], buoyData[2], buoyData[3] -- 27 - 29
    = unpack(I)

	if gx == nil then return true end
  
  buoyData[4] = getDistance2d(buoyData, {gx, gy})
  buoyData[5] = getDistance3d(buoyData, {gx, gy, gz})

  
  -- detectors[] layout
  -- {inputChannel, pulseOn}
  -- detectors at init:
  -- , {{26},{27}}

	beaconPulse = Ib[26]
	
  if beaconPulse then
    if beaconQuietCounter>0 then
      lastBeaconDistance = beaconQuietCounter * 50 - 200
      lastBeaconTicks = beaconQuietCounter

      lastGroundDistance = sqrt(lastBeaconDistance^2 - gz^2)

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
    drawCircle(x,y,r)
    --r = min(r,200)
    steps = steps or (r*2)
    --print("Circle steps: ", steps)
    if x+r<0 or x-r>w
      or y+r<0 or y-r>h then 
      --print("Aborting circle. x, y, r, steps", x, y, r, steps)
      return 
    end

    local x1, y1
      , x2, y2, aRadians
      = x, y-r
    for i=1, steps do
      aRadians = i/steps * pi * 2
      x2, y2 = x + sin(aRadians) * r
        , y - cos(aRadians) * r

      drawLine(x1,y1,x2,y2)
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


  -- *****
  -- Paste before here
  -- *****

  return {
    onTick  = function()
      onTick()
    end
    , onDraw = function()
      onDraw()
    end
  }



end

beaconTest = beaconTest()