local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")

---@class Boss
---@overload fun(board):Boss
local Boss = class:derive("Boss")

-- TODO: Extract to a separate resource file.
local BOSS_DATA = {
    -- TODO: Waves (after Playtest 1)
    health = 70,
    attacks = {
        {
            type = "shoot",
            delay = 10,
            chargeThreshold = 2,
            effects = {
                sound = "sound_events/boss_shoot.json",
                particle = "boss_shoot",
                screenShake = {power = 2, frequency = 5, duration = 0.2}
            },
            chargeEffects = {
                sound = "sound_events/boss_charge.json"
            }
        }
    },
    activate = {
        effects = {
            -- TODO: Sounds and perhaps something else too?
        }
    },
    damage = {
        effects = {
            flash = 0.1
        }
    },
    stun = {
        duration = 5,
        effects = {
            -- TODO: Sounds and perhaps something else too?
        },
        lightning = {
            delay = 0.1,
            range = 20,
            particle = "boss_stun_lightning",
            minLength = 10
        }
    },
    specialAttack = {
        damage = 25,
        effects = {
            -- TODO: Dedicated sound for performing a special attack on the boss.
            sound = "sound_events/missile_explosion.json",
            particle = "boss_fireball_explode",
            screenShake = {power = 9, frequency = 10, duration = 0.35}
        }
    },
    disarm = {
        effects = {
            -- TODO: Sounds and perhaps something else too?
        }
    },
    visualParts = {
        body = {
            sprite = "sprites/boss_1_idle.json",
            disarmedSprite = "sprites/boss_1_idle.json"
        },
        lights = {
            sprites = {
                "sprites/boss_1_light.json",
                "sprites/boss_1_light_red.json"
            },
            offsets = {Vec2(20, 8), Vec2(29, 11), Vec2(32, 20), Vec2(29, 29), Vec2(20, 32), Vec2(11, 29), Vec2(8, 20), Vec2(11, 11)}
        },
        door = {
            sprite = "sprites/boss_1_door.json",
            offset = Vec2(18, 18)
        },
        core = {
            sprite = "sprites/boss_1_core.json",
            offset = Vec2(19, 19)
        }
    }
}

---Constructs a new Boss.
---@param board Board The board on which the boss is located.
function Boss:new(board)
    self.board = board

    self.x, self.y = 5, 4
    self.w, self.h = 3, 3
    self.health = BOSS_DATA.health
    self.active = false
    self.dead = false
    self.shootTime = BOSS_DATA.attacks[1].delay
    self.shotCharged = false
    self.stunTime = nil
    -- Visual
    self.stunLightningTime = nil
    self.flashTime = nil
    self.lightAnimationProgress = 0
    self.doorAnimation = 0
    self.doorAnimationTarget = false

    self.sprite = _Game.resourceManager:getSprite(BOSS_DATA.visualParts.body.sprite)
    self.disarmedSprite = _Game.resourceManager:getSprite(BOSS_DATA.visualParts.body.disarmedSprite)
    self.lightSprites = {}
    for i, path in ipairs(BOSS_DATA.visualParts.lights.sprites) do
        self.lightSprites[i] = _Game.resourceManager:getSprite(path)
    end
    self.lightSpriteOffsets = BOSS_DATA.visualParts.lights.offsets
    self.doorSprite = _Game.resourceManager:getSprite(BOSS_DATA.visualParts.door.sprite)
    self.coreSprite = _Game.resourceManager:getSprite(BOSS_DATA.visualParts.core.sprite)
    self.flashShader = _Game.resourceManager:getShader("shaders/whiten.glsl")
end

---Activates this Boss, if it is not active yet.
---When the boss is active, it will actually perform attacks.
function Boss:activate()
    if self.active then
        return
    end
    self.active = true
    self:dispatchEffects(BOSS_DATA.activate.effects)
end

---Hurts the boss by the given amount of health points.
---@param health integer The amount of health points to be taken away from the boss.
function Boss:damage(health)
    if self.dead then
        return
    end
    self.health = math.max(self.health - health, 0)
    self:dispatchEffects(BOSS_DATA.damage.effects)
    if self.health == 0 then
        self:die()
    end
end

---Stuns the boss for a moment and resets the shooting time.
function Boss:stun()
    self.shootTime = BOSS_DATA.attacks[1].delay
    self.stunTime = BOSS_DATA.stun.duration
    self:dispatchEffects(BOSS_DATA.stun.effects)
end

