--[[
Transponder
DTplayers's Workshop - May 18, 2019 @ 6:56pm - May 31, 2020 @ 8:47pm
https://steamcommunity.com/sharedfiles/filedetails/?id=1745482481

This is similar to ADS-B. When wired up to the correct sensors and antennas, the transponder will automatically find an open channel to send out it's positional data. It operates on channels 500-600, so there can be at most 100 tracked objects in the world at any given time. If the transponder ever finds that another device is transmitting it's channel, it will switch frequencies to a new channel automatically and reinitialize. If you select the microcontroller while in the editor, you can type in an 8 character name for your aircraft which will be sent along with your positional data to all nearby control towers.

  ]]

freqLow = 500
freqHigh = 600

delayMax = 8
delay = delayMax

scanDelayMax = 500
scanDelay = scanDelayMax

freq = freqLow

resetFreq = true
first = true

callsign = string.sub(string.upper(property.getText("Callsign")), 1, 8)


function onTick()
	
	if first then
		first = false
		output.setNumber(13, freq)
		
		for i = 1, #callsign do
			output.setNumber(i + 4, string.byte(callsign, i))
		end
	end
	
	if resetFreq then --delay starts at maxDelay
		output.setBool(2, false)
		output.setNumber(13, freq)
		delay = delay - 1
		
		if delay <= 0 then
			delay = delayMax
			if input.getBool(1) then
				freq = freq + 1
				if freq >= freqHigh then freq = freqLow end
				output.setNumber(13, freq)
			else
				resetFreq = false
				output.setBool(2, true)
			end
		end
		
		
	else
		
		gpsX = input.getNumber(13)
		gpsY = input.getNumber(14)
		
		output.setNumber(1, gpsX)
		output.setNumber(2, gpsY)
		output.setNumber(3, input.getNumber(15)) --alt
		output.setNumber(4, input.getNumber(16)) --spd
		
		output.setBool(1, true)
		
		scanDelay = scanDelay - 1
		if scanDelay <= 0 then
			resetFreq = true
			scanDelay = scanDelayMax
		end
		
	end
end
