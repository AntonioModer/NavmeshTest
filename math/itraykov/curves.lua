--
-- Curves
--
-- For a given curve, arc or shape:
-- Returns a list of vertices that describe the curve
--

local remove = table.remove
local insert = table.insert
local max, min, floor = math.max, math.min, math.floor
local sin, cos, atan2 = math.sin, math.cos, math.atan2
local sqrt, log = math.sqrt, math.log
local pi12 = math.pi/2
local pi = math.pi
local pi34 = 3/4*math.pi*2
local pi2 = math.pi*2

local curves = {}

-- minimum segment length in pixels
curves.epsilon = 4
-- maximum number of segments per arc or circle
curves.maxseg = 512

--- Elliptic arc
-- @param rx, ry horizontal and vertical radii
-- @param x, y offset position
-- @param ia, fa initial and final angle
-- @param a offset angle (optional)
function curves.earc(rx, ry, x, y, ia, fa, a, out)
  assert(curves.epsilon > 0, "epsilon must be greater than 0")
  -- Ramanujan approximation: perimeter of an ellipse
  -- pi * (3(a + b) - sqrt((3a + b) + (a + 3b))
  local l = 3*(rx + ry) - sqrt((3*rx + ry) + (rx + 3*ry))*pi

  local d = floor(l/curves.epsilon)
  d = max(d, 4)
  d = min(d, curves.maxseg)

  a = a or 0
  out = out or {}
  local sa = sin(a)
  local ca = cos(a)
  local arc = fa - ia
  for i = 0, d do
    local a = i/d*arc + ia
    local ct = cos(a)
    local st = sin(a)
    local lx = x + rx*ct*ca - ry*st*sa
    local ly = y + ry*st*ca + rx*ct*sa
    insert(out, lx)
    insert(out, ly)
  end
  return out
end

--- Ellipse
-- @param rx, ry horizontal and vertical radii
-- @param x, y offset position
-- @param a offset angle (optional)
function curves.ellipse(rx, ry, x, y, a, out)
  -- counter-clockwise arc from 0 to pi*2
  return curves.earc(rx, ry, x, y, 0, pi2, a, out)
end

--- Circular arc
-- @param r radius
-- @param x, y offset position
-- @param ia, fa initial and final angle
function curves.carc(r, x, y, ia, fa, out)
  return curves.earc(r, r, x, y, ia, fa, 0, out)
end

--- Circle
-- @param r radius
-- @param x, y offset position
function curves.circle(r, x, y, out)
  -- counter-clockwise arc from 0 to pi*2
  return curves.carc(r, x, y, 0, pi2, out)
end

--- Length of a quadratic Bezier
--- Closed-form solution to elliptic integral for arc length
function curves.qbezierlen(x1, y1, x2, y2, x3, y3)
  local ax = x1 - 2*x2 + x3
  local ay = y1 - 2*y2 + y3
  local bx = 2*x2 - 2*x1
  local by = 2*y2 - 2*y1

  local a = 4*(ax*ax + ay*ay)
  local b = 4*(ax*bx + ay*by)
  local c = bx*bx + by*by

  local abc = 2*sqrt(a + b + c)
  local a2  = sqrt(a)
  local a32 = 2*a*a2
  local c2  = 2*sqrt(c)
  local ba  = b/a2

  return (a32*abc + a2*b*(abc - c2) + (4*c*a - b*b)*log((2*a2 + ba + abc)/(ba + c2)))/(4*a32)
end

--- Quadratic Bezier curve
-- @param x1, y1 starting point
-- @param x2, y2 control point
-- @param x3, y3 end point
function curves.qbezier(x1, y1, x2, y2, x3, y3, out)
  assert(curves.epsilon > 0, "epsilon must be greater than 0")
  local l = curves.qbezierlen(x1, y1, x2, y2, x3, y3)
  
  local d = floor(l/curves.epsilon)
  d = max(d, 3)
  d = min(d, curves.maxseg)
  
  out = out or {}
  for i = 0, d do
    local t = i/d
    local xa = x1 + (x2 - x1)*t
    local ya = y1 + (y2 - y1)*t
    local xb = x2 + (x3 - x2)*t
    local yb = y2 + (y3 - y2)*t
    
    local x = xa + (xb - xa)*t
    local y = ya + (yb - ya)*t

    insert(out, x)
    insert(out, y)
  end
  return out
end

--- Length of a cubic Bezier
-- @param x1, y1 starting point
-- @param x2, y2 control point 1
-- @param x3, y3 control point 2
-- @param x4, y4 end point
function curves.cbezierlen(x1, y1, x2, y2, x3, y3, x4, y4)
  local px, py
  local l = 0
  for i = 0, 16 do
    local t = i/16
    local u = 1 - t
    local tt = t*t
    local uu = u*u
    local uuu = uu*u
    local ttt = tt*t
   
    local x = uuu*x1 + 3*uu*t*x2 + 3*u*tt*x3 + ttt*x4
    local y = uuu*y1 + 3*uu*t*y2 + 3*u*tt*y3 + ttt*y4
    if px and py then
      local dx = px - x
      local dy = py - y
      l = l + (dx*dx + dy*dy)
    end
    px, py = x, y
  end
  -- todo : RESULT IS INCORRECT?
  return sqrt(l)
end

--- Cubic Bezier curve
-- @param x1, y1 starting point
-- @param x2, y2 control point 1
-- @param x3, y3 control point 2
-- @param x4, y4 end point
function curves.cbezier(x1, y1, x2, y2, x3, y3, x4, y4, out)
  assert(curves.epsilon > 0, "epsilon must be greater than 0")
  local l = curves.cbezierlen(x1, y1, x2, y2, x3, y3, x4, y4)
  
  local d = floor(l/curves.epsilon)
  d = max(d, 4)
  d = min(d, curves.maxseg)
  
  out = out or {}
  for i = 0, d do
    local t = i/d
    local u = 1 - t
    local tt = t*t
    local uu = u*u
    local uuu = uu*u
    local ttt = tt*t
   
    local x = uuu*x1 + 3*uu*t*x2 + 3*u*tt*x3 + ttt*x4
    local y = uuu*y1 + 3*uu*t*y2 + 3*u*tt*y3 + ttt*y4
    
    insert(out, x)
    insert(out, y)
  end
  return out
end

--- Rounded axil-aligned bounding box
-- @param l, t top-left point
-- @param r, b bottom-right point
-- @param rx, ry corner radius
function curves.raabb(l, t, r, b, rx, ry, out)
  assert(l < r and t < b, "misaligned aabb")
  out = out or {}
  --cr = min(cr, (r - l)/2, (b - t)/2)
  rx = min(rx, (r - l)/2)
  ry = min(ry, (b - t)/2)
  --[[
  curves.qbezier(l, t + ry, l, t, l + rx, t, out)
  curves.qbezier(r - rx, t, r, t, r, t + ry, out)
  curves.qbezier(r, b - ry, r, b, r - rx, b, out)
  curves.qbezier(l + rx, b, l, b, l, b - ry, out)
  ]]
  local l2, r2 = l + rx, r - rx
  local t2, b2 = t + ry, b - ry
  curves.earc(rx, ry, l2, t2, pi, pi34, 0, out)
  curves.earc(rx, ry, r2, t2, pi34, pi2, 0, out)
  curves.earc(rx, ry, r2, b2, 0, pi12, 0, out)
  curves.earc(rx, ry, l2, b2, pi12, pi, 0, out)
  return out
end

--- Rounded box
-- @param x, y center of the box
-- @param hw, hh half-width and half-height extents
-- @param rx, ryu corner radius
function curves.rbox(x, y, hw, hh, rx, ry, out)
  return curves.raabb(x - hw, y - hh, x + hw, y + hh, rx, ry, out)
end

--- Capsule
-- @param x1, y1 starting point
-- @param x2, y2 ending point
-- @param r capsule radius
function curves.capsule(x1, y1, x2, y2, r, out)
  out = out or {}
  local dx, dy = x2 - x1, y2 - y1

  local a = atan2(dx, -dy)
  curves.carc(r, x1, y1, a, a + pi, out)
  curves.carc(r, x2, y2, a - pi, a, out)
  return out
end

return curves