---Kills this boss. This function is automatically called when the boss' health reaches 0.
function Boss:die()
    if self.dead then
        return
    end
    self.dead = true
    self:dispatchEffects(BOSS_DATA.disarm.effects)
end

---Returns the percentage of health this Boss currently has.
---@return number
function Boss:getHealthPercentage()
    return self.health / BOSS_DATA.health
end

---Returns `true` if the provided coordinates are occupied by this boss.
---@param x integer The X tile coordinate on the board.
---@param y integer The Y tile coordinate on the board.
---@return boolean
function Boss:matchCoords(x, y)
    return _Utils.isPointInsideBox(x, y, self.x, self.y, self.w - 1, self.h - 1)
end

---Returns `true` if the provided coordinates are occupied by this boss and block lightning.
---@param x integer The X tile coordinate on the board.
---@param y integer The Y tile coordinate on the board.
---@return boolean
function Boss:blocksLightning(x, y)
    return x == self.x + 1 and y == self.y + 1
end

---Returns `true` if the provided coordinates are considered to have a special attack attempted when damaged.
---@param x integer The X tile coordinate on the board.
---@param y integer The Y tile coordinate on the board.
---@return boolean
function Boss:coordsIsSpecialAttack(x, y)
    return x == self.x + 1 and y == self.y + 1
end

---Attempts a special attack on this Boss.
---Currently, it is hardcoded to explode the fireball inside the boss which deals massive damage when the boss is ready to shoot its fireball.
function Boss:trySpecialAttack()
    if not self.shotCharged then
        return
    end
    self.shotCharged = false
    self:dispatchEffects(BOSS_DATA.specialAttack.effects)
    self:damage(BOSS_DATA.specialAttack.damage)
end

---Returns the center position of the Boss on the screen.
---@return Vector2
function Boss:getCenterPos()
    return self.board:getTileCenterPos(Vec2(self.x + math.floor(self.w / 2), self.y + math.floor(self.h / 2)))
end

---Flashes the Boss for the provided amount of time.
---@param duration number The flash duration in seconds.
function Boss:flash(duration)
    self.flashTime = duration
end

---Dispatches effects from this boss being damaged or destroyed, by playing a sound, shaking the screen, spawning particles, etc.
---@private
---@param effects table? A table of effects to be executed.
function Boss:dispatchEffects(effects)
    if not effects then
        return
    end
    local pos = self:getCenterPos()
    if effects.flash then
        self:flash(effects.flash)
    end
    if effects.particle then
        _Game.game:spawnParticles(effects.particle, pos)
    end
    if effects.sound then
        _Game:playSound(effects.sound)
    end
    if effects.screenShake then
        _Game.game:shakeScreen(effects.screenShake.power, effects.screenShake.direction, effects.screenShake.frequency, effects.screenShake.duration)
    end
end

---Updates this Boss.
---@param dt number Time delta in seconds.
function Boss:update(dt)
    self:updateStun(dt)
    self:updateStunLightning(dt)
    self:updateShoot(dt)
    self:updateFlash(dt)
    self:updateLights(dt)
    self:updateDoor(dt)
end

---Updates the stun logic for this Boss.
---@private
---@param dt number Time delta in seconds.
function Boss:updateStun(dt)
    if not self.stunTime then
        return
    end
    self.stunTime = self.stunTime - dt
    if self.stunTime <= 0 then
        self.stunTime = nil
        self.shotCharged = false
    end
end

