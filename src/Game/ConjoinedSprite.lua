local class = require "com.class"

---@class ConjoinedSprite
---@overload fun(sprite, width, height):ConjoinedSprite
local ConjoinedSprite = class:derive("ConjoinedSprite")

local Vec2 = require("src.Essentials.Vector2")

---Constructs a new Conjoined Sprite.
---Conjoined Sprites are a series of Sprites arranged in a grid, where borders matter.
---@param sprite Sprite The Sprite this Conjoined Sprite is made of. It must have 64 states in total, as following:
--- - States 1-16: Left top quadrant. 1 - nothing, +1 - left, +2 - top, +4 - top-left corner, +8 - middle.
--- - States 17-32: Right top quadrant. 17 - nothing, +1 - right, +2 - top, +4 - top-right corner, +8 - middle.
--- - States 33-48: Left bottom quadrant. 33 - nothing, +1 - left, +2 - bottom, +4 - bottom-left corner, +8 - middle.
--- - States 49-64: Right bottom quadrant. 49 - nothing, +1 - right, +2 - bottom, +4 - bottom-right corner, +8 - middle.
---
--- All states from each group must have the same size. Group pairs 1+3 and 2+4 must have common width, while group pairs 1+2 and 3+4 must have common height.
---@param width integer Width of the data table.
---@param height integer Height of the data table.
---Whether a particular cell is enabled or disabled. The size of this array will determine the size of this object, plus two cells horizontally and vertically.
function ConjoinedSprite:new(sprite, width, height)
    self.sprite = sprite
    self.data = {}
    for x = 1, width do
        self.data[x] = {}
        for y = 1, height do
            self.data[x][y] = false
        end
    end

    self.sx1 = self.sprite:getFrameSize(1).x
    self.sx2 = self.sprite:getFrameSize(17).x
    self.sy1 = self.sprite:getFrameSize(1).y
    self.sy2 = self.sprite:getFrameSize(33).y
    self.sx = self.sx1 + self.sx2
    self.sy = self.sy1 + self.sy2
end

---Sets the new cell state at the given position.
---@param x integer X position, starting from 1.
---@param y integer Y position, starting from 1.
---@param state boolean Whether the cell should be filled.
function ConjoinedSprite:setCell(x, y, state)
    assert(x >= 1 and x <= #self.data and y >= 1 and y <= #self.data[1], "Out of bounds indexing: (" .. x .. ", " .. y .. ") with size (" .. #self.data .. ", " .. #self.data[1] .. ")")
    self.data[x][y] = state
end

---Returns the state number to be used in the given tile of this Conjoined Sprite.
---@private
---@param pos Vector2 The tile on the grid, ranging from `(0, 0)` to `(#self.data + 1, #self.data[1] + 1)`.
---@param quadrant integer The quadrant. 1 = top left, 2 = top right, 3 = bottom left, 4 = bottom right.
function ConjoinedSprite:getStateFromPos(pos, quadrant)
    local state = quadrant * 16 - 15
    local horizontalOffset = (quadrant == 1 or quadrant == 3) and -1 or 1
    local verticalOffset = quadrant <= 2 and -1 or 1

    -- Check horizontally.
    if self.data[pos.x + horizontalOffset] and self.data[pos.x + horizontalOffset][pos.y] then
        state = state + 1
    end
    -- Check vertically.
    if self.data[pos.x] and self.data[pos.x][pos.y + verticalOffset] then
        state = state + 2
    end
    -- Check the corner.
    if self.data[pos.x + horizontalOffset] and self.data[pos.x + horizontalOffset][pos.y + verticalOffset] then
        state = state + 4
    end
    -- Check the middle.
    if self.data[pos.x] and self.data[pos.x][pos.y] then
        state = state + 8
    end

    return state
end

---Draws the Conjoined Sprite on the screen.
---@param pos Vector2 The position this Conjoined Sprite should be drawn on. The top left corner of the actual data tile.
function ConjoinedSprite:draw(pos)
    for i = 0, #self.data + 1 do
        for j = 0, #self.data[1] + 1 do
            local coords = Vec2(i, j)
            local p = pos + Vec2((i - 1) * self.sx, (j - 1) * self.sy)
            self.sprite:draw(p, nil, self:getStateFromPos(coords, 1))
            self.sprite:draw(p + Vec2(self.sx1, 0), nil, self:getStateFromPos(coords, 2))
            self.sprite:draw(p + Vec2(0, self.sy1), nil, self:getStateFromPos(coords, 3))
            self.sprite:draw(p + Vec2(self.sx1, self.sy1), nil, self:getStateFromPos(coords, 4))
        end
    end
end

return ConjoinedSprite