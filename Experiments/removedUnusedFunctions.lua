function numberOrZero(x)
  return x~=nil and type(x)=='number' and x or 0
end
--[[ 
  Thinking through if this function is worth the bytes:
  function minifies to:
  "function C(G)return G~=nil and type(G)=='number'and G or 0 end;" 
  cost is 63 characters
  a = numberOrZero(b)
    = aa(b) <minimized>
  a = ifVal(isValidNumber(b),b,0)
    = aa(ab(b),b,0) <minimized>
    so 8 extra characters
    8 uses of function would save 1 character.
    Yeah, not seeing it
--]]

--[[
--  This version minifies to 81-8=73 bytes
function getSomeIndexValues(lastIndex, firstIndex, l_indexList)
  firstIndex, l_indexList 
    = firstIndex or 1
    , {}
  for i=firstIndex,lastIndex do
  --for i=min(firstIndex,lastIndex),max(firstIndex,lastIndex) do
    l_indexList[#l_indexList+1] = i
  end
  return tableUnpack(l_indexList)
end
]]

--[[
-- this version minifies to 67-8=59 bytes
function getSomeIndexValues(lastIndex, l_indexList)
  l_indexList = {}
  for i=1,lastIndex do
  --for i=min(firstIndex,lastIndex),max(firstIndex,lastIndex) do
    l_indexList[i] = i
  end
  return tableUnpack(l_indexList)
end
-- still can't justify it
--]]