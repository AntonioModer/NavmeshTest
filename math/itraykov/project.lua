--
-- Point projections
-- Based on Real-Time Collision Detection by Christer Ericson 
--
-- Given a point (p) and shape (b):
-- Returns the closest point (q) on the shape (b)
-- Returns the original point (p) if it lies inside the shape area
--

local vec = require("utils.math.vec")

local dot = vec.dot

local sqrt = math.sqrt
local min = math.min
local max = math.max

local project = {}

--[[
--  \
--  (a)
--    \
--     \
--     (b)
--       \    (p)
--       (q)
--         \

function project.line(px, py, ax, ay, bx, by)
  -- todo: could probably be simplified
  local dx, dy = bx - ax, by - ay
  local npx, npy = px - ax, py - ay
  local d1 = dot(npx, npy, dx, dy)
  local d2 = dot(dx, dy, dx, dy)
  assert(d2 ~= 0, "line has zero length")
  local u = d1/d2
  local qx = ax + u*dx
  local qy = ay + u*dy
  return qx, qy
end
]]

-- (a)
--   \
--    \       (p)
--     \
--     (q)
--       \
--       (b)

function project.segment(px, py, ax, ay, bx, by)
  local dx, dy = bx - ax, by - ay
  local npx, npy = px - ax, py - ay
  local d1 = dot(npx, npy, dx, dy)
  local d2 = dot(dx, dy, dx, dy)
  assert(d2 ~= 0, "segment has zero length")
  local u = d1/d2
  if u < 0 then
    u = 0
  else
    if u > 1 then
      u = 1
    end
  end
  local qx = ax + u*dx
  local qy = ay + u*dy
  return qx, qy
end

--      (b)
--     /  \  (p)
--    /   (q)
--   /      \
-- (a)------(c)

function project.triangle(px, py, ax, ay, bx, by, cx, cy)
  local abx, aby = bx - ax, by - ay
  local acx, acy = cx - ax, cy - ay
  local apx, apy = px - ax, py - ay
  -- vertex region outside a
  local d1 = dot(abx, aby, apx, apy)
  local d2 = dot(acx, acy, apx, apy)
  if d1 <= 0 and d2 <= 0 then
    return ax, ay
  end
  -- vertex region outside b
  local bpx, bpy = px - bx, py - by
  local d3 = dot(abx, aby, bpx, bpy)
  local d4 = dot(acx, acy, bpx, bpy)
  if d3 >= 0 and d4 <= d3 then
    return bx, by
  end
  -- edge region ab
  local vc = d1*d4 - d3*d2
  if vc <= 0 and d1 >= 0 and d3 <= 0 then
    local v = d1/(d1 - d3)
    local qx = ax + abx*v
    local qy = ay + aby*v
    return qx, qy
  end
  -- vertex region outside c
  local cpx, cpy = px - cx, py - cy
  local d5 = dot(abx, aby, cpx, cpy)
  local d6 = dot(acx, acy, cpx, cpy)
  if d6 >= 0 and d5 <= d6 then
    return cx, cy
  end
  -- edge region ac
  local vb = d5*d2 - d1*d6
  if vb <= 0 and d2 >= 0 and d6 <= 0 then
    local w = d2/(d2 - d6)
    local qx = ax + acx*w
    local qy = ay + acy*w
    return qx, qy
  end
  -- edge region bc
  local va = d3*d6 - d5*d4
  if va <= 0 then
    local d43 = d4 - d3
    local d56 = d5 - d6
    -- assert(d43 > 0 and d56 > 0)
    -- todo: probably an unnecessary check
    if d43 >= 0 and d56 >= 0 then
      local w = d43/(d43 + d56)
      local qx = bx + (cx - bx)*w
      local qy = by + (cy - by)*w
      return qx, qy
    end
  end
  -- inside face region
--[[
  -- compute qx, qy using barycentric coords
  local denom = 1/(va + vb + vc)
  local v = vb*denom
  local w = vc*denom
  local qx = ax + abx*v + acx*w
  local qy = ay + aby*v + acy*w
  return qx, qy
  ]]
  return px, py
end

--   .-'''-.    (p)
--  /      (q)
-- |   (c)   |
--  \       /
--   `-...-'

function project.circle(px, py, cx, cy, cr)
  local dx, dy = px - cx, py - cy
  local d = sqrt(dx*dx + dy*dy)
  -- point is inside the circle
  if d <= cr then
    return px, py
  end
  local qx = dx/d*cr + cx
  local qy = dy/d*cr + cy
  return qx, qy
end

-- ----------
-- |       (q)  (p)
-- |   (r)  |
-- |        |
-- ----------

function project.rect(px, py, x, y, hw, hh)
  local qx, qy = px - x, py - y
  if qx > hw then
    qx = hw
  elseif qx < -hw then
    qx = -hw
  end
  if qy > hh then
    qy = hh
  elseif qy < -hh then
    qy = -hh
  end
  return qx + x, qy + y
end

return project