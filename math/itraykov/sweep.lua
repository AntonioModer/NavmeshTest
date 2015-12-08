--
-- Sweeping or dynamic intersection tests
-- Based on Real-Time Collision Detection by Christer Ericson
--

require("utils.math.common")
local intersect = require("utils.math.intersect")
local project = require("utils.math.project")

local length = math.length
local min, max = math.min, math.max
local line_vs_circle = intersect.line_circle
local line_vs_raabb = intersect.line_raabb
local aabb_vs_aabb = intersect.aabb_aabb
local point_on_aabb = project.aabb

local sweep = {}

--   .-'''-.
--  /       \   v
-- |  (c1)---|-->  .-'''-.
--  \       /     /       \
--   `-...-'     |   (c2)  |
--                \       /
--                 `-...-'

-- Tests moving circle (c1) vs static circle (c2)
-- Returns time of impact (0-1), collision normal and point
function sweep.circle_circle(c1x, c1y, radius1, c2x, c2y, radius2, vx, vy)
  local radii = radius1 + radius2
  local qx, qy, t = line_vs_circle(c1x, c1y, vx + c1x, vy + c1y, c2x, c2y, radii)
  if t == nil then
    return
  end

  -- collision point
  local qx = (c2x - qx)/radii*radius1 + qx
  local qy = (c2y - qy)/radii*radius1 + qy

  -- collision normal
  local v = length(vx, vy)
  local nx = (c1x + vx/v*t) - qx
  local ny = (c1y + vy/v*t) - qy
  local d = length(nx, ny)
  nx = nx/d
  ny = ny/d

  return t/v, nx, ny, qx, qy
end

--   .-'''-.
--  /       \   v
-- |   (c)---|-->  ---------
--  \       /      |       |
--   `-...-'       |  (r)  |
--                 |       |
--                 --------- 

-- Tests moving circle (c) vs static aabb (r)
-- Returns time of impact (0-1), collision normal and point
function sweep.circle_aabb(cx, cy, radius, l, t, r, b, vx, vy)
  local bx, by = vx + cx, vy + cy

  local l2 = l - radius
  local r2 = r + radius
  local t2 = t - radius
  local b2 = b + radius

  local qx, qy, tq = line_vs_raabb(cx, cy, bx, by, l2, t2, r2, b2, radius)
  if tq == nil then
    return
  end

  -- collision point
  local v = length(vx, vy)
  local qt = tq/v
  local px, py = point_on_aabb(cx + vx*qt, cy + vy*qt, l, t, r, b)

  -- collision normal
  local nx = qx - px
  local ny = qy - py
  local n = length(nx, ny)
  nx = nx/n
  ny = ny/n

  return qt, nx, ny, px, py
end

--  ----------
--  |        |  v
--  |  (r1)--|-->  ----------
--  |        |     |        |
--  ----------     |  (r2)  |
--                 |        |
--                 ---------- 

-- Tests moving aabb (r1) vs static aabb (r2)
-- Returns time of impact (0-1), collision normal and point(s)
function sweep.aabb_aabb(l1, t1, r1, b1, l2, t2, r2, b2, vx, vy)
  if aabb_vs_aabb(l1, t1, r1, b1, l2, t2, r2, b2) == true then
    -- todo: separate and figure out collision point if they are initially overlapping
    return 0
  end
  local tfirst, tlast = 0, 1
  if vx < 0 then
    if r1 <= l2 then
      return
    end
    if r2 < l1 then
      tfirst = max((r2 - l1)/vx, tfirst)
    end
    if r1 > l2 then
      tlast = min((l2 - r1)/vx, tlast)
    end
  elseif vx > 0 then
    if l1 >= r2 then
      return
    end 
    if r1 < l2 then
      tfirst = max((l2 - r1)/vx, tfirst)
    end
    if r2 > l1 then
      tlast = min((r2 - l1)/vx, tlast)
    end
  else
    if r2 < l1 or l2 > r1 then
      return
    end
  end
  if tfirst > tlast then
    return
  end

  if vy < 0 then
    if b1 <= t2 then
      return
    end
    if b2 < t1 then
      tfirst = max((b2 - t1)/vy, tfirst)
    end
    if b1 > t2 then
      tlast = min((t2 - b1)/vy, tlast)
    end
  elseif vy > 0 then
    if t1 >= b2 then
      return
    end 
    if b1 < t2 then
      tfirst = max((t2 - b1)/vy, tfirst)
    end
    if b2 > t1 then
      tlast = min((b2 - t1)/vy, tlast)
    end
  else
    if b2 < t1 or t2 > b1 then
      return
    end
  end
  if tfirst > tlast then
    return
  end

  -- collision point
  local tx, ty = vx*tfirst, vy*tfirst
  local q1x, q1y = point_on_aabb(l1 + tx, t1 + ty, l2, t2, r2, b2)
  local q2x, q2y = point_on_aabb(r1 + tx, b1 + ty, l2, t2, r2, b2)

  -- collision normal: todo
  local nx = 0
  local ny = 0
  if q1x <= l2 and q2x <= l2 then
    nx = -1
  elseif q1x >= r2 and q2x >= r2 then
    nx = 1
  elseif q1y <= t2 and q2y <= t2 then
    ny = -1
  elseif q1y >= b2 and q2y >= b2 then
    ny = 1
  end
  return tfirst, nx, ny, q1x, q1y, q2x, q2y
end

return sweep