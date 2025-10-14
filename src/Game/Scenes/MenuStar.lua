local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class MenuStar
---@overload fun(t):MenuStar
local MenuStar = class:derive("MenuStar")

---Creates a new Menu Star.
---@param t number? If specified, the star will start off from that particular moment of lifetime: `0` (default) freshly spawned next to the right edge of the screen, `1` about to despawn on the left edge.
function MenuStar:new(t)
    t = t or 0

    self.maxTime = 4 + love.math.random() * 12
    self.time = self.maxTime * t

    -- Y position: The star will move 120 pixels down during its course.
    -- Therefore, the total amount of lines the star can travel through is 180 + 120 = 300.
    self.startPos = Vec2(330, love.math.random() * 300 - 120)
    self.endPos = Vec2(-10, self.startPos.y + 100)
    self.pos = self.startPos * (1 - t) + self.endPos * t

    --local temperature = math.random() ^ 4 * 3
    local temperature = math.random() + 2
    local r, g, b
    if temperature < 1 then
        r, g, b = 1, temperature, 0
    elseif temperature < 2 then
        r, g, b = 1, 1, temperature - 1
    elseif temperature < 3 then
        r, g, b = 3 - temperature, 3 - temperature, 1
    end
    local brightness = love.math.randomNormal(0.15, 0.6)
    self.color = Color(r + (1 - r) * brightness, g + (1 - g) * brightness, b + (1 - b) * brightness)

    self.alpha = love.math.randomNormal(0.1, 0.4) + (16 - self.maxTime) * 0.08
    self.size = math.floor(math.random() ^ 5 * 3) + 1
    self.starSprites = {
        _Game.resourceManager:getSprite("sprites/star1.json"),
        _Game.resourceManager:getSprite("sprites/star2.json"),
        _Game.resourceManager:getSprite("sprites/star3.json")
    }
    self.sprite = self.starSprites[self.size]

    self.delQueue = false
end

---Updates the Menu Star.
---@param dt number Time delta in seconds.
function MenuStar:update(dt)
    self.time = self.time + dt
    local t = self.time / self.maxTime
    self.pos = self.startPos * (1 - t) + self.endPos * t
    if t >= 1 then
        self.delQueue = true
    end
end

---Draws the Menu Star on the screen.
function MenuStar:draw()
    self.sprite:draw(self.pos, nil, nil, nil, nil, self.color, self.alpha)
end

return MenuStar