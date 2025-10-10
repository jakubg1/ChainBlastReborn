local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class LevelIntro
---@overload fun(game):LevelIntro
local LevelIntro = class:derive("LevelIntro")

---Creates a Level Intro scene.
---@param game GameMain The main game class this scene belongs to.
function LevelIntro:new(game)
    self.name = "level_intro"
    self.game = game
    self.level = game.sceneManager:getLevel()

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.time = 0
end

---Returns whether this scene should accept any input.
---@return boolean
function LevelIntro:isActive()
    return false
end

---Updates the Level Intro animation.
---@param dt number Time delta in seconds.
function LevelIntro:update(dt)
    self.time = self.time + dt
    if self.time >= 2.5 and not self.level.board then
        self.level:startBoard()
    end
    if self.time >= 3.5 then
        self.level.ui:setHUDAlpha(1)
    end
    if self.time >= 7.5 then
        self.game.sceneManager:changeScene("level", true, true)
    end
end

---Draws the Level Intro animation.
function LevelIntro:draw()
    local natRes = _Game:getNativeResolution()
    local alpha = math.min(self.time, 1)
    if self.time >= 6.5 then
        alpha = math.min(7.5 - self.time, 1)
    end
    if self.game.player.lives == 1 then
        self.font:drawWithShadow(string.format("Level %s", self.level.data.name), natRes / 2 + Vec2(0, -10), Vec2(0.5), nil, alpha)
        alpha = math.max(math.min(self.time - 1.5, 1))
        if self.time >= 6.5 then
            alpha = math.min(7.5 - self.time, 1)
        end
        self.font:drawWithShadow("This is your last chance!", natRes / 2, Vec2(0.5), Color(1, 0, 0), alpha)
        self.font:drawWithShadow("Don't screw up!", natRes / 2 + Vec2(0, 10), Vec2(0.5), Color(1, 0, 0), alpha)
    else
        self.font:drawWithShadow(string.format("Level %s", self.level.data.name), natRes / 2, Vec2(0.5), nil, alpha)
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function LevelIntro:mousepressed(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function LevelIntro:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function LevelIntro:keypressed(key)
end

return LevelIntro