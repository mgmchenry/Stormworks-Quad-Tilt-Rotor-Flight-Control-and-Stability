p,s,i,o=property,screen,input,output
gb,gn,sb,sn,pgb,pgn,pgt = i.getBool,i.getNumber,o.setBool,o.setNumber,p.getBool,p.getNumber,p.getText
drf,dt,dcf,dtf,sc=s.drawRectF,s.drawText,s.drawCircleF,s.drawTriangleF,s.setColor
_TYPES = {'Helicopter','L Plane','S Plane','Boat','M Ship','L Ship','Car','Truck','Building','Hidden','Other'}
_ROLES = {'Military','Civilian','Firefight','Police','Tourism','Medical','Hidden','Other'}
_TYPES[0],_ROLES[0] = 'Unknow','Unknow'

_PDT = pgn('Pulse Delay Tick')
PDT=_PDT

_VN = string.format('%-10.10s',pgt('Name'))
_VT = pgn('Type')
_VR = pgn('Role')

TICK = 0

VEH = {}

SD=pgb('Default')
VX,VY,VA,ID=0,0,0,0
DISP = nil
SX,SY,ZOOM = 0,0,4
CLICK,IP,IX,IY=false,false,0,0

function click(rX, rY, rW, rH) return IX > rX and IY > rY and IX < rX+rW and IY < rY+rH end

function onTick()
	TICK = TICK + 1
	if TICK < 10 then
	PDT=_PDT+gn(10)
	ID=gn(11)
	else
	
	PDT = PDT - 1

	W,H = gn(1),gn(2)
	oip=IP
	IP,IX,IY = gb(1),gn(3),gn(4)
	if not IP then IP,IX,IY = gb(2),gn(5),gn(6) end
	CLICK = IP and (not oip)

	VX,VY,VA = gn(7),gn(8),gn(9)
	
	VEH[ID]={TICK,VX,VY,VA,_VT,-1,_VN}
	
	if 0 < PDT and PDT <= _PDT then --R
		if gb(3) then
			n=string.char(gn(21),gn(22),gn(23),gn(24),gn(25),gn(26),gn(27),gn(28),gn(29),gn(30))
			VEH[gn(17)]={TICK,gn(18),gn(19),gn(20),gn(31),gn(32),n}
		end
	elseif -10 < PDT and PDT <= 0 and SD then --W
		sb(3, true)
		sn(17,ID)
		sn(18,VX)
		sn(19,VY)
		sn(20,VA)
		sn(31,_VT)
		sn(32,_VR)
		ascii = {string.byte(_VN,1,-1)}
		for i=1,10 do
			sn(20+i,ascii[i])
		end
	elseif PDT <= -10 then --RST
		sb(3, false)
		PDT = _PDT+5
	end
	
	if CLICK then
		if not (DISP == nil) then
			DISP = nil
		elseif click(1,1,6,7) then
			OIX=1
			if ZOOM > 0.125 then ZOOM = ZOOM / 2 end
		elseif click(1,9,6,7) then
			OIX=-1
			if ZOOM < 48 then ZOOM = ZOOM * 2 end
		elseif click(1,17,6,7) then SX,SY=0,0
		elseif click(W-7,1,6,7) then SD=not SD
		else
			x,y=map.screenToMap(VX+SX,VY+SY, ZOOM, W,H, IX, IY)
			SX,SY=x-VX,y-VY
			-- LF clkd veh
			for i,data in pairs(VEH) do
				vx,vy=map.mapToScreen(VX+SX,VY+SY, ZOOM, W,H, data[2], data[3])
				vx,vy=vx-W/2,vy-H/2
				if (vx*vx+vy*vy < 25) then
					DISP=i
					break
				end
			end
		end		
	end	
	end
end

