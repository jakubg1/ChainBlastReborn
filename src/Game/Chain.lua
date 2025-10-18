local class = require "com.class"

---@class Chain
---@overload fun(board, coords, type):Chain
local Chain = class:derive("Chain")

local Vec2 = require("src.Essentials.Vector2")

-- TODO: Extract board object types to resource files.
-- TODO: Finish and implement.
local CHAIN_TYPES = {
    chain_red = {
        sprite = "sprites/chain_red.json",
        linkSprite = "sprites/chain_link_red.json",
        rendering = "chain",
        color = 1,
        affectedByGravity = true,
        selectable = true,
        shufflable = true,
        canMatch = true,
        canConnect = true,
        rotateSound = "sound_events/chain_rotate.json",
        onDestroy = {
            particle = "chain_destroy",
            --screenShake = {power = 0.5, frequency = 20, duration = 0.15},
            spawnChainParticles = true,
            countChainDestroyed = true
        }
    },
    chain_blue = {
        sprite = "sprites/chain_blue.json",
        linkSprite = "sprites/chain_link_blue.json",
        rendering = "chain",
        color = 2,
        affectedByGravity = true,
        selectable = true,
        shufflable = true,
        canMatch = true,
        canConnect = true,
        rotateSound = "sound_events/chain_rotate.json",
        onDestroy = {
            particle = "chain_destroy",
            --screenShake = {power = 0.5, frequency = 20, duration = 0.15},
            spawnChainParticles = true,
            countChainDestroyed = true
        }
    },
    chain_yellow = {
        sprite = "sprites/chain_yellow.json",
        linkSprite = "sprites/chain_link_yellow.json",
        rendering = "chain",
        color = 3,
        affectedByGravity = true,
        selectable = true,
        shufflable = true,
        canMatch = true,
        canConnect = true,
        rotateSound = "sound_events/chain_rotate.json",
        onDestroy = {
            particle = "chain_destroy",
            --screenShake = {power = 0.5, frequency = 20, duration = 0.15},
            spawnChainParticles = true,
            countChainDestroyed = true
        }
    },
    chain_rainbow = {
        sprite = "sprites/chain_rainbow.json",
        linkSprite = "sprites/chain_link_rainbow.json",
        rendering = "chain",
        color = 0,
        affectedByGravity = true,
        selectable = true,
        shufflable = true,
        canMatch = true,
        canConnect = true,
        rotateSound = "sound_events/chain_rotate.json",
        onDestroy = {
            particle = "chain_destroy",
            --screenShake = {power = 0.5, frequency = 20, duration = 0.15},
            spawnChainParticles = true,
            countChainDestroyed = true
        }
    },
    crate = {
        sprite = "sprites/crate.json",
        rendering = "crate",
        onNearbyMatch = {
            damage = 1
        },
        onDamage = {
            sound = "sound_events/crate_destroy.json",
            flash = 0.1,
            particle = "crate_damage",
            screenShake = {power = 1, frequency = 20, duration = 0.15}
        },
        onDestroy = {
            sound = "sound_events/crate_destroy.json",
            particle = "crate_destroy",
            screenShake = {power = 2, frequency = 20, duration = 0.15},
            spawnCrateParticles = true
        }
    },
    rock = {
        sprite = "sprites/rock.json",
        rendering = "crate",
        affectedByGravity = true,
        onDestroy = {
            screenShake = {power = 2, frequency = 20, duration = 0.15},
            spawnCrateParticles = true
        }
    }
}

