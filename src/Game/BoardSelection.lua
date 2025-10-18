local Vec2 = require("src.Essentials.Vector2")
local class = require "com.class"

---Represents a single selection on the Board.
---@class BoardSelection
---@overload fun(board):BoardSelection
local BoardSelection = class:derive("BoardSelection")

---Creates a new Board Selection.
---@param board Board The board on which the selection is performed.
function BoardSelection:new(board)
    self.board = board

    self.selectedCoords = {}
    self.selectedDirections = {}
    -- It might be the case that we cross an already selected tile. In such case, this will not necessarily be the last entry in the selectedCoords table.
    self.selectingDirection = nil
end

---Begins the tile selection process by selecting the currently hovered tile.
---@param coords Vector2 The selection's starting position.
function BoardSelection:start(coords)
    local tile = self.board:getTile(coords)
    local chain = self.board:getChain(coords)
    if tile and chain and chain:canBeSelected() then
        tile:select()
        table.insert(self.selectedCoords, coords)
    end
end

---Expands the tile selection by a neighbour in the specified direction.
---@param direction integer The direction to expand the selection to. 1 is up, then clockwise.
function BoardSelection:expand(direction)
    local oppositeDirection = (direction + 1) % 4 + 1

    local prevCoords = self:getLastCoords()
    local newCoords = prevCoords + self.board.DIRECTIONS[direction]
    local tile = self.board:getTile(newCoords)
    local chain = self.board:getChain(newCoords)
    local prevTile = self.board:getTile(prevCoords)
    local prevChain = self.board:getChain(prevCoords)

    -- Back out if we can't select in this direction, or if somehow the previous tiles do not exist.
    if not tile or not chain or not prevTile or not prevChain then
        return
    end
    -- Back out if we cannot select that chain.
    if not chain:canBeSelected() then
        return
    end
    -- Back out also if we've already selected this tile from the other side.
    if tile:isSideSelected(oppositeDirection) then
        return
    end
    -- Also if we're trying to impossibly rotate the chains (for instance, straight pieces in L shape).
    if #self.selectedCoords > 1 and prevChain.rotation % 2 ~= direction % 2 and prevChain.shape == 1 then
        return
    end
    -- And finally if the color doesn't match.
    if not prevChain:matchesWithColor(chain:getColor()) then
        return
    end

    -- If all of the above conditions are satisfied, we can go on.
    tile:select()
    tile:selectSide(oppositeDirection)
    chain:rotate(oppositeDirection, true)
    prevTile:selectSide(direction, true)
    if #self.selectedCoords == 1 then
        -- If we are selecting the second tile, the first one gets rotated as well!
        prevChain:rotate(oppositeDirection, true)
    end
    table.insert(self.selectedCoords, newCoords)
    table.insert(self.selectedDirections, direction)

	self:updateHighlights()
end

