h0 = 3/4 --hud size in meters
d0 = 1/4 --#distance from tip of pilot seat to hud
d0 = d0+0.375
pi2 = 2*math.pi
gps,trg,tt,pp,ss,cc,rr,dd = {},{},{},{},{},{},{},{}

function clamp(a,b,c) return math.min(math.max(a,b),c) end

function getN(...)
	local r={}
	for i,v in ipairs({...}) do r[i]=input.getNumber(v) or 0 end
	return table.unpack(r)
end

function worldToScreen(...) --x,y,z
	if gps.x == nil then return 0,0,0 end
	tt.x,tt.y,tt.z = ...

	a1 = tr/math.cos(pi2*tf)
	rr.y = pi2*(tu<0 and (1.5+a1)%1 or (1-a1)%1)
	rr.x = pi2*tf
	rr.z = pi2*cp

	for k,v in pairs(rr) do
		pp[k] = tt[k]-gps[k]
		cc[k] = math.cos(v)
		ss[k] = math.sin(v)
	end	
	a2=(cc.y*pp.z+ss.y*(ss.z*pp.y+cc.z*pp.x))
	a3=(cc.z*pp.y-ss.z*pp.x)
	dd.x = cc.y*(ss.z*pp.y+cc.z*pp.x)-ss.y*pp.z
	dd.y = ss.x*a2+cc.x*a3
	dd.z = cc.x*a2-ss.x*a3
	px = w/2+w*((d0/dd.y)*(dd.x/h0))
	py = h/2-h*((d0/dd.y)*(dd.z/h0))
	return px,py,dd.y
end

function onTick()
	gps.x,gps.y,gps.z, trg.x,trg.y,trg.z, cp,tf,tu,tr = getN(11,12,13, 14,15,16, 17,18,19,20)
end

function onDraw()
	screen.setColor(0, 0, 0,255)
	screen.drawClear()
	w = screen.getWidth()
	h = screen.getHeight()
	cx = w/2
	cy = h/2

	if (trg.x~=0 or trg.y~=0 or trg.z~=0) then
		x,y,z = worldToScreen(trg.x,trg.y,trg.z)
		screen.setColor(0,255,0)
		x,y = math.floor(x+0.5),math.floor(y+0.5)
		if z>0 and x>0 and x<w and y>0 and y<h then
			s = clamp((d0/z)*50,3,50)
			screen.drawLine(x-1,y,x-s,y)
			screen.drawLine(x+1,y,x+s,y)
			screen.drawLine(x,y+1,x,y+s)
			screen.drawLine(x,y-1,x,y-s)
		else
			if z<0 then
				x=cx-x
				y=cy-y
			end
			tx = clamp(x,0,w)
			ty = clamp(y,0,h)
			r = math.atan(x-cx,y-cy)
			r1 = r+pi2/12
			r2 = r-pi2/12
			screen.drawTriangleF(tx,ty, tx-8*math.sin(r1), ty-8*math.cos(r1), tx-8*math.sin(r2), ty-8*math.cos(r2))
		end
	end
end


--[[
Lidar version:

]]

h0 = 3/4 --hud size in meters
d0 = 1/4 --#distance from tip of pilot seat to hud
d0 = d0+0.375
pi2 = 2*math.pi
gps,obj,tt,pp,ss,cc,rr,dd = {},{},{},{},{},{},{},{}
tick = 0
lo = math.floor
hi = math.ceil
id = 1
clamp = function(x1,x2,x3) return math.min(math.max(x1,x2),x3) end
points = {}
p1 = {x=0,y=0,z=0}
x1,y1 = 0,0

function getN(...)
	local r={}
	for i,v in ipairs({...}) do r[i]=input.getNumber(v) end
	return table.unpack(r)
end

function worldToScreen(...) --x,y,z
	if gps.x == nil then return 0,0,0 end
	tt.x,tt.y,tt.z = ...

	a1 = tr/math.cos(pi2*tf)
	rr.y = pi2*(tu<0 and (1.5+a1)%1 or (1-a1)%1)
	rr.x = pi2*tf
	rr.z = pi2*cp

	for k,v in pairs(rr) do
		pp[k] = tt[k]-gps[k]
		cc[k] = math.cos(v)
		ss[k] = math.sin(v)
	end	
	a2=(cc.y*pp.z+ss.y*(ss.z*pp.y+cc.z*pp.x))
	a3=(cc.z*pp.y-ss.z*pp.x)
	dd.x = cc.y*(ss.z*pp.y+cc.z*pp.x)-ss.y*pp.z
	dd.y = ss.x*a2+cc.x*a3
	dd.z = cc.x*a2-ss.x*a3
	px = w/2+w*((d0/dd.y)*(dd.x/h0))
	py = h/2-h*((d0/dd.y)*(dd.z/h0))
	return px,py,dd.y
end

function onTick()
	gps.x,gps.y,gps.z, cp,tf,tu,tr = getN(11,12,13, 17,18,19,20)
	
	tick = tick>=5 and 0 or tick+1
	--if tick==0 then

	local p = {}
	--dir = cp -dir
	p.x,p.y,p.z = getN(21,22,23)
	if p.x~=0 and p.y~=0 and p.z~=0 then
		if math.sqrt( (p.x-p1.x)^2 + (p.y-p1.y)^2 + (p.z-p1.z)^2 ) > 2 then
			points[id] = p
			p1 = p
			id = id>10000 and 1 or id+1
		end
	end

end

function onDraw()
	screen.setColor(0, 0, 0,255)
	screen.drawClear()
	w = screen.getWidth()
	h = screen.getHeight()

	-- draw saved
	for i,v in ipairs(points) do
		x,y,z = worldToScreen(v.x,v.y,v.z)
		dz = (v.z-gps.z)/25*255
		if z>0 then
			dis = math.sqrt( (x1-x)^2 + (y1-y)^2 )
			if dis > 2 then
				x1,y1 = x,y
				if dz>0 then
					screen.setColor(0,50-clamp(dz,0,50),clamp(dz,50,255),clamp((d0/z)*(255/h0),35,255))
				else
					screen.setColor(clamp(-dz,0,255),clamp(dz/-2,0,255),0,clamp((d0/z)*(255/h0),35,255))
				end
				screen.drawCircleF(x,y,clamp((d0/z)*20,0.6,75))
			end
		end
	end
end