---Constructs a new Chain. Chains can be chains or can be any other object that occupies a chain space in the game, such as a crate, a rock, etc.
---@param board Board The board this Chain belongs to.
---@param coords Vector2 The tile position where this Chain is on the board.
---@param type string The type of the Chain. Can be `"chain"` or `"crate"`.
function Chain:new(board, coords, type)
    self.board = board
    -- Logical position of the Chain. This is used for match calculation, etc.
    self.coords = coords
    self.type = type
    self.config = CHAIN_TYPES[type]

    -- 1 = straight, 2 = cross
    self.shape = math.random() < 1/15 and 2 or 1
    self.health = 1

    -- 1 = vertical, 2 = horizontal
    self.rotation = self.shape == 2 and 1 or math.random(1, 2)
    self.rotationMax = 3 - self.shape
    self.rotationAnim = nil
    -- This will be restored if the chain is rotated temporarily.
    self.savedRotation = self.rotation

    self.powerup = nil

    -- The visual position of the chain. Differs from `self.coords` if the chain is currently falling, shuffling, shaking, etc.
    self.visualCoords = coords
    self.fallTarget = nil
    self.fallSpeed = 0
    self.fallDelay = nil
    self.shuffleStart = nil
    self.shuffleTarget = nil
    self.shuffleTime = 0
    self.releasePos = nil
    self.releaseSpeed = nil
    self.releaseTime = nil
    self.releaseRotation = nil
    self.releaseRotationSpeed = nil
    self.panicTime = nil
    self.panicOffset = Vec2()
    self.shakeTime = nil
    self.shakeOffset = Vec2()
    self.destroyDelay = nil
    self.flashTime = nil
    ---@type {delay: number, time: number}[]
    self.flashQueue = {}

    self.LINK_DATA = {
        {pos = Vec2(6, -1), state = 2, rot = 0},
        {pos = Vec2(15, 6), state = 2, rot = math.pi / 2},
        {pos = Vec2(6, 9), state = 1, rot = 0},
        {pos = Vec2(5, 6), state = 1, rot = math.pi / 2}
    }
    self.sprite = _Game.resourceManager:getSprite(self.config.sprite)
    self.linkSprite = self.config.linkSprite and _Game.resourceManager:getSprite(self.config.linkSprite)
    self.flashShader = _Game.resourceManager:getShader("shaders/whiten.glsl")

    self.delQueue = false
end

---Updates the Chain.
---@param dt number Time delta in seconds.
function Chain:update(dt)
    if self.rotationAnim then
        self.rotationAnim = self.rotationAnim + dt * 40
        if self.rotationAnim >= 4 then
            self.rotationAnim = nil
        end
    end

    -- Falling animation
    if self.fallTarget then
        -- Delay
        if self.fallDelay then
            self.fallDelay = self.fallDelay - dt
            if self.fallDelay <= 0 then
                self.fallDelay = nil
            end
        end
        -- Actual falling
        if not self.fallDelay then
            self.fallSpeed = self.fallSpeed + 20 * dt
            self.visualCoords.y = self.visualCoords.y + self.fallSpeed * dt
            if self.visualCoords.y >= self.fallTarget.y then
                -- We landed!
                self.visualCoords.y = self.fallTarget.y
                self.fallTarget = nil
                self.fallSpeed = 0
                _Game:playSound("sound_events/chain_land.json")
            end
        end
    end

    -- Shuffling animation
    if self.shuffleTarget then
        self.shuffleTime = self.shuffleTime + dt
        local t = 0
        if self.shuffleTime > 0 then
            t = 1 - math.sin((1 - self.shuffleTime / 0.5) * (math.pi / 2))
        end
        self.visualCoords = self.shuffleStart * (1 - t) + self.shuffleTarget * t
        if self.shuffleTime >= 0.5 then
            self.visualCoords = self.shuffleTarget
            self.shuffleStart = nil
            self.shuffleTarget = nil
            self.shuffleTime = 0
        end
    end

    -- Release animation
    if self.releaseSpeed then
        self.releaseTime = self.releaseTime + dt
        self.releaseSpeed = self.releaseSpeed + Vec2(0, self.releaseTime * 3.75)
        self.releasePos = self.releasePos + self.releaseSpeed * dt
        if self.releaseRotationSpeed then
            self.releaseRotation = self.releaseRotation + self.releaseRotationSpeed * dt
        end
    end

    -- Panic animation
    if self.panicTime then
        self.panicTime = self.panicTime + dt
        self.panicOffset = Vec2(love.math.randomNormal(self.panicTime), love.math.randomNormal(self.panicTime))
    end

    -- Shake animation
    if self.shakeTime then
        self.shakeTime = self.shakeTime - dt
        if self.shakeTime > 0 then
            if self.shakeOffset.x == 0 and self.shakeOffset.y == 0 then
                self.shakeOffset = Vec2(math.random() < 0.5 and -1 or 1, math.random() < 0.5 and -1 or 1)
            end
        else
            self.shakeOffset = Vec2()
            self.shakeTime = nil
        end
    end

    -- Destruction delay
    if self.destroyDelay then
        self.destroyDelay = self.destroyDelay - dt
        if self.destroyDelay <= 0 then
            self:destroy()
        end
    end

    -- Flash time
    if self.flashTime then
        self.flashTime = self.flashTime - dt
        if self.flashTime <= 0 then
            self.flashTime = nil
        end
    end

    -- Flash queue
    for i = #self.flashQueue, 1, -1 do
        local entry = self.flashQueue[i]
        entry.delay = entry.delay - dt
        if entry.delay <= 0 then
            table.remove(self.flashQueue, i)
            self:flash(entry.time)
        end
    end
