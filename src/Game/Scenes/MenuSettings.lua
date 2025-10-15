local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local Text = require("src.Game.Scenes.Text")
local MenuCursor = require("src.Game.Scenes.MenuCursor")

---Settings screen in the Menu scene.
---@class MenuSettings
---@overload fun(scene):MenuSettings
local MenuSettings = class:derive("MenuSettings")

---Constructs a new Settings screen.
---@param scene Menu The owner of this screen.
function MenuSettings:new(scene)
    self.scene = scene

    self.settings = {
        {
            name = "Video",
            contents = {
                {name = "Full Screen", type = "checkbox", key = "fullscreen", description = "Controls whether the game should be running in full screen."},
                {name = "Reduced Particles", type = "checkbox", key = "reducedParticles", description = "Turning this setting on will cause the game to display\nmuch less particles. Helps avoiding visual clutter\nat the cost of graphical quality."},
                {name = "Screen Flash Strength", type = "slider", key = "screenFlashStrength", description = "Controls how bright the screen flashes will be.\nSetting this to 0% turns screen flashes off completely."},
                {name = "Screen Shake Strength", type = "slider", key = "screenShakeStrength", description = "Controls the power of screen shake effects.\nSetting this to 0% disables screen shake effects completely."},
                {name = "Auto-Pause on Inactivity", type = "checkbox", key = "autoPause", description = "If enabled, the game will be automatically paused when\nthe player's cursor does not move for 3 seconds."}
            }
        },
        {
            name = "Audio",
            contents = {
                {name = "Mute", type = "checkbox", key = "mute", description = "Turns off all audio output in this game."},
                {name = "Global Volume", type = "slider", key = "globalVolume", description = "Controls the level of all audio output in the game."},
                {name = "SFX Volume", type = "slider", key = "soundVolume", description = "Controls most gameplay sounds\n(such as breaking chains, activating powerups or menu actions)."},
                {name = "Music Volume", type = "slider", key = "musicVolume", description = "Volume used for the music."},
                {name = "Music Cue Volume", type = "slider", key = "musicCueVolume", description = "Volume used for certain in-game events\n(such as level complete, fail, etc.)."}
            }
        },
        {
            name = "Handicap",
            contents = {
                {name = "Disable Timer", type = "checkbox", key = "handicapTime", description = "If this is turned on, there will be no time limits on any levels\nin this game. There is no penalty for doing this;\nhowever, in the future, achievements will be disabled if any\nof the handicap settings are turned on."}
            }
        }
    }
    self.cursor = MenuCursor()
    self.checkboxSprite = _Game.resourceManager:getSprite("sprites/checkbox.json")
    self.sliderSprite = _Game.resourceManager:getSprite("sprites/slider_frame.json")
    self.hoveredCategory = nil
    self.selectedCategory = 1
    self.hoveredSetting = nil
    self.sliderDragX = nil
    self.sliderDragOrigValue = nil
    self.backToMenuHovered = false
    self.backToMenuTime = nil -- Starts counting up from 0 if a menu option has been selected.
    -- Build UI.
    self.texts = {
        header = Text(Vec2(160, 10), {text = "Settings", textAlign = Vec2(0.5, 0), color = Color("#ffffff"), shadowOffset = Vec2(1)}),
        description = Text(Vec2(25, 115), {text = "", textAlign = Vec2(0, 0), color = Color("#ffffff"), shadowOffset = Vec2(1)}),
        back = Text(Vec2(160, 155), {text = "Back to Menu", textAlign = Vec2(0.5, 0), color = Color("#aaaaaa"), shadowOffset = Vec2(1)})
    }
    local categoryBuildX = 35
    for i, category in ipairs(self.settings) do
        local text = Text(Vec2(categoryBuildX, 30), {text = "[" .. category.name .. "]", textAlign = Vec2(0, 0), color = self.selectedCategory == i and Color("#ffffff") or Color("#aaaaaa"), shadowOffset = Vec2(1)})
        categoryBuildX = categoryBuildX + text:getFinalTextSize().x + 5
        self.texts["category" .. i] = text
    end
    self:rebuildSettingList()
    self.categoryCursorX, self.categoryCursorWidth = self:getCategoryCursorDetails(1)
    self.categoryCursorTargetX, self.categoryCursorTargetWidth = self.categoryCursorX, self.categoryCursorWidth
end

---Returns the current value of the provided setting from the settings manifest as a string.
---This is what is displayed on the rightmost column of the settings menu.
---@param setting table<string, string> A single setting from the settings manifest.
---@return string
function MenuSettings:getSettingValueStr(setting)
    local value = self:getSettingValue(setting)
    if type(value) == "boolean" then
        return value and "On" or "Off"
    else
        return tostring(math.floor(value * 100)) .. "%"
    end
end

