--[[

--]]

I,O,P=input,output,property
gn,sn,gb,sb,pn=I.getNumber,O.setNumber,I.getBool,O.setBool,P.getNumber
lock,tch=false,0
function onTick()
	ps=gb(1)
	iX=gn(3)
	iY=gn(4)
	pge=gn(7)
    --chn=string.format("%.0f",gn(8))
    chn=gn(8)
    if chn==0 then chn=1 end
    chn=string.format("%.0f",chn)
	mut=gn(9)
	meg=gn(10)
	tm={{0,0,w,7,"CH "..chn,0},
		{1,8,w-2,7,"TALK",0},
		{1,16,w-2,7,"MUTE",mut},
		{1,24,w-2,7,"MEGA",meg}
	}
	tk={{1,7,6,7,"0",0},
		{9,7,6,7,"1",0},
		{17,7,6,7,"2",0},
		{25,7,6,7,"3",0},
		{1,15,6,7,"4",0},
		{9,15,6,7,"5",0},
		{17,15,6,7,"6",0},
		{25,15,6,7,"7",0},
		{1,23,6,7,"8",0},
		{9,23,6,7,"9",0},
		{17,23,6,7,"D",0},
		{25,23,6,7,"E",0}
	}
	
	if ps then
		if pge==1 then
			for i,v in ipairs(tk) do
				if tc(v[1],v[2],v[3],v[4]) then
					tk[i][6]=1
					if not lock then
						if i==12 then
							-- enter
							sn(1,0)
							sn(2,tch)
						elseif i==11 then
							-- delete
							if string.len(tch)>0 then
								tch=string.sub(tch,0,string.len(tch)-1)
							end
						else
							-- number input
							if string.len(tch)<3 then
								tch=tch..tk[i][5]
							end
						end
					end
					lock=true
				end
			end
		else
			for i,v in ipairs(tm) do
				if tc(v[1],v[2],v[3],v[4]) then
					tm[i][6]=1
					if not lock then
						if i==1 then
							-- numpad
							tch=chn
							sn(1,1)
						elseif i==2 then
							-- talk
							sb(1,true)
							if meg==1 then
								sb(3,true)
							else
								sb(2,true)
							end
						elseif i==3 then
							-- mute
							if mut==1 then
								sn(3,0)
							else
								sn(3,1)
							end
						else
							-- megaphone
							if meg==1 then
								sn(4,0)
							else
								sn(4,1)
							end
						end
					end
					lock=true
				end
			end
		end
	else
		lock=false
		sb(1,false)
		sb(2,false)
		sb(3,false)
	end
	
	if mut==1 then
		sb(4,false)
	else
		sb(4,true)
	end
end

S=screen
w,h=0,0
sc=S.setColor
function onDraw()
	w=S.getWidth()
	h=S.getHeight()
	
	sc(0,0,0)
	S.drawClear()
	
	if pge==1 then
		sc(255,255,255)
		S.drawTextBox(0,0,w,7,"CH "..tch,0,0)
	
		for i,v in ipairs(tk) do
			if v[6]==1 then
				sc(0,255,0)
			else
				sc(255,255,255)
			end
			S.drawRectF(v[1],v[2],v[3],v[4])
		
			sc(0,0,0)
			S.drawTextBox(v[1],v[2],v[3],v[4],v[5],0,0)
		end
	else
		for i,v in ipairs(tm) do
			if v[6]==1 then
				sc(0,255,0)
			else
				sc(255,255,255)
			end
			S.drawRectF(v[1],v[2],v[3],v[4])
		
			sc(0,0,0)
			S.drawTextBox(v[1],v[2],v[3],v[4],v[5],0,0)
		end
	end
end
	
function tc(x,y,w,h)
	return iX>x and iY>y and iX<x+w and iY<y+h
end