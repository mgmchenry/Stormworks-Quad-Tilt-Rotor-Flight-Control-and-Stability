_ENV = _G

-- why is repl.it on Lua 5.1 still?
pack = pack or function(...)
  return { n = select("#", ...), ... }
end

table.pack = table.pack or pack

__debug = {
  AlertIf = function (condition, ...)
    if condition then
      if __debug.IsTable(condition) then print(unpack(condition)) end
      if select(1,...) then print(...) end
    end
    return true
  end
  , IsTable = function (v)
    return string.sub(tostring(v),1,5) == "table"
  end
  , TableContents = function(value, label)
    label = label and ("("..tostring(label)..") ") or ""
    if value==nil then
      print(label.."cannot expand as table, value is nil")
      return
    end
    if type(value) == "table" then
      print(label.."table contents:")
      local valueCount = 0
      for key,v in pairs(value) do
        print(key, v)
        valueCount = valueCount + 1
      end
      print(label.."Table value count:", valueCount)
    else
      print(label.."value is not a table")
      local sType, sVal = type(value), "<???>"
      if sType == "string" then
        sVal = "("..value..")"
      elseif sType == "boolean" then
        sVal = "(".. (value and "true" or "false") ..")"
      elseif sType == "number" then
        sVal = "("..string.format(value)..")"
      end
      print(label..sType..":"..sVal)
    end
  end
  , lastFuncCall = {
    name=""
    , count=0
    , messageTexts = {}
  }
}

__debug.lastFuncCall.print = function(text)
  local texts = __debug.lastFuncCall.messageTexts
  texts[#texts+1] = text
end


for i=1,32 do
  inValues[i]=nil
  outValues[i]=nil
  inBools[i]=nil
  outBools[i]=nil
end

local function f(name, func, isQuiet)
  local dummyF = function(...)
    local maybePrint, funcInfo
      = print
      , __debug.lastFuncCall

      
    --print("func, count", name, funcInfo.name, funcInfo.count)

    if name~=funcInfo.name then
      
      if #funcInfo.messageTexts>0 then
        for i, message in ipairs(funcInfo.messageTexts) do
          print(message)
        end
      end
      funcInfo.messageTexts={}
      funcInfo.name = name
      funcInfo.count = 1
    else
      funcInfo.count = funcInfo.count + 1
      if funcInfo.count > 2 then
        funcInfo.messageTexts={}
        maybePrint = funcInfo.print
        maybePrint("    ... " .. (funcInfo.count-3) .. " additional calls to " .. name .. " ...")
      end
    end

    if isQuiet then
      funcInfo.quietTexts = {}
      maybePrint = function(m, ...)
        funcInfo.quietTexts[#funcInfo.quietTexts+1] = m
      end
    end

    local params = {...}
    if name~=nil then
      maybePrint(" --> function call: "..name.." ( "..string.format("%d", #params).." parameters)")
    end
    if #params>0 then
      local message = " --> f("
      local commaMaybe = ""
      for i,param in ipairs(params) do
        local pString, sVal = type(param), "<???>"
        if type(param) == "string" then
          sVal = "("..param..")"
        elseif type(param) == "boolean" then
          sVal = "(".. (param and "true" or "false") ..")"
        elseif type(param) == "number" then
          sVal = "("..string.format(param)..")"
        end

        message = message..commaMaybe..pString..sVal
        commaMaybe = ", "
      end
      message = message..")"
      maybePrint(message)
    end
    local result, resultPack = nil
    if func==nil then
      return
    end
    resultPack = table.pack(func(...))
    if resultPack==nil then
      maybePrint("resultPack is nil")
    else
      if resultPack.n==nil then
        maybePrint("resultPack has no n")
        maybePrint(resultPack)
      end
      for i=1, resultPack.n do
        result = resultPack[i]
        local rString, sVal = type(result), "<???>"
        if type(result) == "string" then
          sVal = "("..result..")"
        elseif type(result) == "boolean" then
          sVal = "(".. (result and "true" or "false") ..")"
        elseif type(result) == "number" then
          sVal = "("..string.format(result)..")"
        end

        maybePrint(" --> return "..rString..sVal)
      end
    end
    return unpack(resultPack)
  end
  return dummyF
end


input = {
  getNumber=f("getNumber", function(channel) return inValues[channel] end, true),
  getBool=f("getBool", function(channel) return inBools[channel] end, true)
}
output = {
  setNumber=f("setNumber", function(channel, value) outValues[channel]=value end, true),
  setBool=f("setBool", function(channel, value) outBools[channel]=value end, true)
}
screen = {
  drawTextBox=f("drawTextBox"),
  drawText=f("drawText"),
  setColor=f("setColor"),
  getWidth=f("getWidth", function() return 98 end),
  getHeight=f("getHeight", function() return 98 end),
  drawLine=f("drawLine"),
  setColor=f("setColor"),
  drawClear=f("drawClear"),
  drawTriangleF=f("drawTriangleF"),
  drawTriangle=f("drawTriangle")
  , drawRectF=f("drawRectF")
  , drawRect=f("drawRectF")
  , drawCircle=f("drawCircle") --x, y, radius
  , drawCircleF=f("drawCircleF") --x, y, radius

  , setMapColorOcean=f("setMapColorOcean")
	, setMapColorShallows=f("setMapColorShallows")
	, setMapColorLand=f("setMapColorLand")
	, setMapColorGrass=f("setMapColorGrass")
	, setMapColorSand=f("setMapColorSand")
	, setMapColorSnow=f("setMapColorSnow")
  , drawMap=f("drawMap")
}
propValues = {}
property = {
  getNumber=f("getNumber", function(key) 
    return propValues[key] 
  end)
  , getText=f("getText", function(key) 
    return propValues[key] 
  end)
}
map = {
  -- vx,vy = MS(mx,my,zo,w,h,gx,gy)
  mapToScreen=f("mapToScreen", function(mapX, mapY, zoom, screenW, screenH, worldX, worldY)
    screenW = math.max(screenW, 1)
    screenH = math.max(screenH, 1)
    zoom = math.min(math.max(zoom, 0.1), 50) * 1000 / screenW
    screenX, screenY
      = (worldX - mapX) / zoom + screenW / 2
      , screenH / 2 - (worldY - mapY) / zoom
    return screenX, screenY
  end)
  -- SM(mx,my, zo, w,h, 0,h)
  ,screenToMap=f("screenToMap", function(mapX, mapY, zoom, screenW, screenH, pixelX, pixelY) 
    screenW = math.max(screenW, 1)
    screenH = math.max(screenH, 1)
    zoom = math.min(math.max(zoom, 0.1), 50) * 1000 / screenW
    worldX, worldY
      = (pixelX - screenW / 2) * zoom + mapX
      , (screenH / 2 - pixelY) * zoom + mapY
    return worldX, worldY
  end)
}

devInput = {
  -- Pony API functions
  setBool = function(index, val) inBools[index] = val end
  , setNumber = function(index, val) inValues[index] = val end
}

function onTick()
  print("onTick undefined")
end

function onDraw()
  print("onDraw undefined")
end

function runTest(func, message)
  if message~=nil then print("Test call: "..message) 
  else message="" end
  local status, err = pcall(func)
  if status then
    print("No Errors: Success!")
    print()
  else
    print()
    print(" *** "..message.." Error ***")
    if (type(err) == "table") then
      for key,value in pairs(err) do
        print("err."..toString(key)..":")
        print(value)
      end
    else
      print(err)
    end
    error(err)
  end
end