---Returns the current value of the provided setting from the settings manifest.
---@param setting table<string, string> A single setting from the settings manifest.
---@return any
function MenuSettings:getSettingValue(setting)
    if setting.key then
        return _Game.runtimeManager.options:getSetting(setting.key)
    end
    return setting.type == "slider" and 1 or false
end

---Changes the value of the provided setting from the settings manifest.
---@param setting table<string, string> A single setting from the settings manifest.
---@param value any A new value for the setting.
function MenuSettings:setSettingValue(setting, value)
    if setting.key then
        _Game.runtimeManager.options:setSetting(setting.key, value)
    end
end

---Returns the manifest of the currently hovered setting, or `nil` if no setting is hovered.
---@return table<string, string>?
function MenuSettings:getHoveredSetting()
    if not self.hoveredSetting then
        return
    end
    return self.settings[self.selectedCategory].contents[self.hoveredSetting]
end

---Rebuilds the setting list UI for the currently selected category. Use if a setting has been changed or a different category has been selected.
function MenuSettings:rebuildSettingList()
    for i = 1, 9 do
        self.texts["setting" .. i] = nil
        self.texts["setting" .. i .. "_val"] = nil
    end
    local settingBuildY = 48
    for i, setting in ipairs(self.settings[self.selectedCategory].contents) do
        local color = self.hoveredSetting == i and Color("#ffffff") or Color("#aaaaaa")
        self.texts["setting" .. i] = Text(Vec2(30, settingBuildY), {text = setting.name, textAlign = Vec2(0, 0), color = color, shadowOffset = Vec2(1)})
        self.texts["setting" .. i .. "_val"] = Text(Vec2(290, settingBuildY), {text = self:getSettingValueStr(setting), textAlign = Vec2(1, 0), color = color, shadowOffset = Vec2(1)})
        settingBuildY = settingBuildY + 12
    end
end

---Returns the center X position and the width of the category cursor of the `n`-th category specified.
---@param n integer The ID of the category to calculate the values for.
---@return number, number
function MenuSettings:getCategoryCursorDetails(n)
    local categoryText = self.texts["category" .. n]
    local w = categoryText:getFinalTextSize().x
    local x = categoryText.pos.x + w / 2
    w = w + 4
    return x, w
end

---Updates the Settings screen.
---@param dt number Time delta in seconds.
function MenuSettings:update(dt)
    self:updateCategories(dt)
    self:updateSettings(dt)
    self:updateBackToMenu(dt)
end

---Updates the category part of the settings interface.
---@private
---@param dt number Time delta in seconds.
function MenuSettings:updateCategories(dt)
    -- Update category hover.
    local lastCategoryHover = self.hoveredCategory
    self.hoveredCategory = nil
    if not self.backToMenuTime and not self.sliderDragX then
        for i = 1, #self.settings do
            if i ~= self.selectedCategory then
                local text = self.texts["category" .. i]
                local pos = text.pos
                local size = text:getFinalTextSize()
                if _Utils.isPointInsideBox(_MousePos.x, _MousePos.y, pos.x - 2, pos.y, size.x + 4, size.y) then
                    self.hoveredCategory = i
                end
            end
        end
    end
    -- Highlight the current and the hovered category.
    for i = 1, #self.settings do
        local highlighted = self.selectedCategory == i or self.hoveredCategory == i
        self.texts["category" .. i]:setProp("color", highlighted and Color("#ffffff") or Color("#aaaaaa"))
    end
    -- Play a sound if we've hovered over another option.
    if self.hoveredCategory and self.hoveredCategory ~= lastCategoryHover then
        _Game:playSound("sound_events/ui_hover.json")
    end
    -- Update the category cursor.
    self.categoryCursorTargetX, self.categoryCursorTargetWidth = self:getCategoryCursorDetails(self.selectedCategory)
    self.categoryCursorX = self.categoryCursorX * 0.5 + self.categoryCursorTargetX * 0.5
    self.categoryCursorWidth = self.categoryCursorWidth * 0.5 + self.categoryCursorTargetWidth * 0.5
end

