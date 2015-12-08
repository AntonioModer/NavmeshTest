local sqrt = math.sqrt
local acos = math.acos
local cos = math.cos
local sin = math.sin
local atan2 = math.atan2
local pi = math.pi
local pi2 = math.pi*2

local vec = {}

--- Returns the squared length of a vector
--- Description:
-- Based on the Pythagorean theorem
-- L^2 = ax^2 + ay^2
--- Commutative:
-- len2(ax,ay) = len2(ay,ax)
--- Result:
-- L is always zero or greater
--- Parameters:
-- @param ax, ay vector
-- @return squared length
function vec.len2(ax, ay)
  return ax*ax + ay*ay
end

--- Returns the length of a vector
--- Description:
-- Based on the Pythagorean theorem
-- L^2 = ax^2 + ay^2
-- L = sqrt(L^2)
--- Commutative:
-- len(ax,ay) = len(ay,ax)
--- Result:
-- L is always zero or greater
--- Parameters:
-- @param ax, ay vector
-- @return length
function vec.len(ax, ay)
  return sqrt(ax*ax + ay*ay)
end

--- Returns the squared distance between two points
--- Description:
-- Based on the Pythagorean theorem
--- Commutative:
-- len(a,b) = len(b,a)
--- Result:
-- L is always zero or greater
--- Parameters:
-- @param x1, y1 first point
-- @param x2, y2 second point
-- @return squared distance between the points
function vec.dist2(x1, y1, x2, y2)
  local dx = x1 - x2
  local dy = y1 - y2
  return dx*dx + dy*dy
end

--- Returns the distance between two points
--- Description:
-- Based on the Pythagorean theorem
--- Commutative:
-- dist(a,b) = dist(b,a)
--- Result:
-- L is always zero or greater
--- Parameters:
-- @param x1, y1 first point
-- @param x2, y2 second point
-- @return distance between the points
function vec.dist(x1, y1, x2, y2)
  local dx = x1 - x2
  local dy = y1 - y2
  return sqrt(dx*dx + dy*dy)
end

--- Normalizes a vector
--- Description:
-- Changes the vector magnitude without affecting its direction
-- L = len(a)
-- N = a*(1/L)
--- Result:
-- does not work with zero-length vectors
--- Parameters:
-- @param ax, ay vector
-- @return unit vector or 0, 0
function vec.norm(ax, ay)
  local d = sqrt(ax*ax + ay*ay)
  if d > 0 then
    x, y = x/d, y/d
  end
  return x, y
end

--- Returns the dot product of two vectors (scalar or inner product)
--- Description:
-- The dot product (D) tells us about the angle (R) between the two vectors
-- Lp = len(a)*len(b)
-- D = Lp*cos(R)
-- D = ax*bx + ay*by
--- Commutative:
-- dot(a,b) = dot(b,a)
--- Distributive:
-- dot(a,(b + c)) = dot(a,b) + dot(a,c)
--- Result:
-- -Lp <= D <= Lp (depending on the angle R)
-- D is positive when R is acute
-- D is negative when R if obtuse
-- D is zero when R is a right-angle (vectors a and b are perpendicular)
--- Parameters:
-- @param ax, ay first vector
-- @param bx, by second vector
-- @return the dot product
function vec.dot(ax, ay, bx, by)
  return ax*bx + ay*by
end

--- Returns the cross product of two vectors
--- Description:
-- In 3D, the cross product produces a third vector perpendicular to the original two
-- In 2D, the cross product (C) is equal to the area of the parallelogram spanned by the two vectors
-- Lp = len(a)*len(b)
-- C = Lp*sin(R)
-- C = ax*by - ay*bx
-- C = determinant(a,b)
--- Non-commutative:
-- cross(a,b) == -cross(b,a)
--- Result:
-- -Lp <= C <= Lp (depending on the angle R)
-- C is zero when vectors a and b are parallel
--- Parameters:
-- @param ax, ay first vector
-- @param bx, by second vector
-- @return the cross product
function vec.cross(ax, ay, bx, by)
  return ax*by - ay*bx
