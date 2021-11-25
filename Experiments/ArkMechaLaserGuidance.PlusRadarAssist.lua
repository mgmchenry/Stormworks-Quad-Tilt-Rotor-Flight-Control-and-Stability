-- ArkMecha IR guidance
-- Radar added by mgm

xls = {0,0,0,0,0}
yls = {0,0,0,0,0}
avgs = {{},{},{},{},{},{},{},{}}
s=160
l=5
x,y,lz,ly,rDis  ,rx,ry,dDis,tDis=0,0,0,0,0  ,0,0,0,0
sqrt=math.sqrt
abs=math.abs

activeTimer=30
active=false
lock=false
radarLock=false
impact=false
impactMisfire=false
detonate=false
blinker=0
tickFuse=0

function mean(l)
	sum=0
	for i,n in pairs(l) do
		sum=sum+n
	end
	return sum/#l
end

function curve(n)
	if n~=0 then
		return sqrt(abs(n))*abs(n)/n
	else
		return 0
	end
end

function onTick()
	tSize = 5
	lx = input.getNumber(16)
	ly = input.getNumber(17)
	rDis = input.getNumber(1)
	rx = input.getNumber(2) * -1
	ry = input.getNumber(3)
	impact = input.getBool(3)
	
	if (input.getBool(1) or input.getBool(2)) and not active then
		activeTimer=activeTimer-1
	end
	if impact and not active then
		impactMisfire = true
	end
	
	lock=lx~=0
	radarLock=rx~=0
	x,y=lx,ly
	if radarLock and not lock then
		x=rx
		y=ry
	end
	aDis,dDis,pDis=0,0,0
	if tickFuse>0 then
		tickFuse=tickFuse-1 
	end
	samples=10 
	for i,v in ipairs({lx,ly,rx,ry,rDis,aDis,dDis,tDis}) do
		if i>3 then samples=40 end
		local count=#avgs[i]
		avgs[i][count+1]=v
		if count>samples then table.remove(avgs[i],1) end
	end
	if rDis==0 and #avgs[8]>5 then
		rDis=pDis+dDis
		avgs[5][#avgs[5]]=rDis
	end
	if rDis==0 then
		avgs[6] = {}
		avgs[7] = {}
		avgs[8] = {}
	else
		aDis=mean(avgs[5])
		avgs[6][#avgs[6]]=aDis
		if #avgs[6]<samples then
			avgs[7] = {}
		else
			dDis = (avgs[6][samples] - avgs[6][samples-1])
			avgs[7][#avgs[7]] = dDis
			dDis = mean(avgs[7])
			
			pDis=aDis + (dDis * samples / 2)
			tDis=math.max(0,pDis - tSize) / dDis * -1
			if dDis<0 and #avgs[7]>5 then
				avgs[8][#avgs[8]] = tDis
				tDis=mean(avgs[8])
				if #avgs[8]>5 and tDis<180 and (tickFuse>120 or tickFuse==0) then
					tickFuse=math.floor(tDis)
				end
			else
				avgs[8] = {}
			end
		end
	end
	if x==x and active then
		xa=mean(xls)
		ya=mean(yls)
		x2=curve(x) -- -curve((x-xa)*s)
		y2=curve(y) -- -curve((y-ya)*s)
		table.insert(xls,x)
		table.insert(yls,y)
		table.remove(xls,1)
		table.remove(yls,1)
	else
		active=activeTimer==0
		x2=0
		y2=0
	end
	output.setNumber(3,x)
	output.setNumber(4,y)
	output.setNumber(1,x2)
	output.setNumber(2,y2)
	blinker = blinker % 10 + 1
	output.setBool(1,lock or (radarLock and blinker>5))
	detonate = detonate
		or (active and not impactMisfire and impact) and "impact"
		or (active and rDis>0 and rDis < tSize) and "prox"
		or (active and tickFuse>0 and tickFuse < 5) and "fuse"

	output.setBool(2,detonate)
end

local sX,xY
function print2(text,number)
	number = type(number)=="number" and string.format("%0.3f",number) or tostring(number)
	screen.drawText(sX, sY, text .. number)
	sY = sY + 6				
end
function onDraw()
	sX,sY=3,7
	screen.setColor(0,0,0,255)
	screen.drawClear()
	screen.setColor(255,255,255)
	print2(
		(lock and "+LSR " or "")
		.. (radarLock and "+RDR " or "")
		, impactMisfire and "MISFIRE" or "")
	if tickFuse>0 then
		print2("tickfuse " .. tostring(tickFuse))
	end
	print2("lSR X:", mean(avgs[1]))
	print2("lSR Y:", mean(avgs[2]))
	print2("rdr X:", mean(avgs[3]))
	print2("rdr Y:", mean(avgs[4]))
	print2("dis: ", mean(avgs[5]))
	print2(detonate and ("kaboom: " .. detonate)
		or active and "active " or ("inactive " .. tostring(activeTimer))		
		, (impact and "+impact " or ""))
	--if tDis>0 then
		print2("s2t:", tDis/60)
	--end
	--if dDis<0 then
		print2("delta:", dDis)
		print2("pDis:", pDis)
	--end
end
