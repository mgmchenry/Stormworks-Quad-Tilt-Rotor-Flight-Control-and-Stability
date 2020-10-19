This is a good example of the code I'm writing that I hate (simplified)
```lua
      local bufferPosition
        , signal
        , cascadeMap
        , valueBuffer
        , cascadeElement
        , currentValue, previousValue, delta

      = signalSet[t_bufferPosition]
        , signalSet[signalKey]

      -- cascadeMap contruction - value delta is velocity. velocity delta is accel
        , tableValuesAssign(nilzies, {t_Value, t_Velocity}, {t_Velocity, t_Accel})
      
      valueBuffer = signal[t_buffers] -- firt get buffer container for this signal
      valueBuffer = valueBuffer[elementKey] -- inside, buffer for this element

      currentValue = moduloCorrect(values[i],signal[t_modPeriod],signal[t_modOffset])

      signal[elementKey] = currentValue
      valueBuffer[bufferPosition] = currentValue
      cascadeElement = cascadeMap[elementKey]

      if cascadeElement then
        -- def: this[f_sGetSmoothedValue] = function(signalSet, signalKey, elementKey, smoothTicks, delayTicks)
        currentValue = this[f_sGetSmoothedValue](signalSet, signalKey, elementKey, 3)
        -- smoothed over 3 ticks should be decent
        previousValue = this[f_sGetSmoothedValue](signalSet, signalKey, elementKey, 3, 1)

        delta = moduloCorrect(
          currentValue - previousValue
          ,signal[t_modPeriod],signal[t_modOffset]
          ) * ticksPerSecond

        --signal[cascadeElement] = delta
        -- ^ doesn't cut it because velocity won't cascade to accel that way
        -- so:
        -- def: this[f_sAssignValues] = function(signalSet, values, elementKey, signalKeys)
        this[f_sAssignValues](signalSet, {delta}, cascadeElement, {signalKey})
        
      end
    end
  end
