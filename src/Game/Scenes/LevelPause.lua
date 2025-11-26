local Scene = require("src.Game.Scenes.Scene")
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class LevelPause : Scene
---@overload fun(game):LevelPause
local LevelPause = Scene:derive("LevelPause")

---Constructs a Level Pause Scene.
---The actual level alongside with its HUD is handled separately. Check the Scene Manager.
---@param game GameMain The main game class instance this Menu belongs to.
function LevelPause:new(game)
    self.name = "level_pause"
    self.game = game

    self.animation = 1
	self.font = _Game.resourceManager:getFont("fonts/standard.json")
end

---Updates the pause screen.
---@param dt number Time delta in seconds.
function LevelPause:update(dt)
end

---Draws the pause screen.
function LevelPause:draw()
    local natRes = _Game:getNativeResolution()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    self.font:drawWithShadow("Game Paused", natRes / 2 + Vec2(0, -5), Vec2(0.5), Color(1, 1, 0), self.animation)
    local alpha = 0.5 + (_TotalTime % 2) * 0.5
    if _TotalTime % 2 > 1 then
        alpha = 1 + (1 - _TotalTime % 2) * 0.5
    end
    self.font:drawWithShadow("Click to continue", natRes / 2 + Vec2(0, 5), Vec2(0.5), nil, self.animation * alpha)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function LevelPause:mousepressed(x, y, button)
    if button == 1 then
        self.game.sceneManager:getLevel():togglePause()
    end
end

return LevelPause