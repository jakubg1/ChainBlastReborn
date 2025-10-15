local class = require "com.class"
local MenuMain = require("src.Game.Scenes.MenuMain")
local MenuSettings = require("src.Game.Scenes.MenuSettings")
local MenuStar = require("src.Game.Scenes.MenuStar")

---@class Menu
---@overload fun(game):Menu
local Menu = class:derive("Menu")

---Constructs a Menu scene.
---@param game GameMain The main game class instance this Menu belongs to.
function Menu:new(game)
    self.name = "menu"
    self.game = game

    self.music = _Game.resourceManager:getMusic("music_tracks/menu_music.json")
    self.screen = MenuMain(self)
    self.stars = {}
    -- Spawn initial stars.
    for i = 1, 150 do
        table.insert(self.stars, MenuStar(math.random()))
    end

    self.introTime = 0
    self.introStep = 1
end

---Goes to the main menu screen.
function Menu:goToMain()
    self.screen = MenuMain(self)
end

---Goes to the settings screen.
function Menu:goToSettings()
    self.screen = MenuSettings(self)
end

---Ends this scene and starts a level.
function Menu:startLevel()
    self.game.sceneManager:startLevel()
    self.game.sceneManager:changeScene("level_intro")
end

---Returns whether this scene should accept any input.
---@return boolean
function Menu:isActive()
    return true
end

---Updates the Menu.
---@param dt number Time delta in seconds.
function Menu:update(dt)
    -- Intro animation
    if self.introTime then
        self.introTime = self.introTime + dt
        if self.introStep == 1 then
            if self.introTime >= 1 then
                self.introStep = 2
                -- Play the explosion sound.
                _Game:playSound("sound_events/explosion.json")
            end
        elseif self.introStep == 2 then
            if self.introTime >= 2 then
                self.introTime = nil
                -- Play the music.
                self.music:stop()
                self.music:play(1)
            end
        end
        self.screen:animateIntro(self.introTime)
    end
    -- Current screen
    self.screen:update(dt)
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
    if self.introStep == 2 then
        love.graphics.setColor(0.06, 0.02, 0.05)
    else
        love.graphics.setColor(0, 0, 0)
    end
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
    -- Stars
    if self.introStep == 2 and not _Game.runtimeManager.options:getSetting("reducedParticles") then
        for i, star in ipairs(self.stars) do
            star:draw()
        end
    end
    -- Scene
    self.screen:draw()
    -- Intro flash
    if self.introStep == 2 then
        if self.introTime then
            love.graphics.setColor(1, 1, 1, 2 - self.introTime)
            love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)
        end
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Menu:mousepressed(x, y, button)
    self.screen:mousepressed(x, y, button)
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