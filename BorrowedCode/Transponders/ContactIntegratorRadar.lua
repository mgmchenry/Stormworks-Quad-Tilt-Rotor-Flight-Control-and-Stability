--[[
Signal output module
]]

dM,dR=2,10
lostT,srs,trs=0,1,1
tm,twx,twy,twz,yaw=0,0,0,0,0,0
yawO={}
dtm,dtwx,dtwy,dtwz=0,0,0,0
dtcx,dtcy,dtcz=0,0,0
tsqz=0
TRm=0

inB=input.getBool
inN=input.getNumber
ouB=output.setBool
ouN=output.setNumber
m=math
pi=m.pi
pi2=2*pi
s=m.sin
c=m.cos
t=m.tan
as=m.asin
at=m.atan
abs=m.abs
f4="%4.0f"
sc=screen
drT=sc.drawText

function sgn(x)
	return x/abs(x)
end
function len2(x,y)
	return (x^2+y^2)^0.5
end
function len3(x,y,z)
	return (x^2+y^2+z^2)^0.5
end
function drTf(x,y,txt,fmt)
	return drawText(x,y,string.format(fmt,txt))
end
function angDif1(a,b)
	a,b=a*pi2,b*pi2
	return at(s(a-b),c(a-b))/pi2
end
function angFix(a)
	return (a+0.5)%1-0.5
end
function SphToRec(r,qx,qz)
	x=r*c(qx)*s(qz)
	y=r*c(qx)*c(qz)
	z=r*s(qx)
return x,y,z
end
function LocalToWorld(xl,yl,zl,qx,qy,qz,xlw,ylw,zlw)
	qx,qz=as(s(qx)/c(qy)),qz-at(t(qx)*t(qy))
	xw=xlw+c(qz)*c(qy)*xl-(s(qz)*c(qx)+c(qz)*s(qy)*s(qx))*yl+(s(qz)*s(qx)-c(qz)*s(qy)*c(qx))*zl
	yw=ylw+s(qz)*c(qy)*xl+(c(qz)*c(qx)-s(qz)*s(qy)*s(qx))*yl-(c(qz)*s(qx)+s(qz)*s(qy)*c(qx))*zl
	zw=zlw+s(qy)*xl+c(qy)*s(qx)*yl+c(qy)*c(qx)*zl
return xw,yw,zw
end
function CalcWrldCrd(sr,sqx,sqz,rqx,rqy,rqz,xlw,ylw,zlw)
	xl,yl,zl=SphToRec(sr,sqx,sqz)
	xw,yw,zw=LocalToWorld(xl,yl,zl,rqx,rqy,rqz,xlw,ylw,zlw)
return xw,yw,zw
end
function RecToSph(x,y,z)
	xy=len2(x,y)
	r=len2(xy,z)
	qx=at(z,xy)
	qz=at(x,y)
return r,qx,qz
end
function WorldToLocal(xw,yw,zw,qx,qy,qz,xlw,ylw,zlw)
	qx,qz=as(s(qx)/c(qy)),qz-at(t(qx)*t(qy))
	xr,yr,zr=xw-xlw,yw-ylw,zw-zlw
	xl=c(qz)*c(qy)*xr-s(qz)*c(qy)*yr+s(qy)*zr
	yl=(s(qz)*c(qx)+c(qz)*s(qy)*s(qx))*xr+(c(qz)*c(qx)-s(qz)*s(qy)*s(qx))*yr-c(qy)*s(qx)*zr
	zl=(s(qz)*s(qx)-c(qz)*s(qy)*c(qx))*xr+(c(qz)*s(qx)+s(qz)*s(qy)*c(qx))*yr+c(qy)*c(qx)*zr
return xl,yl,zl
end
function CalcLclCrd(xw,yw,zw,rqx,rqy,rqz,xlw,ylw,zlw)
	xl,yl,zl=WorldToLocal(xw,yw,zw,rqx,rqy,rqz,xlw,ylw,zlw)
	sr,sqx,sqz=RecToSph(xl,yl,zl)
	return sr,sqx,sqz,xl,yl,zl
end
function pnpn(x,xMax,dx,sign)
	x=x+sign*dx
	if abs(x)>xMax then
		x=sgn(x)*xMax
		sign=-sign
	end
	return x,sign
end
function RadYawS(yw)
	if rng==1 then
		yw=yw+rpt*1
	else
		yw,srs=pnpn(yw,rng/2,2*rpt*rng,srs)
	end
	return angFix(yw)
end
function RadYawT(yw,yw0)
	TRrng=at(10/tsr)/pi2+lostT/10*fov
	dyw=angDif1(yw,yw0)
	if abs(dyw)>TRrng then
		yw=yw0
	else
		dyw,trs=pnpn(dyw,TRrng,fov/2,trs)
		yw=dyw+yw0
	end
	return angFix(yw)
