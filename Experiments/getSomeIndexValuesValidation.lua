
local function catchArray(...)
  return {...}
end


local propTest = [[
	{label="target rps",min=0,max=20,r=120,g=0,b=0},
	{label="rps",min=0,max=20,r=0,g=120,b=0},
	{label="throttle",min=0,max=1,r=0,g=0,b=120},
	{label="temp",min=-20,max=130,r=120,g=0,b=120},
	{label="generator",min=0,max=600,r=120,g=120,b=0},
	{label="fuel",min=0,max=187.5,r=0,g=120,b=120}
]]
--propTest = "1,2,3"


for section in string.gmatch(propTest, '([^{]+)}') do
  print("section", section)
  for value in string.gmatch(section, 
    '([^,]+)'
    ) do
    print("val: ", value)
  end
end



min = math.min
max = math.max
tableUnpack = table.unpack
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

print("getSomeIndexValues validation:")
x = {}; x[#x+1]=1; x[#x+1]=2; x[#x+1]=3; print(unpack(x)); print(# x)
print("getSomeIndexValues(5):")
print(getSomeIndexValues(5))
x = catchArray(getSomeIndexValues(5))
print(x)
print(unpack(x)); print(# x)

print("getSomeIndexValues(9,5):")
x = catchArray(getSomeIndexValues(9,5))
print(x)
print(unpack(x)); print(# x)

print("getSomeIndexValues(5,9):")
x = catchArray(getSomeIndexValues(5,9))
print(x)
print(unpack(x)); print(# x)


local t={first=1, second=2};print(t);for i,v in pairs(t) do print(i,v) end; print(unpack(t))

local f,s="first","second"; local t={f=1, s=2};print(t);for i,v in pairs(t) do print(i,v) end; print(unpack(t))