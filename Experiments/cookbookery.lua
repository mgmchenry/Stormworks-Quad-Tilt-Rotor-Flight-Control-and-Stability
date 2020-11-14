-- radar target mass =
-- Signal strength = Target Mass / Target Distance

--http://lua-users.org/wiki/StringRecipes
--Iterate over words in a string (adapted from Lua manual)
-- words and numbers
for word in str:gmatch("%w+") do ... end

-- identifiers in typical programming languages
for id in str:gmatch("[_%a][_%w]*") do ... end

-- whitespace-separated components (without handling quotes)
for id in str:gmatch("%S+") do ... end
--Iterate over lines in a buffer, ignoring empty lines
--(works for both DOS and Unix line ending conventions)
for line in str:gmatch("[^\r\n]+") do ... end
--Any of the above can also be done as a function iterator:

-- call func with each word in a string
str:gsub("%w+", func)


https://github.com/stravant/lua-minify/blob/master/minify.lua

https://www.lexaloffle.com/bbs/?tid=36804

local function writefile(filename, extension, input)
   local file = io.open(filename.."."..extension, "w")
  file:write(input)
file:close()
print('successfully created "'..filename..'.'..extension..'"')
end

--[[
PID notes -

https://www.reddit.com/r/Stormworks/comments/dk6kah/how_to_set_up_pid_ziglernicolson_method/
How to set up PiD (Zigler-Nicolson Method)
Como Volto V2 RIP since 0.9.6
https://steamcommunity.com/sharedfiles/filedetails/?id=1895231045

--]]

--[[

The string.char and string.byte functions convert between characters and their internal numeric representations. The function string.char gets zero or more integers, converts each one to a character, and returns a string concatenating all those characters. The function string.byte(s, i) returns the internal numeric representation of the i-th character of the string s; the second argument is optional, so that a call string.byte(s) returns the internal numeric representation of the first (or single) character of s. In the following examples, we assume that characters are represented in ASCII:

    print(string.char(97))                    -->  a
    i = 99; print(string.char(i, i+1, i+2))   -->  cde
    print(string.byte("abc"))                 -->  97
    print(string.byte("abc", 2))              -->  98
    print(string.byte("abc", -1))             -->  99
In the last line, we used a negative index to access the last character of the string.
The function string.format is a powerful tool when formatting strings, typically for output. It returns a formatted version of its variable number of arguments following the description given by its first argument, the so-called format string. The format string has rules similar to those of the printf function of standard C: It is composed of regular text and directives, which control where and how each argument must be placed in the formatted string. A simple directive is the character `%´ plus a letter that tells how to format the argument: `d´ for a decimal number, `x´ for hexadecimal, `o´ for octal, `f´ for a floating-point number, `s´ for strings, plus other variants. Between the `%´ and the letter, a directive can include other options, which control the details of the format, such as the number of decimal digits of a floating-point number:

    print(string.format("pi = %.4f", PI))     --> pi = 3.1416
    d = 5; m = 11; y = 1990
    print(string.format("%02d/%02d/%04d", d, m, y))
      --> 05/11/1990
    tag, title = "h1", "a title"
    print(string.format("<%s>%s</%s>", tag, title, tag))
      --> <h1>a title</h1>
In the first example, the %.4f means a floating-point number with four digits after the decimal point. In the second example, the %02d means a decimal number (`d´), with at least two digits and zero padding; the directive %2d, without the zero, would use blanks for padding. For a complete description of those directives, see the Lua reference manual. Or, better yet, see a C manual, as Lua calls the standard C libraries to do the hard work here.

--]]