end

---Whether this Chain color can be connected with the given color.
---@param color integer The color to be checked with.
---@return boolean
function Chain:matchesWithColor(color)
    if not self.config.canMatch then
        return false
    end
    return self.config.color == color or self.config.color == 0 or color == 0
end

---Returns a neighboring chain in the given direction.
---@param direction integer The direction to look in. 1 is up, then clockwise.
---@return Chain?
function Chain:getNeighborChain(direction)
    return self.board:getChain(self.coords + self.board.DIRECTIONS[direction])
end

---Whether this Chain is able to connect to other chains in the given direction.
---@param direction integer The direction to look in. 1 is up, then clockwise.
---@return boolean
function Chain:hasConnection(direction)
    if not self.config.canConnect then
        return false
    end
    if self.shape == 2 then
        return true
    end
    if self.rotation == 1 then
        return direction % 2 == 1
    else
        return direction % 2 == 0
    end
end

---Returns whether this Chain is connected with its neighbor in the given direction.
---@param direction integer The direction to look in. 1 is up, then clockwise.
---@return boolean
function Chain:isConnected(direction)
    local neighbor = self:getNeighborChain(direction)
    -- No neighbor = nothing to connect with.
    if not neighbor then
        return false
    end
    -- Both chains must be able to connect with each other.
    if not self:hasConnection(direction) or not neighbor:hasConnection((direction + 1) % 4 + 1) then
        return false
    end
    -- And finally, both colors must match.
    return self:matchesWithColor(neighbor:getColor())
end

---Returns whether this Chain is *visually* connected with its neighbor in the given direction.
---This differs from `:isConnected()`, because the chain can be connected without showing its link.
---That could deny a match if the cursor was moved sufficiently quickly and the rotating animation hasn't yet finished.
---@param direction integer The direction to look in. 1 is up, then clockwise.
---@return boolean
function Chain:isVisuallyConnected(direction)
    local neighbor = self:getNeighborChain(direction)
    -- No neighbor = nothing to connect with.
    if not neighbor then
        return false
    end
    -- The chains must not be rotating.
    if self.rotationAnim or neighbor.rotationAnim then
        return false
    end
    -- Or falling.
    if self.fallTarget or neighbor.fallTarget then
        return false
    end
    -- Or shuffling...
    if self.shuffleTarget or neighbor.shuffleTarget then
        return false
    end
    -- Nope, released don't work either.
    if self.releasePos or neighbor.releasePos then
        return false
    end
    -- Check all the conditions for normal connections. We can't show a connection that does not exist!
    return self:isConnected(direction)
end

