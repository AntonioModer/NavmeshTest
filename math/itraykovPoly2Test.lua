--[[
version 0.0.1
HELP:
	+ https://love2d.org/forums/viewtopic.php?f=3&t=81155#p190628
TODO:
	- https://love2d.org/forums/viewtopic.php?f=3&t=81155#p190749
--]]

local thisModule = {}

local poly2 = require("code.math.itraykov.poly2")
local Delaunay = require("code.math.delaunayTriangulation.byYonaba.delaunay")
local Point    = Delaunay.Point

-- Creating 10 random points
--for i = 1, 100 do
--	points[i] = Point(math.random() * 1000, math.random() * 1000)
--end

local polygon = {
    100,   100
  , 200*5, 100
  , 200*5, 200*5
  , 100,   200*5
}

local hole = {
    150, 150
  , 250, 150
  , 250, 250
  , 150, 250
}


--points[#points+1] = Point(100, 520)

--points[#points+1] = Point(102, 500)						-- test
-----------------------------

local timer = {}
timer.start = love.timer.getTime()

local triangles
local polygonCut
for i=1, 1 do
	polygonCut = poly2.cuthole(polygon, hole)
	triangles = poly2.triangulate(polygonCut)
--	triangles = love.math.triangulate(polygonCut)
end

timer.result = love.timer.getTime() - timer.start
print("time = ", timer.result)
print("polygonCut points count = ", #polygonCut/2)
print("triangles count = ", #triangles/6)

--for i, v in ipairs(triangles) do
--	print(v)
--end

function thisModule:draw()
--	love.graphics.setLineStyle('rough')
	love.graphics.setLineWidth(3)
--	love.graphics.setLineJoin('none')
	
--	for i, triangle in ipairs(triangles) do
--		if triangle ~= false then
--			love.graphics.setColor(0, 255, 0, 255)
--			love.graphics.polygon("fill", triangle)	
			
--			love.graphics.setColor(0, 0, 255, 255)
--			love.graphics.polygon("line", triangle)
--		end
--	end
	
--	love.graphics.setColor(0, 255, 0, 255)
--	love.graphics.polygon("fill", polygonCut)	
	
--	love.graphics.setColor(0, 0, 255, 255)
--	love.graphics.polygon("line", polygonCut)	
	
	-- iterate triangles
	for i = 1, #triangles, 6 do
		local ax, ay = triangles[i], triangles[i + 1]
		local bx, by = triangles[i + 2], triangles[i + 3]
		local cx, cy = triangles[i + 4], triangles[i + 5]
		
		love.graphics.setColor(0, 255, 0, 255)
		love.graphics.polygon("fill", ax, ay, bx, by, cx, cy)
		
		love.graphics.setColor(0, 0, 255, 255)
		love.graphics.polygon("line", ax, ay, bx, by, cx, cy)		
	end	
	
	love.graphics.setLineWidth(1)
--	love.graphics.setLineJoin('miter')
end

return thisModule