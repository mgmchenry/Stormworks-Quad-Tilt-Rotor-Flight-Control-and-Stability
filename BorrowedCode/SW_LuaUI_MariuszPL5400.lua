-- by MariuszPL5400
UiElement = {x, y}
UiElements = {}
Rectangle = {x, y, width, height}

function UiElement.new(x, y)
    local self = {}
    self.x = x
    self.y = y
    self.isPressed = false

    self.draw = function() end
    self.checkIsPressed = function(x, y, isPressed) end
    self.onPressed = function() end

    table.insert(UiElements, self)

    return self
end

function Rectangle.new(x, y, width, height)
    local self = UiElement.new(x, y)
    self.width = width
    self.height = height

    self.normalDraw = function()
        screen.drawRect(self.x, self.y, self.width, self.height)
    end

    self.pressedDraw = function()
        screen.drawRectF(self.x, self.y, self.width + 1, self.height + 1)
    end

    self.draw = self.normalDraw

    self.checkIsPressed = function(x, y, isPressed)
        local isElementPressed = isPressed and x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
        self.isPressed = isElementPressed

        if isElementPressed then
            self.draw = self.pressedDraw
            self.onPressed()
        else
            self.draw = self.normalDraw
        end

        return isElementPressed
    end

    return self
end

local touchX, touchY, isPressed

rectangle = Rectangle.new(5, 5, 10, 10)
rectangle2 = Rectangle.new(5, 20, 20, 20)

function onTick()
    touchX = input.getNumber(3)
    touchY = input.getNumber(4)
    isPressed = input.getBool(1)

    for key, uiElement in pairs(UiElements) do
        uiElement.checkIsPressed(touchX, touchY, isPressed)
        output.setBool(key, uiElement.isPressed)
    end
end

function onDraw()
    for key, uiElement in pairs(UiElements) do
        uiElement.draw()
    end
end