---Returns a list of coordinates of all chains connected together that involve this chain.
---@param excludedCoords table? Utility parameter used only in recursive calls. Do not set.
---@return table
function Chain:getGroup(excludedCoords)
    excludedCoords = excludedCoords or {self.coords}

    for i = 1, 4 do
        if self:isConnected(i) then
            local newChain = self:getNeighborChain(i)
            assert(newChain)
            local newCoords = newChain.coords
            if not _Utils.isValueInTable(excludedCoords, newCoords) then
                table.insert(excludedCoords, newCoords)
                newChain:getGroup(excludedCoords)
            end
        end
    end
    return excludedCoords
end

---Returns whether this Chain alongside with its neighbors can make a group of at least 3 chains.
---@param directions table? Utility parameter used only in recursive calls. Do not set.
---@return boolean
function Chain:canMakeMatch(directions)
    if not directions then
        if self.shape == 1 then
            return self:canMakeMatch({1, 3}) or self:canMakeMatch({2, 4})
        elseif self.shape == 2 then
            return self:canMakeMatch({1, 2, 3, 4})
        end
    end
    assert(directions)

    local potentialConnections = 0
    for i, direction in ipairs(directions) do
        local chain = self:getNeighborChain(direction)
        if chain and chain.config.canMatch and self:matchesWithColor(chain:getColor()) then
            potentialConnections = potentialConnections + 1
        end
        if potentialConnections >= 2 then
            return true
        end
    end
    return false
end

---Returns the color of this Chain, used to determine if chains can connect and for selections.
---@return integer
function Chain:getColor()
    return self.config.color
end

---Returns whether this Chain can fall downwards when there is an empty space below.
---@return boolean
function Chain:canFall()
    return self.config.affectedByGravity
end

---Returns whether this Chain can be selected by the player.
---@return boolean
function Chain:canBeSelected()
    return self.config.selectable
end

---Returns whether this Chain can be shuffled.
---@return boolean
function Chain:canBeShuffled()
    return self.config.shufflable
end

---Rotates the Chain one step clockwise, or to the given rotation state.
---@param rotation integer? The new Chain rotation state.
---@param temporary boolean? Whether the Chain will be rotated temporarily, and its previous state can be restored by calling `:unrotate()`.
function Chain:rotate(rotation, temporary)
    rotation = rotation or self.rotation + 1
    local newRotation = (rotation - 1) % self.rotationMax + 1

    if self.rotation ~= newRotation then
        self.rotationAnim = 1
        _Game:playSound(self.config.rotateSound)
    end
    self.rotation = newRotation
    if not temporary then
        self.savedRotation = rotation
    end
end

---Restores the previous Chain rotation if it has been temporarily rotated.
function Chain:unrotate()
    self.rotation = self.savedRotation
end

---Starts the fall animation for this Chain and updates its coordinates.
---This function DOES NOT update the position of this Chain on the board.
---Use `Board:fallChain()` instead.
---@param coords Vector2 The target position for this Chain to fall to. The X component is ignored.
---@param delay number? If specified, the chain will wait this amount of seconds before starting to fall.
function Chain:fallTo(coords, delay)
    self.fallTarget = coords
    self.fallDelay = delay
    self.coords = coords
end

---Starts the shuffle animation for this Chain and updates its coordinates.
---This function DOES NOT update the position of this Chain on the board.
---Use `Board:shuffleChain()` instead.
---@param coords Vector2 The new chain position.
function Chain:shuffleTo(coords)
    self.shuffleStart = self.visualCoords
    self.shuffleTarget = coords
    self.shuffleTime = love.math.random() * -0.5
    self.coords = coords
end

---Sets a Powerup on this Chain.
---@param powerup string The powerup ID.
function Chain:setPowerup(powerup)
    self.powerup = powerup
end

