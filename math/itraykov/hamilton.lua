local sort = table.sort

-- graph
local g = nil
-- starting nodes
local nodes = {}
-- degrees per node
local degree = {}
-- visited nodes
local visited = {}
-- maximum nodes in path
local solution = 0
local degree1 = 0
local degree2 = 0
local count = 0

local function release()
  g = nil
  for i = 1, #nodes do
    nodes[i] = nil
  end
  for k in pairs(degree) do
    degree[k] = nil
  end
  solution = 0
  degree1 = 0
end

local function init(_g)
  release()
  g = _g
  -- calculate degrees
  for a, b in pairs(g) do
    degree[a] = 0
    for _ in pairs(b) do
      degree[a] = degree[a] + 1
    end
    if degree[a] == 1 then
      degree1 = degree1 + 1
    elseif degree[a] == 2 then
      degree2 = degree2 + 1
    end
    count = count + 1
  end
  -- find good starting points
  if degree1 > 0 then
    -- exceptional case
    -- start from degree one only
    for a in pairs(degree) do
      if degree[a] == 1 then
        nodes[#nodes + 1] = a
      end
    end
  elseif degree2 < count then
    -- exceptional case
    -- ignore degree two
    for a in pairs(degree) do
      if degree[a] ~= 2 then
        nodes[#nodes + 1] = a
      end
    end
  else
    -- general case
    -- start from every degree
    for a in pairs(degree) do
      nodes[#nodes + 1] = a
    end
  end
  -- sort by degree
  sort(nodes, function(a, b) return degree[a] < degree[b] end)
  solution = count
  if degree1 > 2 then
    solution = solution - (degree1 - 2)
  end
end

local function findFrom(a, path, best)
  -- push
  path[#path + 1] = a
  visited[a] = true
  if #path == solution then
    -- found a solution?
    return true
  elseif #path > #best then
    -- better than longest path?
    for i = 1, #path do
      best[i] = path[i]
    end
  end
  -- descend
  for b in pairs(g[a]) do
    if not visited[b] then
      if findFrom(b, path, best) then
        return true
      end
    end
  end
  -- pop
  path[#path] = nil
  visited[a] = nil
  return false
end

local function find(g)
  init(g)
  local path = {}
  local best = {}
  -- try all starting points
  for i = 1, #nodes do
    for j = 1, #path do
      path[j] = nil
    end
    -- note: nodes of degree 2 are a special case
    -- found a solution?
    if findFrom(nodes[i], path, best) then
      return path
    end
    if #path > #best then
      for j = 1, #path do
        best[j] = path[j]
      end
    end
  end
  return best
end

local ham = {}

ham.find = find
ham.index = init

return ham