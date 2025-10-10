local class = require "com.class"

---@class SceneLevel
---@overload fun(game):SceneLevel
local SceneLevel = class:derive("SceneLevel")

---Constructs a Level Scene. This is an empty scene, which is active during gameplay.
---The actual level alongside with its HUD is handled separately. Check the Level class and the Scene Manager.
---@param game GameMain The main game class instance this Menu belongs to.
function SceneLevel:new(game)
    self.name = "level"
    self.game = game
end

---Returns whether this scene should accept any input.
---@return boolean
function SceneLevel:isActive()
    return false
end

---Updates the intro.
---@param dt number Time delta in seconds.
function SceneLevel:update(dt)
end

---Draws the intro.
function SceneLevel:draw()
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function SceneLevel:mousepressed(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function SceneLevel:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function SceneLevel:keypressed(key)
end

return SceneLevel