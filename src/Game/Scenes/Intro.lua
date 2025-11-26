local Scene = require("src.Game.Scenes.Scene")

---@class Intro : Scene
---@overload fun(game):Intro
local Intro = Scene:derive("Intro")

---Creates an Intro Scene, which shows up at startup of the game after the loading screen.
---@param game GameMain The main game class instance this Menu belongs to.
function Intro:new(game)
    self.name = "intro"
    self.game = game
end

---Updates the intro.
---@param dt number Time delta in seconds.
function Intro:update(dt)
end

---Draws the intro.
function Intro:draw()
    local natRes = _Game:getNativeResolution()
    love.graphics.setColor(0.5, 0, 0)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Intro:mousepressed(x, y, button)
    if button == 1 then
        self.game.sceneManager:changeScene({foreground = "menu_main"}, true, true)
    end
end

return Intro