---Starts the release animation for this Chain.
function Chain:release()
    self.releasePos = self:getPos()
    self.releaseSpeed = Vec2(love.math.random() * 75 - 37.5, love.math.random() * -37.5 - 75)
    self.releaseTime = 0
    --self.releaseRotation = 0
    --self.releaseRotationSpeed = love.math.randomNormal(15, 0)
end

---Starts the panic animation for this Chain (shaking rapidly).
function Chain:panic()
    self.panicTime = 0
end

---Shakes the chain slightly for the provided duration.
---@param duration number The duration of the shake in seconds.
function Chain:shake(duration)
    self.shakeTime = duration
end

---Flashes the chain white for a specified amount of time.
---@param duration number Flash duration in seconds.
---@param delay number? If specified, the flash will be delayed by this duration in seconds.
function Chain:flash(duration, delay)
    if delay then
        table.insert(self.flashQueue, {delay = delay, time = duration})
        return
    end
    self.flashTime = duration
end

---Spawns some power particles which go to the power meter.
---@param amount integer Amount of particles to be spawned.
function Chain:spawnPowerParticles(amount)
    -- TODO: Better way to store power colors and crystal position?
    local pos = self:getCenterPos()
    local pos2 = self.board.level.ui.POWER_CRYSTAL_CENTER_POS
    local color = self.board.level.ui.POWER_METER_COLORS[self.config.color]
    for i = 1, amount do
        -- Because the amount of particles in particle effect data is constant, we have to spawn them one by one.
        _Game.game:spawnParticles("power_spark", pos, pos2, color)
    end
end

---Dispatches effects from this board object being damaged or destroyed, by playing a sound, shaking the screen, spawning particles, etc.
---@private
---@param effects table? A table of effects to be executed.
function Chain:dispatchEffects(effects)
    if not effects then
        return
    end
    local pos = self:getCenterPos()
    local reduce = _Game.runtimeManager.options:getSetting("reducedParticles")
    if effects.flash then
        self:flash(effects.flash)
    end
    if effects.particle then
        _Game.game:spawnParticles(effects.particle, pos)
    end
    if effects.spawnChainParticles then
        if not reduce and _Game.game.settings.chainExplosionStyle == "legacy" then
            _Game.game:spawnParticleFragments(pos, "", self.sprite, self:getState(), self:getFrame())
        end
    end
    if effects.spawnCrateParticles then
        if not reduce then
            _Game.game:spawnParticleFragments(pos, "", self.sprite, self:getState(), self:getFrame(), 4)
        end
    end
    if effects.sound then
        _Game:playSound(effects.sound)
    end
    if effects.screenShake then
        _Game.game:shakeScreen(effects.screenShake.power, effects.screenShake.direction, effects.screenShake.frequency, effects.screenShake.duration)
    end
    if effects.countChainDestroyed then
        _Game.game.player.chainsDestroyed = _Game.game.player.chainsDestroyed + 1
    end
end

---Damages this Chain. If its health hits 0, it is also destroyed.
---@param amount integer? How many hit points should be deducted from this object, 1 by default.
function Chain:damage(amount)
    amount = amount or 1
    if amount <= 0 then
        return
    end
    self.health = math.max(self.health - amount, 0)
    if self.health == 0 then
        self:destroy()
    else
        self:dispatchEffects(self.config.onDamage)
    end
end

---Notifies this board object that a match has happened nearby. For crates, this means that they get damaged or destroyed.
function Chain:sideImpact()
    local effects = self.config.onNearbyMatch
    if not effects then
        return
    end
    if effects.damage then
        self:damage(effects.damage)
    end
end