---Updates the lightning animation for when this Boss is stunned.
---@private
---@param dt number Time delta in seconds.
function Boss:updateStunLightning(dt)
    -- End the stun lightning animation (or don't proceed) if the boss is no longer stunned.
    if not self.stunTime then
        self.stunLightningTime = nil
        return
    end
    self.stunLightningTime = (self.stunLightningTime or BOSS_DATA.stun.lightning.delay) - dt
    if self.stunLightningTime <= 0 then
        self.stunLightningTime = self.stunLightningTime + BOSS_DATA.stun.lightning.delay
        local pos1 = self:getCenterPos() + Vec2((math.random() * 2 - 1) * BOSS_DATA.stun.lightning.range, (math.random() * 2 - 1) * BOSS_DATA.stun.lightning.range)
        local pos2 = self:getCenterPos() + Vec2((math.random() * 2 - 1) * BOSS_DATA.stun.lightning.range, (math.random() * 2 - 1) * BOSS_DATA.stun.lightning.range)
        if (pos1 - pos2):len() > BOSS_DATA.stun.lightning.minLength then
            self.board.level.game:spawnParticles(BOSS_DATA.stun.lightning.particle, pos1, pos2)
        end
    end
end

---Updates the shooting logic for this Boss, only when it is active and alive.
---@private
---@param dt number Time delta in seconds.
function Boss:updateShoot(dt)
    -- The boss will not attempt to shoot if it is dormant, dead or stunned.
    if not self.active or self.dead or self.stunTime then
        return
    end
    self.shootTime = self.shootTime - dt
    if self.shootTime <= 2 and not self.shotCharged then
        self.shotCharged = true
        self:dispatchEffects(BOSS_DATA.attacks[1].chargeEffects)
    end
    if self.shootTime <= 0 then
        self.shootTime = self.shootTime + BOSS_DATA.attacks[1].delay
        self.shotCharged = false
        local shotPos = Vec2(self.x + 1, self.y + 1)
        self.board:spawnBossFireball(shotPos)
        self:dispatchEffects(BOSS_DATA.attacks[1].effects)
    end
end

---Updates the flashing timer for this Boss.
---@private
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

---Updates the light animation.
---@private
---@param dt number Time delta in seconds.
function Boss:updateLights(dt)
    local speed = (BOSS_DATA.attacks[1].delay - self.shootTime) ^ 1.2 * 2
    self.lightAnimationProgress = (self.lightAnimationProgress + dt * speed) % 4
end

---Updates the door animation.
---@private
---@param dt number Time delta in seconds.
function Boss:updateDoor(dt)
    if self.doorAnimationTarget then
        -- Door is open.
        self.doorAnimation = math.min(self.doorAnimation + dt / 0.35, 1)
        -- Close the door: The moment the animation finishes
        self.doorAnimationTarget = self.doorAnimation < 1 or self.dead
    else
        -- Door is closed.
        self.doorAnimation = math.max(self.doorAnimation - dt / 0.35, 0)
        -- Open the door: 0.25 seconds before the shot (or when the boss is disarmed)
        self.doorAnimationTarget = self.shootTime <= 0.25 or self.dead
    end
end

---Returns the sprite this Boss should be using right now.
---@private
---@return Sprite
function Boss:getSprite()
    return self.dead and self.disarmedSprite or self.sprite
end

---Returns whether the light at the provided index should be lit at this moment and which color.
---`0` means the light should be off. `1` means the light should be lit yellow. `2` means the light should be lit red.
---@private
---@param index integer The light index, corresponding to the `lightSpriteOffsets` field.
---@return 0|1|2
function Boss:getLightState(index)
    if not self.active then
        -- Dormant (off)
        return 0
    elseif self.dead then
        -- Disarmed (off)
        return 0
    elseif self.stunTime then
        -- Stunned (flash red)
        return _TotalTime % 0.2 < 0.1 and 2 or 0
    elseif self.shotCharged then
        -- Charged (flash yellow)
        if _TotalTime % 0.1 < 0.05 then
            return 1
        end
    end
    return index % 4 == math.floor(self.lightAnimationProgress) and 1 or 0
end

---Returns the frame to be used by the door, an integer from 1 to 6.
---@private
---@return integer
function Boss:getDoorFrame()
    return _Utils.clamp(math.floor(self.doorAnimation * 8), 1, 5)
end

---Draws the Boss on the screen.
---@param offset Vector2? If set, the offset from the actual draw position in pixels. Used for screen shake.
function Boss:draw(offset)
    local pos = self.board:getTilePos(Vec2(self.x, self.y))
    if offset then
        pos = pos + offset
    end
    local shader = self.flashTime and self.flashShader
    -- Base
    self:getSprite():draw(pos, nil, nil, nil, nil, nil, nil, nil, shader)
    -- Lights
    for i, lightOffset in ipairs(self.lightSpriteOffsets) do
        local state = self:getLightState(i)
        if state > 0 then
            self.lightSprites[state]:draw(pos + lightOffset, nil, nil, nil, nil, nil, nil, nil, shader)
        end
    end
    -- Core
    if self.dead then
        self.coreSprite:draw(pos + BOSS_DATA.visualParts.core.offset, nil, nil, _TotalTime % 0.2 < 0.1 and 1 or 2)
    end
    -- Door
    if not self.dead then
        self.doorSprite:draw(pos + BOSS_DATA.visualParts.door.offset, nil, nil, self:getDoorFrame(), nil, nil, nil, nil, shader)
    end
end

return Boss