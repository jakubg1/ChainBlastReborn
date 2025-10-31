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
    self:prepareTilemaps()
    self:prepareNormalmap()

    self.stars = {}
    for i = 1, 1500 do
        --self.stars[i] = LevelStar(true)
    end

    self.visible = true
    self.flashAlpha = nil
    self.flashDecay = nil
end

---Prepares the tilemaps. This should be done in the constructor.
---@private
function LevelBackground:prepareTilemaps()
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
end

---Prepares assets and buffers required to make the normalmapped background work.
---@private
function LevelBackground:prepareNormalmap()
    self.t_diffuse = _Game.resourceManager:getSprite("sprites/normalmap_test/diffuse.json")
    self.t_normal = _Game.resourceManager:getSprite("sprites/normalmap_test/normal.json")
    self.s_pointlight = _Game.resourceManager:getShader("shaders/l_pointlight.glsl")
    self.s_diffuse = _Game.resourceManager:getShader("shaders/l_diffuse.glsl")

    local natRes = _Game:getNativeResolution()
    self.lightmap = love.graphics.newCanvas(natRes.x, natRes.y)
    self.lightStrength = 0.35
    self.lightRange = 300
end

---Generates the lightmap.
---@private
function LevelBackground:generateLightmap()
    local natRes = _Game:getNativeResolution()
    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.lightmap)
    local oldShader = love.graphics.getShader()
    love.graphics.setShader(self.s_pointlight.shader)
    self.s_pointlight.shader:send("x", _MousePos.x)
    self.s_pointlight.shader:send("y", _MousePos.y)
    self.s_pointlight.shader:send("strength", self.lightStrength)
    self.s_pointlight.shader:send("range", self.lightRange)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    love.graphics.setShader(oldShader)
    -- VERY DIRTY HACK!!!! We are doing the same thing Game.lua does when setting the main display canvas.
    -- This should be handled by a canvas stack instead!!!
    love.graphics.setCanvas({oldCanvas, stencil = true})
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
    --for i, star in ipairs(self.stars) do
        --star:draw()
    --end
    -- Tilemaps
    --for i = 3, 1, -1 do
        --self.maps[i]:draw(Vec2(-8))
    --end
    -- Normalmapped tiled background
    self:drawNormalmap()
    -- Flash
    if self.flashAlpha then
        love.graphics.setColor(1, 1, 1, self.flashAlpha * _Game.runtimeManager.options:getSetting("screenFlashStrength"))
        love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    end
end

---Draws the normalmapped background.
---@private
function LevelBackground:drawNormalmap()
    -- Generate the lightmap.
    self:generateLightmap()

    -- Set the shader and draw the diffuse.
    local oldShader = love.graphics.getShader()
    love.graphics.setShader(self.s_diffuse.shader)
    self.s_diffuse.shader:send("lightmap", self.lightmap)
    self.s_diffuse.shader:send("lightmap_size", {self.lightmap:getDimensions()})
    self.s_diffuse.shader:send("normal", self.t_normal.config.image.img)
    for x = 0, 19 do
        for y = 0, 11 do
            self.t_diffuse:draw(Vec2(x * 16, y * 16))
        end
    end
    -- Restore the previous shader.
    -- TODO: Shader and canvas stacks should be added to OpenSMCE and handled by the Display class.
    love.graphics.setShader(oldShader)
end

return LevelBackground