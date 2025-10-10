local class = require "com.class"

---@class Intro
---@overload fun(game):Intro
local Intro = class:derive("Intro")

---Creates an Intro Scene, which shows up at startup of the game after the loading screen.
---@param game GameMain The main game class instance this Menu belongs to.
function Intro:new(game)
    self.name = "intro"
    self.game = game
end

---Returns whether this scene should accept any input.
---@return boolean
function Intro:isActive()
    return true
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
        self.game.sceneManager:changeScene("menu")
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function Intro:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function Intro:keypressed(key)
end

return Intro