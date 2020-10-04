-- Stormworks Lua module Test Helper Example Thing
-- V 0.4 Michael McHenry 2019-06-07
inValues, outValues, inBools, outBools = {}, {}, {}, {}
table.unpack = table.unpack or unpack

-- Set up SW environment
dofile("Stormworks_Stub.lua")

propValues["BaseIndex"] = 1
--dofile("QuadFlightControl.V0.07.15.lua")
--dofile("ScaleController.V2.lua")
--dofile("QuadFlightControl.V0.09.18.lua")
dofile("RailPulseEncoder.lua")
--dofile("OnOffDecoder.lua")

--runTest(function() onTick() end, "onTick")
--runTest(function() onDraw() end, "onDraw")
-- Those return without doing anything because inValues are nil

-- Set an inValue so it continues to the error:
inValues[1] = 0
-- actually, set them all :P
for i=1,32 do
	inValues[i]= 0
end

runTest(function() onTick() end, "onTick")
runTest(function() onDraw() end, "onDraw")

-- Set rps high enough to trigger hover code
inValues[29] = 80
for i=5,26 do
	inValues[i]= 0
end
inValues[5] = 3
inValues[6] = 0.75
inBools[1] = true

runTest(function() onTick() end, "onTick")
runTest(function() onDraw() end, "onDraw")

for i=1,32 do
	inValues[i]=1
end
inValues[29] = 80

runTest(function() onTick() end, "onTick")
runTest(function() onDraw() end, "onDraw")