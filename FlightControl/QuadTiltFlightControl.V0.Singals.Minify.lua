
sourceVS1123c="repl.it/@mgmchenry"
local a,b,c,d,e,f,g,h=_ENV,property.getText,string.gmatch,table.unpack,"Ark"
,'([^,\r\n]+)',false
local i,j=function(k,l,m,n)
m={}
for o in l do
n=k
__debug.AlertIf({"key["
..o.."]"
})
for p in c(o,'([^. ]+)')do
__debug.AlertIf({"subkey["
..p.."]"
})
n=n[p]__debug.AlertIf({"context:"
,string.sub(tostring(n),1,20)})
end
m[#m+1]=n 
end
return d(m)end,function(q,m)
m={}__debug.AlertIf({"stringUnpack text:"
,q})
for r in c(q,f)do
__debug.AlertIf({"stringUnpack value: ("
..r..")"
})m[#m+1]=r 
end
return d(m)
end
local s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L=i(a,c(b(e..0)
..b(e..1),f))
x(K(L))
local M,N,O,P,Q,R,S,T,U,V,W=L*2,0,60
function P(X,Y,Z)
return X and Y or Z 
end

function Q(_,a0)
return y(_)==_ and _~=a0 
end

function R(a1,a2,a3)
a3=a3
or 1
return a2 and(a1-a3)%a2+a3 or a1 
end

function S(_)
return _>0 and 1 or _<0 and-1 or 0 
end

function T(r,a4,a5)
return Q(r)
and(r>a5 and a5 or r<a4 and a4 or r)
end

function U(a6,a7)
a7=a7
or{}
for a8,r in z(a6)do
a7[a8]=B(r)
end
return a7 
end

function V(a9,aa,ab)a9,aa,ab=a9
or 1,aa or{},ab or"token_"
for a8=1,a9 do
N=N+1
aa[#aa+1]=ab..N 
end
return d(aa)
end
local ac,ad,ae,af,ag,ah,ai,aj,ak,al,am,an,ao,ap,aq,ar,as,at=V(18)
__debug.AlertIf(not at and justDie()
)
__debug.AlertIf(not at=="token_"
..N and justDie()
)
function W(k,au,av)
k=k
or{}
for a8,r in z(au)do
k[r]=av[a8]end
return k 
end
local aw,ax,ay,az
function ay()
local aA,aB,aC,aD,aE,aF,aG,aH,aI,aJ={},{1,2,3,4,5,6,21,22,23,24,25,26,29},ax[af]({"t_pilotRoll"
,"t_pilotPitch"
,"t_pilotYaw"
,"t_pilotUpdown"
,"t_pilotAxis5"
,"t_pilotAxis6"
,"t_gpsX"
,"t_gpsY"
,"t_compass"
,"t_tiltPitch"
,"t_tiltRoll"
,"t_tiltUp"
,"t_rotorRPS"
}),{"heading"
,"sideDrift"
,"forwardDrift"
,"sideAcc"
,"forwardAcc"
,"rotorAltitude"
},{},{"thrust"
,"alt"
,"tilt"
},{"t_roTargetAcc"
,"t_roRotorPitchOut"
,"t_roPitch41G"
,"t_roRotorTilt"
},ax[ae],ax[ad]local aK,aL,aM,aN,aO,aP,aQ,aR,aS,aT,aU,aV,aW=d(aC[ac])
local aX,aY,aZ,a_,b0,b1=d(aD)
local b2,b3,b4=d(aF)
local b5,b6,b7,b8=d(aG)
W(aC[aS],{aq,ar},{1,-0.5})ax[af](aD,h,aC)
for a8=1,4 do
aE[a8]=ax[af](aF)ax[af](aG,{as},aE[a8])
end

function aJ(b9,ba)
for a8=1,4 do
local bb,bc,bd,be,bf,bg,bh=aE[a8],{a8*3+6,a8*3+7,a8*3+8}aI(bb,U(bc),aj,aF)
local bi,bj,bk,bl=aH(bb,aF)bd,be,bf,bg=aH(bb,aG,as)
bl=aH(bb,{b4},ak)
bh=1/F(bj*L*2)*(E(bj)<0.06 and 0 or E(bj)<0.11 and H(E(bj)-0.06,0)*1/0.05 or 1)
bd=(b9+ba*P(a8<3,-1,1))*bh
be=T((be or 0)+(bd-bl)/20/O,-1,1)
bg=0
aI(bb,{bd,be,bf,bg},as,aG)
D(a8,be)
D(a8+4,bg)ax[ag](bb)
end
end
aA[at]=function()
aI(aC,U(aB))
local bm,bn,bo,bp,bq,br,bs,bt,bu,bv=0,aH(aC,{aT,aV,aQ,aR,aS,aK,aL,aM,aN})
for a8,r in z(U({9,12,15,18}))do
bm=bm+(r or 0)/4 
end
if bo<0 then
bn=bn+0.25*S(bo)
end
aI(aC,{bn},aj,{aT})
local bw,bx,by,bz,bA=aH(aC,{aS,aU,aT,aQ,aR},ak)
local bB,bC=aH(aC,{aQ,aR},al)
local bD,bE,bF,bG,bH,bI,bJ,bK,bL=br+0.25,I(bA,bz)/M,J(bz*bz+bA*bA),I(bC,bB)/M,J(bB*bB+bC*bC)bI,bJ,bK,bL=F(M*(bE-bD))*-bF,G(M*(bE-bD))*bF,F(M*(bG-bD))*-bH,G(M*(bG-bD))*bH
aI(aC,{bD,bI,bJ,bK,bL,bm},aj,aD)
local bM,bN,bO,bP,bQ,bR,bS,bT,bU,b9=aH(aC,{b1},am)or bm>0 and bm+0.5,.2
bP,bS=aH(aC,{b1},ak),aH(aC,{b1},al)
bR=bP+bS*bN
bO=bm+(bP+bR)/2*bN
bM=bm~=0 and E(bv)+E(bt)>0.03 and bO or bM
bQ=E(bv)>0.3 and bv*10 or bM and bm and T((bM-bm)/bN/2,-10,10)or 0
b9=(bQ-bR)/bN
aJ(b9,bt-bn)
for a8,r in z({bm,bM,bt,bs,bI,bJ,bK,bL})do
D(a8+9,r)
end
ax[ag](aC)
end
return aA 
end

function ax()
local aA,bV,bW,bX,bY={},{aj,ak,al,am,an,ao},V(3)aA[af]=function(bZ,b_,c0,c1,c2,c3,c4,c5)
__debug.AlertIf(Q(bZ),"getting x signal tokens:"
,bZ)
__debug.AlertIf(not Q(bZ),"assigning tokens:"
,d(bZ))bZ,b_,c2=Q(bZ)and{V(bZ)}
or bZ,b_ or bV,W(h,{ac,bX,bW},{{},c1 or 60,1})
c0=c0
or c2
c1,c3=c0[bX],c0[ac]__debug.AlertIf({"Using signal elements:"
,d(b_)})
for a8,c6 in z(bZ)do
c3[#c3+1]=c6
c5,c4={},{}c0[c6],c5[bY],c5[ap]=c5,b_,c4
for c7,c8 in z(b_)do
c5[c8]=g
c4[c8]={}
for c9=1,c1 do
c4[c8][c9]=g 
end
end
end
return c0 
end
aA[ag]=function(c0)
local ca,cb,cc=R(c0[bW]+1,c0[bX])c0[bW]=ca
for a8,c6 in z(c0[ac])do
cc=c0[c6]cb=cc[bY]or bV
for c7,c8 in z(cb)do
cc[ap][c8][ca]=h 
end
end
end
aA[ad]=function(c0,av,cd,ce,cf)cf,ce,cd=cf
or{cd or aj},ce or c0[ac],cd or aj
for a8,cg in z(ce)do
local ch,cc,ci,cj,ck,cl,cm,cn=c0[bW],c0[cg],W(h,{aj,ak},{ak,al})
cj=cc[ap]cj=cj[cd]cl=R(av[a8],cc[aq],cc[ar])cc[cd]=cl
cj[ch]=cl
ck=ci[cd]if ck then
cl=aA[ah](c0,cg,cd,3)
cm=aA[ah](c0,cg,cd,3,1)
cn=R(cl-cm,cc[aq],cc[ar])*O
aA[ad](c0,{cn},ck,{cg})
end
end
end
aA[ae]=function(c0,ce,cd,aa)cd,aa=cd
or aj,aa or{}
for a8,r in z(ce)do
__debug.AlertIf(not __debug.IsTable(c0),"signalSet is not a table"
,c0)
__debug.AlertIf(c0[r]==h and{"signalKey"
,a8,r,"missing from set"
,__debug.TableContents(c0[ac],"signalSet t_tokenList"
)},"huh"
)
__debug.AlertIf(c0[r]==h and{__debug.TableContents(ce,"signalKeys list passed to GetValues"
)})
__debug.AlertIf(__debug.IsTable(r)and{"signalKey is a table"
,__debug.TableContents(r,"signalKey"
)})
__debug.AlertIf(not __debug.IsTable(c0[r]),"signal is not a table - signalName:"
,r,"value"
,c0[r])
__debug.AlertIf(c0[r][cd]==h and{"Signal element is nil. SignalKey:"
,r,"ElementKey:"
,cd,__debug.TableContents(c0[r],"signal elements"
)})aa[a8]=c0[r][cd]end
return d(aa)
end
aA[ah]=function(c0,cg,cd,co,cp)cd,co,cp=cd
or aj,co or 3,cp or 0
local ca,c1,cc,cq,cj,cr,cs,ct=c0[bW],c0[bX],c0[cg],0
cj=cc[ap][cd]cp=T(cp,0,c1-1)
co=T(co,1,c1-cp)
for a8=0,co-1 do
cs=R(ca-cp-a8,c1)
cr=cj[cs]ct=ct
or cr
cq=cq+(Q(cr)and R(cr-ct,cc[aq],cc[ar])or 0)
end
return R(cq/co+(ct or 0),cc[aq],cc[ar])
end
return aA 
end
ax=ax()
ay=ay()
local cu,cv=0,-1
function onTick()
if B(1)==h then
return 
end
cu=cu+1
ay[at]()
end