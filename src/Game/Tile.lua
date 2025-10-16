local class = require "com.class"

---@class Tile
---@overload fun(board, coords, type):Tile
local Tile = class:derive("Tile")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



---Constructs a Tile.
---@param board Board The Board this Tile belongs to.
---@param coords Vector2 The tile position where this Tile is on the board.
---@param type integer The tile type. Allowed: "normal", "flip" (switcheroo), "ice".
function Tile:new(board, coords, type)
    self.board = board
    self.coords = coords
    self.type = type

    self.gold = false
    self.goldAnimation = nil
    self.goldAnimation2 = nil
    self.iceLevel = 0
    if self.type == "ice" then
        self.iceLevel = 2
    end

    self.visible = false
    self.visibleDelay = nil
    self.alpha = 0

    self.selected = false
    self.selectedAsPowerupVictim = false
    self.selectedSides = {false, false, false, false}

	self.sprite = _Game.resourceManager:getSprite("sprites/tiles.json")
    self.iceBreakSound = _Game.resourceManager:getSoundEvent("sound_events/ice_break.json")
end



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



---Impacts this Tile by making it gold or removing one level of ice.
function Tile:impact()
    if self.type == "normal" then
        if not self.gold then
            self:makeGold()
        end
    elseif self.type == "flip" then
        if self.gold then
            -- Flip tiles lose their gold status if matched over them again.
            self:loseGold()
        else
            self:makeGold()
        end
    elseif self.type == "ice" then
        self:breakIceLevel()
    end
end



---Explodes this Tile by removing (evaporating) all ice and making it forcibly gold.
function Tile:explode()
    if self.type == "normal" then
        if not self.gold then
            self:makeGold()
        end
    elseif self.type == "flip" then
        -- Flip tiles are forcibly turned gold when exploded.
        if not self.gold then
            self:makeGold()
        end
    elseif self.type == "ice" then
        self:removeIce()
        self:makeGold()
    end
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



---Makes the tile gold and plays the gold tile animation.
function Tile:makeGold()
    self.gold = true
    if self.type == "normal" then
        self.goldAnimation = 0
        self.goldAnimation2 = 0
    elseif self.type == "flip" then
        self.goldAnimation2 = 0
        -- TODO: Gold animation for flip tiles
    end
end



---Removes the gold status from the tile. Used in flip tiles.
function Tile:loseGold()
    self.gold = false
    -- TODO: Gold animation for flip tiles
end



---Breaks one level of ice. Plays a sound and spawns some particles.
---If that was the last ice layer, the tile is turned into a normal tile.
function Tile:breakIceLevel()
    self.iceLevel = self.iceLevel - 1
    if self.iceLevel == 0 then
        -- If all ice is broken, convert to a normal tile.
        self.type = "normal"
    end
    self.iceBreakSound:play()
    local pos = self:getPos() + Vec2(7)
    -- 7 is the ice tile, 2 is the full ice stage.
    if not _Game.runtimeManager.options:getSetting("reducedParticles") then
        _Game.game:spawnParticleFragments(pos, "", self.sprite, 7, 2, 4)
    end
    -- Add to the timer.
    self.board.level:addTime(0.5)
end



---Removes all ice from this Tile, playing no sound nor particles.
function Tile:removeIce()
    if self.type ~= "ice" then
        return
    end
    self.iceLevel = 0
    self.type = "normal"
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



function Tile:getState()
    if self.type == "normal" then
        if self.gold then
            if _Game.game.settings.goldTileStyle == "new" then
                return 3
            end
            return 2
        end
        return 1
    elseif self.type == "flip" then
        if self.gold then
            return 5
        end
        return 4
    elseif self.type == "ice" then
        return 7
    end
end



function Tile:getFrame()
    if self.type == "normal" then
        if self.goldAnimation then
            return math.floor(self.goldAnimation) + 2
        end
        return 1
    elseif self.type == "flip" then
        return 1
    elseif self.type == "ice" then
        return self.iceLevel
    end
end



---Draws this Tile on the screen.
---@param offset Vector2? If set, the offset from the actual draw position in pixels. Used for screen shake.
function Tile:draw(offset)
    local pos = self:getPos()
    if offset then
        pos = pos + offset
    end
    self.sprite:draw(pos, nil, self:getState(), self:getFrame(), nil, nil, self.alpha)
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