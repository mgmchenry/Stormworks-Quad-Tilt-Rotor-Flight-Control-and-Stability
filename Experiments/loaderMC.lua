local statusText, statusTick = {"ArkLua not found"}, 0
function onDraw()
  statusTick=statusTick+1
  
  screen.setColor(255,255,255,255)
  for i,text in ipairs(statusText) do
    screen.drawText(2,6 * i + 2, text)
  end
  screen.drawText(2,6 * #statusText + 8 , "Tick: " .. statusTick)
end 

if type(dofile)=="function" then
  do
    local loader, program
      = "Experiments/luaMCLoader.lua"
      --, "Experiments/MonitorCalibration.Tall.lua"
      , "ArkNet/ArkNetHostAircraftControl.lua"
    print("executing loader: " .. loader)
    dofile(loader)
    print("running program: " .. program)
    ArkLua.runMC(program)
    --dofile("ArkLua/MCLoader.lua")
    --ArkLua.runMC("ArkLua/MonitorCalibration.lua")
  end

end
