local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")

---@class Shaker
---@overload fun():Shaker
local Shaker = class:derive("Shaker")

---Constructs a Shaker.
---Shaker is an entity which can be shaked by any number of shakes, and returns the result of shaking as a single vector.
function Shaker:new()
	self.shakes = {}
    self.cachedOffset = nil
end

---Shakes the Shaker. A few shakes can be active at once.
---@param power number The power of the shake, in pixels.
---@param direction number? The direction of the shake, in radians. 0 is left. If omitted, a random angle will be chosen for this shake, but horizontal direction will be preferred.
---@param frequency number The frequency of the shake, in 1/s.
---@param duration number How long will the shake persist until it is removed, in seconds.
function Shaker:shake(power, direction, frequency, duration)
	if not direction then
		-- Prefer horizontal shake because it is said that people tolerate it better
		-- (bias towards 0 or math.pi)
		direction = math.random() < 0.5 and 0 or math.pi
		direction = direction + love.math.randomNormal(math.pi / 8, 0)
	end
	table.insert(self.shakes, {
		vector = Vec2(power, 0):rotate(direction),
		frequency = frequency,
		maxTime = duration,
		time = 0
	})
end

---Returns the current offset of the Shaker. If no shakes are active, returns `(0, 0)`.
---This function is safe against multiple calls; the calculated value will be cached until next frame.
---@return Vector2
function Shaker:getOffset()
    if self.cachedOffset then
        return self.cachedOffset
    end
	local total = Vec2()
	for i, shake in ipairs(self.shakes) do
		-- Count shake power.
		local decayFactor = _Utils.map(shake.time, 0, shake.maxTime, 1, 0)
		-- The following is a quadratic falloff, personally I feel like it is much more headache-inducing
		--local decayFactor = 1 - _Utils.map(shake.time, 0, shake.maxTime, 0, 1) ^ 2
		local t = math.sin((shake.time * shake.frequency) * math.pi * 2) * decayFactor
		total = total + shake.vector * t
	end
	-- Round the final value.
	total = (total + 0.5):floor()
    -- Cache the final value and return it.
    self.cachedOffset = total
    return total
end

---Updates the Shaker.
---@param dt number Time delta in seconds.
function Shaker:update(dt)
    self.cachedOffset = nil
	for i, shake in ipairs(self.shakes) do
		shake.time = shake.time + dt
		if shake.time >= shake.maxTime then
			shake.delQueue = true
		end
	end
	-- Remove all finished shakes.
	_Utils.removeDeadObjects(self.shakes)
end

return Shaker