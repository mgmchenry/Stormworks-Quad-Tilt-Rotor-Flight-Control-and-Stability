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


M=math
si=M.sin
co=M.cos
pi=M.pi
local abs, min, max, sqrt, unpack
  = M.abs, M.min, M.max, M.sqrt
  , table.unpack

S=screen
C=S.setColor
dL=S.drawLine
local drawCircle, drawCircleF
  , screenToMap, mapToScreen
  = S.drawCircle, S.drawCircleF
  , map.screenToMap, map.mapToScreen
dRF=S.drawRectF
dTF=S.drawTriangleF
dTx=S.drawText
dTxB=S.drawTextBox

--[[
function mapToScreen(mapX, mapY, zoom, screenW, screenH, worldX, worldY)
    screenW = math.max(screenW, 1)
    screenH = math.max(screenH, 1)
    zoom = math.min(math.max(zoom, 0.1), 50) * 1000 / screenW
    return (worldX - mapX) / zoom + screenW / 2, screenH / 2 - (worldY - mapY) / zoom
end
function screenToMap(mapX, mapY, zoom, screenW, screenH, pixelX, pixelY)
    screenW = math.max(screenW, 1)
    screenH = math.max(screenH, 1)
    zoom = math.min(math.max(zoom, 0.1), 50) * 1000 / screenW
    return (pixelX - screenW / 2) * zoom + mapX, (screenH / 2 - pixelY) * zoom + mapY
end
--]]

I=input
O=output

tU=table.unpack
F=string.format

local zoom, tz, zooms
  , grids, grid
  , sis, SZ, wp, sel
  , triMarkerSize
  , homeButtonHeight, centerOnGPS
  , lastTouchTick
  , lastInputX, lastInputY
  , inputX, inputY
  , outDis, outCourse

  , beaconRadius
  , clamp

  = 1, 5*32*0.11, {0.3,2,5,10,30,50}
  , {10,100,500,1000,2500,5000}, 100
  , {5,4,3,2,1,1}, 4, {}, 0
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

local getBool
  = I.getBool

function dPoi(xx,yy,s,r,...) 
local a,x,y=...,0,0 a=(a or 30)*pi/360;
x=xx+s/2*si(r);
y=yy-s/2*co(r);
xx=xx-s/4*si(r);
yy=yy+s/4*co(r);
dTF(xx,yy,x,y,x-s*si(r+a),y+s*co(r+a))
dTF(xx,yy,x,y,x-s*si(r-a),y+s*co(r-a)) 
end
function clamp(a,b,c) return M.min(M.max(a,b),c) end
function getN(...)local a={}for b,c in ipairs({...})do a[b]=I.getNumber(c)end;return tU(a)end
function outN(o, ...) for i,v in ipairs({...}) do O.setNumber(o+i-1,v) end end

