--interpreting axis inputs as button presses:
--https://discord.com/channels/357480372084408322/578586360336875520/773338162620661782
--quale
-- https://www.desmos.com/calculator/2e7ong62us
local 
  channels, buffers
  , buffLen, buffPos
  , axis
  , b1Down, b2Down, b3Down

  = {}, {}
  , 60, 0
  , 
  {
    {.40, {255,0,0}, .1}
    ,{.30, {0,255,0}, .2}
    ,{.20, {0,0,255}, .4}
    ,{.10, {200,200,200}, .6}
  }

for i, conf in ipairs(axis) do
  channels[i] = {val=0, keyDown=0, sVal=0, sensitivity=conf[1]^2
    , power=0
    , attack=0, decay=0, arkAxis=0}
  buffers[i] = {{},{}}
end
buffers[5] = {}

M = math
abs, min, max 
  = M.abs, M.min, M.max

baserate = 1/60

function onTick()
  buffPos = buffPos % buffLen + 1
  for i, c in ipairs(channels) do
      local current = input.getNumber(i)
      c.keyDown = M.floor(
        (c.val + (current - c.val) / c.sensitivity) 
        * 10 + 0.5
        ) / 10
      c.val = current
      c.sVal = (c.sVal*9 + current) / 10
      c.power = c.sVal ^ 2
      buffers[i][1][buffPos] = current

      rate = axis[i][3]
      if abs(c.keyDown)>0 then
        c.attack = min(1, c.attack + baserate * rate * 2)
        c.decay = max(0, c.decay - baserate * rate * 4)
      else
        c.decay = min(1, c.decay + baserate * rate * 0.5)
        c.attack = max(0, c.attack - baserate * rate)
      end

      c.arkAxis =min(1, max(-1
        , c.arkAxis 
        - c.arkAxis * c.decay ^ 2
        + c.keyDown * c.attack * baserate * 2))
      buffers[i][2][buffPos] = c.arkAxis      
  end
  b1Down = input.getBool(1)
  b2Down = input.getBool(2)
  b3Down = input.getBool(3)
end

S=screen
sDL,sDT=S.drawLine,S.drawText
setC = function(c,l,c2) --r,g,b,a
  l = l or 0.4
  c2={}
  for i=1,3 do
    c2[i]=c[i] and (c[i]*l) or 0
  end
  c2[4] = c[4]
  S.setColor(table.unpack(c2))
end

goal = 0
change = 1
nextChange = 1

function onDraw()

  local sW, sH
    = S.getWidth()
    , S.getHeight()

  goal = (goal + change*baserate*.05) % 2
  change = change + min(baserate, max(-baserate, nextChange-change))
  gate = M.sin(goal * M.pi)
  if change==nextChange then
    nextChange = gate>.1 and gate or goal
  end
  buffers[5][buffPos] = gate
	--S.drawClear()
	
  for i,conf in ipairs(axis) do
    buffer = buffers[i][b1Down and 2 or 1]
    for xi=buffLen-1,1,-1 do
      sVal=nil
      local lx0
        , lx1
        , lMin, lRange
        , lVal0, lVal1 

        = (sW) * (xi - 1) / buffLen-1
        , (sW) * xi / buffLen-1
        , -1, 2
        , buffer[(buffPos-xi) % buffLen+1] or 0
        , buffer[(buffPos-xi-1) % buffLen+1] or 0

      lVal0, lVal1
        = (lVal0 - lMin)/lRange * sH
        , (lVal1 - lMin)/lRange * sH

      setC(axis[i][2])
      sDL(
        lx0
        , sH - lVal0
        , lx1
        , sH - lVal1)
      if b3Down then
        sVal=(sVal or lVal1)*.9+lVal1*.05+lVal0*.05

        setC(axis[i][2],0.2)
        sDL(
          lx0
          , sH - sVal - 1
          , lx0
          , sH - sVal + 1)
      end      
      if b2Down then      
        lVal0, lVal1
          = buffer[(buffPos-xi) % buffLen+1] or 0
          , buffer[(buffPos-xi-1) % buffLen+1] or 0

        lVal0, lVal1
          = (abs(lVal0)*lVal0 - lMin)/lRange * sH
          , (abs(lVal1)*lVal1 - lMin)/lRange * sH

        setC(axis[i][2],0.3)
        sDL(
          lx0-3
          , sH - lVal0-3
          , lx1+2
          , sH - lVal1+2)
        sDL(
          lx0+2
          , sH - lVal0-3
          , lx1-3
          , sH - lVal1+2)
      end
      
      setC({200,0,200}, xi / buffLen / 2 + 0.2 )
      gate = buffers[5][(buffPos-xi) % buffLen+1] or 0
      gate = sH * (gate + 1) / 2
      sDL(
          lx0
        , gate - 5
        , lx0
        , gate - 10)
        
      sDL(
          lx0
        , gate + 5
        , lx0
        , gate + 10)

    end
  end

  if b1Down then
    sDT(0, 0, "  Raw|Key| Atk | Dcy | arkAxis     Sensitivity")
    for i, c in ipairs(channels) do
      setC(axis[i][2])
      sDT(0, 10 * i, 
        string.format('%+.2f| %+i|%+.2f|%+.2f| %+.2f      axis-%02i %i%%'
        , c.sVal, c.keyDown, c.attack, c.decay, c.arkAxis, i, axis[i][3]*100))
    end

  else
    sDT(0, 0, "Smooth| Key|Raw Val    Sensitivity   Val^2")
    for i, c in ipairs(channels) do
      setC(axis[i][2])
      sDT(0, 10 * i, 
        string.format(' %+.2f|%+.1f|%+.4f    axis-%02i %i%%  %+.4f'
        , c.sVal, c.keyDown, c.val, i, axis[i][1]*100, c.power))
    end
  end
end