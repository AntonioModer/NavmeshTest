terminal = require('utils.log.terminal')

display:create("terminal test", 1024, 768, 32, true)

s = Sprite()
display.viewport:add_child(s)
c = s.canvas

local white = Color(255, 255, 255)
local red = Color(255, 0, 0)

wave = require("utils.math.wave")
waves = {}
for fn, func in pairs(wave) do
  table.insert(waves, fn)
end

function drawwave(func)
  c:clear()
  c:move_to(0, 0)
  c:line_to(0, 1*200)
  c:move_to(1*400, 0)
  c:line_to(1*400, 1*200)
  c:move_to(-1*400, 0)
  c:line_to(-1*400, 1*200)
  c:move_to(-1*400, 0)
  c:line_to(1*400, 0)
  c:move_to(-1*400, 1*200)
  c:line_to(1*400, 1*200)
  c:set_line_style(1, red, 1)
  c:stroke()
  for i = -200, 200 do
    local r = i/100
    if i == -200 then
      c:move_to(r*400, func(r)*200)
    else
      c:line_to(r*400, func(r)*200)
    end
  end
  c:set_line_style(1, white, 1)
  c:stroke()
end

i = 1
function mouse:on_press()
  i = i + 1
  if i > #waves then
    i = 1
  end
  local fn = waves[i]
  drawwave(wave[fn])
  terminal.trace("wave", fn)
end

mouse:on_press()