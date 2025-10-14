local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local Text = require("src.Game.Scenes.Text")
local MenuStar = require("src.Game.Scenes.MenuStar")

---@class Menu
---@overload fun(game):Menu
local Menu = class:derive("Menu")

---Constructs a Menu scene.
---@param game GameMain The main game class instance this Menu belongs to.
function Menu:new(game)
    self.name = "menu"
    self.game = game

    self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.smallFont = _Game.resourceManager:getFont("fonts/small.json")
    self.texts = {
        Text(Vec2(160, 10), {text = "Chain Blast", textAlign = Vec2(0.5, 0), color = Color("#4cff4c"), gradientWaveColor = Color("#199919"), gradientWaveFrequency = 200, gradientWaveSpeed = 100, scale = 4, shadowOffset = Vec2(2)}),
        Text(Vec2(160, 75), {text = "Main Menu", textAlign = Vec2(0.5, 0), color = Color("#ffffff"), shadowOffset = Vec2(1)}),
        Text(Vec2(3, 179), {text = "Pre-Alpha Version - Subject to change", textAlign = Vec2(0, 1), color = Color("#888888"), shadowOffset = Vec2(1), font = self.smallFont}),
        Text(Vec2(317, 179), {text = "(c) jakubg1", textAlign = Vec2(1, 1), color = Color("#888888"), shadowOffset = Vec2(1), font = self.smallFont}),
    }
    self.menuOptions = {
        Text(Vec2(160, 90), {text = "Play!", textAlign = Vec2(0.5, 0), color = Color("#bbbbbb"), shadowOffset = Vec2(1)}),
        Text(Vec2(160, 100), {text = "Settings", textAlign = Vec2(0.5, 0), color = Color("#bbbbbb"), shadowOffset = Vec2(1)}),
        Text(Vec2(160, 110), {text = "Credits", textAlign = Vec2(0.5, 0), color = Color("#bbbbbb"), shadowOffset = Vec2(1)}),
        Text(Vec2(160, 120), {text = "Exit", textAlign = Vec2(0.5, 0), color = Color("#bbbbbb"), shadowOffset = Vec2(1)}),
    }
    self.hoveredOption = nil
    self.selectedOption = nil
    self.selectedTime = nil -- Starts counting up from 0 if a menu option has been selected.
    self.cursorAnim = 1
    self.cursorAnimH = 0.5

    self.stars = {}
    -- Spawn initial stars.
    for i = 1, 150 do
        table.insert(self.stars, MenuStar(math.random()))
    end
end

---Returns whether this scene should accept any input.
---@return boolean
function Menu:isActive()
    return true
end

---Updates the Menu.
---@param dt number Time delta in seconds.
function Menu:update(dt)
    -- Menu options
    local lastHover = self.hoveredOption
    self.hoveredOption = nil
    if not self.selectedOption then
        for i, option in ipairs(self.menuOptions) do
            local pos = option:getPos()
            local w = 100
            if _Utils.isPointInsideBox(_MousePos.x, _MousePos.y, 160 - w / 2, pos.y, w, 10) then
                self.hoveredOption = i
                break
            end
        end
    end
    -- Play a sound if we've hovered over another option.
    if self.hoveredOption and self.hoveredOption ~= lastHover then
        _Game:playSound("sound_events/ui_hover.json")
    end
    -- Highlight the hovered option.
    for i, option in ipairs(self.menuOptions) do
        option:setProp("color", self.hoveredOption == i and Color("#ffffff") or Color("#bbbbbb"))
    end
    -- Animate the rainbow cursor.
    if self.hoveredOption then
        self.cursorAnim = self.cursorAnim * 0.5 + self.hoveredOption * 0.5
        self.cursorAnimH = math.max(self.cursorAnimH - dt, 0)
    else
        self.cursorAnimH = math.min(self.cursorAnimH + dt, 0.5)
    end
    -- Selected setting
    if self.selectedOption and self.selectedTime then
        self.selectedTime = self.selectedTime + dt
        if self.selectedTime >= 0.5 then
            self.selectedTime = nil
            if self.selectedOption == 1 then
                self.game.sceneManager:startLevel()
                self.game.sceneManager:changeScene("level_intro")
            elseif self.selectedOption == 2 then
            elseif self.selectedOption == 3 then
            elseif self.selectedOption == 4 then
                love.event.quit()
            end
        end
    end
    -- Stars
    for i, star in ipairs(self.stars) do
        star:update(dt)
        if star.delQueue then
            self.stars[i] = MenuStar()
        end
    end
end

---Draws the Menu.
function Menu:draw()
    local natRes = _Game:getNativeResolution()
    -- Background
    love.graphics.setColor(0.06, 0.02, 0.05)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    -- Stars
    for i, star in ipairs(self.stars) do
        star:draw()
    end
    -- Text
    for i, text in ipairs(self.texts) do
        text:draw()
    end
    -- Menu options
    for i, option in ipairs(self.menuOptions) do
        option:draw()
    end
    -- Rainbow cursor
    local xWidthPrev = self.menuOptions[math.floor(self.cursorAnim)]:getFinalTextSize().x * (1 - self.cursorAnim % 1)
    local xWidthNext = self.menuOptions[math.ceil(self.cursorAnim)]:getFinalTextSize().x * (self.cursorAnim % 1)
    local xWidth = math.max((xWidthPrev + xWidthNext) / 2 - 20, 0)
    local xSeparation = math.max(self.cursorAnimH ^ 2 * 600, xWidth)
    local color = _Utils.getRainbowColor(_TotalTime / 4)
    self.font:draw(">", Vec2(130 + math.sin(_TotalTime * math.pi) * 4 - xSeparation, 80 + self.cursorAnim * 10), Vec2(1, 0), color)
    self.font:draw("<", Vec2(190 - math.sin(_TotalTime * math.pi) * 4 + xSeparation, 80 + self.cursorAnim * 10), Vec2(0, 0), color)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Menu:mousepressed(x, y, button)
    if button == 1 then
        if self.hoveredOption then
            self.selectedOption = self.hoveredOption
            self.selectedTime = 0
            _Game:playSound("sound_events/ui_select.json")
        end
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function Menu:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function Menu:keypressed(key)
end

return Menu