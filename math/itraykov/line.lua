--
-- Segment, ray and line casts
-- ===========================
--

-- Definitions
-- ===========
-- This module works with three different types:
-- "segment" has two endpoints
-- "ray" has one endpoint
-- "line" has no endpoints

-- Results
-- =======
-- Each test, returns either one or two points.
-- The order of returned points is determined by
-- the direction of the segment, ray or line (a-b).
--
-- After each returned intersection point,
-- the module also returns the intersection "time".
-- The intersection "time" can be defined as the ratio:
-- R = |a-q|/|a-b|
-- if a-b is a segment: R is from 0 to 1
-- if a-b is a ray: R is 0 or greater
-- if a-b is a line: R could be any number

-- Example
-- =======
-- -- one intersection point:
-- qx,qy,q = line.segment(-1,0,1,0, 0,-1,0,1, "segment")
-- assert(qx == 0 and qy == 0 and q == 0.5)
--
-- -- two intersection points:
-- qx,qy,q, qx2,qy2,q2 = line.circle(-1,0,1,0, 0,0,0.5, "segment")
-- assert(qx == -0.5 and qy == 0 and q == 0.25)
-- assert(qx2 == 0.5 and qy2 == 0 and q2 == 0.75)

-- Limitations
-- ===========
-- "line.segment" does not work with "collinear" segments, rays or lines
-- None of the functions work with "degenerate" segments, rays or lines
-- Triangles are not supported :(

-- License
-- =======
-- MIT License

-- Credits
-- =======
-- "Real-Time Collision Detection" by Christer Ericson: http://realtimecollisiondetection.net/
-- "Path" by Cosmin Apreutesei: https://code.google.com/p/lua-files/wiki/path

local sqrt = math.sqrt

local line = {}

function line.is_degenerate(ax, ay, bx, by)
  --return dist2(ax, ay, bx, by) == 0
  local dx, dy = ax - bx, ay - by
  return dx*dx + dy*dy == 0
end


--  (a)
--    \  (b2)
--     \ / 
--     (q)
--     / \
--   (a2) \
--        (b)

--- Segment
--- Note: does not work with parallel or collinear lines
-- @param x1,y1,x2,y2 First segment, ray or line
-- @param x3,y3,x4,y4 Second segment, ray or line
-- @param lt1 Defines x1,y1-x2,y2 as either: "segment", "ray" or "line" (optional)
-- @param lt2 Defines x3,y3-x4,y4 as either: "segment", "ray" or "line" (optional)
-- @return Intersection point and times or nil
function line.segment(x1, y1, x2, y2, x3, y3, x4, y4, lt1, lt2)
  lt1 = lt1 or "segment"
  lt2 = lt2 or "segment"
  local dx1, dy1 = x2 - x1, y2 - y1
  local dx2, dy2 = x4 - x3, y4 - y3

  local dx3, dy3 = x1 - x3, y1 - y3
  local d = dx1*dy2 - dy1*dx2
	if d == 0 then
  --[[
    -- parallel
    local dx4, dy4 = x2 - x3, y2 - y3
    local sta = dx3*dy4 - dy3*dx4
    if sta ~= 0 then
      return -- non-intersecting parallel
    end
    local d2 = dx1*dx1 + dy1*dy1
    if d2 == 0 then
      return -- degenerate
    end
    local nx, ny = dx1/d2, dy1/d2
    local t1a = nx*x3 + ny*y3 -- dot(nx, ny, x3, y3)
    local t1b = nx*x4 + ny*y4 -- dot(nx, ny, x4, y4)
    ]]
    return -- collinear
  end
  local t1 = (dx2*dy3 - dy2*dx3)/d
  if (lt1 ~= "line" and t1 < 0) or (lt1 == "segment" and t1 > 1) then
    return -- non-intersecting segment or ray
  end
  local t2 = (dx1*dy3 - dy1*dx3)/d
  if (lt2 ~= "line" and t2 < 0) or (lt2 == "segment" and t2 > 1) then
    return -- non-intersecting segment or ray
  end
  return x1 + t1*dx1, y1 + t1*dy1, t1, t2
end

-- (a)
--   \ .-'''-.
--   (q)      \
--   | \ (c)   |
--    \ \     /
--     `(q2)-'
--        \   
--        (b)  

--- Circle
-- @param ax,ay,bx,by segment, ray or line
-- @param cx,cy circle center
-- @param cr circle radius
-- @param lt defines a-b as either: "segment", "ray" or "line" (optional)
-- @return intersection point(s) and time(s) or nil
function line.circle(ax, ay, bx, by, cx, cy, cr, lt)
  lt = lt or "segment"
  -- normalize segment
  local dx, dy = bx - ax, by - ay
  local d = sqrt(dx*dx + dy*dy) -- len(dx, dy)
  if d == 0 then
    return -- degenerate
  end
  local nx, ny = dx/d, dy/d
  local mx, my = ax - cx, ay - cy
  local b = mx*nx + my*ny -- dot(mx, my, nx, ny)
  local c = mx*mx + my*my - cr*cr -- dot(mx, my, mx, my) - cr*cr
  if lt ~= "line" and c > 0 and b > 0 then
    return -- non-intersecting
  end
  local discr = b*b - c
  if discr < 0 then
    return -- non-intersecting
  end
  discr = sqrt(discr)
  local tmin = -b - discr
  if lt ~= "line" and tmin < 0 then
    tmin = 0
  end
  if lt == "segment" and tmin > d then
    return -- non-intersecting
  end
  local tmax = discr - b
  if lt == "segment" and tmax > d then
    tmax = d
  end
  -- first intersection point
  local qx, qy = ax + tmin*nx, ay + tmin*ny, tmin
  if tmax == tmin then
    return qx, qy, tmin/d
  end
  -- second intersection point
  return qx, qy, tmin/d, ax + tmax*nx, ay + tmax*ny, tmax/d
end

-- (a)
--   \ --------
--    \|      |
--    (q)     |
--     |\     |
--     -(q2)---
--        \   
--        (b)

--- Axis-aligned rectangle (l,t,r,b)
-- @param ax,ay,bx,by segment, ray or line
-- @param l,t left/top corner of the rectangle
-- @param r,b right/bottom corner of the rectangle
-- @param lt defines a-b as either: "segment", "ray" or "line" (optional)
-- @return intersection point(s) and time(s) or nil
function line.aabb(ax, ay, bx, by, l, t, r, b, lt)
  lt = lt or "segment"
  -- make sure the axis-aligned rectangle is correctly defined
  if l > r then
    l, r = r, l
  end
  if t > b then
    t, b = b, t
  end
  -- normalize segment
  local dx, dy = bx - ax, by - ay
  local d = sqrt(dx*dx + dy*dy) -- len(dx, dy)
  if d == 0 then
    return -- degenerate
  end
  local nx, ny = dx/d, dy/d
  -- minimum and maximum intersection values
  local tmin, tmax
  if lt == "segment" then
    tmin = 0
    tmax = d
  elseif lt == "ray" then
    tmin = 0
  end
  --if abs(dx) < EPSILON then
  if dx == 0 then
    -- vertical line
    if ax < l or ax > r then
      return -- non-intersecting
    end
  else
    local t1, t2 = (l - ax)/nx, (r - ax)/nx
    if t1 > t2 then
      t1, t2 = t2, t1
    end
    if tmin == nil or tmin < t1 then
      tmin = t1
    end
    if tmax == nil or tmax > t2 then
      tmax = t2
    end
    if tmin > tmax then
      return -- non-intersecting
    end
  end
  --if abs(dy) < EPSILON then
  if dy == 0 then
    -- horizontal line
    if ay < t or ay > b then
      return -- non-intersecting
    end
  else
    local t1, t2 = (t - ay)/ny, (b - ay)/ny
    if t1 > t2 then
      t1, t2 = t2, t1
    end
    if tmin == nil or tmin < t1 then
      tmin = t1
    end
    if tmax == nil or tmax > t2 then
      tmax = t2
    end
    if tmin > tmax then
      return -- non-intersecting
    end
  end
  -- first intersection point
  local qx, qy = ax + nx*tmin, ay + ny*tmin, tmin
  if tmin == tmax then
    return qx, qy, tmin
  end
  -- second intersection point
  return qx, qy, tmin/d, ax + nx*tmax, ay + ny*tmax, tmax/d
end

--- Axis-aligned rectangle (second representation)
-- @param ax,ay,bx,by segment, ray or line
-- @param l,t left/top corner of the rectangle
-- @param w,h width and height of the rectangle
-- @param lt defines a-b as either: "segment", "ray" or "line" (optional)
-- @return intersection point(s) and time(s) or nil
function line.rect(ax, ay, bx, by, l, t, w, h, lt)
  return line.aabb(ax, ay, bx, by, l, t, l + w, t + h, lt)
end

--- Axis-aligned rectangle (third representation)
-- @param ax,ay,bx,by segment, ray or line
-- @param x,y center point of the rectangle
-- @param hw,hh half-width and half-height extents of the rectangle
-- @param lt defines a-b as either: "segment", "ray" or "line" (optional)
-- @return intersection point(s) and time(s) or nil
function line.box(ax, ay, bx, by, x, y, hw, hh, lt)
  return line.aabb(ax, ay, bx, by, x - hw, y - hh, x + hw, y + hh, lt)
end

return line