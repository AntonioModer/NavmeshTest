--
-- Isomap tracer (based on marching squares)
--

local msq = {}

local north = { 0, 1 }
local east = { 1, 0 }
local south = { 0, -1 }
local west = { -1, 0 }

-- (1)--(2)
--  |    |
-- (8)--(4)

-- Marching directions following contours counterclockwise
local march =
{
  east, north, east, east,
  south, nil, south, south,
  west, north, nil, east,
  west, north, west, nil
}

-- Returns the direction in which we are marching
local function step(w, h, x, y, iso)
  local nw = msq.getval(x - 1, y + 1)
  local ne = msq.getval(x, y + 1)
  local sw = msq.getval(x - 1, y)
  local se = msq.getval(x, y)

  local state = 0
  if nw and nw >= iso then
    state = 1
  end
  if ne and ne >= iso then
    state = state + 2
  end
  if se and se >= iso then
    state = state + 4
  end
  if sw and sw >= iso then
    state = state + 8
  end
  return state
end

-- Marches around a contour returning its path
local prev = nil

local function trace(w, h, sx, sy, iso, path)
  path = path or {}
  local x, y = sx, sy
  prev = nil
  local i = 1
  while true do
    local state = step(w, h, x, y, iso)
    -- resolve ambiguous cases
    if state == 5 then
      if prev == east then
        state = 1
      else
        --assert(prev == west)
        state = 4
      end
    elseif state == 10 then
      if prev == south then
        state = 2
      else
        --assert(prev == north)
        state = 8
      end
    end
    -- no more moves
    if state == 15 then
      break
    end
    local n = march[state + 1]
    path[i] = x
    path[i + 1] = y
    
    -- closed contour?
    if #path >= 6 and (x == sx and y == sy) then
      break
    end
    
    x = x + n[1]
    y = y + n[2]
    
    prev = n
    i = i + 2
  end
  return path
end

-- Finds the next edge of a contour on the map
local function find(w, h, x, y, iso)
  -- starting above iso level?
  local above = msq.getval(x, y) >= iso
  repeat
    local v = msq.getval(x, y)
    if (not above and v >= iso) or (above and v < iso) then
      return x, y
    end
    x = x + 1
    -- move to the next row
    if x > w then
      x = 1
      y = y + 1
      local v2 = msq.getval(x, y)
      if v2 then
        above = v2 >= iso
      end
    end
  until y >= h
end

-- Traces all contours
function msq.traceall(w, h, iso)
  -- index starting from 1, 1
  local sx, sy = 1, 1
  -- hash table with traced contours
  local visited = {}
  -- found paths
  local paths = {}

  repeat
    -- find the next contour
    sx, sy = find(w, h, sx, sy, iso)
    if sx == nil or sy == nil then
      -- no more contours
      break
    end

    -- is this a new contour?
    local j = (sy - 1)*w + sx
    if not visited[j] then
      local path = trace(w, h, sx, sy, iso)
      if path then
        -- jump to the end of the contour: todo?
        sx, sy = path[#path - 1], path[#path]
        -- hash this contour
        for i = 1, #path, 2 do
          local x, y = path[i], path[i + 1]
          local j = (y - 1)*w + x
          visited[j] = true
        end
        table.insert(paths, path)
      end
    end
    sx = sx + 1
    if sx > w then
      sx = 1
      sy = sy + 1
    end
  until sy >= h
  return paths
end

function msq.smooth(path, iso)
  for i = 1, #path, 2 do
    local x, y = path[i], path[i + 1]

    local nw = msq.getval(x - 1, y + 1) or 0
    local ne = msq.getval(x, y + 1) or 0
    local sw = msq.getval(x - 1, y) or 0
    local se = msq.getval(x, y) or 0

    local w = (nw + sw)/2
    local e = (ne + se)/2
    local n = (nw + ne)/2
    local s = (sw + se)/2

    local z = iso
    local h = 0
    if w > e then
      z = math.max(z, e)
      z = math.min(z, w)
      h = -(z - e)/(w - e)
    elseif e > w then
      z = math.max(z, w)
      z = math.min(z, e)
      h = (z - w)/(e - w)
    end
    local z = iso
    local v = 0
    if n > s then
      z = math.max(z, s)
      z = math.min(z, n)
      v = (z - s)/(n - s)
    elseif s > n then
      z = math.max(z, n)
      z = math.min(z, s)
      v = -(z - n)/(s - n)
    end
    
    path[i] = x + h/2
    path[i + 1] = y + v/2
  end
end

-- Returns the value of a position on the map
-- Must be implemented by the user
function msq.getval(x, y)
  assert(false, "Undefined getval")
end

return msq