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
--             3,894 ArkNav01x04a
-- Pony IDE testSim https://lua.flaffipony.rocks/?id=_uM_iSyvu
-- https://lua.flaffipony.rocks/?id=i-dL_XsU6
-- Adapted from Tajin's excellent navigation map to allow additional overlays
-- and to be usable on 2x2 monitors
source={"ArkNav01x04d","repl.it/@mgmchenry"}

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
    prop_getText("ArkMF0")
    --"abs,min,max,sqrt,ceil,floor,sin,cos,atan,pi"
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

-- test custom implementation
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
  , screenIsBig, scrollWidth
  , lastTouchTick
  , lastInputX, lastInputY
  , inputX, inputY
  , outDis, outCourse


  = {},{},{},{}
  , 1, 5*32*0.11, {0.3,2,5,10,30,50}
  , {10,100,500,1000,2500,5000}, 100
  , {5,4,3,2,1,1}, 4, {}, 0
  , {}, 0, 0
  , 15 -- triMarkerSize
  , 9, true -- homeButtonHeight, centerOnGPS
  , true, 13 -- screenIsBig, scrollWidth
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

	if not(gx and W) then return end
	if wx == nil then 
    if gx==0 then return end 
    wx,wy,Fx,Fy,Fz = gx,gy,gx,gy,zoom 
  end

  screenIsBig = W>32
  scrollWidth = screenIsBig and 10 or 5
  triMarkerSize = screenIsBig and 15 or 7

	--if swp>0 and swp<=#wp then sel=swp end

	lastTouchTick = lastTouchTick + 1
  
			
	if t2 and not t then
    -- if ty < 13 find selected nav index
    ttx = ty<13 and screenIsBig and
      ceil((tx-11)/13)
      or 0

    -- if ttx is greater than max nav items +1 (for add waypoint button) set to 0
    ttx = ttx>(#wp +1)      
      and 0
      or ttx

		if tx < scrollWidth and ty < homeButtonHeight then
      -- if already using centerOnGPS set selected waypoint to 0
      sel = centerOnGPS and 0 or sel
      centerOnGPS = true
    elseif tx < scrollWidth then
      Fz = (ty - homeButtonHeight) / (H - homeButtonHeight)
      --Fz = sin(Fz^2*pi/2) * 50
      Fz = clamp(Fz,0,1)^2 * 50

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
  end
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
  local hereBoxX, thereBoxX = 60, screenIsBig and 13 or 80
  if centerOnGPS then
    hereBoxX, thereBoxX = thereBoxX, hereBoxX
  end

  if w==W then
    dRF(8,0,2,h)
    C(0,0,0,200)
    --setColor() -- black is default

    -- Zoom slider background
    dRF(0,homeButtonHeight,scrollWidth-2,h)

    if screenIsBig then
      dRF(58,h-19,45,16)
      dRF(11,h-19,45,16)
      dTxB(105,h-19,w-110,15,format("grid:%.0f  scale:%.1f",grid,zo),-1,1)
    end

    -- Draw zoom slider:
    C(255,150,0)
    --setColor(yellow)
    --[[
    Now to find tz from Fz in the reverse of how it was calculated
    To account for display size changes. In onTick:    
      Fz = (ty - homeButtonHeight) / (H - homeButtonHeight)
      --Fz = sin(Fz^2*pi/2) * 50
      Fz = Fz^2 * 50
    --]]
    tz = sqrt(Fz/50) * (h - homeButtonHeight) + homeButtonHeight
    dL(1,tz,scrollWidth-2,tz)
    dTxB(105,h-20,w-110,15,format("grid:%.0f  scale:%.1f",grid,zo),-1,1)
    dTxB(thereBoxX,h-20,45,15,format("x:%.0f\ny:%.0f",wx,wy),-1,1)

    -- draw home button in green (gps follow) or grey(click for gps follow)
		C(0,sel==0 and 150 or 0,0,220)
		dRF(0, 0, scrollWidth, homeButtonHeight-2)
  end
	
	vx,vy = mapToScreen(mx,my,zo,w,h,gx,gy)
	r = dir*pi*-2
	
	if vx<scrollWidth or vx>w or vy<0 or vy>h then
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

  text = screenIsBig and format("d:%.0f c:%.0f",outDis,outCourse) or ""
  dTx(13,h-26,text)

  if w==W then
    C(0,0,0,50)
    --setColor(black,50)
    dL(scrollWidth,cy+1,cx-5,cy+1)
    dL(cx+1,0,cx+1,cy-5)
    dL(cx+6,cy+1,w,cy+1)
    dL(cx+1,cy+6,cx+1,h)
    C(255,255,255,50)
    --setColor(white,50)
    dL(scrollWidth,cy,cx-5,cy)
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
		if w==W and screenIsBig then
			dRF(-2+i*13,2,10,10)
			C(255,255,255)
      --setColor(white)
			dTx((i>9 and -2 or 1)+i*13,4,i)
		end
		i=i+1
	end
	if w==W and screenIsBig then
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