end

--- Returns the angle in radians between two points
--- Non-commutative:
-- ang(a,b) == -ang(b,a)
--- Result:
-- 0 <= A <= pi (depending on the angle between the two points)
-- A is zero when the two points are equal
--- Parameters:
-- @param ax, ay first point
-- @param bx, by second point
-- @return the angle between the two points
function vec.ang(x1, y1, x2, y2)
  return atan2(y1 - y2, x1 - x2)
end

--- Returns the angle in radians between two vectors
--- Description:
-- Uses the dot product (D) to find the angle (A) between two vectors (a,b)
-- normalized vectors:
-- D = dot(a,b)
-- cos(A) = D
-- A = acos(D)
-- non-normalized vectors:
-- D = dot(a,b)
-- cos(A) = D/(len(a)*len(b))
-- A = acos(D/(len(a)*len(b)))
--- Non-commutative:
-- vang(a,b) == -vang(b,a)
--- Result:
-- -pi <= A <= pi (depending on the angle between the two vectors)
-- A is zero when one of the vectors has zero length
--- Parameters:
-- @param ax, ay first vector
-- @param bx, by second vector
-- @return the angle between the two vectors
function vec.vang(ax, ay, bx, by)
  -- local a = len2(ax, ay)*len2(bx, by)
  local a = (ax*ax + ay*ay)*(bx*bx + by*by)
  a = sqrt(a)
  if a > 0 then
    -- a = acos(dot(ax, ay, bx, by)/a)
    a = acos((ax*bx + ay*by)/a)
    if ax*by - ay*bx < 0 then
      a = -a
    end
  end
  return a
end

--- Returns the angle in radians between two vectors
--- Description:
-- Uses atan2 to find the angle (R) which is slightly less accurate then acos
-- Rd = atan2(b) - atan2(a)
-- R = (Rd + pi)%(2*pi) - pi
--- Non-commutative:
-- vang2(a,b) == -vang2(b,a)
--- Result:
-- -pi <= R < pi (depending on the angle between the vectors)
-- R could be -pi but never pi
-- R could be non-zero even when one of the vectors has zero length
--- Parameters:
-- @param ax, ay first vector
-- @param bx, by second vector
-- @return the angle between the two vectors
function vec.vang2(ax, ay, bx, by)
  local a = atan2(by, bx) - atan2(ay, ax)
  return (a + pi)%(pi2) - pi
end

--- Rotates a vector by the given angle (A) in radians
--- Description:
-- Does not change the length (L) of the vector, only its direction (R)
-- C, S = cos(A), sin(A)
-- v2 = [C*vx - S*vy, S*vx + C*vy] 
-- Alternative implementation:
-- R = atan2(v) + A
-- L = len(v)
-- v2 = [cos(R)*L, sin(R)*L]
--- Range:
-- Assuming the y-axis points up and the x-axis points right:
-- rotates counter-clockwise when A is positive
-- rotates clockwise when A is negative
-- no change when A is zero (zero angle)
-- no change when L is zero (zero-length vector)
--- Parameters:
-- @param x, y vector
-- @param a angle in radians
-- @return rotated vector
function vec.rotate(ax, ay, a)
  local c = cos(a)
  local s = sin(a)
  return c*ax - s*ay, s*ax + c*ay
end

--- Moves one point away from another by the given distance
--- Description:
-- Uses the Pythagorean theorem
-- d = norm(b - a)
-- c = a + d*dist
--- Range:
-- returns the original point when a and b are equal
--- Parameters:
-- @x1, y1 first point
-- @x2, y2 second point
-- @dist distance to translate the second point
-- @return translated third point
function vec.ext(x1, y1, x2, y2, dist)
  -- d = len(a,b)
  local dx, dy = x2 - x1, y2 - y1
  local d = sqrt(dx*dx + dy*dy)
  if d > 0 then
    d = dist/d
  end
  return dx*d + x2, dy*d + y2
