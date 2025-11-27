local Scene = require("src.Game.Scenes.Scene")
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local Text = require("src.Game.Text")
local MenuCursor = require("src.Game.MenuCursor")

---@class LevelPause : Scene
---@overload fun(game):LevelPause
local LevelPause = Scene:derive("LevelPause")

---Constructs a Level Pause Scene.
---The actual level alongside with its HUD is handled separately. Check the Scene Manager.
---@param game GameMain The main game class instance this Menu belongs to.
function LevelPause:new(game)
    self.name = "level_pause"
    self.game = game

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.options = {
        Text(Vec2(160, 80), {text = "Resume", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1)}),
        Text(Vec2(160, 92), {text = "Settings", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1)}),
        Text(Vec2(160, 104), {text = "Quit to Menu", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1)})
    }
    self.hoveredOption = nil
    self.selectedOption = nil
    self.selectedTime = nil -- Starts counting up from 0 if a menu option has been selected.
    self.cursor = MenuCursor()

    self.startTime = 0 -- Counts up when the menu is brought up
    self.endTime = nil -- Counts up when the menu is going to disappear (after `selectedTime`)
    -- Skip the pause intro animation if we are not asked to do so.
    if not self.game.sceneManager.playPauseIntro then
        self:skipIntro()
    end
end

---Skips the intro animation.
function LevelPause:skipIntro()
    self.startTime = nil
end

---Updates the pause screen.
---@param dt number Time delta in seconds.
function LevelPause:update(dt)
    -- Handle the start time
    if self.startTime then
        self.startTime = self.startTime + dt
        if self.startTime >= 0.5 then
            self.startTime = nil
            self.game.sceneManager.playPauseIntro = false
            -- Immediately hover whatever is at cursor.
            self:hoverOptionAtCursor()
        end
        -- Animate the texts.
        for i, option in ipairs(self.options) do
            option.pos.x = _Utils.mapc(self.startTime or 0.5, -0.1 + i * 0.1, 0.2 + i * 0.1, 400, 160)
        end
    end
    -- Handle the end time
    if self.endTime then
        self.endTime = self.endTime + dt
        if self.endTime >= 0.5 then
            self.endTime = nil
            self.game.sceneManager:getLevel():setPause(false)
        end
        -- Animate the texts.
        for i, option in ipairs(self.options) do
            option.pos.x = _Utils.mapc(self.endTime or 0.5, -0.1 + i * 0.1, 0.2 + i * 0.1, 160, -80)
        end
    end
    -- Highlight the hovered option.
    for i, option in ipairs(self.options) do
        option:setProp("color", self.hoveredOption == i and Color("#ffffff") or Color("#aaaaaa"))
    end
    -- Animate the rainbow cursor.
    if self.hoveredOption then
        self.cursor:setY(self.options[self.hoveredOption].pos.y)
        self.cursor:setWidth(self.options[self.hoveredOption]:getFinalTextSize().x)
    end
    self.cursor:setGrab(self.hoveredOption ~= nil)
    self.cursor:update(dt)
    -- Handle selected menu entry
    if self.selectedOption and self.selectedTime then
        self.selectedTime = self.selectedTime + dt
        if self.selectedTime >= 0.5 then
            self.selectedTime = nil
            if self.selectedOption == 1 then
                self:close()
            elseif self.selectedOption == 2 then
                self.game.sceneManager:changeScene({foreground = "menu_settings"})
            elseif self.selectedOption == 3 then
                self.game.sceneManager.playMenuIntro = true
                self.game.sceneManager:changeScene({foreground = "menu_main", background = "", level = "", hud = ""}, true)
            end
        end
    end
end

---Hovers the option at the provided index.
---@param index integer? The option index to be hovered. `nil` will unhover all options.
function LevelPause:hoverOption(index)
    if index then
        index = _Utils.clamp(index, 1, #self.options)
    end
    if self.hoveredOption == index then
        return
    end
    if self.startTime or self.selectedOption then
        -- Do not proceed if the user has currently no control over what is happening
        -- (an option has been already selected or the intro animation hasn't finished yet)
        return
    end
    self.hoveredOption = index
    if index then
        _Game:playSound("sound_events/ui_hover.json")
    end
end

---Hovers the option that is currently under the mouse cursor, or unhovers the options if none of them are hovered.
function LevelPause:hoverOptionAtCursor()
    for i, option in ipairs(self.options) do
        local pos = option:getPos()
        local w = 100
        if _Utils.isPointInsideBox(_MousePos.x, _MousePos.y, 160 - w / 2, pos.y, w, 12) then
            self:hoverOption(i)
            return
        end
    end
    self.hoveredOption = nil
end

---Hovers the previous option relative to the currently hovered one, or the last one if no option is hovered.
function LevelPause:hoverPreviousOption()
    self:hoverOption(self.hoveredOption and (self.hoveredOption - 2) % #self.options + 1 or #self.options)
end

---Hovers the next option relative to the currently hovered one, or the first one if no option is hovered.
function LevelPause:hoverNextOption()
    self:hoverOption(self.hoveredOption and self.hoveredOption % #self.options + 1 or 1)
end

---Submits the currently hovered option. Does nothing if there is no hovered option.
function LevelPause:submitHoveredOption()
    if not self.hoveredOption then
        return
    end
    self.selectedOption = self.hoveredOption
    self.selectedTime = 0
    self.hoveredOption = nil
    _Game:playSound("sound_events/ui_select.json")
end

---Starts the closing process for the pause screen.
function LevelPause:close()
    self.endTime = 0
end

---Draws the pause screen.
function LevelPause:draw()
    local natRes = _Game:getNativeResolution()
    -- Background
    local alpha = 1
    if self.startTime then
        alpha = _Utils.mapc(self.startTime, 0, 0.2, 0, 1)
    elseif self.endTime then
        alpha = _Utils.mapc(self.endTime, 0.3, 0.5, 1, 0)
    end
    love.graphics.setColor(0, 0, 0, alpha * 0.7)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    -- Text
    self.font:drawWithShadow("Game Paused", Vec2(160, 65), Vec2(0.5, 0), Color(1, 1, 0), alpha)
    -- Back to menu warning
    if self.hoveredOption == 3 then
        self.font:drawWithShadow("WARNING!", Vec2(160, 120), Vec2(0.5, 0), Color(1, 0, 0))
        self.font:drawWithShadow("This demo doesn't feature level saves yet.", Vec2(160, 135), Vec2(0.5, 0), Color(1, 1, 1))
        self.font:drawWithShadow("Level progress will be lost!", Vec2(160, 145), Vec2(0.5, 0), Color(1, 1, 1))
    end
    -- Menu options
    for i, option in ipairs(self.options) do
        option:draw()
    end
    -- Rainbow cursor
    self.cursor:draw()
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function LevelPause:mousepressed(x, y, button)
    if button == 1 then
        self:submitHoveredOption()
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
function LevelPause:mousemoved(x, y, dx, dy)
    self:hoverOptionAtCursor()
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function LevelPause:keypressed(key)
    if key == "return" then
        self:submitHoveredOption()
    elseif key == "up" then
        self:hoverPreviousOption()
    elseif key == "down" then
        self:hoverNextOption()
    end
    return true
end

return LevelPause