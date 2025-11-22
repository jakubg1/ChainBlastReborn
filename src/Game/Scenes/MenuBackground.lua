local class = require "com.class"
local MenuStar = require("src.Game.Scenes.MenuStar")

---@class MenuBackground
---@overload fun(game):MenuBackground
local MenuBackground = class:derive("MenuBackground")

---Constructs a Menu Background scene.
---@param game GameMain The main game class instance this Menu belongs to.
function MenuBackground:new(game)
    self.name = "menu_background"
    self.game = game

    self.stars = {}
    -- Spawn initial stars.
    for i = 1, 150 do
        table.insert(self.stars, MenuStar(math.random()))
    end
end

---Updates the Menu Background.
---@param dt number Time delta in seconds.
function MenuBackground:update(dt)
    for i, star in ipairs(self.stars) do
        star:update(dt)
        if star.delQueue then
            self.stars[i] = MenuStar()
        end
    end
end

---Draws the Menu Background.
function MenuBackground:draw()
    local natRes = _Game:getNativeResolution()
    -- Background
    love.graphics.setColor(0.06, 0.02, 0.05)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    -- Stars
    if not _Game.runtimeManager.options:getSetting("reducedParticles") then
        for i, star in ipairs(self.stars) do
            star:draw()
        end
    end
end

return MenuBackground