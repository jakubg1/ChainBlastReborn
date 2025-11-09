local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")

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
    self.active = false
    self.dead = false
    self.maxShootTime = 10
    self.shootTime = self.maxShootTime
    self.stunTime = nil
    self.flashTime = nil

    self.sprites = {
        dead = _Game.resourceManager:getSprite("sprites/boss_1_dead.json"),
        disarmed = _Game.resourceManager:getSprite("sprites/boss_1_disarmed.json"),
        dormant = _Game.resourceManager:getSprite("sprites/boss_1_dormant.json"),
        idle = _Game.resourceManager:getSprite("sprites/boss_1_idle.json"),
        ready = _Game.resourceManager:getSprite("sprites/boss_1_ready.json"),
        stunned = _Game.resourceManager:getSprite("sprites/boss_1_stunned.json")
    }
    self.flashShader = _Game.resourceManager:getShader("shaders/whiten.glsl")
end

---Activates this Boss, if it is not active yet.
---When the boss is active, it will actually perform attacks.
function Boss:activate()
    if self.active then
        return
    end
    self.active = true
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

---Stuns the boss for a moment and resets the shooting time.
function Boss:stun()
    self.shootTime = self.maxShootTime
    self.stunTime = 5
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

---Flashes the Boss for the provided amount of time.
---@param duration number The flash duration in seconds.
function Boss:flash(duration)
    self.flashTime = duration
end

---Updates this Boss.
---@param dt number Time delta in seconds.
function Boss:update(dt)
    self:updateStun(dt)
    self:updateShoot(dt)
    self:updateFlash(dt)
end

---Updates the stun logic for this Boss.
---@param dt number Time delta in seconds.
function Boss:updateStun(dt)
    if not self.stunTime then
        return
    end
    self.stunTime = self.stunTime - dt
    if self.stunTime <= 0 then
        self.stunTime = nil
    end
end

---Updates the shooting logic for this Boss, only when it is active and alive.
---@param dt number Time delta in seconds.
function Boss:updateShoot(dt)
    -- The boss will not attempt to shoot if it is dormant, dead or stunned.
    if not self.active or self.dead or self.stunTime then
        return
    end
    self.shootTime = self.shootTime - dt
    if self.shootTime <= 0 then
        self.shootTime = self.shootTime + self.maxShootTime
        self.board:spawnBossFireball(Vec2(self.x + 1, self.y + 1))
    end
end

---Updates the flashing timer for this Boss.
---@param dt number Time delta in seconds.
function Boss:updateFlash(dt)
    if not self.flashTime then
        return
    end
    self.flashTime = self.flashTime - dt
    if self.flashTime <= 0 then
        self.flashTime = nil
    end
end

---Returns the sprite this Boss should be using right now.
---@return Sprite
function Boss:getSprite()
    if not self.active then
        return self.sprites.dormant
    elseif self.dead then
        return self.sprites.dead
    elseif self.stunTime then
        return self.sprites.stunned
    elseif self.shootTime < 2 then
        return self.sprites.ready
    end
    return self.sprites.idle
end

---Draws the Boss on the screen.
---@param offset Vector2? If set, the offset from the actual draw position in pixels. Used for screen shake.
function Boss:draw(offset)
    local pos = self.board:getTilePos(Vec2(self.x, self.y))
    if offset then
        pos = pos + offset
    end
    local shader = self.flashTime and self.flashShader
    self:getSprite():draw(pos, nil, nil, nil, nil, nil, nil, nil, shader)
end

return Boss