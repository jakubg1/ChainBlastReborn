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
                {name = "Full Screen", type = "checkbox", description = "Controls whether the game should be running in full screen."},
                {name = "Reduced Particles", type = "checkbox", description = "Turning this setting on will cause the game to display much less particles. Helps avoiding visual clutter at the cost of graphical quality."},
                {name = "Screen Flash Strength", type = "slider", description = "Controls how bright the screen flashes are going to be displayed. Setting this to 0% turns screen flashes off completely."},
                {name = "Screen Shake Strength", type = "slider", description = "Controls the power of screen shake effects. Setting this to 0% will disable screen shake effects completely."}
            }
        },
        {
            name = "Audio",
            contents = {
                {name = "Mute", type = "checkbox", description = "Turns off all audio output in this game."},
                {name = "Global Volume", type = "slider", description = "Controls the level of all audio output in the game."},
                {name = "SFX Volume", type = "slider", description = "Controls most gameplay sounds\n(such as breaking chains, activating powerups or menu actions)."},
                {name = "Music Volume", type = "slider", description = "Volume used for the music."},
                {name = "Music Cue Volume", type = "slider", description = "Volume used for certain in-game events\n(such as level complete, fail, etc.)."}
            }
        },
        {
            name = "Handicap",
            contents = {
                {name = "Disable Timer", type = "checkbox", description = "If this is turned on, there will be no time limits on any levels in this game. There is no penalty for doing this; however, in the future, achievements will be disabled if any of the handicap settings are turned on."}
            }
        }
    }
    self.texts = {
        header = Text(Vec2(160, 10), {text = "Settings", textAlign = Vec2(0.5, 0), color = Color("#ffffff"), shadowOffset = Vec2(1)}),
    }
end

---Updates the Settings screen.
---@param dt number Time delta in seconds.
function MenuSettings:update(dt)
    
end

---Draws the Settings on the screen.
function MenuSettings:draw()
    -- Text
    for id, text in pairs(self.texts) do
        text:draw()
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function MenuSettings:mousepressed(x, y, button)
    
end

return MenuSettings