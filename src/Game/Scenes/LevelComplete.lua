local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class LevelComplete
---@overload fun(game):LevelComplete
local LevelComplete = class:derive("LevelComplete")

---Creates a Level Complete scene.
---@param game GameMain The main game class this scene belongs to.
function LevelComplete:new(game)
    self.name = "level_complete"
    self.game = game
    self.level = game.sceneManager:getLevel()

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.time = 0
end

---Returns whether this scene should accept any input.
---@return boolean
function LevelComplete:isActive()
    return true
end

---Updates the Level Complete animation.
---@param dt number Time delta in seconds.
function LevelComplete:update(dt)
    if not self.time then
        return
    end
    self.time = self.time + dt
    if self.time >= 5 then
        self.time = nil
        self.level:finishBoard()
    end
end

---Draws the Level Complete animation.
function LevelComplete:draw()
    if not self.time then
        return
    end
    local natRes = _Game:getNativeResolution()
    local alpha = math.min(self.time, 0.5)
    if self.time >= 4.5 then
        alpha = 5 - self.time
    end
    _DrawFillRect(Vec2(), natRes, Color(0, 0, 0), alpha)
    local textPos = natRes / 2 + Vec2(math.max(1 - self.time / 0.5, 0) * 150, 0)
    local textAlpha = math.min(5 - self.time, 1)
    self.font:drawWithShadow("Level Complete!", textPos, Vec2(0.5), Color(0, 1, 0), textAlpha)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function LevelComplete:mousepressed(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function LevelComplete:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function LevelComplete:keypressed(key)
end

return LevelComplete