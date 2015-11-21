--[[
Copyright © Savoshchanka Anton Aleksandrovich, 2015
version 0.0.1
HELP:
	+ https://love2d.org/forums/viewtopic.php?f=5&t=81229
	+ clipperTest version 0.0.4
TODO:
	- Class
		-+ Cell
			-? похож на Graph
		-+ Polygon
			-? похож на Node
		- TODO1 внедрить
	- алгоритм
		- для каждого полигона проверяем внутри ли он остальных полигонов
			- если да, то
				- clipper-ом не работаем
				-? version 1
					- запоминаем его как дырку полигона
					- вырезаем и обновляем результат для полигона с дыркой
					- удаляем из cell
					- результат используем только для поиска пути, не для вырезания
				-? version 2
					- вырезаем дырку в нужном полигоне
					- если нужно (если полигон вогнутый), то результат разделяем на выпуклые полигоны, и дальше работаем с выпуклыми
						+ test Hardoncollider Polygon:splitConvex()
							- проблемы с совместимостью с clipper: clean(), simplify()
						- вогнутый полигон удаляем из cell
						- добавляем новые выпуклые полигоны в cell
			- если нет, то работаем clipper-ом
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

------------------------- cell
do
	thisModule.cell = {}
	thisModule.cell.polygons = {}
	thisModule.cell.polygons[1] = {
		200, 110,
		600, 110,
		600, 510,
		200, 510
	}
	thisModule.cell.clipperPolygons = {}

	-- test clean()
--	thisModule.cell.polygons[1] = {
--		10*1, 10*1,
--		100*1, 10*1,
--		100*1, 100*1,
--		10*1, 100*1,
--		99*1, 99*1
--	}		
end

-------------------------- obstacle
do
	thisModule.obstacle = {}
	thisModule.obstacle.polygons = {}
	thisModule.obstacle.polygons[1] = {
		150, 150,
		250, 150,
		250, 250,
		150, 250
	}
	thisModule.obstacle.polygons[2] = {
		0, 0,
		1, 0,
		1, 1,
		0, 1
	}		
	thisModule.obstacle.clipperPolygons = {}
	function thisModule.obstacle:refreshClipperPolygons()
		self.clipperPolygons = {}
		for i, polygon in ipairs(self.polygons) do
			table.insert(self.clipperPolygons, thisModule.clipper:newPolygon(polygon))
		end
	end	
end

-------------------------- result
do
	thisModule.result = {}
	thisModule.result.polygons = {}
	function thisModule.result:refreshFromClipperResult()
		self.polygons = {}
		for polyN1=1, thisModule.clipper.result:size() do
			local clipperPolygons = thisModule.clipper.result:get(polyN1)
			clipperPolygons = thisModule.clipper.polygons(clipperPolygons)
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
	if #thisModule.cell.clipperPolygons > 0 then
		thisModule.obstacle:refreshClipperPolygons()
		
		local p1 = thisModule.clipper:newPolygonsList(thisModule.cell.clipperPolygons)
		local p2 = thisModule.clipper:newPolygonsList(thisModule.obstacle.clipperPolygons)		
		thisModule.clipper.result = thisModule.clipper:clip(p1, p2)
		
		-- вроде не работает тут как ожидал
--		thisModule.clipper.result = thisModule.clipper.result:clean()
--		thisModule.clipper.result = thisModule.clipper.result:simplify()										-- BUG4 смотри картинку
		
		thisModule.result:refreshFromClipperResult()
		
		-- test TODO1
		if true then
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
		
		
	end		
end

-------------------------- clipper
thisModule.clipper = require("clipper.clipper")

table.insert(thisModule.cell.clipperPolygons, thisModule.clipper:newPolygon(thisModule.cell.polygons[1]))
table.insert(thisModule.obstacle.clipperPolygons, thisModule.clipper:newPolygon(thisModule.obstacle.polygons[1]))
table.insert(thisModule.obstacle.clipperPolygons, thisModule.clipper:newPolygon(thisModule.obstacle.polygons[2]))

thisModule.clipper.result = thisModule.clipper:clip(thisModule.clipper:newPolygonsList(thisModule.cell.clipperPolygons), thisModule.clipper:newPolygonsList(thisModule.obstacle.clipperPolygons))
thisModule.result:refreshFromClipperResult()



function thisModule:update(dt)
--	if true then return nil end
	----------------------------------------------------------------------------------------- update obstacle
	-------------------------- двигаем obstacle
	local x, y = love.mouse.getPosition()
	thisModule.obstacle.polygons[1] = {
		x, y,
		x+50, y,
		x+50, y+50,
		x, y+50
	}
	thisModule.obstacle.polygons[2] = {
		0, 0,
		1, 0,
		1, 1,
		0, 1
	}	
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
				fixBUG3.x, fixBUG3.y = x-1, y-1
				thisModule.obstacle.polygons[1] = {
					fixBUG3.x, fixBUG3.y,
					fixBUG3.x+50+2, fixBUG3.y,
					fixBUG3.x+50+2, fixBUG3.y+50+2,
					fixBUG3.x, fixBUG3.y+50+2
				}
				thisModule.obstacle.polygons[2] = {
					0, 0,
					1, 0,
					1, 1,
					0, 1
				}
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
					thisModule.obstacle.polygons[1] = {
						x, y,
						x+50, y,
						x+50, y+50,
						x, y+50
					}
					thisModule.obstacle.polygons[2] = {
						0, 0,
						1, 0,
						1, 1,
						0, 1
					}	
					thisModule:clip()				
				end
			
			end
		end
	end
	
end

function thisModule:mousePressed(x, y, button)
	if button == 'l' then
		-- при нажатии на кнопку мыши запоминаем вырезаную cell, и уже вырезаем в ней в дальнейшем
		thisModule.cell.polygons = thisModule.result.polygons
		do
			thisModule.cell.clipperPolygons = {}
			for i, polygon in ipairs(thisModule.cell.polygons) do
				table.insert(thisModule.cell.clipperPolygons, thisModule.clipper:newPolygon(polygon))
			end
--			print(#thisModule.cell.polygons)
		end
	end	
end

function thisModule:draw()
	
	-- cell.polygons
	if true then
		love.graphics.setColor(0, 255, 0, 255)
		for i, polygon in ipairs(thisModule.cell.polygons) do
			local triangles
			local ok, out = pcall(love.math.triangulate, polygon)
			if ok then
				triangles = out
				for i, triangle in ipairs(triangles) do
					love.graphics.polygon("fill", triangle)
				end					
			else
				love.graphics.print('cant draw(triangulate) cell.polygons', 0, 0, 0, 1, 1)
			end
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
	love.graphics.polygon('fill', thisModule.obstacle.polygons[1])
	
	love.graphics.setColor(0, 255, 0, 255)
	love.graphics.print('#cell.polygons = '..#thisModule.cell.polygons, 0, 40, 0, 1, 1)
	love.graphics.setColor(0, 0, 255, 255)
	love.graphics.print('clipper.result:size() = '..thisModule.clipper.result:size(), 0, 60, 0, 1, 1)
	love.graphics.print('#result.polygons = '..#thisModule.result.polygons, 0, 80, 0, 1, 1)
	local mx, my = love.mouse.getPosition()
	love.graphics.print('mouse position() = '..mx..', '..my, 0, 100, 0, 1, 1)
end

return thisModule