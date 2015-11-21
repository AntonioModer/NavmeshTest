--[[
HELP:
	+ config - это состояние игры при загрузке
	+NO game.version убрать отсюда, чтобы игрок не мог изменить значение
		+INFO игрок не будет иметь доступ к conf.lua
TODO:
	-? config.controls перенести в input.lua
--]]

config = {}
function love.conf(argC)
	argC.identity = "clipperTest"																														-- The name of the save directory (string)
	argC.version = "0.9.2"																														-- The LÖVE version this game was made for
	argC.console = true																															-- Windows only

	config.gameVersion = "0.0.1"
	argC.window.title = [[navMeshTest, v]] .. config.gameVersion .. " (" .. os.date("%Y.%m.%d-%H.%M.%S") .. [[); Copyright © Savoshchanka Anton, 2015 (twitter.com/AntonioModer); LÖVE 2D-framework (love2d.org)]]
	argC.window.icon = nil																														-- Filepath to an image to use as the window's icon (string)
	argC.window.width = 800
	argC.window.height = 600
	argC.window.borderless = false																												-- Remove all border visuals from the window
	argC.window.resizable = false																												-- Let the window be user-resizable
	argC.window.minwidth = 1																													-- Minimum window width if the window is resizable
	argC.window.minheight = 1																													-- Minimum window height if the window is resizable
	argC.window.fullscreen = false
	argC.window.fullscreentype = "normal"																										-- "desktop" or "normal"
	argC.window.vsync = false																													-- Enable vertical sync
	argC.window.fsaa = 0																														-- The number of samples to use with multi-sampled antialiasing
	argC.window.display = 1																														-- Index of the monitor to show the window in
    argC.window.highdpi = false           																										-- Enable high-dpi mode for the window on a Retina display (boolean); default = false
    argC.window.srgb = false              																										-- Enable sRGB gamma correction when drawing to the screen (boolean); default = false
    argC.window.x = nil
    argC.window.y = nil

	argC.modules.audio = true
	argC.modules.event = true
	argC.modules.graphics = true
	argC.modules.image = true
	argC.modules.joystick = true
	argC.modules.keyboard = true
	argC.modules.math = true
	argC.modules.mouse = true
	argC.modules.physics = true
	argC.modules.sound = true
	argC.modules.system = true
	argC.modules.timer = true
	argC.modules.window = true

	config.window = {}
	config.window.width = argC.window.width
	config.window.height = argC.window.height
end
