local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class Tile
---@overload fun(board, coords, type):Tile
local Tile = class:derive("Tile")

-- TODO: Extract tile types to resource files.
local TILE_TYPES = {
    normal = {
        sprite = {state = 1, frame = 1},
        preventsWin = true,
        hostsChain = true,
        onDamage = {
            transformTo = "gold",
            goldAnimation = true,
            goldAnimation2 = true
        },
        onExplode = {
            transformTo = "gold",
            goldAnimation = true,
            goldAnimation2 = true
        }
    },
    gold = {
        sprite = {state = 2, stateAlt = 3, frame = "gold"},
        preventsWin = false,
        hostsChain = true
    },
    flip = {
        sprite = {state = 4, frame = 1},
        preventsWin = true,
        hostsChain = true,
        onDamage = {
            transformTo = "flip_gold",
            goldAnimation2 = true
        },
        onExplode = {
            transformTo = "flip_gold",
            goldAnimation2 = true
        }
    },
    flip_gold = {
        sprite = {state = 5, frame = 1},
        preventsWin = false,
        hostsChain = true,
        onDamage = {
            transformTo = "flip"
        }
    },
    ice = {
        sprite = {state = 7, frame = 2},
        preventsWin = true,
        hostsChain = true,
        onDamage = {
            transformTo = "ice_broken",
            sound = "sound_events/ice_break.json",
            extraTime = 0.5,
            spawnIceParticles = true
        },
        onExplode = {
            transformTo = "normal"
        }
    },
    ice_broken = {
        sprite = {state = 7, frame = 1},
        preventsWin = true,
        hostsChain = true,
        onDamage = {
            transformTo = "normal",
            sound = "sound_events/ice_break.json",
            extraTime = 0.5,
            spawnIceParticles = true
        },
        onExplode = {
            transformTo = "normal"
        }
    },
    wall = {
        preventsWin = false,
        hostsChain = false,
        blocksLightning = true,
        useBrickMap = true
    },
    wall_dirt = {
        preventsWin = false,
        hostsChain = false,
        blocksLightning = true,
        useDirtMap = true,
        useBrickMap = true
    },
    dirt = {
        useDirtMap = true,
        preventsWin = true,
        hostsChain = true,
        onDamage = {
            transformTo = "normal",
            sound = "sound_events/dirt_break.json",
            spawnDirtParticles = true
        },
        onExplode = {
            transformTo = "normal",
            sound = "sound_events/dirt_break.json",
            spawnDirtParticles = true
        }
    },
}

---Constructs a Tile.
---@param board Board The Board this Tile belongs to.
---@param coords Vector2 The tile position where this Tile is on the board.
---@param type string The tile type. For allowed types look at `TILE_TYPES` in `Tile.lua`.
function Tile:new(board, coords, type)
    self.board = board
    self.coords = coords
    self.type = type

    self.config = TILE_TYPES[type]

    self.goldAnimation = nil
    self.goldAnimation2 = nil

    self.visible = false
    self.visibleDelay = nil
    self.alpha = 0

    self.selected = false
    self.selectedAsPowerupVictim = false
    self.selectedSides = {false, false, false, false}

	self.sprite = _Game.resourceManager:getSprite("sprites/tiles.json")
end

---Updates this Tile.
---@param dt number Time delta in seconds.
function Tile:update(dt)
    -- Fade in/out animation
    if self.visibleDelay then
        self.visibleDelay = self.visibleDelay - dt
        if self.visibleDelay <= 0 then
            self.visibleDelay = nil
        end
    else
        if self.visible then
            if self.alpha < 1 then
                self.alpha = math.min(self.alpha + dt / 0.6, 1)
            end
        else
            if self.alpha > 0 then
                self.alpha = math.max(self.alpha - dt / 0.6, 0)
            end
        end
    end

    -- Animation of turning the tile gold
    if self.goldAnimation then
        self.goldAnimation = self.goldAnimation + dt * 25
        if self.goldAnimation >= 7 then
            self.goldAnimation = nil
        end
    end

    if self.goldAnimation2 then
        self.goldAnimation2 = self.goldAnimation2 + dt
        if self.goldAnimation2 >= 4 then
            self.goldAnimation2 = nil
        end
    end
end

---Returns the global coordinates of this Tile.
---@return Vector2
function Tile:getPos()
    return self.board:getTilePos(self.coords)
end

---Returns the global coordinates of this Tile's center.
---@return Vector2
function Tile:getCenterPos()
    return self:getPos() + 7
end

---Converts this Tile into another type.
---@param type string The new tile type. For allowed types look at `TILE_TYPES` in `Tile.lua`.
function Tile:transformTo(type)
    self.type = type
    self.config = TILE_TYPES[type]
end

---Returns whether presence of this tile should block the player from winning the level.
---@return boolean
function Tile:preventsWin()
    return self.config.preventsWin
end

---Returns whether a Chain (or another board object) can sit on this Tile.
---@return boolean
function Tile:hostsChain()
    return self.config.hostsChain
end

---Returns whether the lightning beams cannot reach past this Tile.
---@return boolean
function Tile:blocksLightning()
    return self.config.blocksLightning
end

---Returns whether this Tile is using a dirt map.
---TODO: Change the map to use any string for multi-map support.
function Tile:usesDirtMap()
    return self.config.useDirtMap
end

---Returns whether this Tile is using a brick map.
---TODO: Change the map to use any string for multi-map support.
function Tile:usesBrickMap()
    return self.config.useBrickMap
