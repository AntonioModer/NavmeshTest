local vec = require("utils.math.vec")

-- tests

-- signed triangle area
local cw = { -1,0, 0,1, 1,0 }
assert(vec.sta2(unpack(cw)) < 0)
local ccw = { 1,0, 0,1, -1,0 }
assert(vec.sta2(unpack(ccw)) > 0)
local cl = { 1,0, 0,0, -1,0 }
assert(vec.sta2(unpack(cl)) == 0)

-- point in triangle
-- test vertices
assert(vec.pit(0,0, 0,1, 1,0, 0,0) == false)
assert(vec.pit(0,0, 0,1, 1,0, 0,1) == false)
assert(vec.pit(0,0, 0,1, 1,0, 1,0) == false)
-- test edges
assert(vec.pit(0,0, 0,1, 1,0, 0,1/2) == false)
assert(vec.pit(0,0, 0,1, 1,0, 1/2,0) == false)
assert(vec.pit(0,0, 0,1, 1,0, math.sqrt(1),math.sqrt(1)) == false)
-- test outside point
assert(vec.pit(0,0, 0,1, 1,0, 1,1) == false)
-- test inside point
assert(vec.pit(0,0, 0,1, 1,0, 0.1,0.1) == true)

-- point in circle
-- test perimeter
assert(vec.pic(0,0, 1, 1,0) == false)
assert(vec.pic(0,0, 1, -1,0) == false)
-- test outside point
assert(vec.pic(0,0, 1, 2,0) == false)
assert(vec.pic(0,0, 1, -2,0) == false)
-- test points
for i = 1, 100000 do
  local r = math.random()*math.pi
  local c, s = math.cos(r), math.sin(r)
  local m = math.random()
  -- inside
  local x = c*(m%1)
  local y = s*(m%1)
  assert(vec.pic(0,0, 1, x,y) == true)
  -- perimeter
  local x2 = c
  local y2 = s
  --assert(vec.pic(0,0, 1, x2,y2) == false)
  -- outside
  local x3 = c*(m%1 + 1)
  local y3 = s*(m%1 + 1)
  --assert(vec.pic(0,0, 1, x3,y3) == false)
end

-- point in ellipse
-- test perimeter
assert(vec.pie(0,0, 1,2, 1,0) == false)
assert(vec.pie(0,0, 1,2, 0,2) == false)
-- test outside point
assert(vec.pie(0,0, 1,2, 2,0) == false)
assert(vec.pie(0,0, 1,2, -2,0) == false)
-- test inside point
assert(vec.pie(0,0, 1,2, 0,0) == true)

-- point in rectangle
-- test vertices
assert(vec.pir(0,0, 1,2, 1,2) == false)
assert(vec.pir(0,0, 1,2, -1,2) == false)
assert(vec.pir(0,0, 1,2, 1,-2) == false)
assert(vec.pir(0,0, 1,2, -1,-2) == false)
-- test inside points
for i = 1, 100000 do
  local x = (math.random()*2 - 1)%1
  local y = (math.random()*2 - 1)%1*2
  assert(vec.pir(0,0, 1,2, x,y) == true)
end

local _out = {}
local function randf()
  for i = 1, 6 do
    _out[i] = (math.random()*2 - 1)
  end
  return unpack(_out)
end
local function randi()
  for i = 1, 6 do
    _out[i] = math.random(-2^16, 2^16)
  end
  return unpack(_out)
end

local tests = {}
function tests.len(x1,y1)
  local L1 = vec.len(x1,y1)
  local L2 = vec.len(y1,x1)
  return L1, L2
end
function tests.len_len2(x1,y1)
  -- len and len2
  local L1 = vec.len(x1,y1)^2
  local L2 = vec.len2(x1,y1)
  return L1, L2
end
function tests.dist(x1,y1, x2,y2)
  local L1 = vec.dist(x1,y1, x2,y2)
  local L2 = vec.dist(x2,y2, x1,y1)
  return L1, L2
end
function tests.dist_dist2(x1,y1, x2,y2)
  local L1 = vec.dist(x1,y1, x2,y2)^2
  local L2 = vec.dist2(x1,y1, x2,y2)
  return L1, L2
end
function tests.dot(x1,y1, x2,y2)
  -- dot product
  local D1 = vec.dot(x1,y1, x2,y2)
  local D2 = vec.dot(x2,y2, x1,y1)
  return D1, D2
end
function tests.cross(x1,y1, x2,y2)
  -- cross product
  local C1 = vec.cross(x1,y1, x2,y2)
  local C2 = -vec.cross(x2,y2, x1,y1)
  return C1, C2
end
function tests.vang(x1,y1, x2,y2, x3,y3)
  -- angle between vectors
  local A1 = vec.vang(x1,y1, x2,y2)
  local A2 = -vec.vang(x2,y2, x1,y1)
  return A1, A2
end
function tests.vang2(x1,y1, x2,y2, x3,y3)
  -- angle between vectors
  local A1 = vec.vang2(x1,y1, x2,y2)
  local A2 = -vec.vang2(x2,y2, x1,y1)
  return A1, A2
end
function tests.vang_vang2(x1,y1, x2,y2)
  local A1 = vec.vang(x1,y1, x2,y2)
  local A2 = vec.vang2(x1,y1, x2,y2)
  return A1, A2
end
function tests.sta(x1,y1, x2,y2, x3,y3)
  local STA1 = vec.sta2(x1,y1,x2,y2,x3,y3)
  local STA2 = -vec.sta2(x3,y3,x2,y2,x1,y1)
  return STA1, STA2
end
function tests.sta_cross(x1,y1, x2,y2, x3,y3)
  -- signed triangle area vs cross product
  local STA1 = vec.sta2(x1,y1, x2,y2, x3,y3)
  local STA2 = vec.cross(x1-x3, y1-y3, x2-x3, y2-y3)
  return STA1, STA2
end

local epsilon = 1/math.pi -- must be > 0
local repsilon = 1/epsilon

local function testall(n, rand)
  local errors = {}
  for tn in pairs(tests) do
    errors[tn] = 0
  end
  for i = 1, n do
    local x1,y1, x2,y2, x3,y3 = rand()
    for tn, test in pairs(tests) do
      local v1, v2 = test(x1,y1, x2,y2, x3,y3)
      if v2 > v1 then
        v1, v2 = v2, v1
      end
      local diff = math.abs(v1 - v2)
      local a1 = math.abs(v1)
      local e = diff/math.max((repsilon*a1), epsilon)
      -- abs(v1 - v2) <= max(abs_epsilon, rel_epsilon*max(abs(v1), abs(v2)))
      if e > errors[tn] then
        errors[tn] = e
      end
    end
  end
  return errors
end

local ntests = 100000

local errorsi = testall(ntests, randi)
local errorsf = testall(ntests, randf)

local out = { "error margins for " .. ntests .. " tests (epsilon: " .. repsilon .. ")" }
for tn in pairs(tests) do
  local ei = errorsi[tn]*100
  local ef = errorsf[tn]*100
  out[#out + 1] = string.format('"%s" int:%g%% float:%g%%', tn, ei, ef)
end
error(table.concat(out, "\n"))
