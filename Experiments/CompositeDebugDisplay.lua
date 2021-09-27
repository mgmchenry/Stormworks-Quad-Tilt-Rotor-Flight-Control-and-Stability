-- based on one of the standard ponytools microcontrollers

data = {}

intervalCounter = 0
manualFreeze = false
triggerFrozen = false
freezeOffset = 0
maxRows = 99
displayInterval = 1

function onTick()
	interval = input.getNumber(32)
	triggerFired = not input.getBool(1)
	manualFreeze = input.getBool(32)
  displayInterval = math.max(1,math.min(10,input.getNumber(31)))
	
	if manualFreeze then
		if triggerFrozen then
			triggerFrozen = false
		end
		freezeOffset = 0
	else
		intervalCounter = intervalCounter + 1
		
		if intervalCounter >= interval then
			intervalCounter = 0
			now = {}
			for i=1,6 do	
				now[i] = input.getNumber(i)
			end
			table.insert(now, 1, triggerFired and 1 or 0)
			
			indexNow = #data + 1
			if triggerFired and not triggerFrozen then
				triggerFrozen = true
				freezeOffset = indexNow - 1
			end
			
			if indexNow > maxRows then
				if freezeOffset==1 then
					--no room for new data
				else
					freezeOffset = freezeOffset > 1 and (freezeOffset - 1) or 0
					data[indexNow] = now
					table.remove(data,1)
				end
			else
				data[indexNow] = now
				-- table.insert(data,#data,now)
			end
		end
	end
end

function onDraw()
	SW = screen.getWidth()
	SH = screen.getHeight()	
	
	screen.setColor(120,120,120)
  displayRows = math.floor(SH / 7) - 1
  dataRows = #data

	firstRow = 
    math.min(dataRows - (displayRows - 1) * displayInterval,
    freezeOffset > 0 and freezeOffset or dataRows)
  firstRow = math.max(firstRow, 1)
  lastRow = math.min(firstRow + (displayRows -1 ) * displayInterval, dataRows)

  debugText = string.format("rows %i offset %i first %i frozen %s tripped %s", dataRows, freezeOffset, firstRow
    , tostring(manualFreeze)
    , tostring(triggerFrozen)
    )

  cursorY = 1
  screen.drawText(1, cursorY, debugText)
  
	--for di,d in ipairs(data) do
  for di=firstRow, lastRow, displayInterval do
    d = data[di]
    
    if displayInterval>1 then
      local avg, samples = {}, 0
      for i = 0, displayInterval - 1 do
        d = data[di+i]
        if d then
          samples = samples + 1
          for i = 1, math.max(#d, #avg) do
            avg[i] = (avg[i] or 0) + (d[i] or 0)
          end
        end
      end
      
      for i, val in ipairs(avg) do
        avg[i] = avg[i] / samples
      end
      d = avg
    end

    if d then
      cursorY = cursorY + 7
      columnWidth = SW/(#d + 1)
      maxChars = math.max(5, math.floor((columnWidth - 5) / 5))
      columnWidth = maxChars * 5 + 3
      
      trigger = d[1]
      screen.drawText(1, cursorY, string.format("#%02.0f %1.f", di, trigger))
      x = 5*5 + 4
      --formats = {"%5.2f","%9.6f"}
      
      for i=2,#d do
        val = d[i]
        valstring = 
          type(val)=="number" and string.format("%9.6f", val)
          or tostring(val)
        sub = string.sub(valstring,1,maxChars)
        if string.len(tostring(math.floor(val))) > maxChars then
          sub = "too long"
        end
        screen.drawText(x, cursorY, sub)
        x = x + columnWidth + 3
      end
    end
	end
end