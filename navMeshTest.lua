--[[
Copyright © Savoshchanka Anton Aleksandrovich, 2015
version 0.0.3
HELP:
	+ https://love2d.org/forums/viewtopic.php?f=5&t=81229
	+ clipperTest version 0.0.4
TODO:
	- Class
		-+ Cell
		-+ Polygon
		-+ Obstacle
		-+  внедрить
		- рефакторинг кода
		- тестирование
		- поработать над thisModule.result	
	- TODO1 алгоритм
		- работаем clipper-ом
		-+ для каждого полигона проверяем внутри ли он остальных полигонов (смотри CutHolesTest.cut.isPolygonInPolygon)
			-+ если да, то
				-?YES version 1
					-+ запоминаем его как дырку-полигон в вырезаемом полигоне
					- шаг
						-? вырезаем и обновляем результат для полигона с дыркой
						-? удаляем из cell; 
						- не обязательно делать этот шаг, можно просто запомнить этот полигон как дырку
					- результат с вырезанной дыркой используем только для поиска пути или рисования, не для вырезания (смотри CutHolesTest.cut.cutHoles)
				-?NO version 2
					- вырезаем дырку в нужном полигоне
					- если нужно (если полигон вогнутый), то результат разделяем на выпуклые полигоны, и дальше работаем с выпуклыми
						+ test Hardoncollider Polygon:splitConvex()
							- проблемы с совместимостью с clipper: clean(), simplify()
						- вогнутый полигон удаляем из cell
						- добавляем новые выпуклые полигоны в cell
			- если нет, то работаем clipper-ом
		- TODO2 разобраться с случай1.png
			- как определить последовательность вырезания дырок?
				- всегда ли будет правильная последовательность генерируемая clipper?
--]]

--[[
	zlib License

	Copyright (c) 2015 Savoshchanka Anton Aleksandrovich

	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgement in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
	
--]]

local thisModule = {}
local Cell = require('classes.navmesh.Cell')
local Obstacle = require('classes.navmesh.Obstacle')

-------------------------------------------------- clipper
local clipperModule = require("clipper.clipper")

------------- my
--[[
version 0.0.2
--]]
do

clipperModule.executeOperation = {intersection='intersection', union='union', difference='difference', xor='xor'}
clipperModule.fillType = {even_odd='even_odd', non_zero='non_zero', positive='positive', negative='negative'}

clipperModule.checkType = {}
function clipperModule.checkType.clipper_Polygon(var)
	if string.find(tostring(var), "clipper_Polygon") and not string.find(tostring(var), "clipper_Polygons") then
		return  true
	else
		return  false
	end
end
function clipperModule.checkType.clipper_Polygons(var)
	local result = string.find(tostring(var), "clipper_Polygons")
	if result then
		result = true
	else
		result = false
	end
	return result
end

