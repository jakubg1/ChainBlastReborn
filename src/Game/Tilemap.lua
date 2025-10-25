local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")

---@class Tilemap
---@overload fun(sprite, width, height):Tilemap
local Tilemap = class:derive("Tilemap")

-- Maps state topleft*1 + topright*2 + bottomleft*4 + bottomright*8 to sprite's frame number.
local FRAME_MAP = {[0] = 7, 6, 3, 4, 11, 2, 5, 14, 8, 15, 12, 1, 10, 9, 16, 13}

---Constructs a new Tilemap.
---Tilemaps are a grid which renders sprites appropriately allowing for borders between different environments.
---@param sprite Sprite The Sprite this Tilemap is represented by. It must have 16 FRAMES (not states) in total. The double grid system is used.
---@param width integer Width of the tilemap. The amount of drawn tiles is lower by 1.
---@param height integer Height of the tilemap. The amount of drawn tiles is lower by 1.
function Tilemap:new(sprite, width, height)
    self.sprite = sprite
    ---Stores whether a particular cell is enabled or disabled.
    ---The size of this array determines the size of this object, plus one cell horizontally and vertically.
    ---The array is indexed by X first.
    self.data = {}
    for x = 1, width do
        self.data[x] = {}
        for y = 1, height do
            self.data[x][y] = false
        end
    end

    self.tileSize = self.sprite:getFrameSize(1)
end

---Returns the logical width of this Tilemap (the exact number provided in the constructor).
---The actual amount of tiles is lower by 1.
---@return integer
function Tilemap:getWidth()
    return #self.data
end

---Returns the logical height of this Tilemap (the exact number provided in the constructor).
---The actual amount of tiles is lower by 1.
---@return integer
function Tilemap:getHeight()
    return #self.data[1]
end

---Sets the new cell state at the given position.
---@param x integer X position, starting from 1.
---@param y integer Y position, starting from 1.
---@param state boolean Whether the cell should be filled.
function Tilemap:setCell(x, y, state)
    assert(x >= 1 and x <= #self.data and y >= 1 and y <= #self.data[1], "Out of bounds indexing: (" .. x .. ", " .. y .. ") with size (" .. #self.data .. ", " .. #self.data[1] .. ")")
    self.data[x][y] = state
end

---Returns the frame number to be used in the given tile of this Tilemap.
---@private
---@param x integer The X coordinate of the drawn tile.
---@param y integer The Y coordinate of the drawn tile.
function Tilemap:getFrameFromPos(x, y)
    local state = 0
    -- Checks top left, top right, bottom left and bottom right respectively.
    state = state + (self.data[x][y] and 1 or 0)
    state = state + (self.data[x + 1][y] and 2 or 0)
    state = state + (self.data[x][y + 1] and 4 or 0)
    state = state + (self.data[x + 1][y + 1] and 8 or 0)
    return FRAME_MAP[state]
end

---Draws the Conjoined Sprite on the screen.
---@param pos Vector2 The position this Conjoined Sprite should be drawn on. The top left corner of the actual data tile.
function Tilemap:draw(pos)
    for i = 1, #self.data - 1 do
        for j = 1, #self.data[1] - 1 do
            self.sprite:draw(pos + Vec2(i - 1, j - 1) * self.tileSize, nil, 1, self:getFrameFromPos(i, j))
        end
    end
end

return Tilemap