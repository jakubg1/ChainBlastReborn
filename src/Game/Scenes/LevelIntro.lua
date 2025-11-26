local Scene = require("src.Game.Scenes.Scene")
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class LevelIntro : Scene
---@overload fun(game):LevelIntro
local LevelIntro = Scene:derive("LevelIntro")

---Creates a Level Intro scene.
---@param game GameMain The main game class this scene belongs to.
function LevelIntro:new(game)
    self.name = "level_intro"
    self.game = game
    self.level = game.sceneManager:getLevel()

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.time = 0
end

---Updates the Level Intro animation.
---@param dt number Time delta in seconds.
function LevelIntro:update(dt)
    self.time = self.time + dt
    if self.time >= 2.5 and not self.level.board then
        self.level:startBoard()
    end
    if self.time >= 3.5 then
        self.game.sceneManager:getLevelHUD():setHUDAlpha(1)
    end
    if self.time >= 7.5 then
        self.game.sceneManager:changeScene({foreground = ""})
    end
end

---Draws the Level Intro animation.
function LevelIntro:draw()
    local natRes = _Game:getNativeResolution()
    local alpha = math.min(self.time, 1)
    if self.time >= 6.5 then
        alpha = math.min(7.5 - self.time, 1)
    end
    self.font:drawWithShadow(string.format("Level %s", self.level.config.name), natRes / 2, Vec2(0.5), nil, alpha)
end

return LevelIntro