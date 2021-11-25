--[[
Jailbreak test - show status of enabled lua libriaries

]]

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

if type(dofile)=="function" then
  do
	print = function(...)
		local textOut = ""
		for i,v in ipairs({...}) do
			textOut = textOut==nil and "" or (textOut .. ", ") .. tostring(v)
		end
		statusText[#statusText+1] = textOut
	end
	
	statusText = {"ArkLua Init : " .. (os and tostring(os.date()) or "(no _G.os)")}
	debug.log("where does this go? ", os and os.date() or "(no _G.os)")
	
	for k,v in pairs(type(arg)=="table" and arg or {}) do
		print("arg",k,type(v),v) 
	end
	
	local vars={"USERNAME","TEMP","windir","USERPROFILE","OS","LOCALAPPDATA","HOMEDRIVE","HOMEPATH","ComSpec","APPDATA"}
	if os then
		for i,var in pairs(vars) do
			print(var, "[[" .. tostring(os.getenv(var)) .. "]]")
		end
	end
	
	local info={
		G_= _G or "not found"
		, io = _G.io or "not found"
		, os = _G.os or "not found"
		, debug = debug}
		
	for infoK, infoV in pairs(info) do
	statusText[#statusText+1] = "x=" .. infoK .. " (" .. type(infoV) .. ") " 
		.. tostring(infoV)
		for k,v in pairs(
			type(infoV)=="table" and infoV 
			or infoV==nil and {"??","not found"}
			or {tostring(type(infoV)),"not a table"}
			) do
			--print(" x." .. tostring(k),type(v),v) 
			statusText[#statusText+1]
				= " x." .. tostring(k) 
				.. " (" .. type(v) .. "): " 
				.. tostring(v)
		end
	end
	--[[
	
	for k,v in pairs(_G) do
		print("_G." .. tostring(k),type(v),v) 
		statusText[#statusText+1]
			= "_G." .. tostring(k) 
			.. " (" .. type(v) .. "): " 
			.. tostring(v)
	end
	]]
	
    local loader, program
	  = "ArkLua/MCLoader.lua"
	  , "ArkLua/MonitorCalibration.Tall.lua"
	
    print("executing loader: " .. loader)
    --dofile(loader)
    print("running program: " .. program)
    --ArkLua.runMC(program)
  end

end