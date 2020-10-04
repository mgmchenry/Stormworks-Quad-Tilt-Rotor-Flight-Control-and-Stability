https://steamcommunity.com/sharedfiles/filedetails/?id=1800568163

This is a framework (not a guide) that can be helpful when you want to make complex things in lua but need a way to keep your code compact and organized.

This framework contains:

1. shortcuts for most of the ingame commands (either to save some characters or if you're a lazy typer)

2. some useful minified functions that are often needed and that also help you to keep your code compact (like getting all your input variables in one go)

3. an easy and compact way to define buttons and add actions to them (supports clicking, holding or toggling those buttons)

~ ~ ~
I may also add some additional functions at the end that don't really fit into the framework but can still be useful in special occasions.
Feel free to let me know if you think something is missing.
 
 
Award
Favorite
Share
CREATED BY

Tajin
Offline
Category: Crafting, Gameplay Basics, Secrets, Workshop
Languages: English
Posted
Updated
Jul 11, 2019 @ 4:31pm
Jan 16 @ 11:15am
1,102	Unique Visitors
43	Current Favorites
GUIDE INDEX
Overview
Commented framework 
- - - 
Function: Drawing a rotated triangle (pointer) 
Function: Draw an arc 
Function: lua PID 
Delays 

Comments
Commented framework
Since the steam code-tags are apparently buggy, get the code here:
http://rising.at/Stormworks/lua/framework.lua

You may want to remove the commends and other parts you don't need, to keep the size reasonable.
- - -
Function: Drawing a rotated triangle (pointer)
M=math
si=M.sin
co=M.cos
pi=M.pi
S=screen
dTF=S.drawTriangleF

function drawPointer(x,y,s,r,...) -- position x,y, size, direction, angle/width of the arrow (optional)
    local a = ...
    a = (a or 30)*pi/360
    x = x+s/2*si(r)
    y = y-s/2*co(r)
    dTF(x,y, x-s*si(r+a), y+s*co(r+a), x-s*si(r-a), y+s*co(r-a))
end
Function: Draw an arc
M=math
si=M.sin
co=M.cos
pi=M.pi
S=screen
dTF=S.drawTriangleF
dL=S.drawLine

function drawArc(...) --x,y,radius,(angle1,angle2,filled,step)
	local x,y,r,a1,a2,pie,step = ...
	a1 = a1 or 0
	a2 = a2 or 360
	step = step or 22.5
	if a2<a1 then a2,a1=a1,a2 end
	local a,px,py,ox,oy,ar = false,0,0,0,0,0
	repeat
		a = a and M.min(a+step,a2) or a1
		ar = (a-90) *pi /180
		px,py = x +r *co(ar), y +r *si(ar)
		if a~=a1 then
			if pie then
				dTF(x,y, ox,oy, px,py)
			else
				dL(ox,oy,px,py)
			end
		end
		ox,oy = px,py
	until(a>=a2)
end
Function: lua PID
Slightly different than the regular ingame pid. This one also automatically prevents windup.
function pid(p,i,d)
    return{p=p,i=i,d=d,E=0,D=0,I=0,
		run=function(s,sp,pv)
			local E,D,A
			E = sp-pv
			D = E-s.E
			A = math.abs(D-s.D)
			s.E = E
			s.D = D
			s.I = A<E and s.I +E*s.i or s.I*0.5
			return E*s.p +(A<E and s.I or 0) +D*s.d
		end
	}
end

-- example
pid1 = pid(0.01,0.0005, 0.05)
pid2 = pid(0.1,0.00001, 0.005)
function onTick()
	setpoint = input.getNumber(1)
	pv1 = input.getNumber(2)
	pv2 = input.getNumber(3)
	output.setNumber(1,pid1:run(setpoint,pv1))
	output.setNumber(2,pid2:run(setpoint,pv2))
end
--
Delays
delay = {"test"=60}    -- setup initial delays
function onTick()
    for i,v in pairs(delay) do delay = v>0 and (v-1) or nil end -- decrease all delays by 1 or clear them on 0
    
    if not delay.test then -- do something after the first 60 ticks
        delay.test = 120 -- do the same thing again but now after 120 ticks
    end
end

--[[

Code below is slightly different version from his raw formatted code at https://rising.at/Stormworks/lua/framework.lua

--]]

-- shorcuts (remove what you don't need)
M=math
si=M.sin
co=M.cos
pi=M.pi
pi2=pi*2

S=screen
dL=S.drawLine
dC=S.drawCircle
dCF=S.drawCircleF
dR=S.drawRect
dRF=S.drawRectF
dT=S.drawTriangle
dTF=S.drawTriangleF
dTx=S.drawText
dTxB=S.drawTextBox

C=S.setColor

MS=map.mapToScreen
SM=map.screenToMap

I=input
O=output
P=property
prB=P.getBool
prN=P.getNumber
prT=P.getText

tU=table.unpack
tI=table.insert


-- useful functions (remove what you don't need)
function getN(...)local a={}for b,c in ipairs({...})do a[b]=I.getNumber(c)end;return tU(a)end
	-- get a list of input numbers
function outN(o, ...) for i,v in ipairs({...}) do O.setNumber(o+i-1,v) end end
	-- set a list of number outputs
function getB(...)local a={}for b,c in ipairs({...})do a[b]=I.getBool(c)end;return tU(a)end
	-- get a list of input booleans
function outB(o, ...) for i,v in ipairs({...}) do O.setBool(o+i-1,v) end end
	-- set a list of boolean outputs

function round(x,...) return string.format("%."..(... or 0).."f",x) end
	-- round(x) or round(x,a) where a is the number of decimals
function clamp(a,b,c) return M.min(M.max(a,b),c) end
	-- limit a between b and c
function lerp(a,b,t) return a+t*(b-a) end
	-- scale t between a and b
function grad(g,a,x)local s,d,t=0,0,{}for j=2,#a do	d=a[j]-a[j-1]s=s+d;if s>=x then for i,v in pairs(g[j-1])do t[i]=lerp(v,g[j][i],(d+x-s)/d)end;break end end;return t end
	-- (lerp required) table of colors g, gradient positions in table a, x(0-1) selects
function ssquash(a,b,c,s) return (c-b)/(1+M.exp(-a*s))+b end
	-- sigmoid squash function: limts a between b and c in a curve

function inRect(x,y,a,b,w,h) return x>a and y>b and x<a+w and y<b+h end
	-- check if x,y is inside the rectangle a,b,w,h
function rot(x,y,a) a=a/180*pi return {x=x*co(a)-y*si(a),y=x*si(a)+y*co(a)} end
	-- rotate point x,y around by a and return the resulting position
function rot3D(x,y,z,a,b,c) return {(co(b)*co(c)*x)+(-co(a)*si(c)+si(a)*si(b)*co(z))*y+(si(a)*si(c)+co(a)*si(b)*co(c))*z,(co(b)*si(c)*x)+(co(a)*co(c)+si(a)*si(b)*si(c))*y+(-si(a)*co(c)+co(a)*si(b)*si(c))*z,-si(b)*x+si(a)*co(b)*y+co(a)*co(b)*z} end
	-- rotate point x,y,z around by a,b,c and return the resulting position

function rectF(x,y,w,h,a) w,h=w/2,h/2 t={rot(-w,-h,a),rot(w,-h,a),rot(w,h,a),rot(-w,h,a)} dTF(x+t[1].x,y+t[1].y,x+t[2].x,y+t[2].y,x+t[3].x,y+t[3].y) dTF(x+t[1].x,y+t[1].y,x+t[4].x,y+t[4].y,x+t[3].x,y+t[3].y) end
	-- draw a rectangle at center point x,y with width w and height h at an angle of a
function drawArc(...)local a,b,c,d,e,f,g=...d=d or 0;e=e or 360;g=g or 22.5;if e<d then e,d=d,e end;local h,i,j,k,l,m=false,0,0,0,0,0;repeat h=h and M.min(h+g,e)or d;m=(h-90)*pi/180;i,j=a+c*co(m),b+c*si(m)if h~=d then if f then dTF(a,b,k,l,i,j)else dL(k,l,i,j)end end;k,l=i,j until h>=e end
	-- draw an arc or circle segment x,y,radius,(angle1,angle2,filled,step)
function drawPointer(x,y,s,r,...)local a=...a=(a or 30)*pi/360;x=x+s/2*si(r)y=y-s/2*co(r) dTF(x,y,x-s*si(r+a),y+s*co(r+a),x-s*si(r-a),y+s*co(r-a))end
	-- draw an arrow at point x,y with size s and rotation r. Argument 5 is optional and specifies the width of the arrow.
function drawRing(...)local a,b,c,d,e=...e=e or 16;for f=0,e do ar=pi2/e*f;x1,y1,x2,y2=a+c*co(ar),b+c*si(ar),a+d*co(ar),b+d*si(ar)if f>0 then dTB(x1,y1,x2,y2,X1,Y1)dTB(X1,Y1,x2,y2,X2,Y2)end;X1,Y1,X2,Y2=x1,y1,x2,y2 end end
	-- draws a ring/donut around point x,y with radius1 and radius2. Argument 5 is optional and specifies the number of segments to draw the circles with.
	
	
-- touch handling (remove if you don't need it)
	TOUCH = {
		{5,5,30,10,"1"}, --Button1
		{5,20,30,10,"2"}, --Button2
		{5,35,30,10,"text",0,0}, --Button3
	}
	act = {}
	btn = {}
	
	test = 0
	act[3] = function(i) -- function for button 3, executed on click
		test = test+1
	end
--

function onTick()
	myNumVar,myOtherNum = getN(10,15)
	myBoolVar,myOtherBool = getB(5,9)
	
	-- touch handling (remove if you don't need it)
		w,h,tx,ty=getN(1,2,3,4,5,6);t1,t2=getB(1,2)
		
		for i,t in ipairs(TOUCH) do
			b = btn[i] or {}
			if inRect(tx,ty,t[1],t[2],t[3],t[4]) then
				b.click = t1 and not b.hold
				b.hold = t1
				if b.click then
					b.toggle = not b.toggle
					if act[i] then act[i](i) end
				end
			else
				b.hold = false
			end
			btn[i] = b
		end
	--
	
	outN(11, myNumVar,myOtherNum) -- output to 11 and 12
	outB(1, true,false)
end

function onDraw()
	if t1==nil then return true end -- safety check to make sure variables are set
	w = S.getWidth()
	h = S.getHeight()
	cx,cy = w/2,h/2 -- coordinates of the screen center (always useful)
	
	for i,t in ipairs(TOUCH) do -- loop through defined buttons and render them
		C(20,20,20)
		if btn[i].hold then C(80,80,80) end -- color while holding the button
		dRF(tU(t,1,4)) -- draw button background (tU outputs the first 4 values from the button as parameters here)
		C(255,0,0)
		if btn[i].toggle then C(0,255,0) end -- text green if button is toggled on
		dTxB(tU(t)) -- draw textbox with the button text
	end
	
	C(255,255,255)
	dTx(cx,cy,test) -- test output for the function of button 3
end