---Destroys this Chain and marks it as dead (`delQueue = true`). It will be removed from the Board at the end of this frame.
---Or, alternatively, marks this Chain to be destroyed after a certain delay. We say this Chain is **primed**.
---@param delay number? The time in seconds after which this Chain will be destroyed. If not set, this Chain will be destroyed immediately.
function Chain:destroy(delay)
    if self.delQueue then
        return
    end

    -- Handle the delay parameter.
    if delay then
        self.destroyDelay = delay
        return
    end

    -- Mark as dead.
    self.delQueue = true

    -- Use a powerup.
    if self.powerup == "bomb" then
        self.board:explodeBomb(self.coords)
    elseif self.powerup == "lightning" then
        self.board:explodeLightning(self.coords, self.shape == 2 or self.rotation == 1, self.shape == 2 or self.rotation == 2)
    elseif self.powerup == "missile" then
        self.board:spawnMissile(self.coords)
        _Game:playSound("sound_events/powerup_missile.json")
    end

    -- Dispatch effects: screenshake, particles, sound, stat counting, etc.
    self:dispatchEffects(self.config.onDestroy)
end

---Returns whether the chain is currently falling.
---@return boolean
function Chain:isFalling()
    return self.fallTarget ~= nil
end

---Returns whether this board object is currently being shuffled.
---@return boolean
function Chain:isShuffling()
    return self.shuffleTarget ~= nil
end

---Returns whether this Chain is primed, which means that it is scheduled for destruction.
---@return boolean
function Chain:isPrimed()
    return self.destroyDelay ~= nil
end

---Returns whether this Chain is dead, i.e. destroyed.
---@return boolean
function Chain:isDead()
    return self.delQueue
end

---Returns the current position this Chain should be drawn at.
---@return Vector2
function Chain:getPos()
    if self.releasePos then
        return self.releasePos
    end
    return self.board:getTilePos(self.visualCoords) + self.panicOffset + self.shakeOffset
end

---Returns the center position of this Chain.
---@return Vector2
function Chain:getCenterPos()
    return self:getPos() + 7
end

---Returns the current sprite state of the Chain which should be drawn.
---@return integer
function Chain:getState()
    if self.config.rendering == "chain" then
        if self.shape == 2 then
            return 3
        end
        if self.rotationAnim then
            return 3 - self.rotation
        end
        if self.releaseRotation then
            local rot = self.rotation + math.floor(self.releaseRotation / 4)
            return (rot - 1) % 2 + 1
        end
        return self.rotation
    elseif self.config.rendering == "crate" then
        return math.max(self.health, 1)
    end
    error(string.format("Illegal chain type: %s", self.config.rendering))
end

---Returns the current animation frame of the Chain which should be drawn.
---@return integer
function Chain:getFrame()
    if self.config.rendering == "chain" then
        if self.rotationAnim then
            --local n = math.sin(math.sin((self.rotationAnim / 4) * math.pi / 2) * math.pi / 2) * 3.99
            local n = self.rotationAnim
            return math.floor(n) + 1
        end
        if self.releaseRotation and self.shape == 1 then
            return math.floor(self.releaseRotation) % 4 + 1
        end
        return 1
    elseif self.config.rendering == "crate" then
        return 1
    end
    error(string.format("Illegal chain type: %s", self.config.rendering))
end

---Draws the Chain on the screen, alongside with its links.
---@param offset Vector2? If set, the offset from the actual draw position in pixels. Used for screen shake.
function Chain:draw(offset)
    local pos = self:getPos()
    if offset then
        pos = pos + offset
    end
    local state = self:getState()
    local frame = self:getFrame()
    local shader = self.flashTime and self.flashShader
    -- Draw the shadow.
    self.sprite:drawWithShadow(pos, nil, state, frame, nil, nil, nil, nil, shader, 0.6)
    -- Draw the debugging sprite.
    if _Debug.chainDebug then
        local logicalPos = self.board:getTilePos(self.coords)
        self.sprite:drawWithShadow(logicalPos, nil, state, frame, nil, nil, 0.5)
    end
    -- Draw chain connections.
    for i = 1, 4 do
        if self:isVisuallyConnected(i) then
            local data = self.LINK_DATA[i]
            self.linkSprite:drawWithShadow(pos + data.pos, nil, data.state, nil, data.rot, nil, nil, nil, shader)
        end
    end
end

return Chain