end
function tiltFix(q,v)
	return q-m.min(0,sgn(v))*(sgn(q)/2-2*q)
end

function onTick()
act=inB(1)
isSR,isTR=inB(2),inB(3)
table.insert(yawO,1,yaw)
yawO[5]=nil
if act and yawO[4]~=nil then
	owx,owy,owz=inN(1)+inN(7),inN(2)+inN(8),inN(3)+inN(9)
	com,elv,dst=inN(10)*pi2,inN(11)*pi2,inN(12)
	tm=dst*inN(13)
	vt=inN(6)
	pit,rol=tiltFix(inN(4),vt)*pi2,tiltFix(inN(5),vt)*pi2
	mR,mM=inN(18),inN(19)
	if dst>mR and tm>mM then
		twx,twy,twz=CalcWrldCrd(dst,elv,yawO[4]*pi2,pit,-rol,com,owx,owy,owz)
	else
		tm,twx,twy,twz=0,0,0,0
	end

	rps,dir,rng,fov=inN(21),inN(22),inN(23)/360,inN(24)
	rpt=rps/60

	TRm=inN(29)
	Msgn=1
	if isTR and TRm>0 then
		Msgn=-1
	end

	if Msgn==-1 and abs(TRm-tm)<dM and len3(TRwx-twx,TRwy-twy,TRwz-twz)<dR then
		TRwx,TRwy,TRwz=twx,twy,twz
		lostT=0
	else
		TRwx,TRwy,TRwz=inN(30),inN(31),inN(32)
		lostT=lostT+1
	end

	if TRm>0 and isTR then
		tsr,tsqx,tsqz,tcx,tcy,tcz=CalcLclCrd(TRwx,TRwy,TRwz,-pit,rol,-com,owx,owy,owz)
		tsqx,tsqz=tsqx/pi2,tsqz/pi2
		yaw=RadYawT(yaw,tsqz)
	elseif isSR then
		tcr,tcqx,tcqz=1,0,0
		yaw=RadYawS(yaw)
	end
else
	tm,Msgn,yaw=0,1,0
	srs,trs=1,1
end
ouN(1,tm*Msgn)
ouN(2,twx)
ouN(3,twy)
ouN(4,twz)
ouN(5,tsr)
ouN(6,tsqx)
ouN(7,tsqz)
ouN(11,yaw)
ouB(1,true)
ouB(2,isSR)
ouB(3,isTR)
end

function onDraw()
w=sc.getWidth()
h=sc.getHeight()
sc.setColor(0,255,0)
sc.drawLine(w/2,h/2,w/2+w*c((-yaw+1/4)*pi2),h/2-w*s((-yaw+1/4)*pi2))
drT(1,8,"tm  "..dtm)
drT(1,56,"twx "..dtwx)
drT(1,64,"twy "..dtwy)
drT(1,72,"twz "..dtwz)
drT(1,80,"lostt"..lostT)
if tm>10 then
	sc.setColor(255,0,0)
	drT(1,1,"detect")
	dtm,dtwx,dtwy,dtwz=tm,twx,twy,twz
end
if TRm>10 then
	dtcx,dtcy,dtcz=tcx,tcy,tcz
	drT(1,24,"tcx "..dtcx)
	drT(1,32,"tcy "..dtcy)
	drT(1,40,"tcz "..dtcz)
end
end

--[[
  map module
]]

tick=0
t,l,o={},{},{}
zoom,scr=1,0.1
Mmin=25
dM,dR=2,100
delT=450
tID,N=101,32
divNm,dq=6,10/360
divq=1/8
a,b=255,127
inB=input.getBool;inN=input.getNumber;ouB=output.setBool;ouN=output.setNumber
tI=table.insert;tR=table.remove
m=math
pi=m.pi
pi2=2*pi
s=m.sin
c=m.cos
as=m.asin
at=m.atan
abs=m.abs
sc=screen
sC=sc.setColor
drT=sc.drawText
drL=sc.drawLine
drC=sc.drawCircle
drCF=sc.drawCircleF
drTF=sc.drawTriangleF
MTS=map.mapToScreen

function len3(x,y,z)
	return (x^2+y^2+z^2)^0.5
end

function drA(x0,y0,r,q,qa,dN,fill)
	for j=-1,1,2 do
		dqi=j*qa/dN
		for i=1,dN/2 do
			qi1=q-dqi*i
			qi2=qi1+dqi
			x1,y1,x2,y2=x0+r*c(qi1),y0-r*s(qi1),x0+r*c(qi2),y0-r*s(qi2)
			if fill then
				drTF(x0,y0,x1,y1,x2,y2)
			else
				drL(x1,y1,x2,y2)
			end
		end
	end
