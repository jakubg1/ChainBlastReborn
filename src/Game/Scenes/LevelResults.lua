local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class LevelResults
---@overload fun(game):LevelResults
local LevelResults = class:derive("LevelResults")

---Creates a Level Results scene.
---@param game GameMain The main game class this scene belongs to.
function LevelResults:new(game)
    self.name = "level_results"
    self.game = game
    self.level = game.sceneManager:getLevel()

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.time = 0
    self.soundStep = 1
    self.SOUND_STEPS = {0.6, 1.0, 1.4, 1.8, 2.2, 3.2}
    self.NEW_RECORD_TIME = 2.4
    self.newRecordDisplayed = false
end

---Returns whether this scene should accept any input.
---@return boolean
function LevelResults:isActive()
    return true
end

---Returns whether the level results animation has finished.
---@private
---@return boolean
function LevelResults:isFinished()
    return self.time > 4
end

---Returns whether the new record badge should be displayed on the results screen.
---@private
---@return boolean
function LevelResults:shouldDisplayNewRecord()
    return not self.level.lost
end

---Skips the level results animation.
function LevelResults:skip()
    self.time = 5
    self.soundStep = #self.SOUND_STEPS
    _Game:playSound("sound_events/ui_select.json")
end

---Updates the Level Results animation.
---@param dt number Time delta in seconds.
function LevelResults:update(dt)
    self.time = self.time + dt
    self.level.ui:setHUDAlpha(0, true)
    self.level.background:setVisible(false)
    local threshold = self.SOUND_STEPS[self.soundStep]
    if threshold and self.time >= threshold then
        _Game:playSound("sound_events/ui_stats.json")
        self.soundStep = self.soundStep + 1
    end
    if self:shouldDisplayNewRecord() and not self.newRecordDisplayed and self.time >= self.NEW_RECORD_TIME then
        _Game:playSound("sound_events/new_record.json")
        self.newRecordDisplayed = true
    end
end

---Draws the Level Results animation.
function LevelResults:draw()
    local xLeft = 60
    local xMid = 160
    local xRight = 260
    local alpha = _Utils.mapc(self.time, 0, 0.5, 0, 1)
    self.font:draw(string.format("Level %s", self.level.config.name), Vec2(xMid, 15), Vec2(0.5), nil, alpha)
    if self.level.lost then
        self.font:draw("Failed!", Vec2(xMid, 25), Vec2(0.5), Color(1, 0, 0), alpha)
    else
        self.font:draw("Complete!", Vec2(xMid, 25), Vec2(0.5), Color(0, 1, 0), alpha)
    end
    if self.time > self.SOUND_STEPS[1] then
        self.font:draw("Time Elapsed:", Vec2(xLeft, 50), Vec2(0, 0.5))
    end
    if self.time > self.SOUND_STEPS[1] + 0.1 then
        self.font:draw(string.format("%.1d:%.2d", self.level.timeElapsed / 60, self.level.timeElapsed % 60), Vec2(xRight, 50), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > self.SOUND_STEPS[2] then
        self.font:draw("Max Combo:", Vec2(xLeft, 60), Vec2(0, 0.5))
    end
    if self.time > self.SOUND_STEPS[2] + 0.1 then
        self.font:draw(tostring(self.level.maxCombo), Vec2(xRight, 60), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > self.SOUND_STEPS[3] then
        self.font:draw("Largest Link:", Vec2(xLeft, 70), Vec2(0, 0.5))
    end
    if self.time > self.SOUND_STEPS[3] + 0.1 then
        self.font:draw(tostring(self.level.largestGroup), Vec2(xRight, 70), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > self.SOUND_STEPS[4] then
        self.font:draw("Time Bonus:", Vec2(xLeft, 80), Vec2(0, 0.5))
    end
    if self.time > self.SOUND_STEPS[4] + 0.1 then
        local bonus = self.level.givenTimeBonus
        local text = "No Bonus!"
        if bonus > 0 then
            text = string.format("%.1fs = %s", self.level.time, bonus)
        end
        self.font:draw(text, Vec2(xRight, 80), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > self.SOUND_STEPS[5] then
        self.font:draw("Level Score:", Vec2(xLeft, 90), Vec2(0, 0.5))
    end
    if self.time > self.SOUND_STEPS[5] + 0.1 then
        self.font:draw(tostring(self.level.score), Vec2(xRight, 90), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.newRecordDisplayed then
        self.font:draw("New Record!", Vec2(xRight, 100), Vec2(1, 0.5), _Utils.getRainbowColor(_TotalTime / 4))
    end
    if self.time > self.SOUND_STEPS[6] - 0.4 then
        self.font:draw("Total Score:", Vec2(xLeft, 120), Vec2(0, 0.5))
    end
    if self.time > self.SOUND_STEPS[6] then
        self.font:draw(tostring(self.game.player.session.score), Vec2(xRight, 120), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.time > 4 then
        local text = "Click anywhere to start next level!"
        if self.level.lost then
            text = "Click anywhere to try again!"
        elseif self.level.config.final then
            text = "Click anywhere to continue!"
        end
        --local alpha = (math.sin((self.time - 4.5) * math.pi) + 2) / 3
        local alpha = 0.5 + (self.time % 2) * 0.5
        if self.time % 2 > 1 then
            alpha = 1 + (1 - self.time % 2) * 0.5
        end
        self.font:draw(text, Vec2(xMid, 150), Vec2(0.5), nil, alpha)
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function LevelResults:mousepressed(x, y, button)
    if button == 1 then
        if self:isFinished() then
            self.level:submitLevelStats()
            if not self.level.lost and self.level.config.final then
                self.game.sceneManager:changeScene("game_win", true, true)
            else
                if not self.level.lost then
                    self.game.player.session:advanceLevel()
                else
                    self.game.player.session:restartLevel()
                end
                self.game.sceneManager:startLevel()
                self.game.sceneManager:changeScene("level_intro", true, true)
            end
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
function LevelResults:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function LevelResults:keypressed(key)
end

return LevelResults