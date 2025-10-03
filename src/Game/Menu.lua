local class = require "com.class"

---@class Menu
---@overload fun(game):Menu
local Menu = class:derive("Menu")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---Constructs a Menu.
---@param game GameMain The main game class instance this Menu belongs to.
function Menu:new(game)
    self.game = game
end

---Updates the Menu.
---@param dt number Time delta in seconds.
function Menu:update(dt)
    
end

---Draws the Menu.
function Menu:draw()
    _DrawFillRect(Vec2(), Vec2(320, 180), Color(0.5, 0.5, 0.5))
    self.game.font:draw("Welcome to the Main Menu!", Vec2(100, 100))
    self.game.font:draw("Click to start", Vec2(100, 110))
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Menu:mousepressed(x, y, button)
    if button == 1 then
        self.game:changeScene("level")
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function Menu:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function Menu:keypressed(key)
end

return Menu