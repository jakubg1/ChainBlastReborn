local class = require "com.class"

---@class Boss
---@overload fun(board):Boss
local Boss = class:derive("Boss")

---Constructs a new Boss.
---@param board Board The board on which the boss is located.
function Boss:new(board)
    self.board = board

    self.x, self.y = 5, 4
    self.w, self.h = 3, 3
    self.maxHealth = 60
    self.health = self.maxHealth
    self.dead = false
end

---Hurts the boss by the given amount of health points.
---@param health integer The amount of health points to be taken away from the boss.
function Boss:damage(health)
    if self.dead then
        return
    end
    self.health = math.max(self.health - health, 0)
    if self.health == 0 then
        self:die()
    end
end

---Kills this boss. This function is automatically called when the boss' health reaches 0.
function Boss:die()
    if self.dead then
        return
    end
    self.dead = true
end

---Returns the percentage of health this Boss currently has.
---@return number
function Boss:getHealthPercentage()
    return self.health / self.maxHealth
end

---Returns `true` if the provided coordinates are occupied by this boss.
---@param x integer The X tile coordinate on the board.
---@param y integer The Y tile coordinate on the board.
---@return boolean
function Boss:matchCoords(x, y)
    return _Utils.isPointInsideBox(x, y, self.x, self.y, self.w - 1, self.h - 1)
end

return Boss