end

--- Returns twice the signed area of a triangle
--- Description:
-- Tells us about the winding (W) of the vertices
-- sta(a,b,c) = cross(a - c, b - c)
-- STA2 = (ax - cx)*(by - cy) - (ay - cy)*(bx - cx)
-- STA = STA2/2
-- TA = abs(STA)
--- Non-commutative:
-- sta(a,b,c) == -sta(c,b,a) -- todo: check?
--- Range:
-- Assuming the y-axis points up and the x-axis points right:
-- STA2 is positive when W is counter-clockwise
-- STA2 is negative when W is clockwise
-- STA2 is zero when W is degenerate (a,b,c are collinear)
--- Parameters:
-- @param x1, y1 first vertex
-- @param x2, y2 second vertex
-- @param x3, y3 third vertex
-- @return twice the signed triangle area
function vec.sta2(x1, y1, x2, y2, x3, y3)
  return (x1 - x3)*(y2 - y3) - (y1 - y3)*(x2 - x3)
end

--- Tests if the point is inside the area of a triangle
--- Description:
-- Uses the signed triangle area
-- Should work with clockwise and counter-clockwise triangles
--- Range:
-- Returns false if the point is on an edge or vertex
--- Parameters:
-- @param x1, y1 first vertex
-- @param x2, y2 second vertex
-- @param x3, y3 third vertex
-- @param px, py point
-- @return true if the point is inside the triangle
function vec.pit(x1, y1, x2, y2, x3, y3, px, py)
  local px1, py1 = x1 - px, y1 - py
  local px2, py2 = x2 - px, y2 - py
  local ab = px1*py2 - py1*px2
  --if ab == 0 then
    --return false
  --end
  local px3, py3 = x3 - px, y3 - py
  local bc = px2*py3 - py2*px3
  --if bc == 0 then
    --return false
  --end
  local sab = ab < 0
  if sab ~= (bc < 0) then
    return false
  end
  local ca = px3*py1 - py3*px1
  --if ca == 0 then
    --return false
  --end
  return sab == (ca < 0)
end

--- Tests if a point is inside the area of a circle
--- Description:
-- Checks the squared distance (dx^2, dy^2) and squared
-- radius (r^2) in order to avoid a call to math.sqrt
--- Range:
-- Returns false if the point is on the perimeter
--- Parameters:
-- @param cx, cy circle center
-- @param r circle radius
-- @param px, py point
-- @return true if the point is inside the circle
function vec.pic(cx, cy, r, px, py)
  local dx, dy = px - cx, py - cy
  return dx*dx + dy*dy < r*r
end

--- Tests if a point is inside the area of an ellipse
--- Range:
-- Returns false if the point is on the perimeter
--- Parameters:
-- @param ex, ey ellipse center
-- @param rx, ry ellipse radii
-- @param px, py point
-- @return true if the point is inside the ellipse
function vec.pie(ex, ey, rx, ry, px, py)
  local dx, dy = px - ex, py - ey
  if rx == 0 or ry == 0 then
    return
  end
  return (dx*dx)/(rx*rx) + (dy*dy)/(ry*ry) < 1
end

--- Tests if a point is inside the area of a rectangle
--- Description:
-- Uses the square of the extents "dx^2" and "dy^2"
-- which in Lua is slightly faster than "math.abs"
--- Range:
-- Returns false if the point is on an edge or vertex
--- Parameters:
-- @param rx, ry rectangle center
-- @param hw, hh rectangle extents
-- @param px, py point
-- @return true if the point is inside the rectangle
function vec.pir(rx, ry, hw, hh, px, py)
  --return abs(px - rx) <= hw and abs(py - ry) <= hh
  local dx, dy = px - rx, py - ry
  return dx*dx < hw*hw and dy*dy < hh*hh
end

return vec