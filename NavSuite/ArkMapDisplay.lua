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

-- Stormworks Ark Map Display
-- V 01.01a Michael McHenry 2020-11-10
-- Pony IDE testSim https://lua.flaffipony.rocks/?id=_uM_iSyvu
source={"ArkNav01x01a","repl.it/@mgmchenry"}

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

  = 1, 5*32*0.11, {0.3,2,5,10,30,50}
  , {10,100,500,1000,2500,5000}, 100
  , {5,4,3,2,1,1}, 4, {}, 0
  , 15
  , 7, true
  , 0 -- lastTouchTick
  , 0, 0
  , 0, 0


function onTick()  

	t2 = getBool(1) -- also getBool(2) for touch 2
	W,H,tx,ty,tx2,ty2
    , gx,gy,gz,dir,swp -- 11-15
    , inputX, inputY
     = getN(1,2,3,4,5,6,11,12,13,14,15,16,17)
	if gx == nil then return true end
	if wx == nil then 
    if gx==0 then return true end 
    wx,wy,Fx,Fy,Fz = gx,gy,gx,gy,zoom 
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

end