local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local Text = require("src.Game.Scenes.Text")
local MenuCursor = require("src.Game.Scenes.MenuCursor")

---Main menu screen in the Menu scene.
---@class MenuMain
---@overload fun(scene):MenuMain
local MenuMain = class:derive("MenuMain")

---Constructs a new Main Menu screen.
---@param scene Menu The owner of this screen.
function MenuMain:new(scene)
    self.scene = scene

    self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.smallFont = _Game.resourceManager:getFont("fonts/small.json")
    self.texts = {
        title1 = Text(Vec2(-1000, 10), {text = "Chain", textAlign = Vec2(1, 0), color = Color("#4cff4c"), gradientWaveColor = Color("#199919"), gradientWaveFrequency = 200, gradientWaveSpeed = 100, scale = 4, shadowOffset = Vec2(2)}),
        title2 = Text(Vec2(1000, 10), {text = "Blast", textAlign = Vec2(0, 0), color = Color("#4cff4c"), gradientWaveColor = Color("#199919"), gradientWaveFrequency = 200, gradientWaveSpeed = 100, scale = 4, shadowOffset = Vec2(2)}),
        title = Text(Vec2(160, 10), {text = "Chain Blast", textAlign = Vec2(0.5, 0), color = Color("#4cff4c"), gradientWaveColor = Color("#199919"), gradientWaveFrequency = 200, gradientWaveSpeed = 100, scale = 4, shadowOffset = Vec2(2), alpha = 0}),
        header = Text(Vec2(160, 70), {text = "Main Menu", textAlign = Vec2(0.5, 0), color = Color("#ffffff"), shadowOffset = Vec2(1), alpha = 0}),
        footer1 = Text(Vec2(3, 179), {text = "Pre-Alpha Version - Subject to change", textAlign = Vec2(0, 1), color = Color("#888888"), shadowOffset = Vec2(1), font = self.smallFont}),
        footer2 = Text(Vec2(317, 179), {text = "(c) jakubg1", textAlign = Vec2(1, 1), color = Color("#888888"), shadowOffset = Vec2(1), font = self.smallFont}),
    }
    self.menuOptions = {
        Text(Vec2(160, 90), {text = "Play!", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1), alpha = 0}),
        Text(Vec2(160, 102), {text = "Settings", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1), alpha = 0}),
        Text(Vec2(160, 114), {text = "Credits", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1), alpha = 0}),
        Text(Vec2(160, 126), {text = "Exit", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1), alpha = 0}),
    }
    self.hoveredOption = nil
    self.selectedOption = nil
    self.selectedTime = nil -- Starts counting up from 0 if a menu option has been selected.
    self.cursor = MenuCursor()
end

---Sets the widget positions and visibility depending on the current intro animation time.
---@param t number? Current intro animation progress. Calling with `nil` will cause the animation to finish.
function MenuMain:animateIntro(t)
    if t then
        if t < 1 then
            self.texts.title1.pos.x = 152 - _Utils.lerp(400, 0, t)
            self.texts.title2.pos.x = 172 + _Utils.lerp(400, 0, t)
        else
            self.texts.title1:setProp("alpha", 0)
            self.texts.title2:setProp("alpha", 0)
            self.texts.title:setProp("alpha", 1)
        end
    else
        -- The title is brought up again so that it is properly displayed when going back from settings.
        self.texts.title:setProp("alpha", 1)
        self.texts.header:setProp("alpha", 1)
        for i, option in ipairs(self.menuOptions) do
            option:setProp("alpha", 1)
        end
        -- Immediately hover whatever happens to be at the mouse cursor.
        self:hoverOptionAtCursor()
    end
end

---Hovers the option at the provided index.
---@param index integer? The option index to be hovered. `nil` will unhover all options.
function MenuMain:hoverOption(index)
    if index then
        index = _Utils.clamp(index, 1, #self.menuOptions)
    end
    if self.hoveredOption == index then
        return
    end
    if self.scene.introTime or self.selectedOption then
        -- Do not proceed if the user has currently no control over what is happening
        -- (an option has been already selected or the intro animation hasn't finished yet)
        return
    end
    self.hoveredOption = index
    if index then
        _Game:playSound("sound_events/ui_hover.json")
    end
end

---Hovers the option that is currently under the mouse cursor, or unhovers the options if none of them is hovered.
function MenuMain:hoverOptionAtCursor()
    for i, option in ipairs(self.menuOptions) do
        local pos = option:getPos()
        local w = 100
        if _Utils.isPointInsideBox(_MousePos.x, _MousePos.y, 160 - w / 2, pos.y, w, 12) then
            self:hoverOption(i)
            return
        end
    end
end

---Hovers the previous option relative to the currently hovered one, or the last one if no option is hovered.
function MenuMain:hoverPreviousOption()
    self:hoverOption(self.hoveredOption and (self.hoveredOption - 2) % #self.menuOptions + 1 or #self.menuOptions)
end

---Hovers the next option relative to the currently hovered one, or the first one if no option is hovered.
function MenuMain:hoverNextOption()
    self:hoverOption(self.hoveredOption and self.hoveredOption % #self.menuOptions + 1 or 1)
end

---Submits the currently hovered option. Does nothing if there is no hovered option.
function MenuMain:submitHoveredOption()
    if not self.hoveredOption then
        return
    end
    self.selectedOption = self.hoveredOption
    self.selectedTime = 0
    self.hoveredOption = nil
    _Game:playSound("sound_events/ui_select.json")
    if self.selectedOption == 1 then
        -- Stop the music if we're going to start a new game.
        self.scene.music:stop(1)
    end
end

---Updates the Main Menu.
---@param dt number Time delta in seconds.
function MenuMain:update(dt)
    -- Highlight the hovered option.
    for i, option in ipairs(self.menuOptions) do
        option:setProp("color", self.hoveredOption == i and Color("#ffffff") or Color("#aaaaaa"))
    end
    -- Animate the rainbow cursor.
    if self.hoveredOption then
        self.cursor:setY(90 + (self.hoveredOption - 1) * 12)
        self.cursor:setWidth(self.menuOptions[self.hoveredOption]:getFinalTextSize().x)
    end
    self.cursor:setGrab(self.hoveredOption ~= nil)
    self.cursor:update(dt)
    -- Handle selected menu entry
    if self.selectedOption and self.selectedTime then
        self.selectedTime = self.selectedTime + dt
        if self.selectedTime >= 0.5 then
            self.selectedTime = nil
            if self.selectedOption == 1 then
                self.scene:startLevel()
            elseif self.selectedOption == 2 then
                self.scene:goToSettings()
            elseif self.selectedOption == 3 then
                self.scene:goToCredits()
            elseif self.selectedOption == 4 then
                love.event.quit()
            end
        end
    end
end

---Draws the Main Menu on the screen.
function MenuMain:draw()
    -- Text
    for id, text in pairs(self.texts) do
        text:draw()
    end
    -- Menu options
    for i, option in ipairs(self.menuOptions) do
        option:draw()
    end
    -- Rainbow cursor
    self.cursor:draw()
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function MenuMain:mousepressed(x, y, button)
    if button == 1 then
        self:submitHoveredOption()
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function MenuMain:mousereleased(x, y, button)
    
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
function MenuMain:mousemoved(x, y, dx, dy)
    self:hoverOptionAtCursor()
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function MenuMain:keypressed(key)
    if key == "return" then
        self:submitHoveredOption()
    elseif key == "up" then
        self:hoverPreviousOption()
    elseif key == "down" then
        self:hoverNextOption()
    end
end

return MenuMain