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

-- Stormworks Ark NavSuite Map Display
-- V 01.02a Michael McHenry 2020-11-10
-- Minifies to 1495 ArkMap01x02a
source={"ArkMap01x02a","repl.it/@mgmchenry"}

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
    = unpack(I)

	if gx == nil then return true end
	if wx == nil then 
    if gx==0 then return true end 
    wx,wy,Fx,Fy,Fz = gx,gy,gx,gy,zoom 
  end
  
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
  
  local S=screen

	S.setMapColorOcean(10,10,15)
	S.setMapColorShallows(15,15,20)
	S.setMapColorLand(60,60,60)
	S.setMapColorGrass(40,60,40)
	S.setMapColorSand(55,55,50)
	S.setMapColorSnow(80,80,80)
  S.drawMap(mapX,mapY,mapZoom)

end