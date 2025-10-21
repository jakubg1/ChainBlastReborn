local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class LevelFailed
---@overload fun(game):LevelFailed
local LevelFailed = class:derive("LevelFailed")

---Creates a Level Failed scene.
---@param game GameMain The main game class this scene belongs to.
function LevelFailed:new(game)
    self.name = "level_failed"
    self.game = game
    self.level = game.sceneManager:getLevel()

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.time = 1
    self.boardNuked = false
end

---Returns whether this scene should accept any input.
---@return boolean
function LevelFailed:isActive()
    return true
end

---Updates the Level Failed animation.
---@param dt number Time delta in seconds.
function LevelFailed:update(dt)
    if not self.time then
        return
    end
    self.time = self.time + dt
    if self.time >= 1 and not self.boardNuked then
        self.boardNuked = true
        self.level:nukeBoard()
    elseif self.time >= 12.5 then
        self.time = nil
        self.level:finishBoard()
    end
end

---Draws the Level Failed animation.
function LevelFailed:draw()
    if not self.time then
        return
    end
    local natRes = _Game:getNativeResolution()
    local alpha = math.max(math.min(self.time - 1.5, 0.5), 0)
    if self.time >= 11 then
        alpha = (12 - self.time) / 2
    end
    _DrawFillRect(Vec2(), natRes, Color(0, 0, 0), alpha)
    local textAlpha = math.max(math.min((self.time - 2) / 2, 1), 0)
    if self.time >= 11 then
        textAlpha = math.min(12 - self.time, 1)
    end
    local text = "Level Failed!"
    self.font:drawWithShadow(text, natRes / 2, Vec2(0.5), Color(1, 0, 0), textAlpha)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function LevelFailed:mousepressed(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function LevelFailed:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function LevelFailed:keypressed(key)
end

return LevelFailed