hardpoint=0
pressed=false
key={'Alt----','AltHold','Spd----','RpsL---','RpsR---','Pitch--','FuelCap','Fuel---'}
ns={7,12,8,9,10,11,13,14,15}
nums={7,12,8,9,10,11,13,14,15}
function onTick()
	--[[
	Alt = input.getNumber(7)
	Spd = input.getNumber(8)
	RpsL = input.getNumber(9)
	RpsR = input.getNumber(10)
	Pitch = input.getNumber(11)
	AltHold=input.getNumber(12)
	FuelMax=input.getNumber(13)
	Fuel=input.getNumber(14)
	]]--
	n={}
	for k=1,9 do
		n[k]=input.getNumber(ns[k])
	end
	nums=n
	W=input.getNumber(1)
	TX=input.getNumber(3)
	if input.getBool(1) then
		hardpoint=math.floor(TX*5/W)
	end
	output.setNumber(hardpoint)
end

function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()
	if hardpoint==0 then
		screen.setColor(1,1,1)
		screen.drawRectF(0,0,w,h)
		screen.setColor(0,255,0)
		for i, k in pairs(key) do
			screen.drawText(0,2+6*i,k..' '..tostring(nums[i]))
		end
		--[[
		screen.drawText(0,8,"Alt "..tostring(Alt))
		screen.drawText(0,14,"Spd "..tostring(Spd))
		screen.drawText(0,20,"RpsL "..tostring(RpsL))
		screen.drawText(0,26,"RpsR "..tostring(RpsR))
		screen.drawText(0,32,"Pitch "..tostring(Pitch))
		screen.drawText(0,38,"AltHold "..tostring(AltHold))
		screen.drawText(0,44,"FuelMax "..tostring(FuelMax))
		screen.drawText(0,50,"Fuel "..tostring(Fuel))
		]]--
	end
	screen.drawLine(0,6,w,6)
	screen.setColor(0,255,0)
	for i = 1,4 do
		screen.drawLine(w/5*i,0,w/5*i,6)
	end
	for i = 0,4 do
		screen.drawRect(w/5*i,0,w/5,6)
	end
end