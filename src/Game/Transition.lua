local class = require "com.class"

---@class Transition
---@overload fun():Transition
local Transition = class:derive("Transition")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")

---Constructs a Transition.
function Transition:new()
    self.time = 0
    self.playing = false
    self.state = false

    self.SPEED = 700
    self.MAX_TIME = 1.2

    self.shader = _Game.resourceManager:getShader("shaders/transition_dither.glsl")
end

---Starts the show animation (transition to dark).
function Transition:show()
    self.time = 0
    self.state = true
    self.playing = true
end

---Starts the hide animation (transition from dark).
function Transition:hide()
    self.time = 0
    self.state = false
    self.playing = true
end

---Forcibly skips the hide animation.
function Transition:clear()
    self.time = 0
    self.state = false
    self.playing = false
end

---Updates the Transition.
---@param dt number Time delta, in seconds.
function Transition:update(dt)
    if self.playing then
        if self.time < self.MAX_TIME then
            self.time = self.time + dt
            if self.time >= self.MAX_TIME then
                self.time = 0
                self.playing = false
            end
        end
    end
end

---Draws the Transition on the screen.
function Transition:draw()
    local natRes = _Game:getNativeResolution()

    if self.time == 0 then
        if self.state or self.playing then
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
        end
    else
        local oldShader = love.graphics.getShader()
        love.graphics.setShader(self.shader.shader)
        self.shader.shader:send("t", self.time * self.SPEED)
        self.shader.shader:send("fadein", self.state)
        love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
        love.graphics.setShader(oldShader)
    end
end

return Transition