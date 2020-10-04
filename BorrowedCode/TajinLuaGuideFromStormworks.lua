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