--property hex parsing:
local function setPropColor(name, colors)
  colors = {}
  for hexByte in string.gmatch(property.getText(name), '%x%x') do
  	print("hexByte", tonumber(hexByte, 16))
    colors[#colors+1] = tonumber(hexByte, 16)
  end
  screen.setColor(table.unpack(colors))
end

function onTick()
end

function onDraw()
    w = screen.getWidth()
    h = screen.getHeight()
    setPropColor("buttonColor")
    screen.drawCircleF(w / 2, h / 2, 30)
    setPropColor("backColor")
    screen.drawCircleF(w / 3, h / 3, 20)   
end

-- some incomplete ideas on config parsing:
local configText = "background:FF00FF,button:0xFFFF00,etc:10A0B0"



function getConfig(text, configTable)
  configTable = configTable or {}
  for i1, kvpair in pairs(split(text, '([^,\r\n]+)')) do
    kvpair = split(kvpair, '[^:]+')
    ke
    for hexByte in string.gmatch(someHex,'%x%x') do
  print(tonumber(hexByte,16))
end

--interpreting axis inputs as button presses:
--https://discord.com/channels/357480372084408322/578586360336875520/773338162620661782
--quale
local channels = {}
local sensitivityValues = {40,30,20,10}

for i = 1, 4 do
    channels[i] = {value=0, unsmoothed=0, smoothed=0, sensitivity=sensitivityValues[i]^2}
end

function onTick()
    for i, c in ipairs(channels) do
        local current = input.getNumber(i)
        c.unsmoothed = c.value + (current - c.value) / c.sensitivity
        c.value = current
        c.smoothed = (c.smoothed*9 + current) / 10
    end
end

function onDraw()
    for i, c in ipairs(channels) do
        screen.drawText(0, 10 * i - 5, string.format('%+.2f', c.value))
        screen.drawText(15, 10 * i - 5, string.format('%+.2f', c.unsmoothed))
    end
end

--[[
jbaker roll correction discussion:
https://discord.com/channels/357480372084408322/525362818455699457/683593174622535681
[2:03 AM] jbaker96 (Boeing Autopilot): @Ritty tilt sensors dont measure tilt on one axis, they just measure their angle above the horizon
[2:03 AM] Ritty: Yeah don't worry, we've figured all that out
[2:04 AM] jbaker96 (Boeing Autopilot): last i saw you were talking about reading the angles from pivots and such though?
[2:05 AM] Ritty: Yeah I'm about to test that out actually.
[2:07 AM] jbaker96 (Boeing Autopilot): still sounds to me like youre working way too hard to get data from the tilt sensors
[2:07 AM] jbaker96 (Boeing Autopilot): if you want to measure roll all you have to do is point a tilt sensor left or right on your vehicle to measure your roll angle above the horizon, same for pitch
[2:07 AM] jbaker96 (Boeing Autopilot): just pointing forward for pitch
[2:07 AM] Ritty: Okay. But if you read what I said, I want 360*
[2:08 AM] Ritty: Tilt sensors only measure 180
[2:08 AM] jbaker96 (Boeing Autopilot): -90 to +90
[2:08 AM] jbaker96 (Boeing Autopilot): if you want 360 roll you need 1 tilt sensor pointing straight up, and all you need to do is check if its positive or negative
[2:08 AM] Ritty: Nope. Tried that.
[2:09 AM] Ritty: Seriously, read the entire conversation first. Because I've already gone through everything you've suggested so far
[2:09 AM] jbaker96 (Boeing Autopilot): if its positive, you can just use your current roll angle as given by the roll tilt sensor, if its negative you can just add 180 to the roll value
[2:09 AM] jbaker96 (Boeing Autopilot): ive literally done this before, trust me
[2:09 AM] Ritty: That's LITERALLY what I started with
[2:09 AM] jbaker96 (Boeing Autopilot): although wait dont do that, its slightly more complicated than that
[2:10 AM] Ritty: But it doesn't work. Because as soon as I pitch up, it starts skipping and displaying wrong numbers
[2:10 AM] jbaker96 (Boeing Autopilot): but seriously ive done this exact thing
[2:10 AM] jbaker96 (Boeing Autopilot): are you using lua? or just the regular logic blocks in the mc?
[2:10 AM] Ritty: read the conversation
[2:11 AM] RemKiwi: Can someone send me a good tutorial on how to make a multi propellor advanced plane?
[2:11 AM] MMorin2020: Have a brief issue regarding my stabilizers. If the positive side of the track is meant to point to the left, does that mean the tilt sensor should be pointing to the right?
[2:11 AM] jbaker96 (Boeing Autopilot): i did, and it seemed that through the entire conversation you didnt fully understand how tilt sensors worked
[2:11 AM] MMorin2020: I think I mixed it briefly.
[2:11 AM] Ritty: I'm not trying to be rude or anything, but it's actually frustrating me that you're just saying things i've done
[2:11 AM] jbaker96 (Boeing Autopilot): and im telling you exactly how ive done it and made it work
[2:12 AM] Ritty: So you're telling me
[2:12 AM] Ritty:

[2:12 AM] Ritty: You read this part?
[2:12 AM] jbaker96 (Boeing Autopilot): just gonna load up the game real quick so i can tell you exactly how i did it
[2:12 AM] Ritty: Where I explicitly explain the thing I set up that's pretty much what you suggested
[2:26 AM] jbaker96 (Boeing Autopilot): @Ritty

[2:26 AM] jbaker96 (Boeing Autopilot): if your setup did something like this it would work
[2:27 AM] jbaker96 (Boeing Autopilot): pretty much the same doesnt usually cut it in math
[2:27 AM] BossyMr: @Ritty Can’t you use two tilt sensors then? One pointing up and one down, you could then figure out the tilt as a combination of the two.
[2:29 AM] jbaker96 (Boeing Autopilot): that setup in my pic will give you -180 to +180 roll
[2:29 AM] jbaker96 (Boeing Autopilot): or 0 - 360 if you just add 180 to the output
[2:31 AM] Aussie_Alaskan: @Nova the Protogen

[2:32 AM] Ritty: Is there any reason why the formulas aren't just 
180 - x and
-180 - x?
[2:33 AM] jbaker96 (Boeing Autopilot): yes, its to make sure that x is subtracted from the 90 before the rest is added up
[2:33 AM] jbaker96 (Boeing Autopilot): you could also do 90-x+90
[2:33 AM] jbaker96 (Boeing Autopilot): and -90-x-90 for the second one
[2:35 AM] jbaker96 (Boeing Autopilot): actually ya you could do that
[2:58 AM] Ritty: Okay so I went to the effort of setting everything up exactly as you described.
[2:58 AM] Ritty: Not only does it do what my original setup did
[2:59 AM] Ritty: It ALSO suffers the same issue
[2:59 AM] Ritty: https://puu.sh/FfYwL/66fb0059dd.mp4
[2:59 AM] Ritty: Ignore the horizon, visual, focus on the numbers. Especially when I'm pitching up a lot, you'll see it skip large numbers (Like from 70 to 120*)
[3:29 AM] jbaker96 (Boeing Autopilot): that is due to a slightly different issue
[3:30 AM] jbaker96 (Boeing Autopilot): take for example if your pitch angle is 0 degrees relative to the horizon, then if you do a complete roll, your roll sensor will be able to go a full 90 degrees above and below the horizon
[3:30 AM] jbaker96 (Boeing Autopilot): but if your pitch is 90 degrees relative to the horizon, your roll sensor will never be able to leave the horizon, constantly outputting 0
[3:31 AM] jbaker96 (Boeing Autopilot): and its linear between 0 and 90 degrees pitch, so if you pitch up 45 degrees, the farthest the roll sensor can be from the horizon is 45 degrees
[3:32 AM] jbaker96 (Boeing Autopilot): to solve that you have to plug both the pitch angle and the roll angle through an equation to correct the roll angle so it is relative to the aircraft instead of the horizon
[3:35 AM] jbaker96 (Boeing Autopilot): all you have to do is convert your pitch angle from a forward facing tilt sensor into degrees by multiplying it by 360, then plug it into the y value of a function block, and plug the roll sensor directly into the x value of the function block and use this (asin((sin(x*pi2))/(sin((90-y)*(pi/180)))))*(180/pi) then take the output of that and use that for your roll angle input in the picture i posted
[3:36 AM] jbaker96 (Boeing Autopilot): and that output is in degrees
[3:40 AM] Ritty: Mmm. I appreciate the equation but I don't like using things I don't fully understand and I've now actually gotten the velocity pivot sensor working great
[3:41 AM] Ritty: It needs some fine tuning on the PID, but otherwise it does exactly what I want it to
[3:41 AM] jbaker96 (Boeing Autopilot): thats a wonky and overly complicated way of solving a simple problem but whatever floats your boat
[3:42 AM] Ritty: PID + velocity pivot actually isn't complicated at all, but okay.
[3:42 AM] jbaker96 (Boeing Autopilot): its moving parts
[3:42 AM] jbaker96 (Boeing Autopilot): adds complexity to a vehicle and more places for things to go wrong
[3:43 AM] Ritty: I'm sure a 1x1x2 spinning block will cause me a lot of problems
[3:43 AM] jbaker96 (Boeing Autopilot): takes up more space than a function block in an mc too
[3:44 AM] jbaker96 (Boeing Autopilot): all im sayin is you could get perfectly accurate results not just really close results while not worrying about any potential issues no matter how small

--]]


--[[
Intersection of two circles
Attempt 1 based on intercept angle:
https://www.desmos.com/calculator/fqxhrg2pzh
Attempt 2 with arbitrary x/y:
https://www.desmos.com/calculator/xnbtj957gg

also good:
https://stackoverflow.com/questions/3349125/circle-circle-intersection-points

Desmos 3d plot fun:
https://www.desmos.com/calculator/ongcgqgcpr

--]]

function getIntersections(x1,y1,r1,x2,y2,r2)
  distance = sqrt((x1-x2)^2 + (y1-y2)^2)
  -- distance from xy1 to xy2 = aSide+bSide. 
  -- aSide is distance from xy1 to intersection line. 
  -- b is distance from xy2 to intersection line
  -- from xy1, h = hypotenuse = r1
  -- aSide is adjacent side of right triangle
  -- oSide is opposite side or right triangle. Intersections are at +/- o
  aSide = (r1^2 - r2^2 + distance^2) / distance / 2
  oSide = sqrt(r1^2 - aSide^2)
  aX = x1 + (x2-x1) * aSide / distance
  aY = y1 + (y2-y1) * aSide / distance

  oX = ( y1 - y2 ) * oSide / distance
  oY = ( x2 - x1 ) * oSide / distance

  return {aX+oX,aY+oY}, {aX-oX,aY-oY}
end

-- goofy boolean truth table for n columns I did one day
columnCount = 5 or whatever
gears = {}

for i = 1, 2^columnCount do
  gears[i] = {i}
  for i2 = columnCount-1, 0, -1 do
    oneMeansTrue = ((i-1)/2^(i2) % 2) >= 1 
    gears[i][columnCount-i2+1] = oneMeansTrue
  end
  print(unpack(gears[i]))
end
