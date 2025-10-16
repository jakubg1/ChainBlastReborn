local class = require "com.class"
local LevelStar = require("src.Game.LevelStar")

---@class LevelBackground
---@overload fun(level):LevelBackground
local LevelBackground = class:derive("LevelBackground")

---Creates a Level Background.
---@param level Level The level which owns this background.
function LevelBackground:new(level)
    self.level = level

    self.stars = {}
    for i = 1, 1500 do
        --self.stars[i] = LevelStar(true)
    end

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
    local natRes = _Game:getNativeResolution()
    love.graphics.setColor(0.05, 0.08, 0.13)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)

    for i, star in ipairs(self.stars) do
        star:draw()
    end

    -- Draw the flash.
    if self.flashAlpha then
        love.graphics.setColor(1, 1, 1, self.flashAlpha * _Game.runtimeManager.options:getSetting("screenFlashStrength"))
        love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    end
end

return LevelBackground