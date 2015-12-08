display:create("triangulation", 800, 600, 32, true)

terminal = require("utils.log.terminal")
geodebug = require("utils.log.geodebug")
require("utils.io.lfs")
require('Box2D')

local red = Color(255, 0, 0)
local lime = Color(0, 255, 0)
local orange = Color(255, 165, 0)
local blue = Color(0, 0, 255)

local s = Sprite()
display.viewport:add_child(s)

-- steps per second
local sps = 1000

local poly = require("utils.math.poly2")

local function readfile(fn)
  local f = io.open(fn, "r")
  local fsz = f:read("*a")
  -- polygon
  local p1 = {}
  local p2 = {}
  local state = "polygon"
  for line in string.gmatch(fsz, "[^\n]+") do
    assert(line ~= "")
    local x, y = string.match(line, "([+-]?[%deE.-]+)[%s,]+([+-]?[%deE.-]+)")
    x, y = tonumber(x), tonumber(y)
    if x and y then
      p2[#p2 + 1] = x
      p2[#p2 + 1] = y
    else
      if #p2 > 0 then
        p1[#p1 + 1] = p2
        p2 = {}
      end
    end
  end
  if #p2 > 0 then
    p1[#p1 + 1] = p2
    p2 = {}
  end
  return p1
end
vec = require("utils.math.vec")
local function newpoly(fn)
  math.randomseed(system.get_ticks())

  local polys = readfile(fn)

  -- vertices in agen are flipped
  for i = 1, #polys do
    poly.scale(polys[i], 1, -1)
  end
  local p1 = polys[1]
  -- center it
  local l,t,r,b = poly.extents(p1)
  local cx,cy = (l + r)/2, (t + b)/2
  for i = 1, #polys do
    poly.translate(polys[i], -cx, -cy)
  end
  -- scale it (again!)
  local w, h = (r - l), (b - t)
  local s = math.min(800/w, 600/h)
  assert(s > 0)
  for i = 1, #polys do
    poly.scale(polys[i], s, s)
  end

  assert(#p1 > 0)
  assert(#p1%2 == 0)

  geodebug.clear()

  --poly.triangulate(polys[1])

  -- stage one: outer polygon
  geodebug.alpha(1)
  geodebug.color(white)
  geodebug.point(p1)
  geodebug.loop(p1)
  
  --[[
  geodebug.color(lime)
  local p = p1
  local a = #p - 3
  local ax, ay = p[a], p[a + 1]
  local b = #p - 1
  local bx, by = p[b], p[b + 1]
  for c = 1, #p, 2 do
    local cx, cy = p[c], p[c + 1]
    if vec.sta(ax,ay, bx,by, cx,cy) > 0 then
      geodebug.point(bx, by)
    end
    ax, ay = bx, by
    bx, by = cx, cy
    a = b
    b = c
  end
  ]]
  
  local holes = {}
  for i = 2, #polys do
    holes[i - 1] = polys[i]
  end
  poly.sortholes(holes)
  
  --local cut = poly.cutholes(p1, holes)
  
  --[[
  local simple = poly.makesimple(cut)
  for i = 1, #simple do
    local p2 = simple[i]
    geodebug.color(blue)
    geodebug.loop(p2)
  end
  ]]

  local cut = poly.copy(p1)
  for i = 1, #holes do
    -- stage two: holes
    local p2 = holes[i]
    geodebug.color(lime)
    --geodebug.point(p2)
    --geodebug.loop(p2)
    
    -- stage three: cut
    cut = poly.cuthole(cut, p2)
    --local i,j = poly.cutholes(cut, p2)
    --geodebug.line(cut[i], cut[i + 1], p2[j], p2[j + 1])
    
    geodebug.erase()

    geodebug.color(white)
    geodebug.loop(cut)
    local tri = poly.triangulate(cut)
    geodebug.color(lime)
    geodebug.triangle(tri)
    geodebug.pause(1000)
  end

  geodebug.color(red)
  geodebug.point(cut)
  geodebug.loop(cut)
  
  -- stage four: triangulation
  local tri = poly.triangulate(cut)
  -- draw triangles
  if tri and #tri > 0 then
    assert(#tri%2 == 0, #tri/2)
    assert(#tri%6 == 0, #tri/2)

    geodebug.color(orange)
    for i = 1, #tri, 6 do
      local t = {}
      for j = i, i + 5 do
        t[#t + 1] = tri[j]
      end
      assert(#t == 6)
      geodebug.loop(t)
    end
  end
  geodebug.color(YELLOW)
  geodebug.triangle(tri)
  
  --[[
  -- todo: box2d causes C crashes
  geodebug.color(blue)
  local p1b = {}
  for i = 1, #p1, 2 do
    p1b[(i + 1)/2] = b2.Vec2(p1[i], p1[i + 1])
  end
  local out = {}
  if #p1b >= 3 then
    b2.Fill(p1b, out)
    out = poly.fromvectors(out)
  end
  poly.scale(out, 1/3,1/3)
  poly.translate(out, -300, -200)
  geodebug.color(blue)
  geodebug.triangle(out)
  
  local cutb = {}
  for i = 1, #cut, 2 do
    cutb[(i + 1)/2] = b2.Vec2(cut[i], cut[i + 1])
  end
  local out2 = {}
  if #cutb >= 3 then
    b2.Fill(cutb, out2)
    out2 = poly.fromvectors(out2)
  end
  poly.scale(out2, 1/3,1/3)
  poly.translate(out2, 300, -200)
  geodebug.color(blue)
  geodebug.triangle(t)
  ]]

  terminal.trace("original (white)", #p1/2)
  terminal.trace("holes (lime)", #polys - 1)
  terminal.trace("'cuthole' (red)", #cut)
  terminal.trace("'triangulate' (yellow)", #tri/6)
  terminal.trace("canvas.polygon (green)", #tri/6)
  --terminal.trace("b2.fill (blue)", #out/3 .. ' with holes:' .. #out2/3)

end

local files = lfs.get_rdir("utils/math/test")
local i = 12
function keyboard:on_press(k)
  if k == KEY_LEFT then
    i = (i - 1)
    if i == 0 then i = #files end
  elseif k == KEY_RIGHT then
    i = (i + 1)
    if i > #files then i = 1 end
  end
  newpoly(files[i])
end
keyboard:on_press(KEY_LEFT)

function mouse:on_press(b)
  newpoly(files[i])
end

function mouse:on_wheelmove(z)
  if z < 0 then
    sps = math.floor(sps/2)
  else
    sps = math.max(sps, 1)
    sps = sps*2
  end
  terminal.trace("steps per second", sps)
end

timer = Timer()
timer:start(16, true)
accum = 0
function timer:on_tick()
  local dt = timer:get_delta_ms()/1000
  local steps = math.floor(accum*sps)
  if steps > 0 then
    geodebug.redraw(steps)
    accum = 0
  else
    accum = accum + dt
  end
  terminal.trace("memory", collectgarbage("count"))
  terminal.trace("file", files[i])
  terminal.trace("mouse wheel", "change visualization speed")
  terminal.trace("mouse click", "restart")
  terminal.trace("left/right keys", "another test")
end
