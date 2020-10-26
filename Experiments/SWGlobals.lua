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

expand = function(list)
  for k,v in pairs(list) do
    v = string.sub(tostring(v),1,20)
    --print("key",k, "value", v)
    writeLine("key: "..k.." Value: "..v)
  end
  if # list > 0 then
    writeLine("Array part size: "..tostring(# list))
    for i,v in ipairs(list) do
      v = string.sub(tostring(v),1,20)
      writeLine(" i:".. string.format("$02i",i) .." Value: "..v)
    end
  end
end

writeLine("_ENV global values")
expand(_ENV)
writeLine("debug values")
expand(_ENV.debug)
writeLine("property values")
expand(_ENV.property)

_ENV.property.Ark = "Just some text"
_ENV.property.ArkF = function(value) return value end

writeLine("property values again")
expand(_ENV.property)

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
		  outLines = {}
		  writeLine("property values again")
      expand(_ENV.property)
      writeLine("_ENV global values")
      expand(_ENV)
		end
	end
end

function setC(r,g,b)
	S.setColor(r*0.4,g*0.4,b*0.4,255)
end

function onDraw()
	S=screen
	SW=S.getWidth()
	SH=S.getHeight()
	setC(200,200,200)
	
	S.drawClear()
	
	setC(0,0,0)
	maxLines = math.floor(SH / 6)
	for i=1,maxLines do
		text = outLines[i - 1 + displayLine] or ""
		S.drawText(1,6 * i, text)
	end
end