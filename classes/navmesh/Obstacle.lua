--[[
version 0.0.1
HELP:
	+ 
--]]

local ClassParent = require('classes.navmesh.Cell')																								-- reserved; you can change the string-name of import-module (parent Class) 
local ThisModule																																-- reserved
if ClassParent then																																-- reserved
	ThisModule = ClassParent:_newClass(...)																										-- reserved
else																																			-- reserved
	ThisModule = {}																																-- reserved
end																																				-- reserved


-- variables static private


-- variables static protected, only in Class


-- variables static public


-- methods static private


-- methods static protected


-- methods static public
function ThisModule:newObject(arg)																												-- rewrite parent method
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local arg = arg or {}																														-- be sure to create empty 'arg' table
	local object = ClassParent.newObject(self, arg)																								-- be sure to call the parent method
	
	-- nonstatic variables, methods; init new variables from methods arguments
	
	
	return object																																-- be sure to return new object
end

return ThisModule																																-- reserved
