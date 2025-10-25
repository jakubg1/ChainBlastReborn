local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")

---Normalmap test screen in the Menu scene.
---@class NormalmapTest
---@overload fun(scene):NormalmapTest
local NormalmapTest = class:derive("NormalmapTest")

---Constructs a new normalmap test screen.
---@param scene Menu The owner of this screen.
function NormalmapTest:new(scene)
    self.scene = scene

    -- Normalmap test
    self.t_diffuse = _Game.resourceManager:getSprite("sprites/normalmap_test/diffuse.json")
    self.t_normal = _Game.resourceManager:getSprite("sprites/normalmap_test/normal.json")
    self.s_pointlight = _Game.resourceManager:getShader("shaders/l_pointlight.glsl")
    self.s_diffuse = _Game.resourceManager:getShader("shaders/l_diffuse.glsl")

    local natRes = _Game:getNativeResolution()
    self.lightmap = love.graphics.newCanvas(natRes.x, natRes.y)
    self.lightStrength = 0.5
    self.lightRange = 20
end

---Updates the normalmap test screen.
---@param dt number Time delta in seconds.
function NormalmapTest:update(dt)
end

---Draws the normalmap test on the screen.
function NormalmapTest:draw()
    -- Generate the lightmap.
    self:drawLightmap()

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
    love.graphics.setShader(oldShader)
end

---Draws the lightmap.
function NormalmapTest:drawLightmap()
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
    love.graphics.setCanvas(oldCanvas)

    -- Peek the lightmap
    --love.graphics.setColor(1, 1, 1)
    --love.graphics.draw(self.lightmap, 0, 0)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function NormalmapTest:mousepressed(x, y, button)
    if button == 1 then
        self.scene:goToMain()
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function NormalmapTest:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param x integer X movement of the mouse wheel.
---@param y integer Y movement of the mouse wheel.
function NormalmapTest:wheelmoved(x, y)
    if love.keyboard.isDown("lctrl", "rctrl") then
        self.lightRange = self.lightRange + y * 2
    else
        self.lightStrength = self.lightStrength + y * 0.1
    end
end

return NormalmapTest