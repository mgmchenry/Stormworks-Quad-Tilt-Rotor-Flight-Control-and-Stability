do
  local loader, program
    = "Experiments/luaMCLoader.lua"
    , "Experiments/monitorCalibrationWithCubes.lua"
  print("executing loader: " .. loader)
  dofile(loader)
  print("running program: " .. program)
  ArkLua.runMC(program)
end