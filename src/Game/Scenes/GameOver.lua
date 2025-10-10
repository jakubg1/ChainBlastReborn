local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class GameOver
---@overload fun(game):GameOver
local GameOver = class:derive("GameOver")

---Creates a Game Over scene.
---@param game GameMain The main game class this scene belongs to.
function GameOver:new(game)
    self.name = "game_over"
    self.game = game
    self.level = game.sceneManager:getLevel()

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.time = 0
    self.heSaid = false
end

---Returns whether this scene should accept any input.
---@return boolean
function GameOver:isActive()
    return true
end

---Updates the Game Over animation.
---@param dt number Time delta in seconds.
function GameOver:update(dt)
    self.time = self.time + dt
    if not self.heSaid and self.time >= 5 then
        _Game:playSound("sound_events/game_over.json")
        self.heSaid = true
    end
    if self.time >= 19 then
        self.game.sceneManager:changeScene("level_results", true, true)
    end
end

---Draws the Game Over animation.
function GameOver:draw()
    local natRes = _Game:getNativeResolution()
    if self.time > 5 then
        local alpha = math.min((17 - self.time) / 4, 1)
        self.font:draw("GAME", natRes / 2, Vec2(0.5, 1), Color(1, 0, 0), alpha, 5)
        self.font:draw("OVER", natRes / 2, Vec2(0.5, 0), Color(1, 0, 0), alpha, 5)
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function GameOver:mousepressed(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function GameOver:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function GameOver:keypressed(key)
end

return GameOver