-- woekin_up
-- https://discord.com/channels/357480372084408322/578586360336875520/771307374875115521
function onTick()
    mX,mY,mZ = input.getNumber(1),input.getNumber(2),input.getNumber(5) --monitor's coordinates and zoom
    wx,wY,wr= input.getNumber(3),input.getNumber(4),input.getNumber(6) --circle coordinates and radius
end
function onDraw()
    sw = screen.getWidth()
    sh = screen.getHeight()
    screen.drawMap(mx, my, mz)
    pX, pY = map.mapToScreen(mx, my, mz, sw, sh, wx, wy)            
    screen.setColor(0, 0, 0, 186)
    screen.drawCircle(pX, pY, (wr/1000)*(sw/mz))                
end