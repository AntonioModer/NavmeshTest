--[[
PILMetaClass module, version 0.2.2
HELP: [=
	+ based on prototype system
	+ Class - superclass, который является родителем всех классов
	+!!! при любом обращении к объекту или Классу необходимо проверять не уничтожен ли он
	+ все Классы (кроме суперкласса Class) должны быть в папке с именем "classes"
	+ только имя переменной ссылающейся на класс и имя файла класса должно начинаться с большой буквы, это нужно для лучшего понимания кода
	+ имеет базовое наследование, может быть только один класс-родитель
	+ все переменные и методы:
		+ encapsulation: private, protected, public
			+ private является истинно закрытым типом
			+ protected имеет знак подчеркивания перед именем (_) и не является закрытым типом, аналогичен public
		+ по умолчанию являются статическими и не создаются в памяти нового объекта или нового класса, или класса-потомка;
		+ при переопределении они создаются в памяти;
		+ являются значением по умолчанию, которое определено в классе или классе-потомке;
		+ их можно переопределять в определении нового класса-потомка;
		+ в объекте переопределять лучше только переменные, методы не желательно, для избежания ошибок
	+ объект будет существовать пока он есть в классе; чтобы удалить объект необходимо удалить его из класса
	+ метод: удаление объекта
		+ выяснить почему часть памяти не удаляется после сборки мусора
			+INFO нужно полностью удалить таблицу объектов из класса и внешние слабые таблицы-ссылки на объекты	
	+ метод: удаление класса
		+ если класс является родителем, то можно его удалять?
			+ нельзя	
	+ слабые ссылки
		+ нельзя использовать слабые таблицы с числовым ключом, т.к. если сборщик удалит значение (nil), то нельзя будет корректно работать с такой таблицей (смотри table.lua "подводный камень 1" и http://www.lua.org/manual/5.1/manual.html#2.5.5)
		+ все ссылки на объект вне класса желательно должны быть значением слабой таблицы
		-?NO класс должен знать свою внешнюю слабую таблицу			
	+ достоинства:
		+ не нужно контролировать вручную наследование переменных в каждом наследнике
		+ в наследнике из-за _index память под несуществующие переменные не выделяется, если не присвоить им значения
	+ недостатки:
		+ необходимо делать для каждого объекта дополнительную метатаблицу, что увеличивает память
	- не нужно делать этого: учет _objectsCount сделать опциональным (или, на крайний случай, убрать отсюда и перенести в Entity) (чтобы не было зависимости от числа)
		+INFO _objectsCount может достигнуть math.huge, но это не страшно, т.к. (math.huge > 0)
	+ везде проверять не удален ли объект; в каждом методе класса: если удален то выводить ошибку
		+INFO последствие: если Класс удален, то для всех его Объектов: <self.destroyed = true>, т.е. все Объекты этого класса будут считаться удаленными, даже если они (и Класс) есть в памяти
	+ разобраться как работать с readonly variables
		-NO с помощью методов
			- проблемы с наследованием
			- медленно
				- можно ускорить с помощью локальных переменных, то тогда память возрастет
			- нужно переводить в private
		+YES просто в коментарии помечать
			- можно сделать ошибку забыв какая переменная
		-NO ввести таблицу readOnly, ro
			- проблемы с наследованием
			- нужно создавать новую таблицу
			- может случится путаница
		-NO писать в имени переменной ro_
			- проблемы с наследованием
			- некрасиво
			- может случится путаница	
=]
TODO:
	- во всех методах аргументы должны передаваться таблицей: method({arg1=1, arg2=2})
		- чтобы легче было работать с components в Entity
	+ переименовать _type в: __type или _luaType или _protoType (_prototypeType)
		-NO или перенести private переменную type в метод type(), нужна также setType()
	- рефакторинг кода
		- во всех исходных файлах классов написать в коментах "static/nonstatic" где надо
	-? узнать, есть ли определенный родитель у много-дочернего объекта (ThisModule:findParent(parentName))
	- заменить type(self) на self._type, для оптимизации
	-?NO указывать в какой таблице хранить объекты и их количество
--]]
--[[
	Copyright © Savoshchanka Anton Aleksandrovich, 2015
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

-- переписываем дефолтную функцию
local typeDef = _G.type																															-- reserved; assignment only in this Class
function type(obj)																																-- reserved; assignment only in this Class
	local typeDef = typeDef
	if typeDef(obj) == 'table' then
		if rawget(obj, "_protoType") then
			return  rawget(obj, "_protoType")
		else
			return typeDef(obj)
		end
	else
		return typeDef(obj)
	end
end

local ThisModule = {}																															-- reserved

-- variables static private
-- ...

-- variables static protected, only in Class
ThisModule._protoType = 'class'																													-- reserved; assignment only in this Class; prototype type
ThisModule._myClassName = string.sub(..., string.find(..., "Class"), -1)																		-- reserved; assignment only in this Class
ThisModule._myModuleName = ...																													-- reserved; assignment only in this Class
ThisModule._objects = {}																														-- reserved; assignment only in this Class
ThisModule._objectsCount = 0																													-- reserved; assignment only in this Class

-- variables static public

-- INFO: -NO переименовать в notDestroyed и поменять значение на противоположное; т.к. не удобно писать: if not object.destroyed then
ThisModule.destroyed = false																													-- reserved; readonly!!!; assignment only in this Class; for optimazition, instead of slow method isDestroyed()

-- methods static private
-- ...

-- methods static protected

function ThisModule:_newClass(moduleName)																										-- reserved; assignment only in this Class; use only in assignment of NewClass
    if self.destroyed then self:destroyedError() end
	
	if type(self) == 'class' then
		local class = {}
		
		-- nonstatic variables, methods
		class._protoType = 'class'
		class._myModuleName = moduleName
		class._myClassName = string.sub(moduleName, string.find(moduleName, "classes")+8, -1)
		class._myClassParent = self
		class._objects = {}
		class._objectsCount = 0
		class.destroyed = false
		
		setmetatable(class, self)
		self.__index = self
		return class 		
	else
		error([[table must be 'class' type, not ']]..type(self)..[[' type]])
	end	
end

-- methods static public

function ThisModule:newObject(arg)																												-- reserved; assignment only in this Class; use only outside the Class definition
    if self.destroyed then self:destroyedError() end																							-- reserved
	
	if type(self) == 'class' then
		local object = {}
		
		object._protoType = 'object'																											-- nonstatic variable
		self._objects[object] = object																											-- static variable
		self._objectsCount = self._objectsCount + 1																								-- static variable
		
		setmetatable(object, self)
		self.__index = self
--		print(self._myClassName..' create new object:', object)																					-- debug
		return object 
	else
		error([[table must be 'class' type, not ']]..type(self)..[[' type]])
	end	

end

function ThisModule:getModuleName()																												-- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	return self._myModuleName
end

function ThisModule:getClass()																													-- reserved; assignment only in this Class; use only for object
    if self.destroyed then self:destroyedError() end																							-- reserved
	
	if type(self) == 'object' then
		return getmetatable(self)
	else
		error([[table must be 'object' type, not ']]..type(self)..[[' type]])
	end
end

function ThisModule:getClassParent()																											-- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	return self._myClassParent
end

function ThisModule:getClassName()																												-- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	return self._myClassName
end

function ThisModule:getClassParentName()																										-- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	local parent = self:getClassParent()
	if parent then
		return parent:getClassName()
	else
		return nil
	end
end

function ThisModule:getObjectsCount()																											-- reserved; assignment only in this Class
	if self.destroyed then self:destroyedError() end																							-- reserved
	
	return self._objectsCount
end

--[[
HELP:
	+ удаление из класса (разрушение)
	+ разрушение объекта не гарантирует удаление объекта из памяти, т.к. может существовать внешняя ссылка на объект
	+?NO разрушенный объект нельзя использовать (как с love.physics.body)
		+ с помощью метатаблицы
		+ при любом действии над объектом выдавать ошибку
		+INFO нет, потому что при обращении к существующей переменной (rawget()) в destroyed-объекте нельзя сделать вызов ошибки, т.к. есть только __index и __newindex, а они этого не могут обеспечить	
--]]
function ThisModule:destroy()																													-- reserved; assignment only in this Class; use only for object
    if self.destroyed then self:destroyedError() end																							-- reserved
	
	if type(self) == 'object' then
		local selfClass = self:getClass()
		selfClass._objects[self] = nil
		if selfClass._objectsCount > 0 then
			selfClass._objectsCount = selfClass._objectsCount - 1
		end
		self.destroyed = true
		
		-- разрушенный объект нельзя использовать (этот код не используется); оставить в коментах для информации
--		setmetatable(self, --nil
--		{
--			__index = function() error([[access denied, object is destoyed]]) end,
--			__newindex = function() error([[assignment denied, object is destoyed]]) end
--		}
--		)
	elseif type(self) == 'class' then
		self.destroyed = true
		package.loaded[self._myModuleName] = nil
	else
		error([[table must be 'object' or 'class' type, not ']]..type(self)..[[' type]])
	end
end

--[[
HELP:
	+ оптимизация: этот метод заменен на переменную destroyed
	+ чтобы проверить разрушен ли объект:
		+ if object and object.destroyed then print('object is destroyed') end
		+ или: if type(object) == "object" and object.destroyed then print('object is destroyed') end
		+ или оптимизированный: if object._protoType == "object" and object.destroyed then print('object is destroyed') end
	+ имя isDestroyed, т.к. может существовать внешняя ссылка на объект и он может существовать вне класса
--]]
--function ThisModule:isDestroyed()
--	if self.destroyed then self:destroyedError() end
--
--	if type(self) == 'object' then
--		if self:getClass()._objects[self] then
--			return false
--		else
--			return true
--		end
--	elseif type(self) == 'class' then
--		if package.loaded[self._myModuleName] then
--			return false
--		else
--			return true
--		end		
--	else
--		error([[table must be 'object' type, not ']]..type(self)..[[' type]])
--	end		
--end

function ThisModule:destroyedError()
	error('Attempt to use destroyed '..self._protoType..'.')
end

-- INFO: + не использую эту функцию из-за соображения скорости кода, т.к. функция выполняется медленее условия (if then) а разница в удобности и наглядности небольшая
function ThisModule:errorIfDestroyed()
	if self.destroyed then self:destroyedError() end
end

function ThisModule:destroyAllObjectsFromClass(individualForEachObject)																			-- reserved; assignment only in this Class
    if self.destroyed then self:destroyedError() end																							-- reserved
	
	if self._objectsCount == 0 then return false end
	if type(self) == 'object' then
		self = self:getClass()
	end
	if individualForEachObject then
		for k, object in pairs(self._objects) do
			object:destroy()
		end
	end
	self._objects = {}
	self._objectsCount = 0
end

--[[
HELP: 
	+ использовать только в короткосуществующей ссылке !!!
	+NO возвращает таблицу "только для чтения"
--]]
function ThisModule:getAllObjects()
	-- make this table read-only 
	local proxy = {}
	setmetatable(proxy, 
		{
			__index = self._objects,																											-- this table	
			__newindex = function (t, k, v)
				error("attempt to update a read-only table", 2)
			end
		}
	)
	return self._objects
end

-- rename to newWeakTableObjects
function ThisModule:newObjectsWeakTable(table)																									-- reserved; for objects
	return setmetatable(table or {}, { __mode = "kv" }) 
end

return ThisModule																																-- reserved