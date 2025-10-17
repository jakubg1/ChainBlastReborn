local class = require "com.class"

---@class Missile
---@overload fun(board, startCoords, targetCoords):Missile
local Missile = class:derive("Missile")

---Constructs a new Missile. Missiles are projectiles that appear and explode a 3x3 area around the targeted tile.
---@param board Board The Board this Missile belongs to.
---@param startCoords Vector2 The source coordinates for this Missile.
---@param targetCoords Vector2 The target coordinates for this Missile.
function Missile:new(board, startCoords, targetCoords)
    self.board = board
    self.startCoords = startCoords
    self.targetCoords = targetCoords

    self.targetPos = self.board:getTileCenterPos(self.targetCoords)
    self.pos = self.board:getTileCenterPos(self.startCoords)
    self.startPos = self.pos
    self.time = 0
    self.targetTime = 0.2

    self.delQueue = false
end

---Updates the Missile.
---@param dt number Time delta in seconds.
function Missile:update(dt)
    self.time = self.time + dt
    local t = self.time / self.targetTime
    self.pos = self.startPos * (1 - t) + self.targetPos * t
    if self.time >= self.targetTime then
        self.pos = self.targetPos
        self:explode()
    else
        _Game.game:spawnParticles("missile_trail", self.pos)
    end
end

---Explodes the Missile.
function Missile:explode()
    self.board:explodeChain(self.targetCoords)
    _Game:playSound("sound_events/missile_explosion.json")
    self.delQueue = true
end

return Missile