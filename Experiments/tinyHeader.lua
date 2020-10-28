
-- Minifies to 3981 characters as of S11.23e
-- Minifies to 3547 characters as of T11.24a
sourceVT1124a="repl.it/@mgmchenry"

local G, prop_getText, gmatch, unpack
  , propPrefix, commaDelimited, empty, nilzies
  -- nilzies not assigned by design - it's just nil but minimizes to one letter

	= _ENV, property.getText, string.gmatch, table.unpack
  , "Ark", '([^,\r\n]+)', false

local getTableValues, stringUnpack 
= function(c,d,e,f)e={}for g in d do f=c;for h in gmatch(g,'([^. ]+)')do f=f[h]end;e[#e+1]=f end;return unpack(e)end,function(i,e)e={}for j in gmatch(i,commaDelimited)do e[#e+1]=j end;return unpack(e)end

local _string, _math, _input, _output, _property
  , _tostring, _tonumber, ipairz, pairz
  , in_getNumber, in_getBool, out_setNumber
  , abs, sin, cos, max, min
  , atan2, sqrt, floor, pi
	= getTableValues(G,gmatch(prop_getText(propPrefix..0)..prop_getText(propPrefix..1), commaDelimited))

-- sanity check that the function set loaded properly. Die on pi() if not
--_ = floor(pi)~=3 and pi()
-- shorter:
_tostring(floor(pi))



--[[
propValues["Ark0"] =
[ [
string,math,input,output,property
,tostring,tonumber,ipairs,pairs
,input.getNumber,input.getBool,output.setNumber
] ]
propValues["Ark1"] =
[ [
,math.abs,math.sin,math.cos,math.max,math.min
,math.atan,math.sqrt,math.floor,math.pi
] ] 
--]]