end

function angDifp(a,b)
	return at(s(a-b),c(a-b))
end

function onTick()
	act,map,lcl,orth=inB(1),inB(6),inB(7),inB(8)
	if map then
		yaw=inN(14)*pi2
		o.x,o.y,o.z,o.com=inN(1)+inN(7),inN(2)+inN(8),inN(3)+inN(9),inN(10)*pi2
		rng,fov,dRng=inN(23)/360,inN(24),inN(20)
		dr,cm=inB(4),inB(5)
	end
end

function onDraw()
w=sc.getWidth()
h=sc.getHeight()
w=w-1

	if map then
		if lcl then
			if orth then
				scw,sch,lxo,lyo=w/(rng*pi2),h/dRng,w/2,h
				lr,lq0=dRng*sch,0;lq=lq0-yaw
			else
				if rng>0.5 then
					scr,lxo,lyo=m.min(w,h)/(2*dRng),w/2,h/2
				else
					scr,lxo,lyo=m.min(h/dRng,w/(2*dRng*s(rng*pi))),w/2,h
				end
				lr,lq0=dRng*scr,pi/2;lq=lq0-yaw
			end
		else
			scr,lxo,lyo=m.min(w,h)/(2*dRng),w/2,h/2
			zoom=w/scr/10^3
			sc.setMapColorLand(70,70,70);sc.setMapColorGrass(25,40,25);sc.drawMap(o.x,o.y,zoom)
			lr,lq0=dRng*scr,pi/2+o.com;lq=lq0-yaw
		end

		sC(63,a,63,b)
		if rng>divq then
			dlq=divq*pi2
			for i=1,rng/2/divq do
			for j=-1,1,2 do
				lqi=lq0-j*i*dlq
				if orth then
					lqi=lqi*scw+lxo
					drL(lqi,0,lqi,lyo)
				elseif not (rng==1 and i==rng/2/divq and j==1) then
					drL(lxo,lyo,lxo+lr*c(lqi),lyo-lr*s(lqi))
				end
			end
			end
		end
		if orth then
			drL(0,h/2,w,h/2)
			sC(63,a,63,195);drL(lxo,0,lxo,lyo)
		else
			divN=m.ceil(m.ceil(m.max(divNm,rng/dq))/2)*2
			drL(lxo,lyo,lxo+lr*c(lq0),lyo-lr*s(lq0))
			drA(lxo,lyo,lr/2,lq0,rng*pi2,divN,false)
		end

		sC(31,a,31,b)
		if act then
			if orth then
				for j=-1,1 do
					lxl,lxw=lxo+(-lq+j*pi2-fov*pi)*scw,fov*pi2*scw
					sc.drawRectF(lxl,0,lxw,lyo)
				end
			else
				drA(lxo,lyo,lr,lq,fov*pi2,6,true)
			end
		end

		sC(0,a,0)
		if orth then
			sc.drawRect(0,0,w-0,h-1)
		else
			drA(lxo,lyo,lr,lq0,rng*pi2,divN,false)
			if rng<1 then
				for j=-1,1,2 do
					lqe=lq0-j*rng*pi
					drL(lxo,lyo,lxo+lr*c(lqe),lyo-lr*s(lqe))
				end
			end
		end

		if lcl and cm then
			for i=-1,1,2 do
				if orth then
					if i==1 then sC(15,15,a,b) else sC(a,15,15,b) end
					cq=angDifp(o.com+i*pi/2+pi/2,0)*scw
					drL(lxo+cq,1,lxo+cq,lyo-1)
				else
					if i==1 then sC(15,15,a) else sC(a,15,15) end
					cq=-o.com-i*pi/2
					tq=pi/32
					drTF(lxo+(lr-2)*c(cq),lyo-(lr-2)*s(cq),lxo+(lr+2)*c(cq+tq),lyo-(lr+2)*s(cq+tq),lxo+(lr+2)*c(cq-tq),lyo-(lr+2)*s(cq-tq))
				end
			end
		end
	end
end

--[[
  Target display module
]]
tick=0
t,l,o={},{},{}
zoom,scr=1,0.1
Mmin=25
dM,dR=2,100
delT=450
tID,N=101,32
divNm,dq=6,10/360
divq=1/8
a,b=255,127
inB=input.getBool;inN=input.getNumber;ouB=output.setBool;ouN=output.setNumber
tI=table.insert;tR=table.remove
m=math
pi=m.pi
pi2=2*pi
s=m.sin
c=m.cos
as=m.asin
at=m.atan
abs=m.abs
sc=screen
sC=sc.setColor
drT=sc.drawText
drL=sc.drawLine
drC=sc.drawCircle
drCF=sc.drawCircleF
MTS=map.mapToScreen

