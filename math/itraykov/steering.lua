



-- Move toward a given heading
-- @param x, y current position
-- @param h current heading
-- @param s current speed
-- @param ts target speed
-- @param ma max acceleration
-- @param dt time step in seconds
-- @return new position and speed
function steering.move(x, y, h, s, ts, ma, dt)
  -- acceleration = (target speed - initial speed)/time
  local a = (ts - t)/dt
  a = math.min(ma, a)
  -- speed = current speed + acceleration
  s = s + a
  local step = s*dt
  return x + math.cos(h)*step, y + math.sin(h)*step
end

-- Move toward a target position
-- @param x, y current position
-- @param tx, ty target position
-- @param s desired speed
-- @param dt time step in seconds
-- @return new position and eta
function steering.moveto(x, y, tx, ty, s, dt)
  if ts == 0 then
    return tx, ty, 0
  end
  -- vector to target
  local dx, dy = tx - x, ty - y
  local d = math.sqrt(dx*dx + dy*dy)
  -- time = distance/speed
  local eta = d/ts
  if eta <= dt then
    return tx, ty, eta
  end
  local step = ts*dt
  dx, dy = dx/d*step, dy/d*step
  return x + dx, y + dy, eta
end

function steering.amoveto(x, y, tx, ty, s, ts, a, dt)
  local na = (ts - s)/dt
  na = math.min(na, a)
  return steering.moveto(x, y, tx, ty, s + na, dt)
end

-- Rotate to a given heading
-- @param h current heading in radians
-- @param fh target heading in radians
-- @param turn turn rate in radians per second
-- @param dt time step in seconds
-- @return new heading and eta
function steering.rotate(h, fh, turn, dt)
  if turn == 0 then
    return fh, 0
  end
  -- arc to target
  local arc = (fh - h + math.pi)%(2*math.pi) - math.pi
  -- time = arc/turn
  local eta = math.abs(arc/turn)
  if eta < dt then
    return fh, 0
  end
  local step = turn*dt
  if arc < 0 then
    step = -step
  end
  return h + step, eta
end

function steering.arotate(h, fh, av, turn, tacceleration, dt)
  local a = (turn - lv)/dt
  a = math.min(a, tacceleration)
  return steering.rotate(x, y, tx, ty, lv + a, dt)
end

-- Rotate to a given position
-- @param x, y current position
-- @param h current heading in radians
-- @param tx, ty target position
-- @param turn turn rate in radians per second
-- @param dt time step in seconds
function steering.rotateto(x, y, h, tx, ty, turn, dt)
  local dx, dy = tx - x, ty - y
  if dx == 0 and dy == 0 then
    return h, 0
  end
  local fh = math.atan2(dy, dx)
  return steering.rotate(h, fh, turn, dt)
end

function steering.arotateto(x, y, h, tx, ty, av, turn, tacceleration, dt)
  local a = (turn - av)/dt
  a = math.min(a, tacceleration)
  return steering.rotateto(x, y, h, tx, ty, av + a, dt)
end


steering.agents = {}

function steering.addAgent(x, y, h)
  local a = { x = x, y = y, h = h, xv = 0, yv = 0, av = 0 }
  a.speed = 0
  a.turn = 0
  a.acceleration = 0
  a.turnacceleration = 0
  table.insert(steering.agents, a)
  return a
end

function steering.setTarget(a, p1, p2)
  local tx, ty = p1, p2
  if type(p1) == "table" then
    a.agent = p1
    tx, ty = p1.x, p1.y
  end
  a.tx = tx
  a.ty = ty
end

function steering.seek(a, tx, ty)
  a.state = 'seeking'
  a.tx = tx
  a.ty = ty
end

function steering.flee(a, tx, ty)
  a.state = 'fleeing'
  a.tx = tx
  a.ty = ty
end

function steering.wander(a, dist, radius, jitter)
  assert(jitter >= 0 and jitter <= 1, "jitter must be between 0 and 1")
  a.state = 'wandering'
  a.dist = dist
  a.radius = radius
  a.jitter = jitter
end

function steering.chase(a, b)
  a.state = 'chasing'
  a.agent = b
end

function steering.follow(a, b, ox, oy)
  a.state = 'following'
  a.agent = b
  a.ox = ox or 0
  a.oy = oy or 0
end

function steering.intercept(a, b, ahead)
  a.state = 'intercepting'
  a.agent = b
  a.ahead = ahead
end

function steering.evade(a, b)
  a.state = 'evading'
  a.agent = b
end

function steering.update(dt)
  for i, a in ipairs(steering.agents) do
    -- current position and heading
    local x, y, h = a.x, a.y, a.h
    -- target position
    local tx, ty = a.tx, a.ty
    -- modify target based on the current state
    local s = a.state
    if s == 'chasing' then
      tx, ty = a.agent.x, a.agent.y
    elseif s == 'intercepting' then
      tx = a.agent.x + a.agent.xv*a.ahead
      ty = a.agent.y + a.agent.yv*a.ahead
    elseif a.state == 'fleeing' then
      local dx, dy = tx - x, ty - y
      tx, ty = -dx + x, -dy + y
    elseif s == 'evading' then
      local dx, dy = tx - a.agent.x, ty - a.agent.y
      tx, ty = -dx + x, -dy + y
    elseif s == 'following' then
      local c = math.cos(a.agent.h)
      local s = math.sin(a.agent.h)
      tx = a.agent.x + c*a.ox - s*a.oy
      ty = a.agent.y + s*a.ox + c*a.oy
    elseif a.state == 'wandering' then
      -- normalized heading vector
      local hx, hy = math.cos(h), math.sin(h)
      -- add random offset to the heading
      local rh = h + (math.random()*2 - 1)*a.jitter*math.pi
      local rx, ry = math.cos(rh), math.sin(rh)
      -- move in front of the agent
      tx = x + hx*a.dist + rx*a.radius
      ty = y + hy*a.dist + ry*a.radius
    end
    --a.x, a.y = steering.moveto(x, y, tx, ty, a.speed, dt)
    a.h = steering.rotateto(x, y, h, tx, ty, a.turn, dt)
    -- forward movement vector
    local xv = math.cos(a.h)*a.speed
    local yv = math.sin(a.h)*a.speed
    local dx, dy = tx - x, ty - y
    local dist = math.sqrt(dx*dx + dy*dy)
    local eta = dist/a.speed
    if eta > dt then
      a.x = x + xv*dt
      a.y = y + yv*dt
    end
  end
end
