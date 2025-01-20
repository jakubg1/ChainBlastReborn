local class = require "com.class"

---@class Bomb
---@overload fun(board, targetCoords):Bomb
local Bomb = class:derive("Bomb")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")



---Constructs a new Bomb. Bombs are projectiles that appear and explode a 3x3 area around the targeted tile.
---@param board Board The Board this Bomb belongs to.
---@param targetCoords Vector2 The target coordinates for this Bomb.
function Bomb:new(board, targetCoords)
    self.board = board
    self.targetCoords = targetCoords

    self.targetPos = self.board:getTilePos(self.targetCoords)
    self.pos = self.targetPos + Vec2(300, 0):rotate(love.math.random() * math.pi * 2)
    self.startPos = self.pos
    self.time = 0
    self.targetTime = 0.5

    self.delQueue = false
end



---Updates the Bomb.
---@param dt number Time delta in seconds.
function Bomb:update(dt)
    self.time = self.time + dt
    local t = self.time / self.targetTime
    self.pos = self.startPos * (1 - t) + self.targetPos * t
    if self.time >= self.targetTime then
        self.pos = self.targetPos
        self:explode()
    else
        _Game.game:spawnParticle(self.pos, "spark")
    end
end



---Explodes the Bomb.
function Bomb:explode()
    self.board:explodeBomb(self.targetCoords)
    self.delQueue = true
end



return Bomb