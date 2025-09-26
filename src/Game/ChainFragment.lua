local class = require "com.class"

---@class ChainFragment
---@overload fun(game, pos, type, sprite, state):ChainFragment
local ChainFragment = class:derive("ChainFragment")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")

---Constructs a new Chain Fragment.
---@param game GameMain The game this fragment belongs to.
---@param pos Vector2 The initial position of the fragment.
---@param type string The type of the fragment. TODO: Replace with data.
---@param sprite Sprite The split sprite of the fragment.
---@param state integer The state index of the sprite to display this Chain Fragment as.
function ChainFragment:new(game, pos, type, sprite, state)
    self.game = game
    self.pos = pos
    self.type = type
    self.sprite = sprite
    self.state = state

    self.time = 0
    self.speed = Vec2(love.math.randomNormal(40, 80), 0):rotate(love.math.random() * math.pi * 2) + Vec2(0, -60)
    self.acceleration = Vec2(0, 200)
    self.angle = 0--love.math.random() * math.pi * 2
    self.angleSpeed = (love.math.random() - 0.5) * math.pi
    self.alpha = love.math.random() + 2

    self.delQueue = false
end

---Updates the fragment.
---@param dt number Time delta in seconds.
function ChainFragment:update(dt)
    self.time = self.time + dt

    self.speed = self.speed + self.acceleration * dt
    self.pos = self.pos + self.speed * dt
    self.angle = self.angle + self.angleSpeed * dt
    self.alpha = self.alpha - 2 * dt

    if self.pos.y > _Game:getNativeResolution().y or self.alpha <= 0 then
        self.delQueue = true
    end
end

---Draws the fragment on the screen.
function ChainFragment:draw()
    self.sprite:drawWithShadow(self.pos, Vec2(0.5), self.state, 1, self.angle, nil, math.min(self.alpha, 1), nil, nil, 0.6)
end

return ChainFragment