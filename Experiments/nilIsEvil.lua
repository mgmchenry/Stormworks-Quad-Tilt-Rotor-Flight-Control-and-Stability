local test1 = {1,2,"a","b",nil,3,4,"c","d",nil}
print("table value count:", # test1)
-- table value count:  4 
for i,v in ipairs(test1) do 
  print("index/value", i,v) 
end
--[[
index/value 1   1
index/value 2   2
index/value 3   a
index/value 4   b
--]]
-- only prints values from index 1-4 before it hits nil and exits the for loop
for i=5,10 do
  print("index/value", i, test1[i])
end
--[[
index/value 5   nil
index/value 6   3
index/value 7   4
index/value 8   c
index/value 9   d
index/value 10  nil
--]]
-- that does print table values 5-10, but you have to know there are supposed to be 10 values somehow

local count=0
for i,v in pairs(test1) do 
  print("key/value", i,v)
  count = count+1
end
print("count", count)
--[[result:
key/value   1   1
key/value   2   2
key/value   3   a
key/value   4   b
key/value   6   3
key/value   7   4
key/value   8   c
key/value   9   d
count   8
--]]
print("table test2")
local test2={a=1,b=2,c=3,d=4,e=nil,f=5,g=6,h=nil}
print("table value count:", # test2)
-- table value count:  0
-- because there are no elements in the array portion 
for i,v in ipairs(test2) do 
  print("index/value", i,v) 
end
-- nothing prints for the same reason
count=0
for i,v in pairs(test2) do 
  print("key/value", i,v)
  count = count+1
end
print("count", count)
--[[result:
key/value   a   1
key/value   c   3
key/value   b   2
key/value   d   4
key/value   g   6
key/value   f   5
count   6
--]]

-- that's not even getting into the issues with ... that select and pack can get around