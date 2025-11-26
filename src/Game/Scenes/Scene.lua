local class = require "com.class"

---@class Scene : Class
---@overload fun(game):Scene
local Scene = class:derive("Scene")

function Scene:new(game)
    self.game = game
end

---Updates the Scene.
---@param dt number Time delta in seconds.
function Scene:update(dt)
end

---Draws the Scene on the screen.
function Scene:draw()
end

---Callback from `main.lua`.
---Returns `true` if the input has been consumed and should not be propagated to layers behind.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
---@return boolean
function Scene:mousepressed(x, y, button)
    return false
end

---Callback from `main.lua`.
---Returns `true` if the input has been consumed and should not be propagated to layers behind.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
---@return boolean
function Scene:mousereleased(x, y, button)
    return false
end

---Callback from `main.lua`.
---Returns `true` if the input has been consumed and should not be propagated to layers behind.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
---@return boolean
function Scene:mousemoved(x, y, dx, dy)
    return false
end

---Callback from `main.lua`.
---Returns `true` if the input has been consumed and should not be propagated to layers behind.
---@param x integer X movement of the mouse wheel.
---@param y integer Y movement of the mouse wheel.
---@return boolean
function Scene:wheelmoved(x, y)
    return false
end

---Callback from `main.lua`.
---Returns `true` if the input has been consumed and should not be propagated to layers behind.
---@param key string The pressed key code.
---@return boolean
function Scene:keypressed(key)
    return false
end

return Scene