local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class GameResults
---@overload fun(game):GameResults
local GameResults = class:derive("GameResults")

---Creates a Game Results scene.
---@param game GameMain The main game class this scene belongs to.
function GameResults:new(game)
    self.name = "level_complete"
    self.game = game
    self.level = game.sceneManager:getLevel()

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.time = 0
    self.soundStep = 1
    self.SOUND_STEPS = {1.2, 1.6, 2, 2.4, 2.8, 3.8}
end

---Returns whether this scene should accept any input.
---@return boolean
function GameResults:isActive()
    return true
end

---Returns whether the game results animation has finished.
---@private
---@return boolean
function GameResults:isFinished()
    return self.time > 4.5
end

---Skips the game results animation.
function GameResults:skip()
    self.time = 5
    self.soundStep = #self.SOUND_STEPS
    _Game:playSound("sound_events/ui_select.json")
end

---Updates the Game Results animation.
---@param dt number Time delta in seconds.
function GameResults:update(dt)
    self.time = self.time + dt
    local threshold = self.SOUND_STEPS[self.soundStep]
    if threshold and self.time >= threshold then
        _Game:playSound("sound_events/ui_stats.json")
        self.soundStep = self.soundStep + 1
    end
end

---Draws the Game Results animation.
function GameResults:draw()
    local xLeft = 60
    local xMid = 160
    local xRight = 260
    local alpha = math.min(math.max((self.time - 0.5) * 2, 0), 1)
    self.font:draw("Game Results", Vec2(xMid, 15), Vec2(0.5), nil, alpha)
    if self.time > 1.2 then
        self.font:draw("Chains Destroyed:", Vec2(xLeft, 40), Vec2(0, 0.5))
    end
    if self.time > 1.3 then
        self.font:draw(tostring(self.game.player.session.chainsDestroyed), Vec2(xRight, 40), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > 1.6 then
        self.font:draw("Largest Link:", Vec2(xLeft, 50), Vec2(0, 0.5))
    end
    if self.time > 1.7 then
        self.font:draw(tostring(self.game.player.session.largestGroup), Vec2(xRight, 50), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > 2 then
        self.font:draw("Max Combo:", Vec2(xLeft, 60), Vec2(0, 0.5))
    end
    if self.time > 2.1 then
        self.font:draw(tostring(self.game.player.session.maxCombo), Vec2(xRight, 60), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > 2.4 then
        self.font:draw("Attempts per Level:", Vec2(xLeft, 70), Vec2(0, 0.5))
    end
    if self.time > 2.5 then
        local started = self.game.player.session.levelsStarted
        local beaten = self.game.player.session.levelsCompleted
        self.font:draw(string.format("%s / %s  %.2f", started, beaten, started / beaten), Vec2(xRight, 70), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > 2.8 then
        self.font:draw("Total Time:", Vec2(xLeft, 80), Vec2(0, 0.5))
    end
    if self.time > 2.9 then
        self.font:draw(string.format("%.1d:%.2d", self.game.player.session.timeElapsed / 60, self.game.player.session.timeElapsed % 60), Vec2(xRight, 80), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > 3.4 then
        self.font:draw("Final Score:", Vec2(xMid, 105), Vec2(0.5))
    end
    if self.time > 3.8 then
        self.font:draw(tostring(self.game.player.session.score), Vec2(xMid, 125), Vec2(0.5), _Utils.getRainbowColor(_TotalTime / 4), nil, 3)
    end
    if self.time > 4.5 then
        local text = "Click anywhere to go to main menu!"
        alpha = 0.5 + (self.time % 2) * 0.5
        if self.time % 2 > 1 then
            alpha = 1 + (1 - self.time % 2) * 0.5
        end
        self.font:draw(text, Vec2(xMid, 155), Vec2(0.5), nil, alpha)
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function GameResults:mousepressed(x, y, button)
    if button == 1 then
        if self:isFinished() then
            self.game.sceneManager:changeScene("menu", true, true)
            self.game.sceneManager:endLevel()
            self.game.player:resetSession()
            _Game:playSound("sound_events/ui_select.json")
        else
            self:skip()
        end
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function GameResults:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function GameResults:keypressed(key)
end

return GameResults