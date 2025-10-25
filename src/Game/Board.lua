local class = require "com.class"

---@class Board
---@overload fun(level):Board
local Board = class:derive("Board")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local Tile = require("src.Game.Tile")
local Chain = require("src.Game.Chain")
local Bomb = require("src.Game.Bomb")
local Missile = require("src.Game.Missile")
local Tilemap = require("src.Game.Tilemap")
local BoardSelection = require("src.Game.BoardSelection")

---Constructs the Board.
---@param level Level The level instance this Board belongs to.
function Board:new(level)
    self.level = level

    self.DIRECTIONS = {
        Vec2(0, -1),
        Vec2(1, 0),
        Vec2(0, 1),
        Vec2(-1, 0)
    }

    self.size = self:getSizeFromData()
    self.pos = Vec2(159, 95) - (self.size * 7.5):ceil()

    self.tiles = {}
    for i = 1, self.size.x do
        self.tiles[i] = {}
    end

    self.chains = {}
    for i = 1, self.size.x do
        self.chains[i] = {}
    end

    self.bombs = {}

    self.playerControl = true
    self.over = false
    self.won = false
    self.hoverCoords = nil
    self.visualHoverCoords = nil
    self.mode = "select" -- `"select"` is the usual one, but can be `"bomb"` or `"lightning"` when a power is active.
    self.selection = nil
	self.lastSelectStart = nil
    self.hintTime = 0
    self.hintCoords = nil

    self.startAnimation = 0
    self.endAnimation = nil

    self.hoverSprite = _Game.resourceManager:getSprite("sprites/hover.json")
    self.hintSprite = _Game.resourceManager:getSprite("sprites/hint.json")
    self.hintPalette = _Game.resourceManager:getColorPalette("color_palettes/hint.json")
    self.backgroundSprite = _Game.resourceManager:getSprite("sprites/board_background.json")
    self.background = nil
    self.dirtLayerSprite = _Game.resourceManager:getSprite("sprites/dirt.json")
    self.dirtLayer = Tilemap(self.dirtLayerSprite, self.size.x + 2, self.size.y + 2)
    self.brickLayerSprite = _Game.resourceManager:getSprite("sprites/bricks.json")
    self.brickLayer = Tilemap(self.brickLayerSprite, self.size.x + 2, self.size.y + 2)

    self.delQueue = false

    self:initializeContents()
end



---Updates the Board.
---@param dt number Time delta in seconds.
function Board:update(dt)
    -- Start animation
    if self.startAnimation then
        self.startAnimation = self.startAnimation + dt
        if self.startAnimation >= 4 then
            self.startAnimation = nil
        end
    end

    -- End animation
    if self.endAnimation then
        self.endAnimation = self.endAnimation + dt
        if self.endAnimation >= 4 then
            self.endAnimation = nil
            self.delQueue = true
        end
    end

    -- Game control
    local fallingObjects = self:countFallingObjects()
    local shufflingObjects = self:countShufflingObjects()
    local primedObjects = self:countPrimedObjects()
    if fallingObjects > 0 or shufflingObjects > 0 or primedObjects > 0 or self.over then
        self.playerControl = false
        -- If the player was making a selection, forcibly stop it but also try submitting whatever the player might have managed to select.
        if self:isSelectionActive() then
            self.selection:finish()
            self.selection = nil
        end
    end

    if not self.playerControl and fallingObjects == 0 and shufflingObjects == 0 and primedObjects == 0 and not self.over and not self.won then
        -- Do another shot.
        self:handleMatches()
        -- We need to recalculate the object counts here because we might have just destroyed something and something started falling, etc.
        fallingObjects = self:countFallingObjects()
        shufflingObjects = self:countShufflingObjects()
        primedObjects = self:countPrimedObjects()
        if fallingObjects == 0 and shufflingObjects == 0 and primedObjects == 0 then
            -- Nothing happened, grant the control to the player.
            if self:isTargetReached() then
                self:releaseChains()
                self.level:win()
                self.won = true
            elseif not self:areMovesAvailable() then
                self:shuffle()
            else
                self.playerControl = true
                self.level.combo = 0
            end
        end
    end

    -- Tile hovering
    self.hoverCoords = nil
    if self.playerControl then
        local hoverCoords = self:getTileCoords(_MousePos)
        if self:getTile(hoverCoords) then
            self.hoverCoords = hoverCoords
        end
        if not self.hintCoords and self.mode == "select" then
            self.hintTime = self.hintTime + dt
            if self.hintTime >= 3 then
                self.hintCoords = self:getRandomMatchableChain().coords
                _Game:playSound("sound_events/hint.json")
            end
        end
    end

    -- Visual tile hover
    if self.hoverCoords then
        if self.visualHoverCoords and _Game.game.settings.smoothHoverMovement then
            self.visualHoverCoords = self.visualHoverCoords * 0.25 + self.hoverCoords * 0.75
        else
            self.visualHoverCoords = self.hoverCoords
        end
    else
        if self.visualHoverCoords then
            self.visualHoverCoords = nil
        end
    end

    -- Tile selection
    if self:isSelectionActive() then
        local lastSelectedCoords = self.selection:getLastCoords()
        if lastSelectedCoords then
            -- We are not using `self.hoverCoords` here to allow fast sweeping beyond the board boundaries. Quality of life! Yay!
            local selectionVector = self:getTileCoords(_MousePos) - lastSelectedCoords
            local direction = nil
            local length = nil
            -- Check if the selection vector is at a right angle (fully in one direction).
            if selectionVector.x == 0 then
                if selectionVector.y < 0 then
                    direction = 1
                    length = -selectionVector.y
                elseif selectionVector.y > 0 then
                    direction = 3
                    length = selectionVector.y
                end
            elseif selectionVector.y == 0 then
                if selectionVector.x < 0 then
                    direction = 4
                    length = -selectionVector.x
                elseif selectionVector.x > 0 then
                    direction = 2
                    length = selectionVector.x
                end
            end
            -- If any of the above checks have passed, we can continue.
            if direction then
                if self.hoverCoords and self.hoverCoords == self.selection:getLastCoords(length) then
                    -- We are going backwards!
                    for i = 1, length do
                        self.selection:shrink()
                    end
                else
                    for i = 1, length do
                        self.selection:expand(direction)
                    end
                end
            end
        elseif self.hoverCoords then
            self.selection:start(self.hoverCoords)
            self.lastSelectStart = self.hoverCoords
        end
    end

    -- Tiles
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local tile = self:getTile(Vec2(i, j))
            if tile then
                tile:update(dt)
            end
        end
    end

    -- Update the chains.
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local chain = self:getChain(Vec2(i, j))
            if chain then
                chain:update(dt)
            end
        end
    end

    -- After updating all of them, see which ones need to be removed from the board.
    local needToFallChains = false
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local chain = self:getChain(Vec2(i, j))
            if chain and chain.delQueue then
                -- Remove dead chains.
                self.chains[i][j] = nil
                needToFallChains = true
            end
        end
    end

    -- If any of the chains have been removed from the board, run the falling checks.
    if needToFallChains and not self.level.lost then
        self:fillHoles()
        self:fillHolesUp()
    end

    -- Bombs
    for i, bomb in ipairs(self.bombs) do
        bomb:update(dt)
    end
    _Utils.removeDeadObjects(self.bombs)

    -- Update the panic animation for chains.
    self:setChainPanicStrength(_Utils.mapc(self.level.time, 0, self.level.minCoyoteTime, 0, 1))

    -- Update dirtmap
    for x = 1, self.size.x do
        for y = 1, self.size.y do
            local tile = self:getTile(Vec2(x, y))
            if tile then
                self.dirtLayer:setCell(x + 1, y + 1, tile:usesDirtMap())
                self.brickLayer:setCell(x + 1, y + 1, tile:usesBrickMap())
            end
        end
    end
