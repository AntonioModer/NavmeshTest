local line = require("math.itraykov.line")
local vec = require("math.itraykov.vec")

local seg = line.segment

local tremove = table.remove
local cos = math.cos
local sin = math.sin
local pi = math.pi
local pi2 = math.pi*2

local poly = {}

--- Validates the polygon
--- Description:
-- 1. must be a numerically indexed table
-- 2. must have three or more coordinate pairs
-- 3. must have an even number of coordinates
--- Parameters:
-- @p polygon table
-- @return true if valid
function poly.assert(p)
  assert(#p >= 6, "polygon must contain at least three vertices")
  assert(#p%2 == 0, "polygon must contain an even number of coordinates")
end

--- Represents each vertex as a table with x and y values
--- Description:
--- Parameters:
-- @param p input polygon
-- @return output polygon
function poly.tovectors(p)
  local p2 = {}
  for i = 1, #p, 2 do
    p2[(i + 1)/2] = { x = p[i], y = p[i + 1] }
  end
  return p2
end

--- Represents each vertex as a pair of numbers
--- Description:
--- Parameters:
-- @param v input polygon
-- @return output polygon
function poly.fromvectors(p)
  local p2 = {}
  for i = 1, #p do
    local i2 = (i - 1)*2 + 1
    local v = p[i]
    p2[i2] = v.x
    p2[i2 + 1] = v.y
  end
  return p2
end

--- Copies the polygon
--- Description:
--- Parameters:
-- @param p source polygon
-- @param p2 destination polygon (optional)
-- @return destination polygon
function poly.copy(p, p2)
  if p2 then
    assert(p ~= p2, "source and destination polygons are the same")
    -- erase any vertices from #p + 1 to #p2
    for i = #p2, #p + 1, -1 do
      p2[i] = nil
    end
  else
    p2 = {}
  end
  -- overwrite vertices i to #p
  for i = 1, #p do
    p2[i] = p[i]
  end
  return p2
end

--- Appends vertices
--- Description:
--- Parameters:
-- @param p source polygon
-- @param p2 destination polygon
-- @return destination polygon
function poly.append(p, p2)
  local n = #p2
  for i = 1, #p do
    n = n + 1
    p2[n] = p[i]
  end
  return p2
end

--- Removes all vertices
--- Description:
--- Parameters:
-- @param p polygon
function poly.remove(p)
  for i = #p, 1, -1 do
    p[i] = nil
  end
end

--- Reverses the winding of a polygon
--- Description:
--- Parameters:
-- @param p polygon
function poly.reverse(p)
  local n = #p
  for i = 1, n/2, 2 do
    local i2 = n - i
    p[i], p[i2] = p[i2], p[i]
    i, i2 = i + 1, i2 + 1
    p[i], p[i2] = p[i2], p[i]
  end
  return p
end

--- Finds the extents of the polygon
-- @param p polygon
-- @return left, top, right and bottom extents
function poly.extents(p)
  local l, t = p[1], p[2]
  local r, b = l, t
  for i = 3, #p, 2 do
    local x, y = p[i], p[i + 1]
    if x < l then
      l = x
    elseif x > r then
      r = x
    end
    if y < t then
      t = y
    elseif y > b then
      b = y
    end
  end
  return l, t, r, b
end

--- Translates the polygon in place
--- Description:
--- Parameters:
-- @param p polygon
-- @param x, y translation offset
function poly.translate(p, x, y)
  for i = 1, #p, 2 do
    p[i] = p[i] + x
    p[i + 1] = p[i + 1] + y
  end
  return p
end

--- Scales the polygon in place
--- Description:
--- Parameters:
-- @param p polygon
-- @param sx, sy scale
function poly.scale(p, sx, sy)
  for i = 1, #p, 2 do
    p[i] = p[i]*sx
    p[i + 1] = p[i + 1]*sy
  end
  return p
end

--- Rotates the polygon in place
--- Description:
--- Parameters:
-- @param p polygon
-- @param a angle in radians
function poly.rotate(p, a)
  local c = cos(a)
  local s = sin(a)
  for i = 1, #p, 2 do
    --p[i], p[i + 1] = rotate(p[i], p[i + 1], a)
    local x, y = p[i], p[i + 1]
    p[i] = c*x - s*y
    p[i + 1] = s*x + c*y
  end
  return p
end

--[[
--- Removes insignificant edges based on length
--- Description:
--- Parameters:
-- @param p polygon
-- @param l minimum edge length
function poly.cleanup(p, l)
  l = l*l
  local ax, ay = p[1], p[2]
  for i = #p - 1, 1, -2 do
    local bx, by = p[i], p[i + 1]
    local dx, dy = bx - ax, by - ay
    local d = dx*dx + dy*dy
    if d <= l then
      tremove(p, i)
      tremove(p, i)
    else
      ax, ay = bx, by
    end
  end
  return p
end

--- Removes insignificant edges based on slope
--- Description:
--- Parameters:
-- @param p polygon
-- @param a minimum slope in radians
function poly.simplify(p, a)
  if #p <= 6 then
    return p
  end
  local ax, ay = p[1], p[2]
  local bx, by = p[#p - 1], p[#p]
  local dx, dy = ax - bx, ay - by
  local j = #p - 1
  for i = #p - 3, 1, -2 do
    local cx, cy = p[i], p[i + 1]
    local ex, ey = cx - bx, cy - by
    local e = vec.vang(dx,dy, ex,ey)%pi
    if e <= a then
      tremove(p, j)
      tremove(p, j)
      j = j - 2
    else
      ax, ay = bx, by
      bx, by = cx, cy
      dx, dy = ex, ey
      j = i
    end
  end
  return p
end
]]

--- Constructs a regular polygon
--- Description:
-- Given a number of sides (n)
-- and a circumradius (r)
-- produces a regular polygon
-- with counter-clockwise winding
-- where the first vertex is [1*r, 0]
--- Parameters:
-- @param n number of sides
-- @param r circumradius
-- @param out output polygon
-- @return regular polygon
function poly.regular(n, r, out)
  out = out or {}
  local i = 1
  for j = 0, n do
    local a = j/n*pi2
    out[i] = cos(a)*r
    out[i + 1] = sin(a)*r
    i = i + 2
  end
  return out
end

--- Constructs a regular polygon
--- Description:
-- Given a number of sides (n)
-- and a side length (s)
-- produces a regular polygon
-- with counter-clockwise winding
-- where the first vertex is [1*r, 0]
--- Parameters:
-- @param n number of sides
-- @param s side
-- @return regular polygon
function poly.regular2(n, s, out)
  local r = s/(2*sin(pi/n))
  return poly.regular(n, r, out)
end

--- Constructs a regular polygon
--- Description:
--- Parameters:
-- @param n number of sides
-- @param a apothem
-- @return regular polygon
function poly.regular3(n, a, out)
  local r = a/(cos(pi/n))
  return poly.regular(n, r, out)
end

-- Returns twice the signed area of a polygon
--- Description:
-- Tells us about the winding (W) of the vertices
-- SA2 = 0
-- for each edge a-b
--  SA2 = SA2 + (bx + ax)*(by - ay)
-- SA = SA2/2
-- A = abs(SA)
--- Range:
-- Assuming the y-axis points up and the x-axis points right:
-- SA2 is positive when W is counter-clockwise
-- SA2 is negative when W is clockwise
-- SA2 is zero when W is degenerate (all edges are collinear)
-- Should work with concave polygons
--- Parameters:
-- @p polygon (simple)
-- @return twice the signed area of the polygon
function poly.area2(p)
  local s = 0
  local ax, ay = p[#p - 1], p[#p]
  for i = 1, #p, 2 do
    local bx, by = p[i], p[i + 1]
    s = s + (bx + ax)*(by - ay)
    ax, ay = bx, by
  end
  return s
end

--- Returns the area of a polygon
--- Parameters:
-- @param p polygon (simple)
-- @return area of the polygon
function poly.area(p)
  local s = poly.area2(p)/2
  if s < 0 then
    s = -s
  end
  return s
end

--- Checks if the polygon winding is counter-clockwise
--- Range:
-- Assuming the y-axis points up and the x-axis points right
--- Parameters:
-- @p polygon
-- @return true if the polygon is counter-clockwise
function poly.ccw(p)
  return poly.area2(p) > 0
end

--- Checks if the polygon is convex
--- Description:
-- For any counter-clockwise oriented polygon,
-- as soon as we find a clockwise turn
-- then we know it's not convex and vice versa
--- Parameters:
-- @param p polygon
-- @param ccw winding of the polygon
-- @return true if the polygon is convex or false otherwise
function poly.convex2(p, ccw)
  local cx, cy = p[3], p[4]
  local bx, by = p[1], p[2]
  for i = #p - 1, 1, -2 do
    local ax, ay = p[i], p[i + 1]
    --local s = sta(ax, ay, bx, by, cx, cy)
    local s = (ax - cx)*(by - cy) - (ay - cy)*(bx - cx)
    if (ccw and s < 0) or (not ccw and s > 0) then
      return false
    end
    cx, cy = bx, by
    bx, by = ax, ay
  end
  return true
end

--- Checks if the polygon is convex
--- Description:
-- Should work with cw and ccw polygons
--- Parameters:
-- @param p polygon
-- @return true if the polygon is convex or false otherwise
function poly.convex(p)
  -- cw polygons: if we make a ccw (left) turn we know it's not convex
  -- ccw polygons: if we make a cw (right) turn we know it's not convex
  local ccw = poly.ccw(p)
  return poly.convex2(p, ccw)
end

--- Checks if the polygon is strictly simple
--- Description:
-- Checks for intersecting edges, shared vertices or edges
--- Range:
-- Returns true for collinear polygons with zero area
--- Parameters:
-- @param p polygon
-- @return true if the polygon is strictly simple or false otherwise
function poly.simple(p)
  -- ignore the last edge (#p to 1) on the first pass
  local n = #p - 3
  -- edges #p to 1 to #p
  local bx, by = p[#p - 1], p[#p]
  for i = 1, #p, 2 do
    local ax, ay = p[i], p[i + 1]
    -- edges i + 1 to n
    local dx, dy = p[i + 2], p[i + 3]
    for j = i + 4, n, 2 do
      local cx, cy = p[j], p[j + 1]
      if seg(ax, ay, bx, by, cx, cy, dx, dy, "segment", "segment") then
        return false
      end
      dx, dy = cx, cy
    end
    bx, by = ax, ay
    -- include the last edge (#p to 1) after the first pass
    n = #p - 1
  end
  return true
end

-- Tests if a point is inside the polygon
-- based on Matthias Richter
function poly.point(p, x, y)
  local inside = false
  local ax, ay = p[#p - 1], p[#p]
  for i = 1, #p, 2 do
    local bx, by = p[i], p[i + 1]
    local cc =
      -- cut
      (((ay > y and by < y) or (ay < y and by > y)) and
      (x - ax < (y - ay)*(bx - ax)/(by - ay))) or
      -- cross
      ((ay == y and ax > x and by < y) or
      (by == y and bx > x and ay < y))
    if cc then
      inside = not inside
    end
    ax, ay = bx, by
  end
  --if not poly.clockwise(p) then
    --inside = not inside
  --end
  return inside
end

-- Tests if one polygon is inside another
-- Both must be non-self-intersecting
function poly.polygon(p, p2)
  -- all points in p2 must be inside p
  for i = 1, #p2, 2 do
    if not poly.point(p, p2[i], p2[i + 1]) then
      return false
    end
  end
  -- no points from p can be in p2
  for i = 1, #p, 2 do
    if poly.point(p2, p[i], p[i + 1]) then
      return false
    end
  end
  -- no edges can intersect
  local ax, ay = p[#p - 1], p[#p]
  for i = 1, #p, 2 do
    local bx, by = p[i], p[i + 1]
    local cx, cy = p2[#p2 - 1], p2[#p2]
    for j = 1, #p2, 2 do
      local dx, dy = p2[j], p2[j + 1]
      if seg(ax,ay, bx,by, cx,cy, dx,dy, "segment", "segment") then
        return false
      end
      cx, cy = dx, dy
    end
    ax, ay = bx, by
  end
  return true
end

function poly.vertex(p, i)
  i = i*2
  return p[i - 1], p[i]
end

function poly.area3(p, i1)
  if i1 < 1 or i1 > #p/2 then
    error("Vertex index out of range: " .. i1)
  end
  i1 = i1*2 - 1
  local i0 = i1 - 2
  local i2 = i1 + 2
  -- wrap vertices
  i0 = (i0 - 1)%#p + 1
  i2 = (i2 - 1)%#p + 1
  local x1, y1 = p[i0], p[i0 + 1]
  local x2, y2 = p[i1], p[i1 + 1]
  local x3, y3 = p[i2], p[i2 + 1]
  -- same as sta
  return (y3 - y1)*(x2 - x1) - (x3 - x1)*(y2 - y1)
end

function poly.reflex_ccw(p, i1)
 return poly.area3(p, i1) <= 0
end

function poly.reflex(p, i1)
  local r = poly.reflex_ccw(p, i1)
  if not poly.ccw(p) then
    r = not r
  end
  return r
end

--- Merges two simple polygons into one weak polygon
-- @p1 first polygon
-- @p2 second polygon
-- @i index on the first polygon
-- @j index on the second polygon
-- @output resulting polygon (optional)
-- @return resulting polygon
local _p2 = {}
function poly.bridge(p, p2, i, j, output)
  assert(i, "first polygon index is nil")
  assert(j, "second polygon index is nil")
  -- the two polygons must have reverse windings
  if poly.ccw(p) == poly.ccw(p2) then
    -- fill buffer
    p2 = poly.copy(p2, _p2)
    poly.reverse(p2)
    j = #p2 - j
  end
  assert(p[i] and p[i + 1], "first polygon index is out of range")
  assert(p2[j] and p2[j + 1], "second polygon index is out of range")
  -- build the resulting polygon
  output = output or {}
  if output == p then
    -- vertices j to #p2 on the second polygon
    for j2 = #p2, j, -1 do
      tinsert(output, i, p2[j2])
    end
    -- vertices 1 to j on the second polygon
    for j2 = j + 1, 1, -1 do
      tinsert(output, i, p2[j2])
    end
  else
    local no = #output
    -- vertices 1 to i on the first polygon
    for i2 = 1, i + 1 do
      output[#output + 1] = p[i2]
    end
    -- vertices j to #p2 on the second polygon
    for j2 = j, #p2 do
      output[#output + 1] = p2[j2]
    end
    -- vertices 1 to j on the second polygon
    for j2 = 1, j + 1 do
      output[#output + 1] = p2[j2]
    end
    -- vertices i to #p on the first polygon
    for i2 = i, #p do
      output[#output + 1] = p[i2]
    end
    -- merging, produces a weak polygon with two extra vertices
    assert(#p + #p2 + 4 - no == #output)
  end
  return output
end

return poly