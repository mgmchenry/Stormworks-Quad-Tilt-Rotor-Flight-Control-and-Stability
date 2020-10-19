_ENV = _G

__debug = {
  AlertIf = function (condition, ...)
    if condition then
      if __debug.IsTable(condition) then print(unpack(condition)) end
      if select(1,...) then print(...) end
    end
    return true
  end
  , IsTable = function (v)
    return string.sub(tostring(v),1,5) == "table"
  end
  , TableContents = function(value, label)
    label = label and ("("..tostring(label)..") ") or ""
    if value==nil then
      print(label.."cannot expand as table, value is nil")
      return
    end
    if type(value) == "table" then
      print(label.."table contents:")
      local valueCount = 0
      for key,v in pairs(value) do
        print(key, v)
        valueCount = valueCount + 1
      end
      print(label.."Table value count:", valueCount)
    else
      print(label.."value is not a table")
      local sType, sVal = type(value), "<???>"
      if sType == "string" then
        sVal = "("..value..")"
      elseif sType == "boolean" then
        sVal = "(".. (value and "true" or "false") ..")"
      elseif sType == "number" then
        sVal = "("..string.format(value)..")"
      end
      print(label..sType..":"..sVal)
    end
  end
}


for i=1,32 do
  inValues[i]=nil
  outValues[i]=nil
  inBools[i]=nil
  outBools[i]=nil
end

local function f(name, func)
  local dummyF = function(...)
    local params = {...}
    if name~=nil then
      print(" --> function call: "..name.." ( "..string.format("%d", #params).." parameters)")
    end
    if #params>0 then
      local message = " --> f("
      local commaMaybe = ""
      for i,param in ipairs(params) do
        local pString, sVal = type(param), "<???>"
        if type(param) == "string" then
          sVal = "("..param..")"
        elseif type(param) == "boolean" then
          sVal = "(".. (param and "true" or "false") ..")"
        elseif type(param) == "number" then
          sVal = "("..string.format(param)..")"
        end

        message = message..commaMaybe..pString..sVal
        commaMaybe = ", "
      end
      message = message..")"
      print(message)
    end
    local result = nil
    if func~=nil then
      result = func(...)
    end
    if result~=nil then
      local rString, sVal = type(result), "<???>"
      if type(result) == "string" then
        sVal = "("..result..")"
      elseif type(result) == "boolean" then
        sVal = "(".. (result and "true" or "false") ..")"
      elseif type(result) == "number" then
        sVal = "("..string.format(result)..")"
      end

      print(" --> return "..rString..sVal)
    end
    return result
  end
  return dummyF
end


input = {
  getNumber=f("getNumber", function(channel) return inValues[channel] end),
  getBool=f("getBool", function(channel) return inBools[channel] end)
}
output = {
  setNumber=f("setNumber", function(channel, value) outValues[channel]=value end),
  setBool=f("setBool", function(channel, value) outBools[channel]=value end)
}
screen = {
  drawTextBox=f("drawTextBox"),
  setColor=f("setColor"),
  getWidth=f("getWidth", function() return 98 end),
  getHeight=f("getHeight", function() return 98 end),
  drawLine=f("drawLine"),
  setColor=f("setColor"),
  drawClear=f("drawClear"),
  drawTriangleF=f("drawTriangleF"),
  drawTriangle=f("drawTriangle")
}
propValues = {}
property = {
  getNumber=f("getNumber", function(key) 
    return propValues[key] 
  end)
  , getText=f("getText", function(key) 
    return propValues[key] 
  end)
}

function onTick()
  print("onTick undefined")
end

function onDraw()
  print("onDraw undefined")
end

function runTest(func, message)
  if message~=nil then print("Test call: "..message) 
  else message="" end
  local status, err = pcall(func)
  if status then
    print("No Errors: Success!")
    print()
  else
    print()
    print(" *** "..message.." Error ***")
    if (type(err) == "table") then
      for key,value in pairs(err) do
        print("err."..toString(key)..":")
        print(value)
      end
    else
      print(err)
    end
    error(err)
  end
end