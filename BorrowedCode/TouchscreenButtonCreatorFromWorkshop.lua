--[[

--]]

--Made by RedPug
function onDraw()
	--the format you need to follow is buttons[channelNumber] = createButton/createSwitch(upper left x, upper left y, "text").
	--do not modify the code as you could break it. in the "buttons[channelNumber]", channelNumber HAS to be starting at 1 then going    up, anything else will NOT work
	buttons[1] = createButton(2, 2, "push 1")
	buttons[2] = createSwitch(2, 15, "toggle 1")
	buttons[3] = createSwitch(2, 28, "toggle 2")
	buttons[4] = createButton(2, 41, "push 2")
end

function onTick()
	mouseX = input.getNumber(3)
	mouseY = input.getNumber(4)
	pressed = input.getBool(1)
	while count > 0 do
		output.setBool(count, buttons[count])
		count = count - 1
	end
	count = 0
end
buttons = {}
toggled = {}
lastPressed = {}
count = 0
function createButton(x, y, text)
	count = count + 1
	screen.setColor(128, 128 ,128)
	screen.drawRect(x, y, string.len(text)*5+2, 8)
	if isPointInRectangle(mouseX, mouseY, x, y, string.len(text)*5+2, 8) and pressed then
		screen.setColor(64, 64, 64)
		screen.drawRectF(x+1, y+1, string.len(text)*5+1, 7)
	end
	setColor(128, 128, 128)
	screen.drawText(x+2, y+2, text)
	isPressed = isPointInRectangle(mouseX, mouseY, x, y, string.len(text)*5+2, 8) and pressed
	return isPressed
end

function createSwitch(x, y, text)
	count = count + 1
	screen.setColor(128, 128 ,128)
	screen.drawRect(x, y, string.len(text)*5+2, 8)
	if not lastPressed[count] and isPointInRectangle(mouseX, mouseY, x, y, string.len(text)*5+2, 8) and pressed then
		toggled[count] = not toggled[count]
	end
	
	lastPressed[count] = pressed
	if toggled[count] then
		screen.setColor(64, 64, 64)
		screen.drawRectF(x+1, y+1, string.len(text)*5+1, 7)
	end
	setColor(128, 128, 128)
	screen.drawText(x+2, y+2, text)
	return toggled[count]
end

function isPointInRectangle(x, y, rectX, rectY, rectW, rectH)
	return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end

function setColor(r, g, b)
	screen.setColor(r, g, b)
end
