--[[
version 0.0.1
HELP:
	+ похож на Graph
--]]

local ClassParent = require('Class')																										-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private


-- variables static protected, only in Class


-- variables static public
ThisModule.x = 0																																-- example
ThisModule.y = 0																																-- example

-- methods static private


-- methods static protected


-- methods static public
function ThisModule:newObject(arg)																												-- rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- nonstatic variables, methods; init new variables from methods arguments
	object.x = arg.x or self.x
	object.y = arg.y or self.y
	object.polygons = self:newObjectsWeakTable()																								-- read only!!!; key and value is <table>;			
	object.polygonsCount = 0																													-- read only!!!;
	
	return object																																-- be sure to return new object
end

function ThisModule:addNewPolygon(arg)
	if self.destroyed then self:destroyedError() end																										-- reserved;
	
	local polygon = require('classes.navmesh.Polygon'):newObject(arg)
	self:addPolygon(polygon)
	
	return polygon
end

function ThisModule:addPolygon(polygon)
	if self.destroyed then self:destroyedError() end																										-- reserved;
	if polygon.destroyed then return false end
	
	self.polygons[polygon] = polygon
	self.polygonsCount = self.polygonsCount + 1
end

function ThisModule:deletePolygon(polygon)
	if self.destroyed then self:destroyedError() end																										-- reserved;
	if not self.polygons[polygon] then return false end
	
	self.polygons[polygon] = nil
	self.polygonsCount = self.polygonsCount - 1
end

function ThisModule:deleteAllPolygons()
	if self.destroyed then self:destroyedError() end																										-- reserved;
	
	for k, polygon in pairs(self.polygons) do
		polygon:destroy()
	end
	
	self.polygons = {}
	self.polygonsCount = 0
end

function ThisModule:draw()
	if self.destroyed then return nil end																										-- reserved; тут не нужен вызов ошибки
	
	for k, polygon in pairs(self.polygons) do
		for i, triangle in ipairs(love.math.triangulate(polygon.vertices)) do
			love.graphics.polygon("fill", triangle)
		end					
	end
end

function ThisModule:test()
	if self.destroyed then return nil end																										-- reserved; тут не нужен вызов ошибки
	
	
end

return ThisModule																																-- reserved
