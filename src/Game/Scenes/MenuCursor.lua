local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")

---@class MenuCursor
---@overload fun():MenuCursor
local MenuCursor = class:derive("MenuCursor")

---Creates a new Menu Cursor. This is a purely visual commodity consisting of two rainbow arrows bouncing outwards and inwards.
---It is used both in the main menu as well as in the settings.
function MenuCursor:new()
    self.y = 80
    self.yTarget = 80
    self.clamp = 0.5
    self.clampTarget = 0.5
    self.width = 0
    self.widthTarget = 0

    self.font = _Game.resourceManager:getFont("fonts/standard.json")
end

---Clamps the cursor inwards.
function MenuCursor:grab()
    self.clampTarget = 0
end

---Releases the clamp. This causes the arrows to leave the screen area.
function MenuCursor:release()
    self.clampTarget = 0.5
end

---Sets the target Y position of the cursor.
---@param y integer The new Y position.
function MenuCursor:setY(y)
    self.yTarget = y
end

---Sets the clamped entity's width. This makes sure the clamp is wider if it is grabbing a big element.
---@param width integer Clamped option width, in pixels.
function MenuCursor:setWidth(width)
    self.widthTarget = width
end

---Updates the Menu Cursor.
---@param dt number Time delta in seconds.
function MenuCursor:update(dt)
    self.y = self.y * 0.5 + self.yTarget * 0.5
    self.width = self.width * 0.5 + self.widthTarget * 0.5
    if self.clamp < self.clampTarget then
        self.clamp = math.min(self.clamp + dt, self.clampTarget)
    elseif self.clamp > self.clampTarget then
        self.clamp = math.max(self.clamp - dt, self.clampTarget)
    end
end

---Draws the Menu Cursor.
function MenuCursor:draw()
    local xWidth = math.max(self.width / 2 - 20, 0)
    local xSeparation = math.max(self.clamp ^ 2 * 600, xWidth)
    local color = _Utils.getRainbowColor(_TotalTime / 4)
    self.font:draw(">", Vec2(130 + math.sin(_TotalTime * math.pi) * 4 - xSeparation, self.y), Vec2(1, 0), color)
    self.font:draw("<", Vec2(190 - math.sin(_TotalTime * math.pi) * 4 + xSeparation, self.y), Vec2(0, 0), color)
end

return MenuCursor