local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class GameWin
---@overload fun(game):GameWin
local GameWin = class:derive("GameWin")

---Constructs a Game Win scene.
---@param game GameMain The main game class this Menu belongs to.
function GameWin:new(game)
    self.name = "game_win"
    self.game = game
    self.level = game.sceneManager:getLevel()

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.time = 0
    self.chimePlayed = false
end

---Returns whether this scene should accept any input.
---@return boolean
function GameWin:isActive()
    return true
end

---Returns whether the game win animation has finished.
---@private
---@return boolean
function GameWin:isFinished()
    return self.time > 12
end

---Updates the Game Win animation.
---@param dt number Time delta in seconds.
function GameWin:update(dt)
    self.time = self.time + dt
    if not self.chimePlayed and self.time >= 1 then
        _Game:playSound("sound_events/game_win.json")
        self.chimePlayed = true
    end
end

---Draws the Game Win animation.
function GameWin:draw()
    local natRes = _Game:getNativeResolution()
    if self.time > 1 and self.time <= 9.5 then
        local alpha = math.max(self.time * 2 - 1.5, 0)
        if self.time > 7.5 then
            alpha = math.min((9.5 - self.time) / 2, 1)
        end
        _DrawFillRect(Vec2(), _Game:getNativeResolution(), _Utils.getRainbowColor(math.min((self.time - 2.5) / 2, 1.3)), alpha)
        self.font:draw("YOU", natRes / 2, Vec2(0.5, 1), Color(0, 0, 0), 1, 6)
        self.font:draw("WIN!", natRes / 2, Vec2(0.5, 0), Color(0, 0, 0), 1, 6)
    elseif self.time > 9.5 then
        local alpha = math.min(math.max((self.time - 9.5) * 2, 0), 1)
        self.font:draw("Congratulations!", Vec2(160, 10), Vec2(0.5), Color(1, 1, 0), alpha)
        local yOffset = math.max((11.5 - self.time) * 150, 0)
        local text = {
            "You just won!",
            "This is a very early build!",
            "If you somehow dug into this and beat all",
            "ten levels, you should feel proud of yourself!",
            "",
            "Because certainly almost nobody besides the game",
            "developer himself has ever done that!",
            "",
            "You're a mad fan of the game!"
        }
        for i, line in ipairs(text) do
            self.font:draw(line, Vec2(160, 30 + i * 10 + yOffset), Vec2(0.5))
        end
    end
    if self:isFinished() then
        local text = "Click anywhere to continue!"
        local alpha = 0.5 + (self.time % 2) * 0.5
        if self.time % 2 > 1 then
            alpha = 1 + (1 - self.time % 2) * 0.5
        end
        self.font:draw(text, Vec2(160, 160), Vec2(0.5), nil, alpha)
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function GameWin:mousepressed(x, y, button)
    if button == 1 then
        if self:isFinished() then
            self.game.sceneManager:changeScene("game_results", true, true)
            _Game:playSound("sound_events/ui_select.json")
        end
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function GameWin:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function GameWin:keypressed(key)
end

return GameWin