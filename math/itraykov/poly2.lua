local vec = require("math.itraykov.vec")
local poly = require("math.itraykov.poly")
local line = require("math.itraykov.line")

local pit = vec.pit
local seg = line.segment
local sqrt = math.sqrt

local tremove = table.remove
local tinsert = table.insert
local tsort = table.sort

--- Cuts a hole in a polygon
--- Based on David Eberly's algorithm
--- The hole must not intersect with the boundary of the outer polygon
--- Modifies the boundary of the outer polygon after each holes is cut
--- To cut two or more holes, they must be ordered by greatest x-value
-- @param p Outer polygon (simple)
-- @param s Inner polygon (simple)
-- @return Resulting polygon
function poly.cuthole(p, s)
  assert(p and s)
  if #s == 0 then
    return p
  end
  --assert(poly.clockwise(p) ~= poly.clockwise(s))
  if poly.ccw(p) == poly.ccw(s) then
    poly.reverse(s)
  end
  
  -- search the vertices on the inner polygon
  local i = 1
  local ix = s[i]
  for i2 = 3, #s, 2 do
    -- find the vertex with maximum x-value
    local x = s[i2]
    if x > ix then
      ix = x
      i = i2
    end
  end
  local iy = s[i + 1]
  
  -- search the edges on the outer polygon
  local j
  local q
  local qx, qy
  local a = #p - 1
  local ax, ay = p[a], p[a + 1]
  for b = 1, #p, 2 do
    local bx, by = p[b], p[b + 1]
    -- find the nearest edge to the right of x,y
    local qx2, qy2, q2 = seg(ix, iy, ix + 1, iy, ax, ay, bx, by, "ray", "segment")
    -- if there are two or more shared edges
    -- that have the same q we want to bridge the last one
    -- therefore >= is critical if there are shared edges
    if q2 and (q == nil or q >= q2) then
      j = b
      -- maximum x-value for the edge a-b
      if ax > bx then
        j = a
      end
      q = q2
      qx, qy = qx2, qy2
    end
    -- move to the next edge
    ax, ay = bx, by
    a = b
  end
  
  if j == nil then
    assert(j, "hole is not entirely inside the polygon")
    return
  end
  
  -- skip if qx, qy is a vertex on the outer polygon
  
  -- search reflex vertices on the outer polygon (excluding j)
  -- strictly inside the triangle i,q,j
  -- if there are no vertices inside i,q,j, we have a valid bridge
  -- otherwise choose the point of the minimum angle
  local jx, jy = p[j], p[j + 1]
  local nx, ny = jx - ix, jy - iy
  local n = sqrt(nx*nx + ny*ny)
  assert(n > 0)
  nx, ny = nx/n, ny/n
  for k = 1, #p, 2 do
    if k ~= j and poly.reflex(p, (k + 1)/2) then
      local kx, ky = p[k], p[k + 1]
      if pit(ix, iy, qx, qy, jx, jy, kx, ky) then
        local nx2, ny2 = kx - ix, ky - iy
        local n2 = sqrt(nx2*nx2 + ny2*ny2)
        assert(n2 > 0)
        nx2, ny2 = nx2/n2, ny2/n2
        if nx2 > nx then
          j = k
          n = n2
          nx, ny = nx2, ny2
        end
      end
    end
  end

  -- we found "i" and "j", now cut polygon
  local output = {}
  -- vertices 1 to j on the outer polygon
  for i2 = 1, j + 1 do
    output[i2] = p[i2]
  end
  -- vertices i to #s on the inner polygon
  for i2 = i, #s do
    output[#output + 1] = s[i2]
  end
  -- vertices 1 to i on the inner polygon
  for i2 = 1, i + 1 do
    output[#output + 1] = s[i2]
  end
  -- vertices j to #p on the outer polygon
  for i2 = j, #p do
    output[#output + 1] = p[i2]
  end
  return output
end

--- Cuts holes in a polygon
--- Holes must not intersect with the boundary of the outer polygon
--- Holes must not intersect with each other
-- @param p Polygon (must not be self-intersecting)
-- @param b List of hole polygons
-- @return Resulting polygon
local _ex = {}
local _ey = {}
local function _comp(a, b)
  local x1, x2 = _ex[a], _ex[b]
  if x1 == x2 then
    return _ey[a] < _ey[b]
  end
  return x1 < x2
end
function poly.sortholes(s)
  -- cache holes by maximum x-value
  for i = 1, #s do
    local h = s[i]
    local x, y = h[1], h[2]
    for i2 = 3, #h, 2 do
      -- find the maximum x-value
      local x2, y2 = h[i2], h[i2 + 1]
      if x2 > x or (x2 == x and y2 > y) then
        x, y = x2, y2
      end
    end
    _ex[h], _ey[h] = -x, -y
  end
  -- sort holes by maximum x-value
  tsort(s, _comp)
  -- clear cache
  poly.remove(_ex)
  poly.remove(_ey)
end

local _queue = {}
function poly.cutholes(p, s, output)
  assert(p and s)
  -- build queue
  for i = 1, #s do
    -- ignore holes with zero vertices
    local s2 = s[i]
    if #s2 > 0 then
      _queue[#_queue + 1] = s2
    end
  end
  -- sort queue
  poly.sortholes(_queue)
  -- process queue
  output = poly.copy(p, output)
  while #_queue > 0 do
    local s2 = tremove(_queue, 1)
    output = poly.cuthole(output, s2)
  end
  return output
end

--- Decomposes a polygon into triangles
-- @param p Polygon (weakly simple)
-- @param s List of holes (optional)
-- @param output Resulting triangles (optional)
-- @return Resulting triangles
function poly.triangulate(p, output)
  -- build output
  output = output or {}
  poly.triangulate2(p, output)
  return output
end

--- Decomposes a polygon into triangles
--- uses ear clipping as described by Erickson
--- time: O(n^2) space: O(n)
--- Description:
-- A polygon of four or more sides
-- always has at least two non-overlapping ears
-- 1. store the polygon as a doubly linked list
-- so that you can quickly remove ear tips
-- 2. iterate over the vertices and find the ears
-- 2b. For each vertex Vi
-- and corresponding triangle Vi-1, Vi, Vi+1
-- test all other reflex vertices to see
-- if any are inside the triangle
-- 3. The ears are removed one at a time.
-- 3b. If an adjacent vertex is convex, it remains convex
-- @param p Polygon (simple and counter-clockwise)
-- @param output Resulting triangles (optional)
-- @return Resulting triangles
function poly.triangulate2_ccw(p, output)
  -- output buffer
  output = output or {}

  -- number of vertices
  local n = #p/2
  -- three of fewer vertices?
  if n <= 3 then
    return poly.append(p, output)
  end
  
  -- double linked list of adjacent vertices
  -- this gets ugly because vertices are indexed in pairs:
  -- [1,2], [3,4], [5,6], [7,8]
  local left = {}
  local right = {}
  for i = 1, n*2, 2 do
    left[i] = i - 2
    right[i] = i + 2
  end
  left[1] = n*2 - 1
  right[n*2 - 1] = 1

  -- number of skipped vertices
  local nskip = 0
  -- current index
  local i1 = 1
  while n >= 3 do
    local isear = true
    -- possible ear tip i0,i1,i2
    local i0, i2 = left[i1], right[i1]
    local x0, y0 = p[i0], p[i0 + 1]
    local x1, y1 = p[i1], p[i1 + 1]
    local x2, y2 = p[i2], p[i2 + 1]
    -- skip if there only three vertices left
    if n > 3 then
      -- check if vertex i0,i1,i2 is an ear tip
      --if sta(x0, y0, x1, y1, x2, y2) >= 0 then
      if (x0 - x2)*(y1 - y2) - (y0 - y2)*(x1 - x2) >= 0 then
        -- check if any reflex vertices are inside the triangle i0,i1,i2
        -- iterate vertices i2+1 to i0-1 (excluding i0,i1,i2)
        local j1 = right[i2]
        repeat
          -- possible reflex vertex j0,j1,j2
          local j0, j2 = left[j1], right[j1]
          local x3, y3 = p[j0], p[j0 + 1]
          local x4, y4 = p[j1], p[j1 + 1]
          local x5, y5 = p[j2], p[j2 + 1]
          -- check if vertex j0,j1,j2 is reflex
          if (y5 - y3)*(x4 - x3) - (x5 - x3)*(y4 - y3) <= 0 then
            -- check if j1 is inside the triangle i0,i1,i2
            -- should be true if j1 is on an edge or vertex
            if pit(x0, y0, x1, y1, x2, y2, x4, y4) then
              isear = false
              break
            end
          end
          j1 = right[j1]
        until j1 == i0
      else
        isear = false
      end
    end
    if isear then
      -- ear tip
      -- output triangle i0,i1,i2
      local s = #output
      output[s + 1], output[s + 2] = x0, y0
      output[s + 3], output[s + 4] = x1, y1
      output[s + 5], output[s + 6] = x2, y2
      -- remove vertex i1 by redirecting "left" and "right"
      right[i0] = i2
      left[i2] = i0
      -- decrement vertex count
      n = n - 1
      nskip = 0
      -- visit the next vertex (left)
      i1 = i0
    else
      -- not an ear tip
      -- skipped vertex
      nskip = nskip + 1
      if nskip > n then
        -- we iterated all vertices, but no more ears found
        -- possibly a self-intersecting polygon
        break
      end
      -- visit the next vertex (right)
      i1 = i2
    end
  end
  -- triangulation of a simple polygon
  -- with n vertices produces n-2 triangles
  --assert(#output/6 == #p/2 - 2)
  return output
end

local _p = {}
function poly.triangulate2(p, output)
  -- the input polygon must be counter-clockwise
  if not poly.ccw(p) then
    -- clear buffer
    p = poly.copy(p, _p)
    poly.reverse(p)
  end
  return poly.triangulate2_ccw(p, output)
end

--[[
--- Clips the subject polygon given a (convex) clip polygon
--- based on the Sutherland–Hodgman algorithm
-- @param s Subject polygon
-- @param p Clip polygon (must be convex)
-- @return Resulting polygon
function poly.clip(s, p)
  assert(poly.convex(p))
  local cw = poly.clockwise(p)
  local output = s
  local input = {}
  -- for each clip edge (a-b)
  local ax, ay = p[#p - 1], p[#p]
  for i = 1, #p, 2 do
    local bx, by = p[i], p[i + 1]
    input = output
    output = {}
    -- for each input edge (s-e)
    local sx, sy = input[#input - 1], input[#input]
    for j = 1, #input, 2 do
      local ex, ey = input[j], input[j + 1]
      -- E inside clip edge
      local sta1 = sta(ex, ey, ax, ay, bx, by)
      if (not cw and sta1 > 0) or (cw and sta1 <= 0) then
        -- S not inside clip edge
        local sta2 = sta(sx, sy, ax, ay, bx, by)
        if (not cw and sta2 <= 0) or (cw and sta2 > 0) then
          local ix, iy = seg(sx,sy,ex,ey, ax,ay,bx,by, "segment", "line")
          assert(ix and iy)
          output[#output + 1] = ix
          output[#output + 1] = iy
        end
        output[#output + 1] = ex
        output[#output + 1] = ey
      else
        -- S inside clip edge
        local sta3 = sta(sx, sy, ax, ay, bx, by)
        if (not cw and sta3 > 0) or (cw and sta3 <= 0) then
          local ix, iy = seg(sx,sy,ex,ey, ax,ay,bx,by, "segment", "line")
          assert(ix and iy)
          output[#output + 1] = ix
          output[#output + 1] = iy
        end
      end
      sx, sy = ex, ey
    end
    ax, ay = bx, by
  end
  return output
end
]]


local _areas = {}
local function _comp(a, b)
  return _areas[a] < _areas[b]
end
local function _sortpaths(p)
  -- cache area sizes
  for i = 1, #p do
    local p = p[i]
    _areas[p] = poly.area(p)
  end
  -- sort by area size
  tsort(p, _comp)
  -- clear cache
  for i = #_areas, 1, -1 do
    _areas[i] = nil
  end
end

--- Generates a hierarchy of paths
-- @param p List of paths
-- @return Hierarchy of paths
local _queue = {}
function poly.subpaths(p)
  -- copy paths
  for i = 1, #p do
    _queue[i] = p[i]
  end
  -- sort by area size
  _sortpaths(_queue)
  -- build hierarchy
  local output = {}
  while #_queue > 0 do
    -- get the path with the smallest area
    local a = tremove(_queue, 1)
    -- find the parent path with the smallest area
    local b
    for j = 1, #_queue do
      -- a fits entirely inside b
      if poly.polygon(_queue[j], a) then
        b = _queue[j]
        break
      end
    end
    if b then
      b.sub = b.sub or {}
      tinsert(b.sub, a)
    else
      tinsert(output, a)
    end
  end
  return output
end

return poly