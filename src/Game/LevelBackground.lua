local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Tilemap = require("src.Game.Tilemap")
local LevelStar = require("src.Game.LevelStar")

---@class LevelBackground
---@overload fun(level):LevelBackground
local LevelBackground = class:derive("LevelBackground")

---Creates a Level Background.
---@param level Level The level which owns this background.
function LevelBackground:new(level)
    self.level = level

    self.sprites = {
        _Game.resourceManager:getSprite("sprites/background_1.json"),
        _Game.resourceManager:getSprite("sprites/background_2.json"),
        _Game.resourceManager:getSprite("sprites/background_3.json"),
    }
    local natRes = _Game:getNativeResolution()
    self.maps = {
        Tilemap(self.sprites[1], math.ceil(natRes.x / 16) + 2, math.ceil(natRes.y / 16) + 2),
        Tilemap(self.sprites[2], 50, 30),
        Tilemap(self.sprites[3], 50, 30)
    }
    for i = 1, 3 do
        local map = self.maps[i]
        for x = 1, map:getWidth() do
            for y = 1, map:getHeight() do
                map:setCell(x, y, math.random() < 0.5 or y > 10)
            end
        end
    end

    self.stars = {}
    for i = 1, 1500 do
        --self.stars[i] = LevelStar(true)
    end

    self.visible = true
    self.flashAlpha = nil
    self.flashDecay = nil
end

---Flashes the background white.
---@param intensity number Flash intensity, from 0 to 1.
---@param duration number Duration of the flash, in seconds.
function LevelBackground:flash(intensity, duration)
    self.flashAlpha = intensity
    self.flashDecay = 1 / duration * intensity
end

---Sets whether the background should be visible.
---@param visible boolean `true` if the background should be visible, `false` if not.
function LevelBackground:setVisible(visible)
    self.visible = visible
end

---Updates the level background.
---@param dt number Time delta in seconds.
function LevelBackground:update(dt)
    for i, star in ipairs(self.stars) do
        star:update(dt)
        if star.delQueue then
            self.stars[i] = LevelStar()
        end
    end

    -- Update the flash.
    if self.flashAlpha then
        self.flashAlpha = self.flashAlpha - self.flashDecay * dt
        if self.flashAlpha <= 0 then
            self.flashAlpha = nil
            self.flashDecay = nil
        end
    end
end

---Draws the level background.
function LevelBackground:draw()
    if not self.visible then
        return
    end
    -- Background
    local natRes = _Game:getNativeResolution()
    love.graphics.setColor(0.05, 0.08, 0.13)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    -- Stars
    for i, star in ipairs(self.stars) do
        star:draw()
    end
    -- Tilemaps
    for i = 3, 1, -1 do
        self.maps[i]:draw(Vec2(-8))
    end
    -- Flash
    if self.flashAlpha then
        love.graphics.setColor(1, 1, 1, self.flashAlpha * _Game.runtimeManager.options:getSetting("screenFlashStrength"))
        love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    end
end

return LevelBackground