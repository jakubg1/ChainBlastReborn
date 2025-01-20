local class = require "com.class"

---@class LevelStar
---@overload fun(primary):LevelStar
local LevelStar = class:derive("LevelStar")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



---Constructs a Level Star. It is a star that appears in the level background, or any other object.
---@param primary boolean? If set, this star will start at any position on the screen. Set only when initializing the star container.
function LevelStar:new(primary)
    local natRes = _Game:getNativeResolution()

    if primary then
        self.pos = Vec2(math.random() * natRes.x, math.random() * natRes.y)
    else
        self.pos = Vec2(natRes.x, math.random() * natRes.y)
    end
    self.depth = math.random() * 10 + 1
    self.brightness = math.random()
    self.pulseAmplitude = math.random() * math.random()
    self.pulseFrequency = math.random() * math.random() * 0.3
    self.pulseOffset = math.random()

    self.sprite = _Game.resourceManager:getSprite("sprites/spark.json")

    self.delQueue = false
end



---Updates the Level Star. Its position is updated, and `delQueue` set to `true` if the star has exited the screen.
---@param dt number Time delta in seconds.
function LevelStar:update(dt)
    self.pos = self.pos + Vec2(-10 / self.depth * dt, 0)
    if self.pos.x < 0 then
        self.delQueue = true
    end
end



---Draws the Level Star on the screen.
function LevelStar:draw()
    local pulseT = (_TotalTime * self.pulseFrequency + self.pulseOffset) % 1
    -- Peak at pulseT = 0.5, sine transition before and after with the sharp edge at the peak.
    local pulseValue = (1 - math.abs(math.cos(pulseT * math.pi))) * self.pulseAmplitude
    local color = Color((self.brightness + 4 * pulseValue) / 5, (self.brightness + 2 * pulseValue) / 3, 1)
    self.sprite:draw(self.pos, Vec2(1), 1, 1, nil, color, 1 / self.depth + (1 - 1 / self.depth) * pulseValue)
end



return LevelStar