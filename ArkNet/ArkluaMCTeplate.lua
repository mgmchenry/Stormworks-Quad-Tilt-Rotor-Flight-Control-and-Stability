if type(dofile)=="function" then
  do
    local loader, program
      = "ArkLua/ArkluaAPI.lua"
      , "ArkLua/monitorCalibrationWithCubes.verbose.lua"
    print("executing loader: " .. loader)
    dofile(loader)
    print("running program: " .. program)
    ArkLua.runMC(program)
  end
else

  -- debug info fallback:
  local statusText, statusTick = {"ArkLua not found"}, 0
  function onDraw()
    statusTick=statusTick+1
    local totalHeight, scroll = #statusText*6+6, 0
    if totalHeight>screen.getHeight() then
      scroll = math.floor(statusTick/8) % (#statusText*6 + 8*6)
      scroll = math.max(0, scroll - 6*8)
    end
    
    screen.setColor(255,255,255,255)
    for i,text in ipairs(statusText) do
    if totalHeight>screen.getHeight() then
      text = tostring(i) .. ": " .. text
    end
      screen.drawText(2,6 * i + 2 - scroll, text)
    end
    screen.drawText(2,6 * #statusText + 8 - scroll, "Tick: " .. statusTick)
  end 

end
