local outLines
  , displayLine
  , isPressed, isHeld
  , writeLine, expand
  = {}
  , 1
  , false, false
  
writeLine = function(text)
	text = text or ""
	local lineNum = #outLines+1
	outLines[lineNum] = string.format("%02i", lineNum) .. "# " .. text
end

expand = function(list, depth, prefix)
  depth = depth or 1
  prefix = (prefix or "") .. "->"
  for k,v,sv in pairs(list) do
    sv = string.sub(tostring(v),1,20)
    --print("key",k, "value", v)
    writeLine(prefix .. string.format("key: %s Value: %s Type: %s", k, sv, type(v)))
    if depth>1 and type(v)=="table" then
	    if v~=_ENV and v~=list then
        writeLine(prefix .. string.format("  %s table values", k))
		    expand(v, depth-1, prefix)
      else
        writeLine(prefix .. string.format("  %s is a nested table", k))
	    end
    end
  end
  if # list > 0 then
    writeLine("Array part size: "..tostring(# list))
    for i,v in ipairs(list) do
      v = string.sub(tostring(v),1,20)
      writeLine(" i:".. string.format("%02i",i) .." Value: "..v)
    end
  end
end

writeLine("_ENV global values")
expand(_ENV)
writeLine("debug values")
expand(_ENV.debug)
writeLine("property values")
expand(_ENV.property)

_ENV.property.ArkText = "Just some text"
_ENV.property.ArkTestFunc = function(value) return value end
_ENV.debug.tellMe = function() return "Nothing" end

function onTick()
	local screenX
    , screenY
    , inputX
    , inputY
    , touch01

	= input.getNumber(1)
	  , input.getNumber(2)
	  , input.getNumber(3)
	  , input.getNumber(4)
	  , input.getBool(1)

	isPressed = touch01 and not isHeld
	isHeld = touch01
	
	if isPressed then
		isPressed = false
		displayLine = (displayLine % (# outLines)) + 1
		if displayLine == 1 then
      dofile("test.lua")
		  outLines = {}
      writeLine("Show Me: ".._ENV.debug.tellMe())
		  writeLine("property values again")
      expand(_ENV.property)
      writeLine("_ENV global values")
      expand(_ENV)
		end
	end
end

local function setC(r,g,b)
	screen.setColor(r*0.4,g*0.4,b*0.4,255)
end

function onDraw()
  local SW, SH
    = screen.getWidth()
	  , screen.getHeight()
	setC(200,200,200)
	
	screen.drawClear()
	
	setC(0,0,0)
	local maxLines = math.floor(SH / 6)
	for i=1,maxLines do
		text = outLines[i - 1 + displayLine] or ""
		screen.drawText(1,6 * i, text)
	end
end 