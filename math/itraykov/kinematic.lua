local move = {}

-- Velocity (m/s)

-- i = initial position
-- f = final position
-- d = distance
-- v = velocity
-- s = speed
-- t = time

-- what is the velocity of a moving object?
-- v = d/t
function velocity(i, f, t)
  return (f - i)/t
end
function velocity2(ix, iy, fx, fy, t)
  local dx, dy = fx - ix, fy - iy
  local d = math.sqrt(dx*dx + dy*dy)
  return dx/d*t, dy/d*t
end

-- what is the speed of a moving object?
-- note: "speed" similar to velocity, but without a direction
-- s = abs(d/t)
function speed(i, f, t)
  return math.abs(f - i/t)
end
function speed2(ix, iy, fx, fy, t)
  local dx, dy = fx - ix, fy - iy
  return math.sqrt(dx*dx + dy*dy)/t
end

--- how long does it take for an object to travel to a given position?
-- t = d/v
function eta(i, f, v)
  return (f - i)/v
end
function eta2(ix, iy, fx, fy, v)
  local dx, dy = tx - x, ty - y
  return math.sqrt(dx*dx + dy*dy)/v
end

--- how far will an object travel moving at a constant velocity?
-- d = v*t
function dist(v, t)
  return v*t
end
function dist2(vx, vy, t)
  return math.sqrt(vx*vx + vy*vy)*t
end

-- Acceleration (m/s^2)

-- iv = initial velocity
-- fv = final velocity
-- Vdt = change in velocity

-- Vdt = a*t
-- a = Vdt/t
-- t = a/Vdt

-- Force (Newtons) and Torque (N m)

-- F = force
-- T = torque
-- av = angular velocity
-- lv = linear velocity
-- m = mass
-- I = inertia

-- what is the inertia of an object?
-- I = m*av
function inertia(v, m)
  return m*av
end

--- how much torque does it take to reach a given angular velocity?
-- T = I*a
function torque(iv, fv, m, t)
  return (fv - iv)/t*(m*iv)
end
--- how much force does it take to reach a given velocity?
-- F = m*a
function force(ivx, ivy, fvx, fvy, m, t)
  return (fvx - ivx)/t*m, (fvy - ivy)/t*m
end

-- t = (fv - iv)*i/T
--- t = (fv - iv)*m/f

--- how long does it take for an object to accelerate to a given angular velocity?
-- t = Vdt*m/T
function atime(iv, fv, m, T)
  return (fv - iv)*(m*iv)/T
end
--- how long does it take for an object to accelerate to a given linear velocity?
-- t = Vdt*m/F
function atime2(ivx, ivy, fvx, fvy, m, F)
  -- change in velocity
  local dx, dy = fvx - ivx, fvy - ivy
  return math.sqrt(dx*dx + dy*dy)*m/F
end

-- Gravity, projectiles and jumping

-- g = gravity
-- iv = initial velocity
-- h = maximum height
-- t = time

-- what is the gravity that would allow launching a projectile to a given height?
-- what is the gravity that would allow jumping to a given height?
-- g = (2*h)/(h^2)
function gravity(h, t)
  return (2*h)/(t^2)
end

-- what is the initial velocity of a projectile?
-- what is the initial velocity of a jump?
-- iv = sqrt(2*g*h)
function velocity(h, g)
  return math.sqrt(2*g*h)
end

-- how long does it take for a projectile to reach its maximum height?
-- how long does it take to reach the maximum height of a jump?
-- note: if the "iv" is not a multiple of "g" the maximum height is reached between frames
-- t = iv/g
function time(iv, g)
  return iv/g
end

-- hM = minimum height
-- vT = termination velocity
-- tT = termination time

-- what is the velocity required to terminate a jump?
function terminationV(iv, g, h, hM)
  assert(g <= 0, "g must be negative")
  return math.sqrt(iv^2 + 2*g*(h - hM))
end

-- how much time is available until a jump can no longer be terminated?
-- note: if the minimum jump height "hM" is small, the time to terminate jumps becomes shorter
function terminationT(t, iv, vT, g, h, hM)
  return t - (2*(h - hM)/(iv + vT))
end

-- Impulse (N·s, kg·m/s)

-- J = m*Vdt
-- Vdt = J/m

-- J = F*t
-- F = J/t

function impulse(iv, fv, m)
  return (fv - iv)*m
end
function impulse2(ivx, ivy, fvx, fvy, m)
  local dx, dy = fvx - ivx, fvy - ivy
  return dx*m, dy*m
end

function impulseF(f, t)
  return f*t
end
function impulseF2(fx, fy, t)
  return fx*t, fy*t
end

-- Kinetic energy (Joules)

-- KE = 1/2*m*v^2

-- what is the kinetic energy of a moving object?
function ke(v, m)
  return m/2*v^2
end
--[[
function ke2(vx, vy, m)
  local hm = m/2
  return hm*vx^2, hm*vy^2
end
]]

-- Gravity

--- what is the velocity that would prevent an object from falling?
-- fv = (iv - g)*t
function compG(v, g, t)
  return (v - g)*t
end
function compG2(lvx, lvy, gx, gy, t)
  return lvx - gx*t, lvy - gy*t
end

-- Damping and springs

-- c = damping coefficient (in Newton-seconds per meter)
-- k = spring tightness

-- FD = -c*v
-- FD = -k*v

--- what is the velocity of a moving object with damping "D"?
-- fv = v/(1 + t*D)
function dampV(v, D, t)
  assert(D*t ~= 0, "both damping and time must be non-zero")
  return v/(1 + t*D)
end
function dampV2(vx, vy, D, t)
  assert(D*t ~= 0, "both damping and time must be non-zero")
  local c = (1 + t*D)
  return vx/c, vy/c
end

-- what is the damping that will slow down a moving object to a halt?
function damp(iv, fv, t)
  -- wrong
  --return math.pow(fv/iv, 1/t)
end

--[[
--- what is the velocity that would make an object unaffected by damping?
-- iv = fv/clamp(1 - t*D, 0, 1)
function idamp(v, D, t, maxV)
  local d = 1 - t*D
  if d <= 0 then
    d = math.sqrt(vx*vx + vy*vy)*maxV
  elseif d > 1 then
    d = 1
  end
  return v/d
end
function idamp2(vx, vy, D, t, maxV)
  local d = 1 - t*D
  if d <= 0 then
    d = math.sqrt(vx*vx + vy*vy)*maxV
  elseif d > 1 then
    d = 1
  end
  return vx/d, vy/d
end
]]