end



---Returns the position of the grid intersection pixel of a given tile's top left corner.
---For tile position, use `:getTilePos()`.
---@param coords Vector2 The tile coordinates, starting from `(1, 1)`.
---@return Vector2
function Board:getTileGridPos(coords)
	return self.pos + (coords - 1) * 15
end

---Returns the position of the top left pixel of a given tile.
---@param coords Vector2 The tile coordinates, starting from `(1, 1)`.
---@return Vector2
function Board:getTilePos(coords)
	return self:getTileGridPos(coords) + 1
end

---Returns the center position of a given tile.
---@param coords Vector2 The tile coordinates, starting from `(1, 1)`.
---@return Vector2
function Board:getTileCenterPos(coords)
    return self:getTilePos(coords) + 7
end

---Returns the 1-based coordinates of the tile laying on the given screen position.
---The function does not check for out-of-bounds coordinates, and as such can return negative or big values!
---@param pos Vector2 The onscreen position of the tile.
---@return Vector2
function Board:getTileCoords(pos)
    return ((pos - self.pos) / 15):floor() + 1
end

---Returns whether a tile exists at the given board coordinates.
---@param coords Vector2 The tile coordinates to be checked.
---@return boolean
function Board:tileExists(coords)
    return coords.x >= 1 and coords.y >= 1 and coords.x <= self.size.x and coords.y <= self.size.y and self.tiles[coords.x][coords.y] ~= nil
end

---Returns the Tile located at the given coordinates.
---If the tile is not found there, returns `nil`.
---@param coords Vector2 The tile coordinates.
---@return Tile?
function Board:getTile(coords)
    if not self:tileExists(coords) then
        return
    end
    return self.tiles[coords.x][coords.y]
end

---Returns the Tile located at the given coordinates.
---If the tile is not found there, throws an error.
---@param coords Vector2 Tile coordinates.
---@return Tile
function Board:assertGetTile(coords)
    return assert(self:getTile(coords), string.format("Attempt to get a tile at %s, but no tile was found :(", coords))
end

---Returns the Chain (or any board item, including boxes, etc.) located at the given coordinates.
---@param coords Vector2 The tile coordinates.
---@return Chain?
function Board:getChain(coords)
    if not self:tileExists(coords) then
        return
    end
    return self.chains[coords.x][coords.y]
end

---Returns the Chain (or any board item, including boxes, etc.) located at the given coordinates.
---@param coords Vector2 Tile coordinates.
---@return Chain
function Board:assertGetChain(coords)
    return assert(self:getChain(coords), string.format("Attempt to get a chain at %s, but no chain was found :(", coords))
end

---Impacts the tile/object at the provided coordinates, for example by damaging a crate or destroying a chain (and creating gold under it).
---@param coords Vector2 Tile coordinates.
function Board:impactTile(coords)
    local tile = self:assertGetTile(coords)
    local chain = self:getChain(coords)
    if chain then
        chain:damage()
        if chain:isDead() then
            tile:impact()
        end
    else
        tile:impact()
    end
end

