local class = require "com.class"
local MenuStar = require("src.Game.Scenes.MenuStar")

---@class Menu
---@overload fun(game):Menu
local Menu = class:derive("Menu")

---Constructs a Menu scene.
---@param game GameMain The main game class instance this Menu belongs to.
function Menu:new(game)
    self.name = "menu"
    self.game = game

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.stars = {}
    -- Spawn initial stars.
    for i = 1, 150 do
        table.insert(self.stars, MenuStar(math.random()))
    end
end

---Returns whether this scene should accept any input.
---@return boolean
function Menu:isActive()
    return true
end

---Updates the Menu.
---@param dt number Time delta in seconds.
function Menu:update(dt)
    for i, star in ipairs(self.stars) do
        star:update(dt)
        if star.delQueue then
            self.stars[i] = MenuStar()
        end
    end
end

---Draws the Menu.
function Menu:draw()
    local natRes = _Game:getNativeResolution()
    love.graphics.setColor(0.06, 0.02, 0.05)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    --self.font:draw("Welcome to the Main Menu!", Vec2(100, 100))
    --self.font:draw("Click to start", Vec2(100, 110))

    for i, star in ipairs(self.stars) do
        star:draw()
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Menu:mousepressed(x, y, button)
    if button == 1 then
        self.game.sceneManager:startLevel()
        self.game.sceneManager:changeScene("level_intro")
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