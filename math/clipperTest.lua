--[[
version 0.0.2
--]]

local thisModule = {}
local clipper = require("code.math.clipper.clipper")
local executeOperation = {intersection='intersection', union='union', difference='difference', xor='xor'}
local fillType = {even_odd='even_odd', non_zero='non_zero', positive='positive', negative='negative'}
local timer = {}

local polygon = {}
timer.start = love.timer.getTime()
polygon[1] = clipper.polygon()

polygon[1]:add(100, 100)
polygon[1]:add(200*5, 100)
polygon[1]:add(200*5, 200*5)
polygon[1]:add(100, 200*5)

polygon[2] = clipper.polygon()
-- in
--polygon[2]:add(150, 150)
--polygon[2]:add(250, 150)
--polygon[2]:add(250, 250)
--polygon[2]:add(150, 250)
-- knife
polygon[2]:add(150, -150)
polygon[2]:add(250, -150)
polygon[2]:add(250, 250*5)
polygon[2]:add(150, 250*5)
-- big out
--polygon[2]:add(150, 150)
--polygon[2]:add(250*5, 150)
--polygon[2]:add(250*5, 250*5)
--polygon[2]:add(150, 250*5)

timer.result = love.timer.getTime() - timer.start
print("clipper.polygon() time:", math.nSA(timer.result))

------------------------------ clipping
local clippingResult
timer.start = love.timer.getTime()
for i=1, 1000 do
	local clO = clipper.new()												-- create a clipper object
	clO:add_subject(polygon[1])
	clO:add_clip(polygon[2])
	clippingResult = clO:execute(executeOperation.difference, fillType.even_odd, fillType.even_odd, false)
--	clippingResult = clippingResult:offset(-5, 'miter', 10)
--	clippingResult = clippingResult:simplify()
end

timer.result = love.timer.getTime() - timer.start
print("clipping time:", math.nSA(timer.result))
print("clippingResult:size(): ",clippingResult:size())
-------------------------------

function thisModule:draw()
	-- polygon[1]
	if false then
		local vertices = {}
		for i=1, polygon[1]:size() do
			vertices[#vertices+1] = tonumber(polygon[1]:get(i).x)
			vertices[#vertices+1] = tonumber(polygon[1]:get(i).y)
		end
		love.graphics.setColor(0, 0, 255, 255)
		love.graphics.polygon("fill", vertices)
	end
	
	-- polygon[2]
	if false then
		local vertices = {}
		for i=1, polygon[2]:size() do
			vertices[#vertices+1] = tonumber(polygon[2]:get(i).x)
			vertices[#vertices+1] = tonumber(polygon[2]:get(i).y)
		end
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.polygon("fill", vertices)
	end

	-- clippingResult
	if true then
		for i=1, clippingResult:size() do
			local poly = clippingResult:get(i)
			
			local vertices = {}
			for i1=1, poly:size() do
				vertices[#vertices+1] = tonumber(poly:get(i1).x)
				vertices[#vertices+1] = tonumber(poly:get(i1).y)
			end
			
			local triangles
			if not love.math.isConvex(vertices) then
				triangles = love.math.triangulate(vertices)
			end
			
			love.graphics.setColor(0, 255, 0, 200)
			if triangles then
				for i=1, #triangles do
					love.graphics.polygon("fill", triangles[i])
				end
			else
				love.graphics.polygon("fill", vertices)
			end			
		end
		
		for i=1, clippingResult:size() do
			local poly = clippingResult:get(i)
			
			for i1=1, poly:size() do
				love.graphics.setColor(255, 0, 0, 255)
				love.graphics.print(i1, tonumber(poly:get(i1).x), tonumber(poly:get(i1).y))
			end		
		end		
	end

end

return thisModule