---Returns the board size from level data.
---@return Vector2
function Board:getSizeFromData()
    local data = self.level.config
    return Vec2(#data.layout[1], #data.layout)
end

---Returns the Cell data from the given coordinates, as defined in the level config file. Returns `nil` if no tile is there.
---@param coords Vector2 The tile coordinates.
---@return table?
function Board:getCellData(coords)
    local data = self.level.config
    local key = data.layout[coords.y]:sub(coords.x, coords.x)
    return data.key[key]
end



---Makes the Chain located at the given coordinates fall to the new position.
---@param coords Vector2 The tile coordinates.
---@param newCoords Vector2 The target position for this Chain to fall to. The X component is ignored.
---@param delay number? If specified, the chain will wait this amount of seconds before starting to fall.
function Board:fallChain(coords, newCoords, delay)
    local chain = self:getChain(coords)
    assert(chain, string.format("Whoops! You want to fall air? (falling from %s to %s)", coords, newCoords))
    chain:fallTo(newCoords, delay)
    self.chains[coords.x][coords.y] = nil
    assert(not self.chains[newCoords.x][newCoords.y], string.format("Whoops! Head-on fall collision (falling from %s to %s)", coords, newCoords))
    self.chains[newCoords.x][newCoords.y] = chain
end



---Makes the Chain located at the given coordinates move to the new position with a shuffle animation.
---@param chain Chain The chain that needs to be shuffled.
---@param newCoords Vector2 The target position for this Chain to fall to. The X component is ignored.
function Board:shuffleChain(chain, newCoords)
    chain:shuffleTo(newCoords)
    self.chains[newCoords.x][newCoords.y] = chain
end



---Makes the Chain not attached to the Board fall to the new position and registers it on the board.
---@param chain Chain The chain that needs to be added.
---@param coords Vector2 The target position for this Chain to fall to. The X component is ignored.
---@param delay number? If specified, the chain will wait this amount of seconds before starting to fall.
function Board:fallNewChain(chain, coords, delay)
    chain:fallTo(coords, delay)
    assert(not self.chains[coords.x][coords.y], string.format("Whoops! Head-on fall collision (falling new to %s)", coords))
    self.chains[coords.x][coords.y] = chain
end



---Fills the board with initial tiles, chains and objects for the first time, and generates the background.
function Board:initializeContents()
    -- Generate the tiles and background data first.
    self.background = Tilemap(self.backgroundSprite, self.size.x + 2, self.size.y + 2)
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local cellData = self:getCellData(coords)
            if cellData and cellData.tile then
                self.tiles[i][j] = Tile(self, coords, cellData.tile.type)
                self.tiles[i][j]:fadeIn((i + j + 10) * 0.12)
                self.background:setCell(i + 1, j + 1, true)
            end
        end
    end

    -- We will fill the board repeatedly until no premade matches exist.
    repeat
        local specialSpawnPositions = {}
        for i = 1, self.size.x do
            for j = 1, self.size.y do
                local coords = Vec2(i, j)
                local cellData = self:getCellData(coords)
                if cellData and cellData.tile and self.tiles[i][j]:hostsChain() then
                    local chainType = cellData.chain and cellData.chain.type or self.level:getRandomSpawn(true)
                    self.chains[i][j] = Chain(self, coords, chainType)
                    if cellData.chain then
                        if cellData.chain.health then
                            self.chains[i][j].health = cellData.chain.health
                        end
                    end
                    table.insert(specialSpawnPositions, coords)
                end
            end
        end
        -- Distribute special spawns.
        if self.level.config.extraSpawns then
            for i, spawn in ipairs(self.level.config.extraSpawns) do
                for j = 1, spawn.amount do
                    local coords = table.remove(specialSpawnPositions, math.random(1, #specialSpawnPositions))
                    self.chains[coords.x][coords.y] = Chain(self, coords, spawn.type)
                end
            end
        end
    until #self:getMatchGroups() == 0 and self:areMovesAvailable()

    -- Move all the chains up and animate them accordingly.
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain then
                chain.visualCoords = coords - Vec2(0, 11)
                chain:fallTo(coords, 2.5 + (i - 1) * 0.1)
            end
        end
    end

    -- Play a sound.
    _Game:playSound("sound_events/board_start.json")
end



---Returns `true` if the player is currently selecting some chains.
---@return boolean
function Board:isSelectionActive()
    return self.selection ~= nil
end



---Returns the number of board objects currently falling.
---@return integer
function Board:countFallingObjects()
    local count = 0
    for x = 1, self.size.x do
        for y = 1, self.size.y do
            local chain = self:getChain(Vec2(x, y))
            if chain and chain:isFalling() then
                count = count + 1
            end
        end
    end
    return count
end

---Returns the number of board objects currently being shuffled.
---@return integer
function Board:countShufflingObjects()
    local count = 0
    for x = 1, self.size.x do
        for y = 1, self.size.y do
            local chain = self:getChain(Vec2(x, y))
            if chain and chain:isShuffling() then
                count = count + 1
            end
        end
    end
    return count
end

---Returns the number of primed board objects.
---@return integer
function Board:countPrimedObjects()
    local count = 0
    for x = 1, self.size.x do
        for y = 1, self.size.y do
            local chain = self:getChain(Vec2(x, y))
            if chain and chain:isPrimed() then
                count = count + 1
            end
        end
    end
    return count
end



---Returns a table of chain colors present in the provided list of chain coordinates.
---@param group table A list of coordinates to be checked for.
---@return table
function Board:countGroupColors(group)
	local colors = {[0] = 0, [1] = 0, [2] = 0, [3] = 0}
	for i, coords in ipairs(group) do
		local color = self:getChain(coords):getColor()
		colors[color] = colors[color] and colors[color] + 1 or 1
	end
	return colors
end



---Returns the powerup ID that should be spawned based on the list of colors provided. If no powerup should be spawned, returns `nil`.
---@param colors table The table with three indices, depicting blue, red and yellow chains respectively.
---@return string?
function Board:getPowerupFromColors(colors)
	-- If there are wilds, then check how many colors we have.
	-- If there's just one color, add to that color.
	-- If there are more colors, combine powerups or even make very destructive combinations.
	if colors[0] > 0 then
		local colorsInPlay = {}
		for i = 1, 3 do
			if colors[i] > 0 then
				table.insert(colorsInPlay, i)
			end
		end
		if #colorsInPlay == 1 then
			colors[colorsInPlay[1]] = colors[colorsInPlay[1]] + colors[0]
			colors[0] = 0
		end
	end
	if colors[1] >= 4 then
		return "bomb"
	elseif colors[2] >= 4 then
		return "lightning"
	elseif colors[3] >= 4 then
		return "missile"
	elseif colors[0] + colors[1] + colors[2] + colors[3] > 4 then
		if colors[1] > 0 and colors[2] > 0 and colors[3] == 0 then
			return "bomb_lightning"
		elseif colors[1] > 0 and colors[2] == 0 and colors[3] > 0 then
			return "missile_bomb"
		elseif colors[1] == 0 and colors[2] > 0 and colors[3] > 0 then
			return "missile_lightning"
		elseif colors[1] > 0 and colors[2] > 0 and colors[3] > 0 then
			return "missile_bomb_lightning"
		end
	end
	return nil
end



---Returns a list of all currently connected groups of 3 or more chains in the form of coordinate lists.
---@return table
function Board:getMatchGroups()
    -- Store the groups themselves.
    local groups = {}
    -- All coordinates that have been used up already end up in this cumulative list too.
    local excludedCoords = {}

    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain then
                local group = chain:getGroup()
                -- If the group has at least three pieces, start storing.
                if #group >= 3 then
                    local duplicate = false
                    -- 2 in 1: check for duplicates, and add the coordinates to the list so they can't be used up later.
                    for k, currentCoords in ipairs(group) do
                        if _Utils.isValueInTable(excludedCoords, currentCoords) then
                            duplicate = true
                            break
                        end
                        table.insert(excludedCoords, currentCoords)
                    end
                    if not duplicate then
                        table.insert(groups, group)
                    end
                end
            end
        end
    end

    return groups
end



---Rearranges the match group, depending on the starting position and neighborhood.
---For example, `{(1, 4), (1, 5), (1, 6), (2, 7), (2, 6), (2, 5), (1, 7)}` becomes
---`{{(1, 4)}, {(1, 5)}, {(1, 6), (2, 5)}, {(2, 6), (1, 7)}, {(2, 7)}}`.
---if `noSplitToSubgroups` is set to `true`, the result will be
---`{{(1, 4), (1, 5), (1, 6), (2, 5), (2, 6), (1, 7), (2, 7)}}`. (yes, it's double nested!!!)
---@param group table The match group to be rearranged.
---@param startFrom Vector2? If present, the position to start from. By default, the first position in the group.
---@param noSplitToSubgroups boolean? If set, the order will be merged into one table, which is still nested inside of an outer table!
---@return table
function Board:rearrangeMatchGroup(group, startFrom, noSplitToSubgroups)
	startFrom = startFrom or group[1]
	local remaining = {}
	-- Copy the table
	for i, coords in ipairs(group) do
		if coords ~= startFrom then
			table.insert(remaining, coords)
		end
	end

	local result = {{startFrom}}
	while #remaining > 0 do
		local subgroup = noSplitToSubgroups and result[1] or {}
		-- We're checking the last subgroup for neighbors.
		for i, coords in ipairs(result[#result]) do
			for j = #remaining, 1, -1 do
				for k = 1, 4 do
					if remaining[j] == coords + self.DIRECTIONS[k] then
						table.insert(subgroup, remaining[j])
						table.remove(remaining, j)
					end
				end
			end
		end
		if not noSplitToSubgroups then
			table.insert(result, subgroup)
		end
	end
	return result
end



---Checks for all groups of 3 chains or more on the board and destroys them, granting points, increasing combo, etc.
---Returns `true` if a match has been found, `false` otherwise.
---@return boolean
function Board:handleMatches()
    local matchGroups = self:getMatchGroups()
    if #matchGroups == 0 then
        return false
    end

    self.level:addCombo()
    _Vars:set("combo", self.level.combo)
    _Vars:set("multiplier", self.level.multiplier)
    _Game:playSound("sound_events/combo.json")
    self:resetHint()
    self.level:startTimer()

    for i, match in ipairs(matchGroups) do
		local colors = self:countGroupColors(match)
        local modifiedMatch = self:rearrangeMatchGroup(match, self.lastSelectStart, true)
        for j, group in ipairs(modifiedMatch) do
            local playerMade = _Utils.isValueInTable(group, self.lastSelectStart)
            local powerColor = nil
            -- If there is only one color in a match, use it.
            -- Otherwise, treat this as a wild match (color 0 - neutral).
            for color, amount in pairs(colors) do
                if amount > 0 then
                    if not powerColor then
                        powerColor = color
                    else
                        powerColor = 0
                    end
                end
            end
            -- Increment, reset or let the color combo as it is based on the current power color and whether the match was player-made.
            -- 0 (wild/neutral) is excluded from the color combo.
            -- Non player-made bad power color matches will not reset the color combo.
            if self.level.powerColor ~= 0 then
                if powerColor == 0 or self.level.powerColor == powerColor then
                    --self.level.powerCombo = self.level.powerCombo + 1
                elseif playerMade then
                    --self.level.powerCombo = 0
                end
            end
            --_Debug.console:print(tostring(self.level.powerCombo))
            for k, coords in ipairs(group) do
                local tile = self:assertGetTile(coords)
                local chain = self:assertGetChain(coords)
                local delay = 0 --0.05
                chain:destroy((k - 1) * delay)
                -- Old bomb meter stuff
                --if tile.gold then  -- (DEPRECATED: now it would be something along the lines of `tile:chargesPower()`)
                --    self.level:addToBombMeter(1)
                --end
                -- New (power meter)
                if not self.level:isPowerFull() or self.level.powerColor == 0 then
                    self.level:addToPowerMeter(self.level.combo > 1 and 2 or 1, powerColor or 0, playerMade)
                    if self.level.powerColor == chain:getColor() or (not playerMade and self.level.powerColor == 0) then
                        chain:spawnPowerParticles(9)
                    else
                        chain:spawnPowerParticles(3)
                    end
                end
                tile:impact()
                -- Remove all adjacent crates.
                for l = 1, 4 do
                    local adjChain = chain:getNeighborChain(l)
                    if adjChain then
                        adjChain:sideImpact()
                    end
                end
            end
        end
        self.lastSelectStart = nil
        self.level:addToMultiplier(#match * 0.05)
        local multiplier = (self.level.combo * (self.level.combo + 1)) / 2 * self.level.multiplier
        self.level:addScore((#match - 2) * 100 * multiplier)
        if #match > 3 then
            --self.level:addTime(#match - 3)
        end
        self.level:capTimerAtZero()
        self.level.largestGroup = math.max(self.level.largestGroup, #match)
        _Game:playSound("sound_events/match.json")
        -- Shake the screen on combos.
        _Game.game:shakeScreen(self.level.combo * 1, nil, 20, 0.15)

		-- Add a powerup only if it's not us who have matched these chains (combo).
        -- Powerups on user-made matches are dispatched in `:finishSelection()`.
		if self.level.config.enablePowerups and self.level.combo > 1 then
            local powerup = self:getPowerupFromColors(colors)
			local powerupChain = self:getChain(modifiedMatch[#modifiedMatch][#modifiedMatch[#modifiedMatch]])
            if powerup and powerupChain then
			    powerupChain:setPowerup(powerup)
            end
		end
    end

    if #matchGroups > 1 then
        print(string.format("Multi-Match x%s!", #matchGroups))
    end
    _Vars:unset("combo")
    _Vars:unset("multiplier")

    return true
end



---Resets the hint coordinates and timer.
function Board:resetHint()
    self.hintCoords = nil
    self.hintTime = 0
end



---Triggers falling all chains on the board to their lowest possible spots, filling any gaps in between.
function Board:fillHoles()
    -- Iterate over columns, starting from the bottom.
    for i = 1, self.size.x do
        local update = true
        -- Check if the column has any stuff that's pending destruction. If so, don't fill it.
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain and chain:isPrimed() then
                update = false
                break
            end
        end
        if update then
            for j = self.size.y, 0, -1 do
                local coords = Vec2(i, j)
                local tile = self:getTile(coords)
                -- If there is an empty space to be filled, start scanning upwards for any possible objects to fall down here.
                if tile and tile:hostsChain() and not self:getChain(coords) then
                    for k = j - 1, 0, -1 do
                        local seekCoords = Vec2(i, k)
                        local chain = self:getChain(seekCoords)
                        if chain and chain:canFall() then
                            self:fallChain(seekCoords, coords)
                            break
                        end
                    end
                end
            end
        end
    end
end



---Spawns chains falling from the top of the screen onto the board on all empty tiles.
---Note that this function does NOT check whether there's anything above the empty tiles.
function Board:fillHolesUp()
    -- Iterate over columns, starting from the bottom.
    for i = 1, self.size.x do
        local update = true
        -- Check if the column has any stuff that's pending destruction. If so, don't fill it.
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain and chain:isPrimed() then
                update = false
                break
            end
        end
        if update then
            local chainsPlaced = 0
            for j = self.size.y, 0, -1 do
                local coords = Vec2(i, j)
                local tile = self:getTile(coords)
                local chain = self:getChain(coords)
                if tile and tile:hostsChain() and not chain then
                    local newChain = Chain(self, Vec2(coords.x, -((13 - self.size.y) / 2) - chainsPlaced), self.level:getRandomSpawn(false))
                    self:fallNewChain(newChain, coords)
                    chainsPlaced = chainsPlaced + 1
                end
            end
        end
    end
end



---Spawns a bomb which will explode at the given location.
---@param targetCoords Vector2 The position the Bomb will explode at.
function Board:spawnBomb(targetCoords)
    table.insert(self.bombs, Bomb(self, targetCoords))
end



---Explodes a Tile at given coordinates and destroys the Chain that is on it.
---@param coords Vector2 The coordinates of the exploded chain.
function Board:explodeChain(coords)
    local tile = self:getTile(coords)
    if tile then
        tile:explode()
        local chain = self:getChain(coords)
        if chain and not chain.shuffleTarget and not chain.fallTarget then
            chain:destroy()
            self.level:addScore(100)
        end
    end
end



---Creates an explosion which destroys objects in a 3x3 area centered around the given coordinates.
---@param coords Vector2 The coordinates of the explosion center.
function Board:explodeBomb(coords)
    for i = -1, 1 do
        for j = -1, 1 do
            self:explodeChain(coords + Vec2(i, j))
        end
    end
    local pos = self:getTileCenterPos(coords)
	_Game.game:spawnParticles("power_bomb", pos)
    _Game:playSound("sound_events/explosion2.json")
    _Game.game:shakeScreen(9, nil, 35, 0.35)
    self.level.background:flash(0.5, 0.35)
end



---Creates a lightning which destroys objects in a horizontal row centered around the given coordinates.
---@param coords Vector2 The coordinates of the lightning center.
---@param horizontal boolean Whether the lightning should strike horizontally.
---@param vertical boolean Whether the lightning should strike vertically.
function Board:explodeLightning(coords, horizontal, vertical)
    if horizontal then
        local left, right = self:getHorizontalLightningRange(coords.x, coords.y)
        for i = left, right do
            self:explodeChain(Vec2(i, coords.y))
        end
        local p1 = self:getTileCenterPos(Vec2(left, coords.y))
        local p2 = self:getTileCenterPos(Vec2(right, coords.y))
        _Game.game:spawnParticles("power_lightning", p1, p2)
    end
    if vertical then
        local top, bottom = self:getVerticalLightningRange(coords.x, coords.y)
        for i = top, bottom do
            self:explodeChain(Vec2(coords.x, i))
        end
        local p1 = self:getTileCenterPos(Vec2(coords.x, top))
        local p2 = self:getTileCenterPos(Vec2(coords.x, bottom))
        _Game.game:spawnParticles("power_lightning", p1, p2)
    end
    _Game:playSound("sound_events/powerup_lightning.json")
    _Game.game:shakeScreen(9, nil, 15, 0.25)
    self.level.background:flash(0.5, 0.35)
end

---Returns whether the tile at the given coordinates blocks lightning.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@return boolean
function Board:tileBlocksLightning(x, y)
    local tile = self:getTile(Vec2(x, y))
    return tile and tile:blocksLightning() or false
end

---Returns the first and last X coordinate the lightning strike will span.
---If the lightning reaches THE EDGE!!!!! THIS IS THE FINAL CHALLENGE O- of the board, the returned coordinates can go 1 tile outside the board.
---@param x integer X coordinate of the lightning initiation.
---@param y integer Y coordinate of the lightning initiation.
---@return integer, integer
function Board:getHorizontalLightningRange(x, y)
    local left, right = x - 1, x + 1
    while left > 0 and not self:tileBlocksLightning(left, y) do
        left = left - 1
    end
    while right <= self.size.x and not self:tileBlocksLightning(right, y) do
        right = right + 1
    end
    return left, right
end

---Returns the first and last Y coordinate the lightning strike will span.
---If the lightning reaches the edge of the board, the returned coordinates can go 1 tile outside the board.
---@param x integer X coordinate of the lightning initiation.
---@param y integer Y coordinate of the lightning initiation.
---@return integer, integer
function Board:getVerticalLightningRange(x, y)
    local top, bottom = y - 1, y + 1
    while top > 0 and not self:tileBlocksLightning(x, top) do
        top = top - 1
    end
    while bottom <= self.size.y and not self:tileBlocksLightning(x, bottom) do
        bottom = bottom + 1
    end
    return top, bottom
end



---Spawns a Missile on the given tile coordinates, that will move towards the specified target.
---@param coords Vector2 The coordinates of a tile the Missile will spawn on.
---@param targetCoords Vector2? The target coordinates the Missile will go towards. If not specified, the tile will be selected automatically.
function Board:spawnMissile(coords, targetCoords)
    if not targetCoords then
        targetCoords = self:getRandomNonGoldTileCoords()
    end
    table.insert(self.bombs, Missile(self, coords, targetCoords))
end



---Returns whether there are any moves available on the board.
---@return boolean
function Board:areMovesAvailable()
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain and chain:canMakeMatch() then
                return true
            end
        end
    end
    return false
end



---Shuffles all chains on the board.
function Board:shuffle()
    local coordsList = {}
    local chains = {}

    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain and chain:canBeShuffled() then
                table.insert(coordsList, coords)
                table.insert(chains, chain)
            end
        end
    end

    repeat
        local shuffledCoords = {}
        for i, coords in ipairs(coordsList) do
            table.insert(shuffledCoords, love.math.random(1, #shuffledCoords + 1), coords)
        end

        for i = 1, #shuffledCoords do
            local coords = shuffledCoords[i]
            local chain = chains[i]
            self:shuffleChain(chain, coords)
        end
    until self:areMovesAvailable()

    _Game:playSound("sound_events/shuffle.json")
end



---Returns `true` if all tiles on the board are gold (or if `forcedWin` on the level is set).
---@return boolean
function Board:isTargetReached()
    if self.level.forcedWin then
        return true
    end
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile and tile:preventsWin() then
                return false
            end
        end
    end
    return true
end



---Returns coordinates of a random tile on the board that is not gold.
---If all tiles are gold, returns `nil`.
---@param excludedCoords table? A list of excluded coordinates (Vector2's) which are guaranteed to not be returned by this function.
---@return Vector2?
function Board:getRandomNonGoldTileCoords(excludedCoords)
    local tiles = {}
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            if not excludedCoords or not _Utils.isValueInTable(excludedCoords, coords) then
                local tile = self:getTile(coords)
                if tile and tile:preventsWin() then
                    table.insert(tiles, coords)
                end
            end
        end
    end
    if #tiles == 0 then
        return
    end
    return tiles[love.math.random(#tiles)]
end

---Returns coordinates of a random rock on the board.
---If there are no rocks, returns `nil`.
---@param excludedCoords table? A list of excluded coordinates (Vector2's) which are guaranteed to not be returned by this function.
---@return Vector2?
function Board:getRandomRockCoords(excludedCoords)
    local tiles = {}
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            if not excludedCoords or not _Utils.isValueInTable(excludedCoords, coords) then
                local chain = self:getChain(coords)
                if chain and chain.type == "rock" then
                    table.insert(tiles, coords)
                end
            end
        end
    end
    if #tiles == 0 then
        return
    end
    return tiles[love.math.random(#tiles)]
end

---Returns coordinates of a random tile on the board.
---@param excludedCoords table? A list of excluded coordinates (Vector2's) which are guaranteed to not be returned by this function.
---@return Vector2
function Board:getRandomTileCoords(excludedCoords)
    local tiles = {}
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            if not excludedCoords or not _Utils.isValueInTable(excludedCoords, coords) then
                local tile = self:getTile(coords)
                if tile then
                    table.insert(tiles, coords)
                end
            end
        end
    end
    return tiles[love.math.random(#tiles)]
end

---Returns the coordinates of the next laser strike.
---@return Vector2
function Board:getRandomLaserTarget()
    -- First, the game looks for rocks. Then for any non-gold tile, and finally, any tile at all.
    return self:getRandomRockCoords() or self:getRandomNonGoldTileCoords() or self:getRandomTileCoords()
end



---Returns a random chain on the board that can make a match.
---If no chains can make a match, returns `nil`.
---@return Chain?
function Board:getRandomMatchableChain()
    local chains = {}
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain and chain:canMakeMatch() then
                table.insert(chains, chain)
            end
        end
    end
    if #chains == 0 then
        return
    end
    return chains[love.math.random(#chains)]
end



---Releases all chains from the board as the level complete animation.
function Board:releaseChains()
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain then
                chain:release()
            end
        end
    end
end



---Sets the panic animation strength for all board objects. This should be used primarily when losing a level.
function Board:setChainPanicStrength(strength)
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local chain = self:getChain(Vec2(i, j))
            if chain then
                chain:setPanicStrength(strength)
            end
        end
    end
end

---Shakes all the chains slightly for the provided duration.
---@param duration number The duration of the shake in seconds.
function Board:shakeChains(duration)
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local chain = self:getChain(Vec2(i, j))
            if chain then
                chain:shake(duration)
            end
        end
    end
end



---Destroys all chains on the board and plays an explosion sound.
function Board:nukeEverything()
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local chain = self:getChain(coords)
            if chain then
                chain:destroy()
            end
        end
    end
    self.hintCoords = nil
    _Game:playSound("sound_events/explosion.json")
end



---Starts the disappearing animation of this Board.
---The board will be queued for deletion after the animation is complete.
function Board:startEndAnimation()
    self.endAnimation = 0
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local coords = Vec2(i, j)
            local tile = self:getTile(coords)
            if tile then
                tile:fadeOut((i + j - 2) * 0.12)
            end
        end
    end
    _Game:playSound("sound_events/board_end.json")
end



---Draws the Board.
function Board:draw()
    local offset = _Game.game.screenShakeTotal

    self:drawBackground()
    self:drawGrid()
    -- Tiles
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local tile = self:getTile(Vec2(i, j))
            if tile then
                tile:draw(offset)
            end
        end
    end
    -- Dirt and walls
    if self.startAnimation then
        self:setDiamondStencil(self.startAnimation * 100)
    elseif self.endAnimation then
        self:setDiamondStencil(math.max(self.endAnimation - 2, 0) * 100, true)
    end
    self.dirtLayer:draw(self.pos - 7 + offset)
    self.brickLayer:draw(self.pos - 7 + offset)
    self:resetStencil()

    self:drawObjects()
    self:drawTileHighlights()
    self:drawHint()
    self:drawCursor()
end

---Draws the board background.
function Board:drawBackground()
    if not self.background then
        return
    end
    local offset = _Game.game.screenShakeTotal
    if self.startAnimation then
        self:setDiamondStencil(self.startAnimation * 100)
    elseif self.endAnimation then
        self:setDiamondStencil(math.max(self.endAnimation - 2, 0) * 100, true)
    end
    self.background:draw(self.pos - 7 + offset)
    self:resetStencil()
end

---Draws the board grid.
function Board:drawGrid()
    local offset = _Game.game.screenShakeTotal
	local lineColor = Color(0.5, 0.5, 0.7)
    local lineShadowColor = Color(0, 0, 0)

    if self.startAnimation then
        self:setDiamondStencil(math.max(self.startAnimation - 0.3, 0) * 100)
    elseif self.endAnimation then
        self:setDiamondStencil(math.max(self.endAnimation - 1.7, 0) * 100, true)
    end
    for i = 1, 2 do
        -- Horizontal
        for y = 1, self.size.y + 1 do
            -- Chunks
            for x = 1, self.size.x do
                if self:tileExists(Vec2(x, y - 1)) or self:tileExists(Vec2(x, y)) then
                    if i == 1 then
                        _DrawLine(self:getTileGridPos(Vec2(x, y)) + 1 + offset, self:getTileGridPos(Vec2(x + 1, y)) + 1 + offset, lineShadowColor, 0.5)
                    else
                        _DrawLine(self:getTileGridPos(Vec2(x, y)) + offset, self:getTileGridPos(Vec2(x + 1, y)) + offset, lineColor)
                    end
                end
            end
        end

        -- Vertical
        for x = 1, self.size.x + 1 do
            -- Chunks
            for y = 1, self.size.y do
                if self:tileExists(Vec2(x - 1, y)) or self:tileExists(Vec2(x, y)) then
                    if i == 1 then
                        _DrawLine(self:getTileGridPos(Vec2(x, y)) + 1 + offset, self:getTileGridPos(Vec2(x, y + 1)) + 1 + offset, lineShadowColor, 0.5)
                    else
                        _DrawLine(self:getTileGridPos(Vec2(x, y)) + offset, self:getTileGridPos(Vec2(x, y + 1)) + offset, lineColor)
                    end
                end
            end
        end
    end
    self:resetStencil()
end

---Draws all board objects on the screen.
function Board:drawObjects()
    local offset = _Game.game.screenShakeTotal
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local chain = self:getChain(Vec2(i, j))
            if chain then
                chain:draw(offset)
            end
        end
    end
end

---Draws tile highlights.
---The tile highlights show up when a powerup is active and the player is choosing its deployment position.
function Board:drawTileHighlights()
    local offset = _Game.game.screenShakeTotal
    for i = 1, self.size.x do
        for j = 1, self.size.y do
            local highlighted = false
            if self.hoverCoords then
                if self.mode == "bomb" then
                    highlighted = math.abs(self.hoverCoords.x - i) <= 1 and math.abs(self.hoverCoords.y - j) <= 1
                elseif self.mode == "lightning" then
                    local hoveredTile = self:getTile(self.hoverCoords)
                    if hoveredTile and not hoveredTile:blocksLightning() then
                        local left, right = self:getHorizontalLightningRange(self.hoverCoords.x, self.hoverCoords.y)
                        local top, bottom = self:getVerticalLightningRange(self.hoverCoords.x, self.hoverCoords.y)
                        highlighted = (i == self.hoverCoords.x and j >= top and j <= bottom) or (j == self.hoverCoords.y and i >= left and i <= right)
                    end
                end
            end
            if highlighted then
                local coords = Vec2(i, j)
                local tile = self:getTile(coords)
                if tile then
                    tile:drawHighlight(offset)
                end
            end
        end
    end
end

---Draws the hint indicator, if it is currently present.
function Board:drawHint()
    if not self.hintCoords then
        return
    end
    local offset = _Game.game.screenShakeTotal
    local pos = self:getTilePos(self.hintCoords) - 2 + offset
    local frame = math.floor((_TotalTime * 15) % 10) + 1
    local color = self.hintPalette:getColor(_TotalTime * 60)
    self.hintSprite:draw(pos, nil, 1, frame, nil, color)
end

---Draws the cursor at the currently hovered tile position.
function Board:drawCursor()
    if not self.visualHoverCoords then
        return
    end
    local offset = _Game.game.screenShakeTotal
    local pos = self:getTilePos(self.visualHoverCoords) - 5 + offset
    local frame = math.floor(math.sin(_TotalTime * 3) * 2 + 2) + 1
    self.hoverSprite:draw(pos, nil, 1, frame)
end



---Sets the diamond stencil for drawing.
---Anything that will be drawn from this point will be invisible beyond the diamond area centered on the board's center position.
---@param size number The diamond size, in pixels.
---@param inverse boolean? If set, only the pixels OUTSIDE the diamond area will be drawn.
function Board:setDiamondStencil(size, inverse)
    -- Make a polygon: determine all four corners first
    local centerPos = self:getTileGridPos(self.size / 2 + 1)
    local angle = 0
    local p1 = centerPos + Vec2(0, -size):rotate(angle)
    local p2 = centerPos + Vec2(size, 0):rotate(angle)
    local p3 = centerPos + Vec2(0, size):rotate(angle)
    local p4 = centerPos + Vec2(-size, 0):rotate(angle)
    -- Mark all pixels within the polygon with value of 1.
    love.graphics.stencil(function()
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)
    end, "replace", 1)
    -- Mark only these pixels as the pixels which can be affected.
    love.graphics.setStencilTest("equal", inverse and 0 or 1)
end



---Resets the stencil set in `:setDiamondStencil()`.
function Board:resetStencil()
    love.graphics.setStencilTest()
end



---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Board:mousepressed(x, y, button)
    if button == 1 then
        if self.hoverCoords then
            if self.mode == "select" then
                if self:getChain(self.hoverCoords) then
                    self.selection = BoardSelection(self)
                end
            elseif self.mode == "bomb" then
                if self:getTile(self.hoverCoords) then
                    self:explodeBomb(self.hoverCoords)
                    self.level.ui:shootLaserFromPowerCrystal(self:getTileCenterPos(self.hoverCoords))
                    self.level:resetPowerMeter()
                    self.level:capTimerAtZero()
                    self:resetHint()
                    self.mode = "select"
                end
            elseif self.mode == "lightning" then
                if self:getChain(self.hoverCoords) then
                    self:explodeLightning(self.hoverCoords, true, true)
                    self.level.ui:shootLaserFromPowerCrystal(self:getTileCenterPos(self.hoverCoords))
                    self.level:resetPowerMeter()
                    self.level:capTimerAtZero()
                    self:resetHint()
                    self.mode = "select"
                end
            end
        end
    elseif button == 2 then
        if self.playerControl then
            if self:isSelectionActive() then
                self.selection:finish(true)
                self.selection = nil
            elseif self.mode == "select" then
                -- If a power can be activated, set the mode to that power.
                local powerMode = self.level:getPowerMode()
                if powerMode then
                    if powerMode == "laser" then
                        self.level:spawnLasers(6)
                        self.level:resetPowerMeter()
                        self.level:capTimerAtZero()
                        self:resetHint()
                    else
                        self.mode = powerMode
                        _Game:playSound("sound_events/power_activate.json")
                    end
                else
                    _Game:playSound("sound_events/no.json")
                end
            else
                -- Cancel the power if we were in a power mode.
                self.mode = "select"
            end
        end
    end
end



---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function Board:mousereleased(x, y, button)
	if button == 1 then
        if self:isSelectionActive() then
            self.selection:finish()
            self.selection = nil
        end
    end
end



return Board