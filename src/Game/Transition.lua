local class = require "com.class"

---@class Transition
---@overload fun():Transition
local Transition = class:derive("Transition")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")

---Constructs a Transition.
function Transition:new()
    self.time = nil
    self.state = false -- `false`: hidden/fading out, `true`: shown/fading in

    self.SPEED = 700
    self.MAX_TIME = 1.1

    self.shader = _Game.resourceManager:getShader("shaders/transition_dither.glsl")
end

---Starts the show animation (transition to dark).
function Transition:startFadeIn()
    self.time = 0
    self.state = true
end

---Starts the hide animation (transition from dark).
function Transition:startFadeOut()
    self.time = 0
    self.state = false
end

---Forcibly skips the show animation.
function Transition:skipIn()
    self.time = nil
    self.state = true
end

---Forcibly skips the hide animation.
function Transition:skipOut()
    self.time = nil
    self.state = false
end

---Returns `true` if the transition is currently playing.
---@return boolean
function Transition:isPlaying()
    return self.time ~= nil
end

---Returns `true` if the transition is currently fading in.
---@return boolean
function Transition:isFadingIn()
    return self.time and self.state
end

---Returns `true` if the transition is currently fading out.
---@return boolean
function Transition:isFadingOut()
    return self.time and not self.state
end

---Returns `true` if the transition is currently blanking the entire screen.
---@return boolean
function Transition:isShown()
    return not self.time and self.state
end

---Returns `true` if the transition is currently hidden. This is the default state.
---@return boolean
function Transition:isHidden()
    return not self.time and not self.state
end

---Updates the Transition.
---@param dt number Time delta, in seconds.
function Transition:update(dt)
    if self.time then
        self.time = self.time + dt
        if self.time >= self.MAX_TIME then
            self.time = nil
        end
    end
end

---Draws the Transition on the screen.
function Transition:draw()
    local natRes = _Game:getNativeResolution()

    if self:isShown() then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    elseif not self:isHidden() then
        local oldShader = love.graphics.getShader()
        love.graphics.setShader(self.shader.shader)
        self.shader.shader:send("t", self.time * self.SPEED)
        self.shader.shader:send("fadein", self.state)
        love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
        love.graphics.setShader(oldShader)
    end
end

return Transition