---Shrinks the selection by one tile.
function BoardSelection:shrink()
    local oppositeDirection = self.selectedDirections[#self.selectedDirections]
    local direction = (oppositeDirection + 1) % 4 + 1

    local prevCoords = self:getLastCoords()
    local newCoords = prevCoords + self.board.DIRECTIONS[direction]
    local tile = self.board:getTile(newCoords)
    local chain = self.board:getChain(newCoords)
    local prevTile = self.board:getTile(prevCoords)   -- This tile will be unselected.
    local prevChain = self.board:getChain(prevCoords)

    -- Back out if we can't unselect in this direction, or if somehow the previous tiles do not exist.
    if not tile or not chain or not prevTile or not prevChain then
        return
    end

    -- If all of the above conditions are satisfied, we can go on.
    prevTile:unselectSide(direction)
    if not prevTile:areSidesSelected() then
        prevTile:unselect()
        prevChain:unrotate()
        if #self.selectedCoords == 2 then
            -- If we are unselecting the second-to-last tile, the last one gets unrotated as well!
            chain:unrotate()
        end
    end
    if tile and chain then
        tile:unselectSide(oppositeDirection)
    end
    table.remove(self.selectedCoords)
    table.remove(self.selectedDirections)

	self:updateHighlights()
end

---Ends the selection process. Processes the matches and then restores the previous chain configuration.
---@param abort boolean? If set to `true`, the selection will be aborted and no match checks will happen.
function BoardSelection:finish(abort)
    -- Unselect all tiles.
    for i, coords in ipairs(self.selectedCoords) do
        local tile = self.board:assertGetTile(coords)
        tile:unselect()
        tile:unselectSides()
    end
	-- Deploy a powerup if applicable. The powerup will always appear at the cursor position.
    if self.board.level.config.enablePowerups then
        local powerupCoords = self.selectedCoords[#self.selectedCoords]
        if powerupCoords then
            local powerupChain = self.board:getChain(powerupCoords)
            if powerupChain then
                local powerupChainGroup = powerupChain:getGroup()
                local powerup = self.board:getPowerupFromColors(self.board:countGroupColors(powerupChainGroup))
                if powerup then
                    powerupChain:setPowerup(powerup)
                end
            end
        end
    end
    -- Handle matches.
    local result = false
    if not abort then
        result = self.board:handleMatches()
    end
    if not result then
        -- The selection didn't work. Play a sound and shake the chains.
        _Game:playSound("sound_events/no.json")
        for i, coords in ipairs(self.selectedCoords) do
            local chain = self.board:getChain(coords)
            if chain then
                chain:shake(0.05)
            end
        end
    end
    -- Unselect all chains and exit the selection mode.
    self.selecting = false
    self.selectedCoords = {}
    self.selectedDirections = {}
    -- Unrotate all chains.
    for i = 1, self.board.size.x do
        for j = 1, self.board.size.y do
            local coords = Vec2(i, j)
            local chain = self.board:getChain(coords)
            if chain and not chain:isPrimed() then
                chain:unrotate()
            end
        end
    end

	self:updateHighlights()
end

---Refreshes highlight state for tiles affected by potential powerups and flashes chains if a valid match is selected.
function BoardSelection:updateHighlights()
	-- Unselect everything.
    for i = 1, self.board.size.x do
        for j = 1, self.board.size.y do
            local coords = Vec2(i, j)
            local tile = self.board:getTile(coords)
            if tile then
				tile:unselectAsPowerupVictim()
            end
        end
    end

    -- Exit if no chains are selected.
	if #self.selectedCoords == 0 then
		return
	end
    -- Flash the chains if a valid match is selected.
    if #self.selectedCoords >= 3 then
        for i, chainCoords in ipairs(self.selectedCoords) do
            self.board:getChain(chainCoords):flash(0.05, (i - 1) * 0.03)
        end
    end
    -- Exit here if powerups are disabled.
    if not self.board.level.config.enablePowerups then
        return
    end

    -- Calculate the potential powerup type.
	local powerupCoords = self.selectedCoords[#self.selectedCoords]
	local powerupChain = self.board:getChain(powerupCoords)
    if not powerupChain then
        return
    end
	local powerupChainGroup = powerupChain:getGroup()
	local powerup = self.board:getPowerupFromColors(self.board:countGroupColors(powerupChainGroup))

    -- Go through all the tiles and check which ones would be affected by that potential powerup.
    for i = 1, self.board.size.x do
        for j = 1, self.board.size.y do
            local coords = Vec2(i, j)
            local tile = self.board:getTile(coords)
            if tile then
				if powerup == "bomb" then
					if math.abs(powerupCoords.x - coords.x) <= 1 and math.abs(powerupCoords.y - coords.y) <= 1 then
						tile:selectAsPowerupVictim()
					end
                elseif powerup == "lightning" then
                    if (powerupChain.shape == 2 or powerupChain.rotation == 2) and powerupCoords.x == coords.x then
                        tile:selectAsPowerupVictim()
                    elseif (powerupChain.shape == 2 or powerupChain.rotation == 1) and powerupCoords.y == coords.y then
                        tile:selectAsPowerupVictim()
                    end
				elseif powerup == "bomb_lightning" then
					if (powerupChain.shape == 2 or powerupChain.rotation == 2) and math.abs(powerupCoords.x - coords.x) <= 1 then
						tile:selectAsPowerupVictim()
					elseif (powerupChain.shape == 2 or powerupChain.rotation == 1) and math.abs(powerupCoords.y - coords.y) <= 1 then
						tile:selectAsPowerupVictim()
					end
				end
            end
        end
    end
	-- Highlight all tiles which are constituting a valid match, too.
	for i, coords in ipairs(powerupChainGroup) do
		self.board:getTile(coords):selectAsPowerupVictim()
	end
end

---Returns a table of currently selected chains' colors as a total of each color.
---@return table
function BoardSelection:countChainColors()
	return self.board:countGroupColors(self.selectedCoords)
end

---Returns the most recently selected position.
---@param n integer? If specified, returns `n+1`-th last position.
---@return Vector2
function BoardSelection:getLastCoords(n)
    return self.selectedCoords[#self.selectedCoords - (n or 0)]
end

return BoardSelection