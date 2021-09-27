f1=false
tick=0
Mmin=101
dM,dR=2,100
calT,delT=60,600
SlID,tID=0,101
N=8
a,b=255,127
TrID={}
Pr,PrO={},{}
t={}
c={}
o={}
inB=input.getBool;inN=input.getNumber;ouB=output.setBool;ouN=output.setNumber
tI=table.insert;tR=table.remove
m=math
pi=m.pi
pi2=2*pi
s=m.sin
abs=m.abs
sc=screen
sC=sc.setColor
drT=sc.drawText
drR=sc.drawRect
drRF=sc.drawRectF
form=string.format

function len3(x,y,z)
	return (x^2+y^2+z^2)^0.5
end
function del(tp)
	for k,v in pairs(ctb) do
		tR(v,tp)
	end
end
function reg(l)
	p=0;ow=false
	t[l].m=abs(t[l].m)
	if #c==0 then
		p=1
	elseif #c<N or t[l].m-c[#c].m>-dM then
		for j=1,#c do
			dmi=t[l].m-c[j].m
			if abs(dmi)<=dM and len3(t[l].x-c[j].x,t[l].y-c[j].y,t[l].z-c[j].z)<dR then
				p=j;ow=true;break
			elseif dmi>dM then
				p=j;break
			elseif j==#c and #c<N then
				p=j+1;break
			end
		end
	end
	if p>0 then
		if ow then
			if t[l].t-c[p].t>3 then
				XO,YO,ZO,TO=c[p].x,c[p].y,c[p].z,c[p].t
			else
			XO,YO,ZO,TO=c[p].xO,c[p].yO,c[p].zO,c[p].tO
			end
			N,V=c[p].n,c[p].v
			tR(c,p)
		else
			N,V,XO,YO,ZO,TO=tID,nil,nil,nil,nil,nil
			tID=tID+1
		end
		tI(c,p,{m=t[l].m,x=t[l].x,y=t[l].y,z=t[l].z,t=t[l].t,n=N,v=V,xO=XO,yO=YO,zO=ZO,tO=TO})
		if #c>N then
		tR(c,#c)
		end
	end
end

function RPr(pr,px,py,rX,rY,rW,rH)
	return pr and px>rX and py>rY and px<rX+rW and py<rY+rH
end

function onTick()
	isPr,xPr,yPr=inB(32),inN(31),inN(32)
	o.x,o.y,o.z,o.com=inN(25),inN(26),inN(27),inN(28)
	for i=1,6 do
		t[i]={con=inB(4*i-3)}
		if t[i].con then
			t[i]={con=t[i].con,isSR=inB(4*i-2),isTR=inB(4*i-1),TRout=inB(24+i),m=inN(4*i-3),x=inN(4*i-2),y=inN(4*i-1),z=inN(4*i),t=tick}
			if t[i].m>Mmin then
				reg(i)
			end
		end
	end
	for i=1,6 do
		if t[i].con and t[i].m<-Mmin then
			reg(i)
		end
	end
	if tick%calT==0 then
		for j=1,#c do
			if c[j].tO==nil then
				c[j].v=0
			else
				c[j].v=6^3*len3(c[j].x-c[j].xO,c[j].y-c[j].yO,c[j].z-c[j].zO)/(c[j].t-c[j].tO)
			end
		end
	end
	if #c>0 then
		for j=1,#c do
			if c[j]~=nil and tick-c[j].t>delT then
				for i=1,6 do
					if c[j].n==TrID[i] then
						TrID[i]=0
					end
				end
				for k=j,#c-1 do
					c[k]=c[k+1]
				end
				tR(c,#c)
			end
		end
	end
	tick=tick+1

	for i=1,6 do
		if TrID[i]==nil then TrID[i]=0 end
		if TrID[i]~=0 then
			for j=1,#c do
				if c[j].n==TrID[i] then
					sendi=j
				end
			end
			ouN(4*i-3,c[sendi].m);ouN(4*i-2,c[sendi].x);ouN(4*i-1,c[sendi].y);ouN(4*i,c[sendi].z)
		else
			ouN(4*i-3,0)
		end
	end
end

function onDraw()
w=sc.getWidth()
h=sc.getHeight()
sC(7,7,7);sc.drawClear()
sC(15,15,15);drRF(16,0,25,72);drRF(61,0,25,72)
for k=1,4 do sC(63,63,63,b);drRF(0,16*k-8,w,8) end

	sC(a,a,a);drT(1,2," ID  DST SPD Lost T")
	if #c>0 then
		for j=1,#c do
			j8=j*8
			PrO[j]=Pr[j]
			Pr[j]=RPr(isPr,xPr,yPr,0,j8,87,8)
			if Pr[j] and not PrO[j] then
				if SlID==0 then SlID=c[j].n else SlID=0 end
			end
			if c[j].n==SlID then
				sC(a,b,0);drR(0,j8,w-1,8)
			end
			sC(a,a,a);drT(1,8*j+2,form("%3d",c[j].n)..form("%5.0f",len3(o.x-c[j].x,o.y-c[j].y,o.z-c[j].z)).."     "..form("%4.0f",tick-c[j].t))
			if c[j].v~=nil then
				drT(41,j8+2,form("%4.0f",c[j].v))
			end
			for i=1,6 do
				sC(a,a,a)
				if c[j].n==TrID[i] then
					if t[i].isSR then
						drT(91,j8+2,i)
					else
						drT(91,j8+2,i)
					end
					sC(a,0,0,15)
					break
				end
				sC(0,a,0,15)
			end
			drRF(0,j8,w,8)
		end
	end 

	for i=1,6 do
		xi,yi=24*((i+2)%3),h-9-10*m.floor((i-1)/3)
		if t[i].con then
			if t[i].isTR then
				if t[i].isSR then RTyp="STR"..i
				else RTyp=" TR"..i
				end
			else
				if t[i].isSR then RTyp=" SR"..i
				else RTyp="RCU"..i
				end
			end
		else
			RTyp="----"
		end
		if t[i].isTR and t[i].TRout then
			if SlID~=0 and TrID[i]==0 and RPr(isPr,xPr,yPr,xi,yi-2,22,8) then
				TrID[i]=SlID
				SlID=0
			end
			if SlID==TrID[i] and TrID[i]~=0 then
				sC(a,a,a)
				drR(72,h-21,22,18)
				drT(74,h-17,"STOP\nTRCK")
				if RPr(isPr,xPr,yPr,72,h-21,22,18) then
					TrID[i]=0
					SlID=0
				end
			end
			sC(7,7,7)
		else
			sC(31,31,31)
		end
		drRF(xi,yi-2,22,8)
		sC(a,a,a);drR(xi,yi-2,22,8);drT(xi+2,yi,RTyp)
	end
end

--[[
  Map module
]]

dx,dy,zoom,z0,zInc=0,0,5,5,0.05
IO=false

tick=0
Mmin=101
dM,dR=2,100
calT,delT=60,600
SlID,tID=0,101
N=8
a,b=255,127
t={}
c={}
o={}
inB=input.getBool;inN=input.getNumber;ouB=output.setBool;ouN=output.setNumber
tI=table.insert;tR=table.remove
m=math
pi=m.pi
pi2=2*pi
s=m.sin
--c=m.cos
at=m.atan
abs=m.abs
sc=screen
sC=sc.setColor
drT=sc.drawText
drR=sc.drawRect
drRF=sc.drawRectF
drCF=sc.drawCircleF
form=string.format
MTS=map.mapToScreen

function len3(x,y,z)
	return (x^2+y^2+z^2)^0.5
end
function del(tp)
	for k,v in pairs(ctb) do
		tR(v,tp)
	end
end
function reg(l)
	p=0;ow=false
	t[l].m=abs(t[l].m)
	if #c==0 then
		p=1
	elseif #c<N or t[l].m-c[#c].m>-dM then
		for j=1,#c do
			dmi=t[l].m-c[j].m
			if abs(dmi)<=dM and len3(t[l].x-c[j].x,t[l].y-c[j].y,t[l].z-c[j].z)<dR then
				p=j;ow=true;break
			elseif dmi>dM then
				p=j;break
			elseif j==#c and #c<N then
				p=j+1;break
			end
		end
	end
	if p>0 then
		if ow then
			if t[l].t-c[p].t>3 then
				XO,YO,ZO,TO=c[p].x,c[p].y,c[p].z,c[p].t
			else
			XO,YO,ZO,TO=c[p].xO,c[p].yO,c[p].zO,c[p].tO
			end
			N,V=c[p].n,c[p].v
			tR(c,p)
		else
			N,V,XO,YO,ZO,TO=tID,nil,nil,nil,nil,nil
			tID=tID+1
		end
		tI(c,p,{m=t[l].m,x=t[l].x,y=t[l].y,z=t[l].z,t=t[l].t,n=N,v=V,xO=XO,yO=YO,zO=ZO,tO=TO})
		if #c>N then
		tR(c,#c)
		end
	end
end

function RPr(pr,px,py,rX,rY,rW,rH)
	return pr and px>rX and py>rY and px<rX+rW and py<rY+rH
end
function BPr(tbl,pr,px,py,rX,rY,rW,rH)
	sC(0,0,0,b);drRF(rX,rY,rW,rH)
	sC(b,b,b);drR(rX,rY,rW,rH)
	drT(rX+3,rY+2,tbl.l)
	if RPr(pr,px,py,rX,rY,rW,rH) then
		tbl.pr=true
	else
		tbl.pr=false
	end
end
function onTick()
	isPr,xPr,yPr=inB(31),inN(29),inN(30)
	o.x,o.y,o.z,o.com=inN(25),inN(26),inN(27),inN(28)
	for i=1,6 do
		t[i]={con=inB(4*i-3)}
		if t[i].con then
			t[i]={con=t[i].con,isSR=inB(4*i-2),isTR=inB(4*i-1),TRout=inB(24+i),m=inN(4*i-3),x=inN(4*i-2),y=inN(4*i-1),z=inN(4*i),t=tick}
			if t[i].m>Mmin then
				reg(i)
			end
		end
	end
	for i=1,6 do
		if t[i].con and t[i].m<-Mmin then
			reg(i)
		end
	end
	if tick%calT==0 then
		for j=1,#c do
			if c[j].tO==nil then
				c[j].v=0
			else
				c[j].v=6^3*len3(c[j].x-c[j].xO,c[j].y-c[j].yO,c[j].z-c[j].zO)/(c[j].t-c[j].tO)
			end
		end
	end
	if #c>0 then
		for j=1,#c do
			if c[j]~=nil and tick-c[j].t>delT then
				for k=j,#c-1 do
					c[k]=c[k+1]
				end
				tR(c,#c)
			end
		end
	end
	tick=tick+1
end

function onDraw()
w=sc.getWidth()
h=sc.getHeight()
P={x=w-12,y=h-20,r=9,l="+"};M={x=w-12,y=h-11,r=9,l="-"};I={x=w-12,y=3,r=9,l="I"}
U={x=3,y=h-29,r=9,l="^"};D={x=3,y=h-20,r=9,l=","};L={x=12,y=h-11,r=9,l="<"};R={x=21,y=h-11,r=9,l=">"};Re={x=3,y=h-11,r=9,l="R"}
BT={P,M,I,U,D,L,R,Re}
sc.setMapColorLand(70,70,70)
sc.setMapColorGrass(25,40,25)
sc.drawMap(o.x+dx,o.y+dy,zoom)

for q,v in pairs(BT) do
	BPr(v,isPr,xPr,yPr,v.x,v.y,v.r,v.r)
end
if P.pr then zoom=zoom-zoom*zInc end
if M.pr then zoom=zoom+zoom*zInc end
if U.pr then dy=dy+zoom*10 end
if D.pr then dy=dy-zoom*10 end
if L.pr then dx=dx-zoom*10 end
if R.pr then dx=dx+zoom*10 end
if Re.pr then dx=0;dy=0;zoom=z0 end
if I.pr and not IO then dispI=not dispI end
IO=I.pr

sC(a,0,0)
omx,omy=MTS(o.x+dx,o.y+dy,zoom,w,h,o.x,o.y)
drCF(omx,omy,1.5)

sC(0,0,a)
for j=1,#c do
	cmx,cmy=MTS(o.x+dx,o.y+dy,zoom,w,h,c[j].x,c[j].y)
	drCF(cmx,cmy,0.7)
	iq=at(cmy-h/2,cmx-w/2)
	ix,iy=cmx+5,cmy-5
	drT(ix,iy,"ID "..form("%3d",c[j].n))
	if dispI then
		drT(ix,iy,"       R "..form("%-5.0f",len3(o.x-c[j].x,o.y-c[j].y,o.z-c[j].z)))
		drT(ix,iy+6,"Z "..form("%-4.0f",c[j].z))
		if c[j].v~=nil then
		drT(ix+35,iy+6,"V "..form("%-3.0f",c[j].v))
		end
		drT(ix,iy+12,"M "..form("%-5.0f",c[j].m))
--		drT(ix,iy+18,"t "..form("%-5.0f",tick-c[j].t))
	end
end

end