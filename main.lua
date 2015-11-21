function love.load()
	require("navMeshTest")
end

function love.mousepressed(x, y, button)
	require("navMeshTest"):mousePressed(x, y, button)
end

function love.update(dt)
	require("navMeshTest"):update(dt)
end

function love.draw()
	require("navMeshTest"):draw()
end