--[[
version 0.0.1
HELP:
	+ Polygon существует вне класса Cell
	+ похож на Node
TODO:
	-NO Class Node
		-? адаптировать код 
		-? унаследовать
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
ThisModule.vertices = {}
ThisModule.clipper = false																														-- <clipper polygon object> or false
ThisModule.imHole = false																														-- im a poligon-hole

-- methods static private


-- methods static protected


-- methods static public

-- arg.vertices = <table>
function ThisModule:newObject(arg)																												-- rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- nonstatic variables, methods; init new variables from methods arguments
	object.vertices = arg.vertices or self.vertices																								-- example: {1, 1, 2, 1, 2, 2}
	object.cut = {}
	object.cut.polygonHoles = {}
	object.cut.result = {}
	
	return object																																-- be sure to return new object
end

function ThisModule:draw()
	if self.destroyed then return nil end																										-- reserved; тут не нужен вызов ошибки
	
	
end

function ThisModule:addPolygonHole(polygon)
	if self.destroyed or polygon.destroyed or self == polygon then return nil end																										-- reserved; тут не нужен вызов ошибки
	
	self.cut.polygonHoles[polygon] = polygon
end

return ThisModule																																-- reserved