function onDraw()
	w = screen.getWidth()
	h = screen.getHeight()
	w2,h2 = w/2,h/2
	
	screen.drawMap(VX+SX,VY+SY,ZOOM)
	
	for i,data in pairs(VEH) do
		d,x,y,a,t,rl,name=data[1],data[2],data[3],data[4],data[5],data[6],data[7]
		px,py=map.mapToScreen(VX+SX,VY+SY, ZOOM, w, h, x, y)
		r,g,b=0,0,0
	
		if rl==-1 then r,g,b=255,255,0
		elseif rl==1 then r,g,b=64,255,16
		elseif rl==2 then r,g,b=64,128,255
		elseif rl==3 then r,g,b=128,0,0
		elseif rl==4 then r,g,b=0,0,128
		elseif rl==5 then r,g,b=0,196,255
		elseif rl==6 then r,g,b=196,196,196
		elseif rl==7 then r,g,b=32,32,32
		elseif rl==8 then r,g,b=255,128,0
		end
		sc(r,g,b)

		if t==1 then dcf(px,py,2.5)
		elseif t==2 then 
			dtf(px-3,py+3,px+3,py+3,px,py-3)
			drf(px-5,py-1,10,2)
		elseif t==3 then dtf(px-3,py+3,px+3,py+3,px,py-3)	
		elseif t==4 then dtf(px-3,py-2,px+3,py-2,px,py+2)
		elseif t==5 then dtf(px-4,py-2,px+4,py-2,px,py+2)
		elseif t==6 then 
			dtf(px-4,py-2,px+4,py-2,px,py+2)
			drf(px-2,py-4,4,2)
		elseif t==7 then drf(px-3,py-2,6,3)
		elseif t==8 then 
			drf(px-3,py-2,6,3)
			drf(px-1,py-4,4,3)
		elseif t==9 then drf(px-2,py-3,4,6)
		elseif t==10 then dt(px-4,py-2,'[]')
		elseif t==11 then dt(px-2,py-2,'#')
		else dt(px-2,py-2,'?')
		end
	end
	
	sc(64, 64, 64)
	drf(1,1,6,7)
	drf(1,9,6,7)
	drf(1,17,6,7)
	drf(w-7,1,6,7)
	sc(196, 196, 196)
	dt(2,2,'+')
	dt(2,10,'-')
	dt(2,18,'c')
	
	if -10 < PDT and PDT <= 0 and SD then sc(255, 255, 0)
	elseif SD then sc(0,128,0)
	else sc(128,0,0)
	end
	dt(w-6,2,'!')
	if not (DISP == nil) then
		data=VEH[DISP]
		sc(128,128,128)
		drf(0,0,54,64)
		sc(64,64,64)
		drf(1,1,52,7)
		sc(0,0,0)
		dt(2,2,data[7])
		t=TICK-data[1]
		m=t//3600
		s=(t-m*3600)//60
		dt(2,9,'t:'..m ..':'..s)
		dt(2,15,'a:'..(data[4]//1)..'m')
		if data[6]==-1 then dt(2,21,_ROLES[_VR]) else dt(2,21,_ROLES[data[6]]) end
		dt(2,27,_TYPES[data[5]])
	end
end

--[[
  Puipuix Rotatable Font:
]]
function onTick() end

function onDraw()
	screen.setColor(255,255,255)
	dst(1,1,"Resizable",2,1)
	dst(85,1,"Rotatable",2,2)
	dst(1,15,"Custom",3,1)
	dst(1,37,"Font!",4.5,1)
	dst(1,62,"!\"#$%&'()*+,-./")
	dst(1,69,"0123456789:;<=>?")
	dst(1,76,"@ABCDEFGHIJKLMNO")
	dst(1,83,"PQRSTUVWXYZ[\\]^_")
	--dst(x,y,text,size=1,rotation=1,is_monospace=false)
	--rotation can be between 1 and 4
end

-- Needed function below

drf=screen.drawRectF
pgt=property.getText

FONT=pgt("FONT1")..pgt("FONT2")
FONT_D={}
FONT_S=0
for n in FONT:gmatch("....")do FONT_D[FONT_S+1]=tonumber(n,16)FONT_S=FONT_S+1 end
function dst(x,y,t,s,r,m)s=s or 1
r=r or 1
if r>2then t=t:reverse()end
t=t:upper()for c in t:gmatch(".")do
ci=c:byte()-31if 0<ci and ci<=FONT_S then
for i=1,15 do
if r>2 then p=2^i else p=2^(16-i)end
if FONT_D[ci]&p==p then
xx,yy=((i-1)%3)*s,((i-1)//3)*s
if r%2==1then drf(x+xx,y+yy,s,s)else drf(x+5-yy,y+xx,s,s)end
end
end
if FONT_D[ci]&1==1 and not m then
i=2*s
else
i=4*s
end
if r%2==1then x=x+i else y=y+i end
end
end
end