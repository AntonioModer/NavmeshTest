local sin = math.sin
local pi = math.pi
local floor = math.floor
local pow = math.pow
local sqrt = math.sqrt
local abs = math.abs

local wave = {}

function wave.sin(x)
  return sin(x*pi)
end

function wave.saw(x)
  return (x + 1)%2 - 1
end

function wave.tri(x)
  return abs(1 - (x - 0.5)%2)*2 - 1
end

function wave.square(x, dc)
  dc = dc or 0.5
  local t = (x + 0.5)%1
  local a = floor(t/0.5)
  if t >= 1*dc then
    return 1
  else
    return 0
  end
end

function wave.lerp(e)
  return e
end

function wave.quad(e)
  return e^2
end

function wave.cubic(e, p)
  return e^3
end

function wave.quart(e, p)
  return e^4
end

function wave.quint(e, p)
  return e^5
end
--[[
function wave.expo(e, p)
  return pow(2, 10*((e/p) - 1))
end

function wave.circ(e, p)
  return sqrt(1 - (e/p)^2) - 1
end
]]
-- t = time: current or running time
-- b = begin: initial value
-- c = change: final - initial value
-- d = duration: total time for the tween
function wave.back(x, s)
--[[
  s = s or 1.70158
  x = (x - 1)
  return (((s + 1)*x + s)*x*x + 1)/2
  ]]
  if not s then s = 1.70158 end
  s = s * 1.525
  x = abs(x)
  x = x*2
  if x < 1 then
    return -1 --(x*x*((s + 1)*x - s)) - 1
  else
    x = x - 2
    return (x*x*((s + 1)*x + s) + 2) - 1
  end
end

return wave