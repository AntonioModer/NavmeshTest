--
-- Static intersection tests
-- Based on Real-Time Collision Detection by Christer Ericson 
--
-- Given two shapes (a) and (b):
-- Returns true if they intersect or false otherwise
--

local vec = require("utils.math.common")
local project = require("utils.math.project")

local sqrt = math.sqrt
local abs = math.abs
local min = math.min
local max = math.max

local dot = vec.dot
local sta = vec.sta
local cross = vec.cross

local point_on_triangle = project.triangle
local point_on_segment = project.segment

--
-- Point
--

local function point_vs_point(px, py, p2x, p2y)
  return px == p2x and py == p2y
end

local function point_vs_segment(px, py, ax, ay, bx, by)
  assert(false, "unsupported")
end

--      (b)
--     /   \
--    /     \  (p)
--   /       \
-- (a)-------(c)

local function point_vs_triangle(px, py, ax, ay, bx, by, cx, cy)
  -- todo: cross has changed now!
  local pab = cross(px - ax, py - ay, bx - ax, by - ay) < 0
  local pbc = cross(px - bx, py - by, cx - bx, cy - by) < 0
  if pab ~= pbc then
    return false
  end
  local pca = cross(px - cx, py - cy, ax - cx, ay - cy) < 0
  if pab ~= pca then
    return false
  end
  return true
end