function len3(x,y,z)
	return (x^2+y^2+z^2)^0.5
end

function reg()
	p=0;ow=false
	t.m=abs(t.m)
	if #l==0 then
		p=1
	elseif #l<N or t.m-l[#l].m>-dM then
		for j=1,#l do
			dmi=t.m-l[j].m
			if abs(dmi)<=dM and len3(t.x-l[j].x,t.y-l[j].y,t.z-l[j].z)<dR then
				p=j;ow=true;break
			elseif dmi>dM then
				p=j;break
			elseif j==#l and #l<N then
				p=j+1;break
			end
		end
	end
	if p>0 then
		if ow then
			if t.t-l[p].t>3 then
				XO,YO,ZO,TO=l[p].x,l[p].y,l[p].z,l[p].t
			else
			XO,YO,ZO,TO=l[p].xO,l[p].yO,l[p].zO,l[p].tO
			end
			N,V=l[p].n,l[p].v
			tR(l,p)
		else
			N,V,XO,YO,ZO,TO=tID,nil,nil,nil,nil,nil
			tID=tID+1
		end
		tI(l,p,{m=t.m,x=t.x,y=t.y,z=t.z,t=t.t,n=N,v=V,xO=XO,yO=YO,zO=ZO,tO=TO})
		if #l>N then
		tR(l,#l)
		end
	end
end
function angDifp(a,b)
	return at(s(a-b),c(a-b))
end

function drA(x0,y0,r,q,qa,dN,fill)
	for j=-1,1,2 do
		dqi=j*qa/dN
		for i=1,dN/2 do
			qi1=q-dqi*i
			qi2=qi1+dqi
			x1,y1,x2,y2=x0+r*c(qi1),y0-r*s(qi1),x0+r*c(qi2),y0-r*s(qi2)
			if fill then
				sc.drawTriangleF(x0,y0,x1,y1,x2,y2)
			else
				drL(x1,y1,x2,y2)
			end
		end
	end
end

function onTick()
	act,map,lcl,orth=inB(1),inB(6),inB(7),inB(8)
	if map then
		yaw=inN(14)*pi2
		o.x,o.y,o.z,o.com=inN(1)+inN(7),inN(2)+inN(8),inN(3)+inN(9),inN(10)*pi2
		rng,fov,dRng=inN(23)/360,inN(24),inN(20)
		dr,cm=inB(4),inB(5)
	end
	if act and map then
		t.m,t.x,t.y,t.z,t.t=inN(25),inN(26),inN(27),inN(28),tick
		if abs(t.m)>=Mmin then
			reg()
		end
		if #l>0 then
			for j=1,#l do
				if l[j]~=nil and tick-l[j].t>delT then
					for k=j,#l-1 do
						l[k]=l[k+1]
					end
					tR(l,#l)
				end
			end
		end
		tick=tick+1
	else
		tick=0
	end
end

function onDraw()
w=sc.getWidth()
h=sc.getHeight()

	if map then
		if lcl then
			if orth then
				scw,sch,lxo,lyo=w/(rng*pi2),h/dRng,w/2,h
				lr,lq=dRng*sch,rng*scw
			else
				if rng>0.5 then
					scr,lxo,lyo=m.min(w,h)/(2*dRng),w/2,h/2
				else
					scr,lxo,lyo=m.min(h/dRng,w/(2*dRng*s(rng*pi))),w/2,h
				end
				lr,lq=dRng*scr,pi/2-yaw
			end
		else
			scr,lxo,lyo=m.min(w,h)/(2*dRng),w/2,h/2
			zoom=w/scr/10^3
			lr,lq=dRng*scr,pi/2+o.com-yaw
		end

sC(a,a,a,b)
		if dr then drT(2,2,"R"..string.format("%d",dRng)) end

sC(0,a,0)
		if act and #l>0 then
			for j=1,#l do
				dwx,dwy=l[j].x-o.x,l[j].y-o.y
				R2,Q=len3(dwx,dwy,0),angDifp(at(dwy,dwx),pi/2+o.com)
				if R2<dRng then
					if lcl and orth then
						mr,mq=R2*sch,-Q*scw
						mx,my=w/2+mq,h-mr
					elseif lcl then
						mr,mq=R2*scr,Q+pi/2
						mx,my=lxo+mr*c(mq),lyo-mr*s(mq)
					else
						mx,my=MTS(o.x,o.y,zoom,w,h,l[j].x,l[j].y)
					end
					sC(0,a,0,delT-(tick-l[j].t));drCF(mx,my,0.7)
				end
			end
		end
	end
end

