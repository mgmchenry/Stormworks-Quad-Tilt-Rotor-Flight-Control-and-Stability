local luaEnv = {
  package = package,
  dofile = dofile,
  require = require,
  print = print
}
--print = function() return end

package = {}
local preload, loaded = {}, {
  string = string,
  debug = debug,
  package = package,
  _G = _G,
  io = io,
  os = os,
  table = table,
  math = math,
  coroutine = coroutine,
}
package.preload, package.loaded = preload, loaded


function require( mod )
  if not loaded[ mod ] then
    local f = preload[ mod ]
    if f == nil then
      error( "module '"..mod..[[' not found:
       no field package.preload[']]..mod.."']", 1 )
    end
    local v = f( mod )
    if v ~= nil then
      loaded[ mod ] = v
    elseif loaded[ mod ] == nil then
      loaded[ mod ] = true
    end
  end
  return loaded[ mod ]
end

function loadMClua(filename)

end

function dofile(name)
  local loaded_chunk = assert(loadfile(name))
  return loaded_chunk()
end

ArkLua = {}
do
  local mc_onTick, mc_onDraw
  local debugText = {}
  local tickCount = 0
  local drawCount = 0
  local maxDrawCount = 0
  local displayLine = 1
  local currentFile = nil
  
  local keySequence = ""
  local keyDown = 0

  local function run_onTick(...)
    maxDrawCount, drawCount = drawCount, 0
    drawCount = 0
    tickCount = tickCount + 1
    debugText = {} --"Tick: " .. tostring(tickCount)}


    local I, Ib = {}, {}    
    for i=1,32 do -- load composite input array and copy to output array for pass-through
      I[i]=input.getNumber(i);Ib[i]=input.getBool(i)
    end
    
    if keyDown>0 and not Ib[keyDown] then
      keySequence = keySequence .. tostring(keyDown)
      keyDown = 0
    end      
    
    for i=1,6 do
      if Ib[i] then
        keyDown = i
      end
    end

    if string.sub(keySequence,1,3)=="666" and string.len(keySequence)<10 then
      -- allow keySequence to grow up to 10 chars
      debugText[1] = {"Tick: " .. tostring(tickCount)}
      debugText[#debugText+1] = "keyCode: " .. keySequence
    elseif string.sub(keySequence,-3,-1)=="666" then
      keySequence = string.sub(keySequence,-3,-1) -- reset sequence to escape code
    elseif string.len(keySequence)>10 then
      keySequence = string.sub(keySequence,-2,-1) -- truncate to last two chars
    end

    if keySequence=="666234" then
      keySequence=""
      debugText[#debugText+1] = "reloading " .. currentFile
      ArkLua.runMC(currentFile)
    end


    if type(mc_onTick)=="function" then
      mc_onTick(...)
    else
      debugText[1] = {"Tick: " .. tostring(tickCount)}
      debugText[#debugText+1] = "no onTick function"
    end
  end

  local function setC(r,g,b)
    screen.setColor(
      math.min(1,(r/255)^2.2)*255
      ,math.min(1,(g/255)^2.2)*255
      ,math.min(1,(b/255)^2.2)*255
    )
  end

  local function run_onDraw(...)
    drawCount = drawCount+1
	  if debugText[1] and string.sub(tostring(debugText[1]),1,4)=="Tick" then
      debugText[1] = string.format("Tick: %i Draw: %i", tickCount, drawCount)
    elseif drawCount==maxDrawCount then
      debugText[1] = string.format("Tick: %i Draw: %i", tickCount, drawCount)	
      debugText[2] = "keyCode: " .. keySequence
    end

    local sWidth, sHeight
      = screen.getWidth()
      , screen.getHeight()
    setC(0,255,0)    
    --screen.drawClear()
    local maxLines = math.floor(sHeight / 6)
    local displayedLines = 0
    while displayedLines<maxLines and displayedLines<#debugText do
      local text = debugText[displayedLines + displayLine] or ""
      screen.drawText(1,6 * displayedLines, text)
      displayedLines = displayedLines + 1
    end

    if type(mc_onDraw)=="function" then
      mc_onDraw(...)
    else
      debugText[#debugText+1] = "no onDraw function"
    end

    local displayedLines = 0
    while displayedLines<maxLines and displayedLines<#debugText do
      local text = debugText[displayedLines + displayLine] or ""
      screen.drawText(1,6 * displayedLines, text)
      displayedLines = displayedLines + 1
    end
  end

  function ArkLua.runMC(filename)
    onTick, onDraw, mc_onTick, mc_onDraw = nil, nil, nil, nil
    currentFile = filename
    dofile(filename)
    mc_onTick, mc_onDraw = onTick, onDraw
    onTick, onDraw = run_onTick, run_onDraw
  end
end

_G.ArkLua = ArkLua
return ArkLua