--   .-'''-.
--  /       \  (p)
-- |   (c)   |
--  \       /
--   `-...-'

local function point_vs_circle(px, py, cx, cy, r)
  local dx, dy = px - cx, py - cy
  local distsq = dx*dx + dy*dy
  return distsq <= r*r
end

--             (p)
-- -----------
-- |         |
-- |         |
-- |         |
-- -----------

local function point_vs_rect(px, py, rx, ry, hw, hh)
  if abs(px - rx) > hw then
    return false
  end
  if abs(py - ry) > hh then
    return false
  end
  return true
end


--
-- Segment
--

local function segment_vs_point(ax, ay, bx, by, ...)
  return point_vs_segment(..., ax, ay, bx, by)
end

--  (d)
--    \  (b)
--     \ / 
--      x
--     / \
--   (a)  \
--        (c)

local function segment_vs_segment(ax, ay, bx, by, cx, cy, dx, dy)
  local sa1 = sta(ax, ay, bx, by, dx, dy)
  local sa2 = sta(ax, ay, bx, by, cx, cy)
  if sa1*sa2 >= 0 then
    return false
  end
  local sa3 = sta(cx, cy, dx, dy, ax, ay)
  local sa4 = sa3 + sa2 - sa1
  if sa3*sa4 >= 0 then
    return false
  end
  return true
end

--        (x2,y2)
--      (b) /
--      / \/
--     /  /\
--    /(x,y)\
--   /       \
-- (a)-------(c)

local function segment_vs_triangle(x, y, x2, y2, ax, ay, bx, by, cx, cy)
  -- todo: brute force, generally you want to return false asap
  -- test segment (x,y,x2,y2) vs each tiangle edge
  if segment_vs_segment(x, y, x2, y2, ax, ay, bx, by) then return true end
  if segment_vs_segment(x, y, x2, y2, bx, by, cx, cy) then return true end
  if segment_vs_segment(x, y, x2, y2, cx, cy, ax, ay) then return true end
  -- is segment (x,y,x2,y2) inside triangle (a,b,c)
  if point_vs_triangle(x, y, ax, ay, bx, by, cx, cy) then return true end
  if point_vs_triangle(x2, y2, ax, ay, bx, by, cx, cy) then return true end
  return false
end

--    (b)
--      \ .-'''-.
--       /       \
--      | \ (c)   |
--       \(a)    /
--        `-...-'

local function segment_vs_circle(x, y, x2, y2, cx, cy, cr)
  -- project circle center on the segment
  local qx, qy = point_on_segment(cx, cy, x, y, x2, y2)
  local dx, dy = qx - cx, qy - cy
  -- compare the distance to radius
  local distsq = dx*dx + dy*dy
  return distsq <= cr*cr
end

--  (b)
--    \________
--    |\      |
--    | \     |
--    |(a)    |
--    ---------

local function segment_vs_rect(x, y, x2, y2, rx, ry, rhw, rhh)
  -- Liang-Barsky
  local dx = x2 - x
  local dy = y2 - y
  local l, t = rx - rhw, ry - rhh
  local r, b = rx + rhw, ry + rhh
  -- left
  local p, q = -dx, -(l - x)
  local r = q/p
  if p == 0 and q < 0 then
    return false
  elseif p < 0 and r > 1 then
    return false
  elseif p > 0 and r < 0 then
    return false
  end
  -- right
  p, q = dx, r - x
  r = q/p
  if p == 0 and q < 0 then
    return false
  elseif p < 0 and r > 1 then
    return false
  elseif p > 0 and r < 0 then
    return false
  end
  -- bottom
  p, q = -dy, -(b - y)
  r = q/p
  if p == 0 and q < 0 then
    return false
  elseif p < 0 and r > 1 then
    return false
  elseif p > 0 and r < 0 then
    return false
  end
  -- top
  p, q = dy, t - y
  r = q/p
  if p == 0 and q < 0 then
    return false
  elseif p < 0 and r > 1 then
    return false
  elseif p > 0 and r < 0 then
    return false
  end
  return true
end

--
-- Triangle
--

local function triangle_vs_point(ax, ay, bx, by, cx, cy, ...)
  return point_vs_triangle(..., ax, ay, bx, by, cx, cy)
end

local function triangle_vs_segment(ax, ay, bx, by, cx, cy, ...)
  return segment_vs_triangle(..., ax, ay, bx, by, cx, cy)
end

--          (b2)
--          / \
--     (b) /   \
--      /\/     \
--     / /\      \
--    /(a2)\----(c2)
--   /      \
-- (a)------(c)

local function triangle_vs_triangle(ax, ay, bx, by, cx, cy, a2x, a2y, b2x, b2y, c2x, c2y)
  -- todo: to be replaced with something like:
  -- Tomas Moller's "A Fast Triangle-Triangle Intersection Test"
  -- we could use segment vs triangle here but it ends up doing 3 extra checks
  -- edge vs edge
  if segment_vs_segment(ax, ay, bx, by, a2x, a2y, b2x, b2y) then return true end
  if segment_vs_segment(ax, ay, bx, by, b2x, b2y, c2x, c2y) then return true end
  if segment_vs_segment(ax, ay, bx, by, c2x, c2y, a2x, a2y) then return true end
  if segment_vs_segment(bx, by, cx, cy, a2x, a2y, b2x, b2y) then return true end
  if segment_vs_segment(bx, by, cx, cy, b2x, b2y, c2x, c2y) then return true end
  if segment_vs_segment(bx, by, cx, cy, c2x, c2y, a2x, a2y) then return true end
  if segment_vs_segment(cx, cy, ax, ay, a2x, a2y, b2x, b2y) then return true end
  if segment_vs_segment(cx, cy, ax, ay, b2x, b2y, c2x, c2y) then return true end
  if segment_vs_segment(cx, cy, ax, ay, c2x, c2y, a2x, a2y) then return true end
  -- triangle (a,b,c) inside (a2,b2,c2)
  if point_vs_triangle(ax, ay, a2x, a2y, b2x, b2y, c2x, c2y) then return true end
  if point_vs_triangle(bx, by, a2x, a2y, b2x, b2y, c2x, c2y) then return true end
  if point_vs_triangle(cx, cy, a2x, a2y, b2x, b2y, c2x, c2y) then return true end
  -- triangle (a2,b2,c2) inside (a,b,c)
  if point_vs_triangle(a2x, a2y, ax, ay, bx, by, cx, cy) then return true end
  if point_vs_triangle(b2x, b2y, ax, ay, bx, by, cx, cy) then return true end
  if point_vs_triangle(c2x, c2y, ax, ay, bx, by, cx, cy) then return true end
  return false
end

--[[
local function triangle_vs_axis(ax, ay, bx, by, cx, cy, sx, sy, ex, ey)
  -- normalize segment
  local xa, ya = ex - sx, ey - sy
  local dsq = xa*xa + ya*ya
  local d = sqrt(dsq)
  local nxa, nya = xa/d, ya/d
  -- project segment origin point to axis
  local o = dot(nxa, nya, sx, sy)
  -- project triangle vertices to the axis
  local a = dot(nxa, nya, ax, ay)
  local b = dot(nxa, nya, bx, by)
  local c = dot(nxa, nya, cx, cy)
  -- find projected extents
  local s = min(a, b, c)
  local e = max(a, b, c)
  -- check for separation
  return e < o or s > o + d
end

local function triangle_vs_triangle(ax, ay, bx, by, cx, cy, a2x, a2y, b2x, b2y, c2x, c2y)
  -- project first triangle
  if triangle_vs_axis(ax, ay, bx, by, cx, cy, a2x, a2y, b2x, b2y) then return false end
  if triangle_vs_axis(ax, ay, bx, by, cx, cy, b2x, b2y, c2x, c2y) then return false end
  if triangle_vs_axis(ax, ay, bx, by, cx, cy, c2x, c2y, a2x, a2y) then return false end
  -- project second triangle
  if triangle_vs_axis(a2x, a2y, b2x, b2y, c2x, c2y, ax, ay, bx, by) then return false end
  if triangle_vs_axis(a2x, a2y, b2x, b2y, c2x, c2y, bx, by, cx, cy) then return false end
  if triangle_vs_axis(a2x, a2y, b2x, b2y, c2x, c2y, cx, cy, ax, ay) then return false end
  return true
end
]]

--     (b).-'''-.
--      /\       \
--     /| \ (s)   |
--    /  \ \     /
--   /    `-\..-'
-- (a)------(c)

