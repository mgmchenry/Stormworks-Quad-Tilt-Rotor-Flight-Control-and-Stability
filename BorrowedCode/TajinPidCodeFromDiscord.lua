--[[
https://discordapp.com/channels/357480372084408322/578586360336875520/744676690927550475
--]]

S=screen
tU=table.unpack
M=math
C=S.setColor

function clamp(a,b,c) return M.min(M.max(a,b),c) end

function pid_old(p,i,d)
    return{p=p,i=i,d=d,E=0,D=0,I=0,
		run=function(s,sp,pv)
			local E,D,A
			E = sp-pv
			D = E-s.E
			s.E = E
			s.I = s.I +E *s.i
			
			return E*s.p +s.I +D*s.d
		end
	}
end
function pid(p,i,d,z)
    return{p=p,i=i,d=d,z=z or 1,E=0,D=0,I=0,
		run=function(s,sp,pv)
			local E,D,A
			E = sp-pv
			D = E-s.E
			A = E<0 and -1 or 1
			s.E = E
			s.I = A*(D-s.D)<0 and s.I*s.z or s.I +E*s.i
			s.D = D
			
			return E*s.p +s.I +D*s.d
		end
	}
end

function onTick()
	lim=input.getNumber(2)
	ran=input.getNumber(3)
	grav=input.getNumber(4)
	pp=input.getNumber(5)
	ii=input.getNumber(6)
	dd=input.getNumber(7)
	zz=input.getNumber(8)
end

function onDraw()
	w = S.getWidth()
	h = S.getHeight()
	cx,cy = w/2,h/2
	
	--np2 =     pid(0.1, 0.25, 0.2)
	np1 = pid_old(pp, ii, dd)
	np2 =     pid(pp, ii, dd, zz)
	pv1,pv2=0,0
	for x=1,w do
		y=x>50 and (x>200 and 10 or -40) or 30
		rnd = ran/2-math.random()*ran -- just a bit of randomness, for fun
		pv1 = pv1 + clamp( np1:run(y,pv1),-lim,lim) +rnd +grav
		pv2 = pv2 + clamp( np2:run(y,pv2),-lim,lim) +rnd +grav
		C(66,66,66) S.drawRectF(x,cy-y,1,1) -- draw the setpoint
		C(99,0,0) S.drawRectF(x,cy-pv1,1,1) -- draw old pid output (red)
		C(0,99,0) S.drawRectF(x,cy-pv2,1,1) -- draw new pid (green)
	end
	
	C(99,0,0) S.drawText(5,5,"regular pid")
	C(0,99,0) S.drawText(5,12,"improved pid")
	C(66,66,66) S.drawTextBox(w-50,5,50,h,"2 limit\n3 rnd\n4 grav\n\n5 P\n6 I\n7 D\n\n8 I-damp\nmultipl.",-1,-1)
end

--[[

And his example from steam guide
https://steamcommunity.com/sharedfiles/filedetails/?id=1800568163
--]]

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

