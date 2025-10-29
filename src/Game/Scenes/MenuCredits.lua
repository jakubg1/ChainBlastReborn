local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local Text = require("src.Game.Scenes.Text")
local MenuCursor = require("src.Game.Scenes.MenuCursor")

---Credits screen in the Menu scene.
---@class MenuCredits
---@overload fun(scene):MenuCredits
local MenuCredits = class:derive("MenuCredits")

---Constructs a new Credits screen.
---@param scene Menu The owner of this screen.
function MenuCredits:new(scene)
    self.scene = scene

    self.cursor = MenuCursor()
    self.backToMenuHovered = false
    self.backToMenuTime = nil -- Starts counting up from 0 if a menu option has been selected.
    -- Build UI.
    self.texts = {
        header = Text(Vec2(160, 10), {text = "Credits", textAlign = Vec2(0.5, 0), color = Color("#4cff4c"), gradientWaveColor = Color("#199919"), gradientWaveFrequency = 200, gradientWaveSpeed = 100, shadowOffset = Vec2(1)}),
        progArtHeader = Text(Vec2(160, 35), {text = "Lead, Programming & Art", textAlign = Vec2(0.5, 0), color = Color("#ffff00"), shadowOffset = Vec2(1)}),
        progArt = Text(Vec2(160, 47), {text = "jakubg1", textAlign = Vec2(0.5, 0), color = Color("#ffffff"), shadowOffset = Vec2(1)}),
        musicHeader = Text(Vec2(70, 65), {text = "Music", textAlign = Vec2(0.5, 0), color = Color("#ffff00"), shadowOffset = Vec2(1)}),
        music = Text(Vec2(70, 77), {text = "Crisps", textAlign = Vec2(0.5, 0), color = Color("#ffffff"), shadowOffset = Vec2(1)}),
        levelDHeader = Text(Vec2(250, 65), {text = "Level Design", textAlign = Vec2(0.5, 0), color = Color("#ffff00"), shadowOffset = Vec2(1)}),
        levelD = Text(Vec2(250, 77), {text = "Stage13-10", textAlign = Vec2(0.5, 0), color = Color("#ffffff"), shadowOffset = Vec2(1)}),
        basedOnHeader = Text(Vec2(160, 95), {text = "Inspired by the game 'Chainz' by", textAlign = Vec2(0.5, 0), color = Color("#ffff00"), shadowOffset = Vec2(1)}),
        basedOn = Text(Vec2(160, 107), {text = "MumboJumbo", textAlign = Vec2(0.5, 0), color = Color("#ffffff"), shadowOffset = Vec2(1)}),
        back = Text(Vec2(160, 155), {text = "Back to Menu", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1)})
    }
end

---Updates the Credits screen.
---@param dt number Time delta in seconds.
function MenuCredits:update(dt)
    self:updateBackToMenu(dt)
end

---Updates the back to menu logic.
---@private
---@param dt number Time delta in seconds.
function MenuCredits:updateBackToMenu(dt)
    -- Check whether Back to Menu is hovered.
    local oldBackToMenuHover = self.backToMenuHovered
    self.backToMenuHovered = not self.backToMenuTime and _Utils.isPointInsideBox(_MousePos.x, _MousePos.y, 160 - 50, 155, 100, 10)
    -- Highlight the hovered button.
    self.texts.back:setProp("color", self.backToMenuHovered and Color("#ffffff") or Color("#aaaaaa"))
    -- If we've just hovered it, play a sound.
    if not oldBackToMenuHover and self.backToMenuHovered then
        _Game:playSound("sound_events/ui_hover.json")
    end

    -- Update the cursor.
    if self.backToMenuHovered then
        self.cursor:setWidth(60)
        self.cursor:setY(155)
    end
    self.cursor:setGrab(self.backToMenuHovered)
    self.cursor:update(dt)

    -- If we are going to back to menu, count down.
    if self.backToMenuTime then
        self.backToMenuTime = self.backToMenuTime + dt
        if self.backToMenuTime >= 0.5 then
            self.scene:goToMain()
        end
    end
end

---Draws the Credits on the screen.
function MenuCredits:draw()
    -- Text
    for id, text in pairs(self.texts) do
        text:draw()
    end
    -- Cursor
    self.cursor:draw()
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function MenuCredits:mousepressed(x, y, button)
    if button == 1 then
        if self.backToMenuHovered then
            self.backToMenuTime = 0
            _Game:playSound("sound_events/ui_select.json")
        end
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function MenuCredits:mousereleased(x, y, button)
end

return MenuCredits