local function triangle_vs_circle(ax, ay, bx, by, cx, cy, sx, sy, r)
  -- find the nearest point from the circle center to the triangle
  local px, py = point_on_triangle(sx, sy, ax, ay, bx, by, cx, cy)
  local vx, vy = px - sx, py - sy
  -- compare the distance to the radius
  local d = dot(vx, vy, vx, vy)
  return d <= r*r
end

local function triangle_vs_rect(ax, ay, bx, by, cx, cy, rx, ry, rhw, rhh)
  assert(false, 'unsupported')
end


--
-- Circle
--

local function circle_vs_point(cx, cy, cr, ...)
  return point_vs_circle(..., cx, cy, cr)
end

local function circle_vs_segment(cx, cy, cr, ...)
  return segment_vs_circle(..., cx, cy, cr)
end

local function circle_vs_triangle(cx, cy, cr, ...)
  return triangle_vs_circle(..., cx, cy, cr)
end

--           .-'''-.
--   .-'''-./       \
--  /      |\  (c2)  |
-- |   (c1) \|      /
--  \       /`-...-'
--   `-...-'

local function circle_vs_circle(c1x, c1y, r1, c2x, c2y, r2)
  -- add the radii and treat c2 as a point
  return point_vs_circle(c1x, c1y, c2x, c2y, r1 + r2)
end

--         -----------
--   .-'''-.         |
--  /      |\        |
-- |   (c) | |       |
--  \      -/---------
--   `-...-'

local function circle_vs_rect(cx, cy, cr, rx, ry, hw, hh)
  -- find the nearest point from the circle center on the rect
  local dx = abs(rx - cx)
  local dy = abs(ry - cy)
  dx = max(dx - hw, 0)
  dy = max(dy - hh, 0)
  -- compare the distance to radius
  local distsq = dx*dx + dy*dy
  return distsq <= cr*cr
end


--
-- Rect
--

local function rect_vs_point(x, y, hw, hh, ...)
  return point_vs_rect(..., x, y, hw, hh)
end

local function rect_vs_segment(x, y, hw, hh, ...)
  return segment_vs_rect(..., x, y, hw, hh)
end

local function rect_vs_triangle(x, y, hw, hh, ...)
  return triangle_vs_rect(..., x, y, hw, hh)
end

local function rect_vs_circle(x, y, hw, hh, ...)
  return circle_vs_rect(..., x, y, hw, hh)
end

--         -----------
-- -----------       |
-- |       | |(r2)   |
-- |  (r1) | |       |
-- |       -----------
-- -----------

local function rect_vs_rect(r1x, r1y, r1hw, r1hh, r2x, r2y, r2hw, r2hh)
  if abs(r1x - r2x) > r1hw + r2hw then
    return false
  end
  if abs(r1y - r2y) > r1hh + r2hh then
    return false
  end
  return true
end


local overlap = {}

overlap.point =
{
  point = point_vs_point, segment = point_vs_segment,
  triangle = point_vs_triangle, circle = point_vs_circle,
  rect = point_vs_rect
}
overlap.segment =
{
  point = segment_vs_point, segment = segment_vs_segment,
  triangle = segment_vs_triangle, circle = segment_vs_circle,
  rect = segment_vs_rect
}
overlap.triangle =
{
  point = circle_vs_point, segment = triangle_vs_segment,
  triangle = triangle_vs_triangle, circle = triangle_vs_circle,
  rect = triangle_vs_rect
}
overlap.circle = 
{
  point = circle_vs_point, segment = circle_vs_segment,
  triangle = circle_vs_triangle, circle = circle_vs_circle,
  rect = circle_vs_rect
}
overlap.rect =
{
  point = rect_vs_point, segment = rect_vs_segment,
  triangle = rect_vs_triangle, circle = rect_vs_circle,
  rect = rect_vs_rect
}


return overlap