function clipperModule:newPolygon(tablePoints)
	assert(#tablePoints > 0, "#table <= 0")
	local clipperPolygon = self.polygon()
	for i=1, #tablePoints, 2 do
		clipperPolygon:add(tablePoints[i], tablePoints[i+1])
	end
	return clipperPolygon
end

function clipperModule:newPolygonsList(tablePolygonsObjects)
	local empty = true
	local clipperPolygonsList = self.polygons()
	for k, polygon in pairs(tablePolygonsObjects) do
--		assert(self.checkType.clipper_Polygon(polygon.clipper), "in table variable at key("..tostring(k)..") is not clipper_Polygon or clipper_Polygons type")
		if self.checkType.clipper_Polygon(polygon.clipper) then
			clipperPolygonsList:add(polygon.clipper)
			empty = false
		end
	end
	if empty then return false end
	return clipperPolygonsList
end

function clipperModule:clip(subjectPolygon, clipPolygon)
	assert(self.checkType.clipper_Polygon(subjectPolygon) or self.checkType.clipper_Polygons(subjectPolygon), "argument1 not clipper_Polygon or clipper_Polygons type")
	assert(self.checkType.clipper_Polygon(clipPolygon) or self.checkType.clipper_Polygons(clipPolygon), "argument2 not clipper_Polygon or clipper_Polygons type")
	
	local clO = self.new()																		-- clipper object
	clO:add_subject(subjectPolygon)
	clO:add_clip(clipPolygon)
	return clO:execute(self.executeOperation.difference, self.fillType.even_odd, self.fillType.even_odd, true)
end
end
------------------------------------------------------------	

------------------------- cell
do
	thisModule.cell = Cell:newObject()
	thisModule.cell:addNewPolygon({vertices = {
		200, 110,
		600, 110,
		600, 510,
		200, 510
	}})

	-- test clean()
--	{
--		10*1, 10*1,
--		100*1, 10*1,
--		100*1, 100*1,
--		10*1, 100*1,
--		99*1, 99*1
--	}		
end

-------------------------- obstacle
do
	thisModule.obstacle = Obstacle:newObject()
	thisModule.obstacle:addNewPolygon({vertices = {
		150, 150,
		250, 150,
		250, 250,
		150, 250
	}})
	thisModule.obstacle:addNewPolygon({vertices = {
		0, 0,
		1, 0,
		1, 1,
		0, 1
	}})
end

-------------------------- result
do
	thisModule.result = {}
	thisModule.result.polygons = {}
	function thisModule.result:refreshFromClipperResult()
		self.polygons = {}
		for polyN1=1, clipperModule.result:size() do
			local clipperPolygons = clipperModule.result:get(polyN1)
			clipperPolygons = clipperModule.polygons(clipperPolygons)
			clipperPolygons = clipperPolygons:clean()										-- try FIX2 BUG3
			clipperPolygons = clipperPolygons:simplify()									-- FIX BUG4
			
			for polyN2=1, clipperPolygons:size() do
				local newPolygon = {}
				table.insert(self.polygons, newPolygon)
				local clipperPolygon = clipperPolygons:get(polyN2)
				for pointN3=1, tonumber(clipperPolygon:size()) do
					table.insert(newPolygon, tonumber(clipperPolygon:get(pointN3).x))
					table.insert(newPolygon, tonumber(clipperPolygon:get(pointN3).y))
				end
			end
		end	
	end
end

function thisModule:clip()
	if thisModule.cell.polygonsCount > 0 then
		
		-- refresh clipper polygons
		for _, polygon in pairs(thisModule.obstacle.polygons) do
			polygon.clipper = clipperModule:newPolygon(polygon.vertices)
		end
		
		local p1 = clipperModule:newPolygonsList(thisModule.cell.polygons)
		local p2 = clipperModule:newPolygonsList(thisModule.obstacle.polygons)
		clipperModule.result = clipperModule:clip(p1, p2)
		
		-- вроде не работает тут как ожидал
--		clipperModule.result = clipperModule.result:clean()
--		clipperModule.result = clipperModule.result:simplify()										-- BUG4 смотри картинку
		
		thisModule.result:refreshFromClipperResult()
		
		-- test
		if false then
			local removeIndexes, polygonsConvex = {}, {}
			for i, polygon in ipairs(thisModule.result.polygons) do
				if not love.math.isConvex(polygon) then
					local concave = require('hardoncollider.polygon')(unpack(polygon))
					table.insert(polygonsConvex, concave:splitConvex())
					table.insert(removeIndexes, i)
				end
			end
			for i, index in ipairs(removeIndexes) do
				table.remove(thisModule.result.polygons, index)
			end
			for _, polygonList in ipairs(polygonsConvex) do
				for _, polygon in ipairs(polygonList) do
					table.insert(thisModule.result.polygons, {polygon:unpack()})
				end
			end			
		end
		-- алгоритм version 1 test
		if false then
			for i1, polygon1 in ipairs(thisModule.result.polygons) do
				for i2, polygon2 in ipairs(thisModule.result.polygons) do
					if polygon1 ~= polygon2 and CutHolesTest.cut.isPolygonInPolygon(polygon1, polygon2) then
						polygon1:addHole(polygon2)
					end
				end
			end
			
			-- вырезаем дырки
			-- ...
		end
	end		
end

---------------------------------------- test

for _, polygon in pairs(thisModule.cell.polygons) do
	polygon.clipper = clipperModule:newPolygon(polygon.vertices)
end
for _, polygon in pairs(thisModule.obstacle.polygons) do
	polygon.clipper = clipperModule:newPolygon(polygon.vertices)
end

clipperModule.result = clipperModule:clip(clipperModule:newPolygonsList(thisModule.cell.polygons), clipperModule:newPolygonsList(thisModule.obstacle.polygons))
thisModule.result:refreshFromClipperResult()
-------------------------------------


function thisModule:update(dt)
--	if true then return nil end
	----------------------------------------------------------------------------------------- update obstacle
	-------------------------- двигаем obstacle
	local x, y = love.mouse.getPosition()
	thisModule.obstacle:deleteAllPolygons()
	thisModule.obstacle:addNewPolygon({vertices = {
		x, y,
		x+50, y,
		x+50, y+50,
		x, y+50
	}})
	thisModule.obstacle:addNewPolygon({vertices = {
		0, 0,
		1, 0,
		1, 1,
		0, 1
	}})
	
	--------------------------- clipper
	if true then
		thisModule:clip()
		
		-- FIX1 BUG3 (see image)
		if true then
			local fixBUG3 = {}
			fixBUG3.need = false
			for i, polygon in ipairs(thisModule.result.polygons) do
				local triangles
				local ok, out = pcall(love.math.triangulate, polygon)
				if not ok then
					-- cant draw(triangulate) result.polygons
					fixBUG3.need = true
					break
				end
			end
			if fixBUG3.need then
				
				------------------------------ scale obstacle to +1
				thisModule.obstacle:deleteAllPolygons()
				fixBUG3.x, fixBUG3.y = x-1, y-1
				thisModule.obstacle:addNewPolygon({vertices = {
					fixBUG3.x, fixBUG3.y,
					fixBUG3.x+50+2, fixBUG3.y,
					fixBUG3.x+50+2, fixBUG3.y+50+2,
					fixBUG3.x, fixBUG3.y+50+2
				}})
				thisModule.obstacle:addNewPolygon({vertices = {
					0, 0,
					1, 0,
					1, 1,
					0, 1
				}})
				thisModule:clip()
				
				------------------------------- перепроверяем
				for i, polygon in ipairs(thisModule.result.polygons) do
					local triangles
					local ok, out = pcall(love.math.triangulate, polygon)
					if not ok then
						-- cant draw(triangulate) result.polygons
						fixBUG3.need = false
						break
					else
						-- если проблема исправлена
						print(os.clock(), 'fix bug 3', x, y)
					end
				end
				
				-------------------------------- если проблема не исправлена, то отменяем предыдущий результат; чтобы было все точно, без лишнего увеличения obstacle
				if not fixBUG3.need then
					thisModule.obstacle:deleteAllPolygons()
					thisModule.obstacle:addNewPolygon({vertices = {
						x, y,
						x+50, y,
						x+50, y+50,
						x, y+50
					}})
					thisModule.obstacle:addNewPolygon({vertices = {
						0, 0,
						1, 0,
						1, 1,
						0, 1
					}})
					thisModule:clip()				
				end
			
			end
		end
	end
	
end

function thisModule:mousePressed(x, y, button)
	if button == 'l' then
--		-- при нажатии на кнопку мыши запоминаем вырезаную cell, и уже вырезаем в ней в дальнейшем
--		thisModule.cell.polygons = thisModule.result.polygons
--		do
--			thisModule.cell.clipperPolygons = {}
--			for i, polygon in ipairs(thisModule.cell.polygons) do
--				table.insert(thisModule.cell.clipperPolygons, clipperModule:newPolygon(polygon))
--			end
----			print(#thisModule.cell.polygons)
--		end
		
		thisModule.cell:deleteAllPolygons()
		for i, polygon in pairs(thisModule.result.polygons) do
			local newPolygon = thisModule.cell:addNewPolygon({vertices = polygon})
			newPolygon.clipper = clipperModule:newPolygon(newPolygon.vertices)
		end
	end	
end

function thisModule:draw()
	
	-- cell.polygons
	if true then
		love.graphics.setColor(0, 255, 0, 255)
		local ok, out = pcall(thisModule.cell.draw, thisModule.cell)
		if ok then
			
		else
			love.graphics.print('cant draw(triangulate) cell.polygons: '..out, 0, 0, 0, 1, 1)
		end
	end
		
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle('rough')
	love.graphics.setLineJoin('none')
	------------------------------------------------------ thisModule.result.polygons
	if true then
		for i, polygon in ipairs(thisModule.result.polygons) do
			local triangles
			local ok, out = pcall(love.math.triangulate, polygon)
			if ok then
				triangles = out
				love.graphics.setColor(0, 0, 255, 255)
				for i1, triangle in ipairs(triangles) do
					love.graphics.polygon('line', triangle)
				end
				
				love.graphics.setColor(255, 0, 0, 255)
				love.graphics.print(i, polygon[1], polygon[2], 0, 1.5, 1.5)
			else
				love.graphics.setColor(0, 0, 255, 255)
				love.graphics.print('cant draw(triangulate) result.polygons', 0, 20, 0, 1, 1)
			end
		end
	end
	love.graphics.setLineStyle('smooth')
	love.graphics.setLineWidth(1)
	
	love.graphics.setColor(255, 0, 0, 255)
	thisModule.obstacle:draw()
	
	love.graphics.setColor(0, 255, 0, 255)
	love.graphics.print('cell.polygonsCount = '..thisModule.cell.polygonsCount, 0, 40, 0, 1, 1)
	love.graphics.setColor(0, 0, 255, 255)
	love.graphics.print('clipper.result:size() = '..clipperModule.result:size(), 0, 60, 0, 1, 1)
	love.graphics.print('#result.polygons = '..#thisModule.result.polygons, 0, 80, 0, 1, 1)
	local mx, my = love.mouse.getPosition()
	love.graphics.print('mouse position() = '..mx..', '..my, 0, 100, 0, 1, 1)
end

return thisModule