end

---Dispatches impact or explosion effects on this Tile.
---@private
---@param effects table? A table of effects to be applied on this Tile.
function Tile:dispatchEffects(effects)
    if not effects then
        return
    end
    if effects.transformTo then
        self:transformTo(effects.transformTo)
    end
    if effects.sound then
        _Game:playSound(effects.sound)
    end
    if effects.extraTime then
        self.board.level:addTime(effects.extraTime)
    end
    if effects.goldAnimation then
        self.goldAnimation = 0
    end
    if effects.goldAnimation2 then
        self.goldAnimation2 = 0
    end
    if effects.spawnIceParticles then
        -- 7 is the ice tile, 2 is the full ice stage.
        if not _Game.runtimeManager.options:getSetting("reducedParticles") then
            _Game.game:spawnParticleFragments(self:getCenterPos(), "", self.sprite, 7, 2, 4)
        end
    end
    if effects.spawnDirtParticles then
        -- 13th frame in the dual-grid system is the full tile sprite.
        if not _Game.runtimeManager.options:getSetting("reducedParticles") then
            _Game.game:spawnParticleFragments(self:getCenterPos(), "", _Game.resourceManager:getSprite("sprites/dirt.json"), 1, 13, 4)
        end
    end
end

---Impacts this Tile. Typically this is done when a chain sitting on this tile is destroyed.
function Tile:impact()
    self:dispatchEffects(self.config.onDamage)
end

---Explodes this Tile. Typically this is used when a powerup reaches this tile.
function Tile:explode()
    self:dispatchEffects(self.config.onExplode)
end

function Tile:select()
    self.selected = true
end

function Tile:unselect()
    self.selected = false
end

function Tile:isSelected()
    return self.selected
end

---Selects this Tile as a Tile that will be affected by the currently selected powerup.
---This is purely visual.
function Tile:selectAsPowerupVictim()
    self.selectedAsPowerupVictim = true
end

---Deselects this Tile as a Tile that will be affected by the currently selected powerup.
---This is purely visual.
function Tile:unselectAsPowerupVictim()
    self.selectedAsPowerupVictim = false
end

---Returns whether this Tile is a Tile that will be affected by the currently selected powerup.
---This is purely visual.
function Tile:isSelectedAsPowerupVictim()
    return self.selectedAsPowerupVictim
end

function Tile:selectSide(direction, visual)
    self.selectedSides[direction] = true
    --if visual then
    --    self.selectionArrows[direction] = true
    --end
end

function Tile:unselectSide(direction)
    self.selectedSides[direction] = false
    --self.selectionArrows[direction] = false
end

function Tile:unselectSides()
    self.selectedSides = {false, false, false, false}
    --self.selectionArrows = {false, false, false, false}
end

function Tile:isSideSelected(direction)
    return self.selectedSides[direction]
end

function Tile:areSidesSelected()
    return self.selectedSides[1] or self.selectedSides[2] or self.selectedSides[3] or self.selectedSides[4]
end

---Returns the state number from the tile spritesheet that should be drawn for this tile.
---@return integer
function Tile:getState()
    local altStyle = _Game.game.settings.goldTileStyle == "new"
    return altStyle and self.config.sprite.stateAlt or self.config.sprite.state
end

---Returns a frame index for the tiles spritesheet that should be drawn as this tile.
---@return integer
function Tile:getFrame()
    if self.config.sprite.frame == "gold" then
        return self.goldAnimation and math.floor(self.goldAnimation) + 2 or 1
    end
    return self.config.sprite.frame
end

---Fades this Tile in.
---@param delay number? If set, this Tile will start fading in after this time in seconds.
function Tile:fadeIn(delay)
    self.visible = true
    self.visibleDelay = delay
end

---Fades this Tile out.
---@param delay number? If set, this Tile will start fading in after this time in seconds.
function Tile:fadeOut(delay)
    self.visible = false
    self.visibleDelay = delay
end

---Draws this Tile on the screen.
---@param offset Vector2? If set, the offset from the actual draw position in pixels. Used for screen shake.
function Tile:draw(offset)
    local pos = self:getPos()
    if offset then
        pos = pos + offset
    end
    if self.config.sprite then
        self.sprite:draw(pos, nil, self:getState(), self:getFrame(), nil, nil, self.alpha)
    end
    if self.selected or self.selectedAsPowerupVictim then
        _DrawFillRect(pos, Vec2(14, 14), Color(0.5, 1, 0.5), 0.7)
    end

    -- Some fancy gold animation
    if _Game.game.settings.goldTileAnimation and self.goldAnimation2 then
        _DrawFillRect(pos, Vec2(14, 14), Color(1, 1, 1), _Utils.map(self.goldAnimation2, 0, 0.3, 1, 0))
        local x = _Utils.map(self.goldAnimation2, 0, 0.2, 0, 20)
        _DrawRect(pos - Vec2(x), Vec2(14, 14) + Vec2(x * 2), Color(1, 1, 1), _Utils.map(self.goldAnimation2, 0.15, 0.2, 1, 0))
    end
end

---Draws this Tile's highlight on the screen. Used to highlight tiles which will be affected when a powerup is deployed from a power.
---@param offset Vector2? If set, the offset from the actual draw position in pixels. Used for screen shake.
function Tile:drawHighlight(offset)
    local pos = self:getPos()
    if offset then
        pos = pos + offset
    end
    _DrawFillRect(pos, Vec2(14, 14), Color(1, 1, 1), 0.7)
end

return Tile