---Updates the setting part of the settings interface.
---@private
---@param dt number Time delta in seconds.
function MenuSettings:updateSettings(dt)
    local availableSettings = self.settings[self.selectedCategory].contents
    -- Update setting hover.
    local lastHover = self.hoveredSetting
    if not self.sliderDragX then
        self.hoveredSetting = nil
        if not self.backToMenuTime then
            for i = 1, #availableSettings do
                if _MousePos.y >= 48 + (i - 1) * 12 and _MousePos.y < 48 + i * 12 then
                    self.hoveredSetting = i
                end
            end
        end
    end
    -- Highlight the hovered setting.
    for i = 1, #availableSettings do
        self.texts["setting" .. i]:setProp("color", self.hoveredSetting == i and Color("#ffffff") or Color("#aaaaaa"))
        self.texts["setting" .. i .. "_val"]:setProp("color", self.hoveredSetting == i and Color("#ffffff") or Color("#aaaaaa"))
    end
    -- Play a sound if we've hovered over another option.
    if self.hoveredSetting and self.hoveredSetting ~= lastHover then
        _Game:playSound("sound_events/ui_hover.json")
    end
    -- Give appropriate description for the currently hovered setting.
    local description = self.hoveredSetting and availableSettings[self.hoveredSetting].description or ""
    self.texts["description"]:setProp("text", description)
    -- Handle slider dragging.
    if self.sliderDragX then
        local setting = self:getHoveredSetting()
        if setting then
            -- Sliding relative to the grabbed position feels wrong.
            --local offset = _MousePos.x - self.sliderDragX
            --self:setSettingValue(setting, _Utils.clamp(self.sliderDragOrigValue + offset / 96))
            self:setSettingValue(setting, _Utils.clamp((_MousePos.x - 161) / 96))
            self:rebuildSettingList()
        end
    end

    -- Check whether Back to Menu is hovered.
    local oldBackToMenuHover = self.backToMenuHovered
    self.backToMenuHovered = not self.backToMenuTime and not self.sliderDragX and _Utils.isPointInsideBox(_MousePos.x, _MousePos.y, 160 - 50, 155, 100, 10)
    -- Highlight the hovered button.
    self.texts.back:setProp("color", self.backToMenuHovered and Color("#ffffff") or Color("#aaaaaa"))
    -- If we've just hovered it, play a sound.
    if not oldBackToMenuHover and self.backToMenuHovered then
        _Game:playSound("sound_events/ui_hover.json")
    end

    -- Update the cursor.
    if self.hoveredSetting then
        self.cursor:setWidth(260)
        self.cursor:setY(48 + (self.hoveredSetting - 1) * 12)
    elseif self.backToMenuHovered then
        self.cursor:setWidth(60)
        self.cursor:setY(155)
    end
    self.cursor:setGrab(self.hoveredSetting ~= nil or self.backToMenuHovered)
    self.cursor:update(dt)
end

---Updates the back to menu logic.
---@private
---@param dt number Time delta in seconds.
function MenuSettings:updateBackToMenu(dt)
    if not self.backToMenuTime then
        return
    end
    self.backToMenuTime = self.backToMenuTime + dt
    if self.backToMenuTime >= 0.5 then
        self.scene:goToMain()
    end
end

---Draws the Settings on the screen.
function MenuSettings:draw()
    -- Text
    for id, text in pairs(self.texts) do
        text:draw()
    end
    -- Settings
    local y = 48
    for i, setting in ipairs(self.settings[self.selectedCategory].contents) do
        local color = self.hoveredSetting == i and Color("#ffffff") or Color("#aaaaaa")
        local value = self:getSettingValue(setting)
        if setting.type == "checkbox" then
            self.checkboxSprite:draw(Vec2(248, y + 1), nil, value and 2 or 1, nil, nil, color)
        elseif setting.type == "slider" then
            self.sliderSprite:draw(Vec2(159, y + 2), nil, nil, nil, nil, color)
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", 161, y + 4, 96, 5)
            if self.sliderDragX and self.hoveredSetting == i then
                love.graphics.setColor(0.5, 0.5, 0.5)
            else
                love.graphics.setColor(color.r, color.g, color.b)
            end
            love.graphics.rectangle("fill", 161, y + 4, 96 * value, 5)
        end
        y = y + 12
    end
    -- Selected category underline (cursor)
    local color = _Utils.getRainbowColor(_TotalTime / 4)
    love.graphics.setColor(color.r, color.g, color.b)
    local selectedCategoryText = self.texts["category" .. self.selectedCategory]
    local x1, y1 = self.categoryCursorX - self.categoryCursorWidth / 2, selectedCategoryText.pos.y + 13
    local x2, y2 = self.categoryCursorX + self.categoryCursorWidth / 2, y1
    love.graphics.line(x1, y1, x2, y2)
    -- Cursor
    self.cursor:draw()
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function MenuSettings:mousepressed(x, y, button)
    if button == 1 then
        if self.hoveredCategory then
            self.selectedCategory = self.hoveredCategory
            self:rebuildSettingList()
            _Game:playSound("sound_events/ui_select.json")
        end
        local setting = self:getHoveredSetting()
        if setting then
            if setting.type == "checkbox" then
                local newValue = not self:getSettingValue(setting)
                self:setSettingValue(setting, newValue)
            elseif setting.type == "slider" then
                self.sliderDragX = _MousePos.x
                self.sliderDragOrigValue = self:getSettingValue(setting)
            end
            self:rebuildSettingList()
            _Game:playSound("sound_events/ui_select.json")
        end
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
function MenuSettings:mousereleased(x, y, button)
    if button == 1 then
        if self.sliderDragX then
            self.sliderDragX = nil
            self.sliderDragOrigValue = nil
        end
    end
end

return MenuSettings