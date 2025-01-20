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

    self.SEGMENT_COUNT = Vec2(24, 13)
    self.SEGMENT_SIZE = _Game:getNativeResolution() / self.SEGMENT_COUNT
    self.DELAY_BETWEEN_SEGMENTS = 0.04
    self.SEGMENT_TIME = 0.2
    self.MAX_TIME = (self.SEGMENT_COUNT.x + self.SEGMENT_COUNT.y) * self.DELAY_BETWEEN_SEGMENTS + self.SEGMENT_TIME
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
    love.graphics.setColor(0, 0, 0)
    if self.time == 0 then
        if self.state or self.playing then
            love.graphics.rectangle("fill", 0, 0, _Game:getNativeResolution().x, _Game:getNativeResolution().y)
        end
    else
        for i = 1, self.SEGMENT_COUNT.x do
            for j = 1, self.SEGMENT_COUNT.y do
                local t = math.min(math.max((self.time - (i + j) * self.DELAY_BETWEEN_SEGMENTS) / self.SEGMENT_TIME, 0), 1)
                if not self.state then
                    t = 1 - t
                end
                local p = self.SEGMENT_SIZE * Vec2(i - 1, j - 1) + (self.SEGMENT_SIZE / 2 * (1 - t))
                love.graphics.rectangle("fill", p.x, p.y, self.SEGMENT_SIZE.x * t, self.SEGMENT_SIZE.y * t)
            end
        end
    end
end



return Transition