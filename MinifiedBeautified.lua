sourceV0917="https://repl.it/@mgmchenry/Stormworks-Quad-Tilt-Rotor-Flight-Control-and-Stability"local a,b,c,d=input,output,screen,math;local e,f,g,i,j=a.getNumber,b.setNumber,a.getBool,c.drawTextBox,table.unpack;local k,l,m,n,o,p=d.abs,d.sin,d.cos,d.max,d.pi;p=o*2;local q,r,s,t,u,v,x,y,z,A,B,C;function q(D,E,F)if D==nil then return nil end;if D>F then return F end;if D<E then return E end;return D end;function C(G)return G~=nil and type(G)=='number'and G or 0 end;function B(G,H)return G~=nil and type(G)=='number'and G~=H end;function r(...)local I={}for J,D in ipairs({...})do I[J]=e(D)end;return j(I)end;function s(K)if K then return-1 end;return 1 end;function t(K,L,M)if K then return L end;return M end;local N,O,P,Q,R=0,1,2,3,4;function A(S,T)T={}for J=1,S do N=N+1;T[J]="token_"..N end;return j(T)end;local U,V,W,X,Y,Z,_=A(7)function x()local a0={ofs=nil,alt=0,tilt=0,vel=0,rot=0,pC=nil,pP=0,pR=0}a0[_]=nil;a0[Z]=0.25;a0[U]={}a0[V]={}a0[W]={}a0[X]={}a0[Y]={}return a0 end;local a1,a2,a3,a4,a5,a6,a7,a8,a9=0,-1,O,0,{x(),x(),x(),x()}a7=5;a8=a7+1;a9=60/a7;local aa,ab,ac,ad,ae,af,ag,ah={},1,2,3,4,5,6;ah={ab,ac,ad,ae,af,ag}for J,D in pairs(ah)do aa[D]={}end;function u(ai)for aj=1,a7 do ai[aj]=ai[aj+1]or 0 end end;function v(G)return G>0 and 1 or G<0 and-1 or 0 end;local ak,al,am,an,ao,ap,aq,ar,as,at,au,av,aw,ax,ay,az,aA,aB,aC,aD;function onTick()if e(1)==nil then return false end;a1=a1+1;ak,al,am,an,ao,ap,aq,ar,as,at,au,av,aw,ax=r(1,2,3,4,5,6,21,22,23,24,25,26,29,30)aB,aD=0,0;aC=0+t(g(1),1,0)-t(g(2),1,0)if av<0 then at=at+0.25*v(av)end;for J,D in pairs(ah)do u(aa[D])end;aa[ad][a8]=as;aa[ab][a8]=au;aa[ac][a8]=at;ay=as-aa[ad][1]az=(au-aa[ab][1])*a9;aA=(at-aa[ad][1])*a9;if ay>.5 then ay=ay-1 end;if ay<-.5 then ay=ay+1 end;ay=ay*a9;for J,a0 in pairs(a5)do local aE=(J-1)*3+9;a0.alt,a0.tilt,a0.vel=r(aE,aE+1,aE+2)a0.hasData=false;for aF,ai in pairs({U,V,W,X,Y})do u(a0[ai])end;if B(a0.alt,0)and B(a0.tilt)and B(a0.vel)then a0.hasData=true;aD=aD+1;aB=aB+a0.alt;a0.v2=(a0.alt-a0[U][1])*a9;a0.acc=a0.vel-a0[V][1]a0.velErr=a0.vel-a0[X][1]a0[_]=a0.acc-a0[Y][1]else a0.acc,a0.velErr,a0[_]=nil,nil,nil end;a0[U][a8]=a0.alt;a0[V][a8]=a0.vel;a0[W][a8]=a0.acc end;local aG,aH,aI,aJ,aK;aG=0;if a3==O then aG=0.25;a3=P end;aG=an;if aD~=4 then aG=an else aB=aB/aD;if a3==P then a3=Q;for J,I in pairs(a5)do I.ofs=I.alt-aB end end;if a6==nil then a6=aB end;if a3==Q then if aw>25 then a3=R;a6=aB+0.25;for J,I in pairs(a5)do I.tg=I.ofs+a6;I.pC=0.25;I.conf=0;I.tv=0 end end end end;aH=(an*10)^2*t(an<0,-1,1)if k(an)>0.05 then a6=aB end;a4=q(a4+aC/(60*3),0,1)aJ=al+(at+ao)*2;aK=ak+au*-2;for J,a0 in pairs(a5)do local aL=q((am+ay*4)*0.25,-.25,.25)if J==2 or J==4 then aL=-aL end;a0.rot=a4+aL;if a3~=R then a0[Z]=aG else local aM,aN,aO,aP,aQ,aR,aS,aT,aU,aV,aW,aX,aY,aZ,a_,b0,b1;aM=a0.tilt*p;aN=m(aM)aO=l(aM)aP=aO/(aN+k(aO))aQ=1/aO;if k(a0.tilt)<0.06 then aQ=0 else if k(a0.tilt)<0.11 then aQ=aQ*n(k(a0.tilt)-0.06,0)*1/0.05 end end;aW=a0.v2;aX=a0.vel*aO;a0.tg=a0.alt+a6-aB;aV=8;aR=q((a0.tg-a0.alt-aW*0.5)*aQ,-aV,aV)if k(an)>0.05 then aR=an*40 end;aS=q(aR-a0.vel,-10,10)aR=a0.vel+aS;a0.tv=aR;aY=s(J<3)aZ=40;a_=at+ao;aT=q((al*10+a_*aZ)*aY-a0.vel*0.5,-4,12)aU=q(aT-a0.vel,-10,10)aT=a0.vel+aU;aY=s(J==2 or J==4)local b2=40;aT=q((ak*10-au*b2)*aY-a0.vel*0.5,-4,12)+aT;aU=q(aT-a0.vel,-10,10)aT=a0.vel+aU;a0.tv=aR+aU;a0.tgAcc=q(a0.tv-a0.vel,-40,40)b0=q(a0.pC*aQ+a0.pC*0.1*a0.tgAcc+a4*ap,-1,1)if a4>0.5 then yp=am*s(J==2 or J==4)b0=b0+yp end;b1=q(b0-a0[Z],-0.05,0.05)a0[Z]=a0[Z]+b1;a0[X][a8]=a0.tv;a0[Y][a8]=a0.tgAcc;if a0[_]<-1 then a0.pC=q(a0.pC+0.001*k(a0[_])*0.5,0.1,0.6)a0.conf=a0.conf-0.01 end;if a0[_]>4 then a0.pC=q(a0.pC-0.001*a0[_]*0.5,0.1,0.6)a0.conf=a0.conf-0.01 end;if k(a0[_])<0.5 then a0.conf=a0.conf+0.01 end end;f(J,a0[Z])f(J+4,a0.rot)end;f(9,aB)f(10,a6)f(11,aJ)f(12,aK)end;function z(S)if S==nill then return"nil"end;return string.format("%.f",S)end;function y(S)if S==nill then return"nil"end;return string.format("%.2f",S)end;function onDraw()if ax==nil then return false end;w=c.getWidth()h=c.getHeight()c.setColor(255,0,0)tw=5*10;tx=20;ty=10;local function b3(b4,D)if ty+10>h then ty=10;tx=tx+tw*2.5 end;i(tx,ty,tw,6,b4,1,0)i(tx+tw+4,ty,tw*2,6,D,-1,0)ty=ty+6 end;tDiff=a1-ax;b3("State",a3)b3("TickDiff",y(tDiff))b3("rRPS",y(aw))b3("qrAlt",y(aB))b3("sCompass",y(as))b3("yawRate",y(ay))for J,I in pairs(a5)do end end
--[[
Before
15,172 bytes
After
4,322 bytes
Compression ratio
71.51%
About this tool
This tool uses luamin to minify any Lua snippet you enter. Under the hood, luamin uses luaparse.

Made by @mathias — fork this on GitHub!
--]]