local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")

---@class BossFireball
---@overload fun(board, startCoords, targetCoords):BossFireball
local BossFireball = class:derive("BossFireball")

---Constructs a new BossFireball. BossFireballs are projectiles that appear and explode a 3x3 area around the targeted tile, removing gold from them.
---@param board Board The Board this BossFireball belongs to.
---@param startCoords Vector2 The source coordinates for this BossFireball.
---@param targetCoords Vector2 The target coordinates for this BossFireball.
function BossFireball:new(board, startCoords, targetCoords)
    self.board = board
    self.startCoords = startCoords
    self.targetCoords = targetCoords

    self.targetPos = self.board:getTileCenterPos(self.targetCoords)
    self.pos = self.board:getTileCenterPos(self.startCoords)
    self.startPos = self.pos
    self.speed = 150
    self.time = 0
    self.targetTime = (self.startPos - self.targetPos):len() / self.speed

    self.sprite = _Game.resourceManager:getSprite("sprites/fireball.json")

    self.delQueue = false
end

---Explodes the BossFireball.
function BossFireball:explode()
    -- Explode the tiles.
    for x = -1, 1 do
        for y = -1, 1 do
            if math.abs(x) + math.abs(y) < 4 then
                self.board:bossExplodeTile(self.targetCoords + Vec2(x, y))
            end
        end
    end
    -- An effect.
    _Game:playSound("sound_events/missile_explosion.json")
    _Game.game:shakeScreen(9, nil, 35, 0.35)
    self.delQueue = true
end

---Updates the BossFireball.
---@param dt number Time delta in seconds.
function BossFireball:update(dt)
    self.time = self.time + dt
    local t = self.time / self.targetTime
    self.pos = self.startPos * (1 - t) + self.targetPos * t
    if self.time >= self.targetTime then
        self.pos = self.targetPos
        self:explode()
    else
        --_Game.game:spawnParticles("missile_trail", self.pos)
    end
end

---Draws the BossFireball.
---@param offset Vector2 Offset used for screenshakes.
function BossFireball:draw(offset)
    self.sprite:draw(self.pos + offset, Vec2(0.5), nil, math.floor(self.time * 5 % 2) + 1)
end

return BossFireball