local beaconPings, lastPingIndex, maxPings, hotSpots
  , hotSpotMaxScore
  , beaconPulse, lastBeaconPulse, lastBeaconDistance, beaconQuietCounter

  , getCircleIntersections, addBeaconPing

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

	t2 = getBool(1)
	W,H,tx,ty,gx,gy,gz,dir,swp
    , inputX, inputY
    , beaconRadius
     = getN(1,2,3,4,11,12,13,14,15,16,17,18)
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

    lastBeaconDistance = beaconRadius
    addBeaconPing(inputX, inputY, lastBeaconDistance)
  end
  lastBeaconPulse = beaconPulse
	O.setBool(20,beaconPulse)
	O.setNumber(20,lastBeaconDistance)

	if swp>0 and swp<=#wp then sel=swp end

	lastTouchTick = lastTouchTick + 1
  
			
	if t2 and not t then
    -- if ty < 13 find selected nav index
    ttx = ty<13 and
      M.ceil((tx-11)/13)
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
			Fz = tz/(h-homeButtonHeight)*5
      --M.sin((tz/H-homeButtonHeight)^2*pi/2)*50
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

  Fx = centerOnGPS and gx or Fx
  Fy = centerOnGPS and gy or Fy

	wx = wx+(Fx-wx)*0.1
	wy = wy+(Fy-wy)*0.1

	zoom = zoom+(Fz-zoom)*0.1
	t = t2
	
	outN(1,gx,gy,wx,wy,gx,gy,gz,sel,#wp,outCourse,outDis)
	if sel>0 then
		outN(1, wp[sel].x,wp[sel].y)
	end
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
	
	C(0,0,0,20)
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
    dRF(0,homeButtonHeight,8,h)
    dRF(58,h-19,45,16)
    dRF(11,h-19,45,16)
    dTxB(105,h-19,w-110,15,F("grid:%.0f  scale:%.1f",grid,zo),-1,1)

    C(255,150,0)
    dL(1,tz+homeButtonHeight,7,tz+homeButtonHeight)
    dTxB(105,h-20,w-110,15,F("grid:%.0f  scale:%.1f",grid,zo),-1,1)
    dTxB(thereBoxX,h-20,45,15,F("x:%.0f\ny:%.0f",wx,wy),-1,1)

    -- draw home button in green (gps follow) or grey(click for gps follow)
		C(0,sel==0 and 150 or 0,0,220)
		dRF(0, 0, 8, homeButtonHeight-2)
  end
	
	vx,vy = mapToScreen(mx,my,zo,w,h,gx,gy)
	r = dir*pi*-2
	
	if vx<10 or vx>w or vy<0 or vy>h then
		C(200,0,0)
		vx = clamp(vx,12,w-3)
		vy = clamp(vy,5,h-3)
		r=M.atan(gx-mx,gy-my)
		dPoi(vx,vy,triMarkerSize,r,40)
	else
		vy1 = vy-(gz/10)/(zo+1)
		if gz<0 then
			C(0,50,200)
			dPoi(vx,vy1,triMarkerSize,r,50)
			C(0,50,100,100)
			dL(vx,vy+5,vx,vy1)
			C(0,0,0,100)
			dPoi(vx,vy,triMarkerSize,r,50)
		else
			C(0,0,0,100)
			dPoi(vx,vy,triMarkerSize,r,50)
			C(100,0,0,100)
			dL(vx,vy-4,vx,vy1)
			C(200,0,0)
			dPoi(vx,vy1,triMarkerSize,r,50)
		end
	end

  lx = sel>0 and wp[sel].x or wx
  ly = sel>0 and wp[sel].y or wy

  lh = M.atan(lx-gx,ly-gy) / pi / -2
  outCourse = ((dir-lh+.5)%1-.5)*360
  --dTx(13,14,F("th:%.2f\ngh:%.2f", lh, dir))
  outDis = sqrt((gx-lx)^2 + (gy-ly)^2)
  dTx(13,h-26,F("d:%.0f c:%.0f",outDis,outCourse))

  if w==W then
    C(0,0,0,50)
    dL(10,cy+1,cx-5,cy+1)
    dL(cx+1,0,cx+1,cy-5)
    dL(cx+6,cy+1,w,cy+1)
    dL(cx+1,cy+6,cx+1,h)
    C(255,255,255,50)
    dL(10,cy,cx-5,cy)
    dL(cx,0,cx,cy-5)
    dL(cx+6,cy,w,cy)
    dL(cx,cy+6,cx,h)
    C(200,0,0)

    dTxB(hereBoxX,h-20,45,15,F("x:%.0f\ny:%.0f",gx,gy),-1,1)
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
			dTx((i>9 and -2 or 1)+i*13,4,i)
		end
		i=i+1
	end
	if w==W then
		C(0,0,0,200)
		dRF(-2+i*13,2,10,10)
		C(255,255,255)
		dL(i*13-1,6,6+i*13,6)
		dL(2+i*13,3,2+i*13,10)
	end

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

end
