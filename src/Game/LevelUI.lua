local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class LevelUI
---@overload fun(level):LevelUI
local LevelUI = class:derive("LevelUI")

---Constructs Level UI.
---@param level Level Owner of this UI.
function LevelUI:new(level)
    self.level = level
    self.game = level.game

    self.scoreDisplay = self.game.player.score
    self.multiplierProgressDisplay = 0
    self.pauseAnimation = 0
    self.startAnimation = 0
    self.winAnimation = nil
    self.loseAnimation = nil
    self.loseAnimationBoardNuked = false
    self.resultsAnimation = nil
    self.resultsAnimationSoundStep = 1
    self.RESULTS_ANIMATION_SOUND_STEPS = {1.2, 1.6, 2, 2.4, 2.8, 3.8}
    self.gameWinAnimation = nil
    self.gameWinChimePlayed = false
    self.gameOverAnimation = nil
    self.gameOverHeSaid = false
    self.gameResultsAnimation = nil
    self.gameResultsAnimationSoundStep = 1
    self.GAME_RESULTS_ANIMATION_SOUND_STEPS = {1.2, 1.6, 2, 2.4, 2.8, 3.8}

    self.hudAlpha = 0
    self.hudComboAlpha = 0
    self.hudComboValue = 0
    self.hudExtraTimeAlpha = 0
    self.hudExtraTimeValue = 0
    self.POWER_METER_COLORS = {
        [0] = Color(1, 1, 1),
        Color(0.9, 0.1, 0.3),
        Color(0.1, 0.4, 0.9),
        Color(1, 0.4, 0),
        --[0] = {1, 1, 1},
        --{0.1, 0.4, 0.9},
        --{1, 0.4, 0},
        --{0.9, 0.1, 0.3}
    }

    self.timerSprite = _Game.resourceManager:getSprite("sprites/hud_timer.json")
end

---Notifies the UI that extra time has been added to the timer.
---@param time number The added time in seconds.
function LevelUI:notifyExtraTime(time)
    self.hudExtraTimeAlpha = 2
    self.hudExtraTimeValue = self.hudExtraTimeValue + time
end

---Notifies the UI that the current level has been complted.
function LevelUI:notifyWin()
    self.winAnimation = 0
end

---Notifies the UI that the current level has been lost.
function LevelUI:notifyLose()
    self.loseAnimation = 0
end

---Starts the level results animation.
function LevelUI:notifyResults()
    self.resultsAnimation = 0
end

---Starts the game win animation.
function LevelUI:notifyGameWin()
    self.resultsAnimation = nil
    self.gameWinAnimation = 0
end

---Starts the game results animation.
function LevelUI:notifyGameResults()
    self.resultsAnimation = nil
    self.gameWinAnimation = nil
    self.gameResultsAnimation = 0
end

---Returns `true` if any UI animation is being played right now.
---@return boolean
function LevelUI:isAnimationPlaying()
    return (self.startAnimation or self.winAnimation or self.loseAnimation or self.resultsAnimation or self.gameOverAnimation or self.gameWinAnimation or self.gameResultsAnimation) ~= nil
end

---Returns `true` if the pause screen is visible in any capacity.
---@return boolean
function LevelUI:isPauseVisible()
    return self.pauseAnimation > 0
end

---Returns `true` if the results animation has finished (is ready to click for the next level).
---@return boolean
function LevelUI:isResultsAnimationFinished()
    return self.resultsAnimation and self.resultsAnimation > 4.5
end

---Returns `true` if the game win animation has finished (is ready to click to go to game results).
---@return boolean
function LevelUI:isGameWinAnimationFinished()
    return self.gameWinAnimation and self.gameWinAnimation > 11.5
end

---Returns `true` if the game results animation has finished (is ready to click to go back to main menu).
---@return boolean
function LevelUI:isGameResultsAnimationFinished()
    return self.gameResultsAnimation and self.gameResultsAnimation > 4.5
end

---Updates the level UI.
---@param dt number Time delta in seconds.
function LevelUI:update(dt)
    self:updatePause(dt)
    self:updateHUD(dt)
    self:updateLevelStart(dt)
    self:updateLevelWin(dt)
    self:updateLevelLost(dt)
    self:updateLevelResults(dt)
    self:updateGameOver(dt)
    self:updateGameWin(dt)
    self:updateGameResults(dt)
end

---Updates the pause screen.
---@param dt number Time delta in seconds.
function LevelUI:updatePause(dt)
    if self.level.pause then
        self.pauseAnimation = math.min(self.pauseAnimation + dt, 1)
    else
        self.pauseAnimation = math.max(self.pauseAnimation - dt, 0)
    end
end

---Updates gauges on the HUD.
---@param dt number Time delta in seconds.
function LevelUI:updateHUD(dt)
    -- Score animation
    if self.scoreDisplay < self.game.player.score then
        self.scoreDisplay = self.scoreDisplay + math.ceil((self.game.player.score - self.scoreDisplay) / 8)
    end

    -- Multiplier animation
    self.multiplierProgressDisplay = self.multiplierProgressDisplay * 0.9 + self.level.multiplierProgress * 0.1

    -- Combo visualization
    if self.level.combo >= 2 then
        self.hudComboAlpha = 1
        self.hudComboValue = self.level.combo
    else
        self.hudComboAlpha = math.max(self.hudComboAlpha - dt, 0)
    end

    -- Extra time visualization
    if self.hudExtraTimeAlpha > 0 then
        self.hudExtraTimeAlpha = self.hudExtraTimeAlpha - dt
        if self.hudExtraTimeAlpha <= 0 then
            self.hudExtraTimeAlpha = 0
            self.hudExtraTimeValue = 0
        end
    end
end

---Updates the level start animation.
---@param dt number Time delta in seconds.
function LevelUI:updateLevelStart(dt)
    if not self.startAnimation then
        return
    end
    self.startAnimation = self.startAnimation + dt
    self.hudAlpha = math.max((self.startAnimation - 4) * 2, 0)
    if self.startAnimation >= 2.5 and not self.level.board then
        self.level:startBoard()
    end
    if self.startAnimation >= 7.5 then
        self.startAnimation = nil
        self.hudAlpha = 1
    end
end

---Updates the level win animation.
---@param dt number Time delta in seconds.
function LevelUI:updateLevelWin(dt)
    if not self.winAnimation then
        return
    end
    self.winAnimation = self.winAnimation + dt
    if self.winAnimation >= 5 then
        self.winAnimation = nil
        self.level:finishBoard()
    end
end

---Updates the level loss animation.
---@param dt number Time delta in seconds.
function LevelUI:updateLevelLost(dt)
    if not self.loseAnimation then
        return
    end
    self.loseAnimation = self.loseAnimation + dt
    if self.loseAnimation >= 1 and not self.loseAnimationBoardNuked then
        self.loseAnimationBoardNuked = true
        self.level:nukeBoard()
        if self.game.player.lives == 0 then
            self.loseAnimation = nil
            self.board = nil
            self.bombMeterTime = nil
            self.game.particles = {}
            self.gameOverAnimation = 0
        end
    elseif self.loseAnimation >= 12.5 then
        self.loseAnimation = nil
        self.level:finishBoard()
    end
end

---Updates the level results animation.
---@param dt number Time delta in seconds.
function LevelUI:updateLevelResults(dt)
    if not self.resultsAnimation then
        return
    end
    self.resultsAnimation = self.resultsAnimation + dt
    self.hudAlpha = math.max(1 - self.resultsAnimation * 2, 0)
    local threshold = self.RESULTS_ANIMATION_SOUND_STEPS[self.resultsAnimationSoundStep]
    if threshold and self.resultsAnimation >= threshold then
        _Game:playSound("sound_events/ui_stats.json")
        self.resultsAnimationSoundStep = self.resultsAnimationSoundStep + 1
    end
end

---Updates the game over screen.
---@param dt number Time delta in seconds.
function LevelUI:updateGameOver(dt)
    if not self.gameOverAnimation then
        return
    end
    self.gameOverAnimation = self.gameOverAnimation + dt
    self.hudAlpha = 0
    if not self.gameOverHeSaid and self.gameOverAnimation >= 5 then
        _Game:playSound("sound_events/game_over.json")
        self.gameOverHeSaid = true
    end
    if self.gameOverAnimation >= 19 then
        self.gameOverAnimation = nil
        self.resultsAnimation = 0.5
    end
end

---Updates the game win screen.
---@param dt number Time delta in seconds.
function LevelUI:updateGameWin(dt)
    if not self.gameWinAnimation then
        return
    end
    self.gameWinAnimation = self.gameWinAnimation + dt
    if not self.gameWinChimePlayed and self.gameWinAnimation >= 1 then
        _Game:playSound("sound_events/game_win.json")
        self.gameWinChimePlayed = true
    end
end

---Updates the game results screen.
---@param dt number Time delta in seconds.
function LevelUI:updateGameResults(dt)
    if not self.gameResultsAnimation then
        return
    end
    self.gameResultsAnimation = self.gameResultsAnimation + dt
    local threshold = self.GAME_RESULTS_ANIMATION_SOUND_STEPS[self.gameResultsAnimationSoundStep]
    if threshold and self.gameResultsAnimation >= threshold then
        _Game:playSound("sound_events/ui_stats.json")
        self.gameResultsAnimationSoundStep = self.gameResultsAnimationSoundStep + 1
    end
end

---Draws the level UI (level intro, pause screen, HUD, win/lose screens, game win/game over screens, game results).
function LevelUI:draw()
    self:drawPause()
    self:drawIntro()
    self:drawHUD()
    self:drawLevelWin()
    self:drawLevelLost()
    self:drawLevelResults()
    self:drawGameOver()
    self:drawGameWin()
    self:drawGameResults()
end

---Draws the pause screen.
function LevelUI:drawPause()
    if self.pauseAnimation == 0 then
        return
    end
    local natRes = _Game:getNativeResolution()
    _DrawFillRect(Vec2(57, 0), Vec2(180, 200), Color(0, 0, 0), self.pauseAnimation)
    self.game.font:draw("Game Paused", natRes / 2 + Vec2(0, -5), Vec2(0.5), Color(1, 1, 0), self.pauseAnimation)
    local alpha = 0.5 + (_TotalTime % 2) * 0.5
    if _TotalTime % 2 > 1 then
        alpha = 1 + (1 - _TotalTime % 2) * 0.5
    end
    self.game.font:draw("Click to continue", natRes / 2 + Vec2(0, 5), Vec2(0.5), nil, self.pauseAnimation * alpha)
end

---Draws the level intro screen.
function LevelUI:drawIntro()
    if not self.startAnimation then
        return
    end
    local natRes = _Game:getNativeResolution()
    local alpha = math.min(self.startAnimation, 1)
    if self.startAnimation >= 6.5 then
        alpha = math.min(7.5 - self.startAnimation, 1)
    end
    if self.game.player.lives == 1 then
        self.game.font:drawWithShadow(string.format("Level %s", self.level.data.name), natRes / 2 + Vec2(0, -10), Vec2(0.5), nil, alpha)
        alpha = math.max(math.min(self.startAnimation - 1.5, 1))
        if self.startAnimation >= 6.5 then
            alpha = math.min(7.5 - self.startAnimation, 1)
        end
        self.game.font:drawWithShadow("This is your last chance!", natRes / 2, Vec2(0.5), Color(1, 0, 0), alpha)
        self.game.font:drawWithShadow("Don't screw up!", natRes / 2 + Vec2(0, 10), Vec2(0.5), Color(1, 0, 0), alpha)
    else
        self.game.font:drawWithShadow(string.format("Level %s", self.level.data.name), natRes / 2, Vec2(0.5), nil, alpha)
    end
end

---Draws the HUD.
function LevelUI:drawHUD()
    if self.hudAlpha == 0 then
        return
    end
    --self.font:draw("10200", Vec2(160, 5), Vec2(0.5, 0), nil, nil, 2)

    -- Score
    self.game.font:draw(tostring(self.scoreDisplay), Vec2(160, 0), Vec2(0.5, 0), nil, self.hudAlpha, 2)
    if self.hudComboAlpha > 0 then
        --self.game.font:draw(string.format("x%s", self.hudComboValue), Vec2(78, 50), Vec2(1, 0), nil, self.hudAlpha * self.hudComboAlpha)
    end

    -- Timer
    if not self.game.player.disableTimeLimit then
        self.game.font:draw("Time", Vec2(35, 20), Vec2(0.5, 0), nil, self.hudAlpha)
        -- Bar
        local t = math.min(self.level.time / self.level.maxTime, 1)
        _DrawFillRect(Vec2(33, 40 + 108 * (1 - t)), Vec2(5, 110 * t), Color(0.1, 0.4, 0.9), self.hudAlpha)
        -- Timer box
        self.timerSprite:draw(Vec2(19, 34), nil, nil, nil, nil, nil, self.hudAlpha)
        -- Text display
        if self.level.time < 9.9 then
            if self.level.time > 5 or not self.level:isTimerTicking() or _TotalTime % 0.25 < 0.125 then
                self.game.font:draw(string.format("%.2f", self.level.time), Vec2(36, 150), Vec2(0.5, 0), Color(1, 0, 0), self.hudAlpha)
            end
        else
            self.game.font:draw(string.format("%.1d:%.2d", self.level.time / 60, self.level.time % 60), Vec2(36, 150), Vec2(0.5, 0), nil, self.hudAlpha)
        end
    end

    -- Old power (bomb) meter
    --[[
    self.game.font:draw("Power", Vec2(285, 20), Vec2(0.5, 0), nil, self.hudAlpha)
    _DrawRect(Vec2(281, 34), Vec2(7, 112), Color(0.7, 0.5, 0.3), self.hudAlpha)
    if self.bombMeterTime then
        if _TotalTime % 0.3 < 0.15 then
            _DrawFillRect(Vec2(29, 112), Vec2(48, 9), Color(1, 0, 0), self.hudAlpha)
        end
        self.game.font:draw(string.format("BOMBS: %s", math.max(3 - math.floor(self.bombMeterTime / 0.5), 0)), Vec2(76, 110), Vec2(1, 0), nil, self.hudAlpha)
    else
        local color = (self.bombMeter > 90 and _TotalTime % 0.3 < 0.15) and Color(1, 1, 1) or Color(1, 0.7, 0)
        local t = math.min(self.bombMeter / 100, 1)
        _DrawFillRect(Vec2(282, 35 + 110 * (1 - t)), Vec2(5, 110 * t), color, self.hudAlpha)
        self.game.font:draw(tostring(self.bombMeter), Vec2(286, 150), Vec2(1, 0), nil, self.hudAlpha)
    end
    ]]

    -- New power meter
    self.game.font:draw("Power", Vec2(285, 20), Vec2(0.5, 0), nil, self.hudAlpha)
    _DrawRect(Vec2(281, 34), Vec2(7, 112), Color(0.7, 0.5, 0.3), self.hudAlpha)
    local color = (self.level.powerMeter > 90 and _TotalTime % 0.3 < 0.15) and Color(1, 1, 1) or self.POWER_METER_COLORS[self.level.powerColor]
    local t = math.min(self.level.powerMeter / 100, 1)
    _DrawFillRect(Vec2(282, 35 + 110 * (1 - t)), Vec2(5, 110 * t), color, self.hudAlpha)
    self.game.font:draw(tostring(self.level.powerMeter), Vec2(286, 150), Vec2(1, 0), nil, self.hudAlpha)

    if self.level.data.multiplierEnabled then
        self.game.font:draw("Multiplier", Vec2(50, 165), Vec2(1, 0), nil, self.hudAlpha)
        _DrawFillRect(Vec2(55, 168), Vec2(150, 7), Color(0.3, 0.3, 0.3), self.hudAlpha)
        _DrawFillRect(Vec2(55, 168), Vec2(150 * self.multiplierProgressDisplay, 7), Color(0, 1, 0), self.hudAlpha)
        self.game.font:draw(string.format("x%s", self.level.multiplier), Vec2(210, 165), Vec2(), nil, self.hudAlpha)
    end

    self.game.font:draw("Pause [Esc]", Vec2(310, 165), Vec2(1, 0), Color(0.5, 0.5, 0.5))
end

---Draws the level win animation.
function LevelUI:drawLevelWin()
    if not self.winAnimation then
        return
    end
    local natRes = _Game:getNativeResolution()
    local alpha = math.min(self.winAnimation, 0.5)
    if self.winAnimation >= 4.5 then
        alpha = 5 - self.winAnimation
    end
    _DrawFillRect(Vec2(), natRes, Color(0, 0, 0), alpha)
    local textPos = natRes / 2 + Vec2(math.max(1 - self.winAnimation / 0.5, 0) * 150, 0)
    local textAlpha = math.min(5 - self.winAnimation, 1)
    self.game.font:drawWithShadow("Level Complete!", textPos, Vec2(0.5), Color(0, 1, 0), textAlpha)
end

---Draws the level loss animation.
function LevelUI:drawLevelLost()
    if not self.loseAnimation then
        return
    end
    local natRes = _Game:getNativeResolution()
    local alpha = math.max(math.min(self.loseAnimation - 1.5, 0.5), 0)
    if self.loseAnimation >= 11 then
        alpha = (12 - self.loseAnimation) / 2
    end
    _DrawFillRect(Vec2(), natRes, Color(0, 0, 0), alpha)
    local textAlpha = math.max(math.min((self.loseAnimation - 2) / 2, 1), 0)
    if self.loseAnimation >= 11 then
        textAlpha = math.min(12 - self.loseAnimation, 1)
    end
    local texts = {"2 attempts left!", "Last attempt left!!!", "Uh oh..."}
    local text = texts[3 - self.game.player.lives]
    self.game.font:drawWithShadow(text, natRes / 2, Vec2(0.5), Color(1, 0, 0), textAlpha)
end

---Draws the level results.
function LevelUI:drawLevelResults()
    if not self.resultsAnimation then
        return
    end
    local xLeft = 60
    local xMid = 160
    local xRight = 260
    local alpha = math.min(math.max((self.resultsAnimation - 0.5) * 2, 0), 1)
    self.game.font:draw(string.format("Level %s", self.level.data.name), Vec2(xMid, 15), Vec2(0.5), nil, alpha)
    if self.level.lost then
        self.game.font:draw("Failed!", Vec2(xMid, 25), Vec2(0.5), Color(1, 0, 0), alpha)
    else
        self.game.font:draw("Complete!", Vec2(xMid, 25), Vec2(0.5), Color(0, 1, 0), alpha)
    end
    if self.resultsAnimation > 1.2 then
        self.game.font:draw("Time Elapsed:", Vec2(xLeft, 50), Vec2(0, 0.5))
    end
    if self.resultsAnimation > 1.3 then
        self.game.font:draw(string.format("%.1d:%.2d", self.level.timeElapsed / 60, self.level.timeElapsed % 60), Vec2(xRight, 50), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.resultsAnimation > 1.6 then
        self.game.font:draw("Max Combo:", Vec2(xLeft, 60), Vec2(0, 0.5))
    end
    if self.resultsAnimation > 1.7 then
        self.game.font:draw(tostring(self.level.maxCombo), Vec2(xRight, 60), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.resultsAnimation > 2 then
        self.game.font:draw("Largest Link:", Vec2(xLeft, 70), Vec2(0, 0.5))
    end
    if self.resultsAnimation > 2.1 then
        self.game.font:draw(tostring(self.level.largestGroup), Vec2(xRight, 70), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.resultsAnimation > 2.4 then
        self.game.font:draw("Time Bonus:", Vec2(xLeft, 80), Vec2(0, 0.5))
    end
    if self.resultsAnimation > 2.5 then
        local text = "No Bonus!"
        if not self.level.lost then
            text = string.format("%.1fs = %s", self.level.time, self.level:getTimeBonus())
        end
        self.game.font:draw(text, Vec2(xRight, 80), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.resultsAnimation > 2.8 then
        self.game.font:draw("Level Score:", Vec2(xLeft, 90), Vec2(0, 0.5))
    end
    if self.resultsAnimation > 2.9 then
        self.game.font:draw(tostring(self.level.score), Vec2(xRight, 90), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.resultsAnimation > 3.4 then
        self.game.font:draw("Total Score:", Vec2(xLeft, 120), Vec2(0, 0.5))
    end
    if self.resultsAnimation > 3.8 then
        self.game.font:draw(tostring(self.game.player.score), Vec2(xRight, 120), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.resultsAnimation > 4.5 then
        local text = "Click anywhere to start next level!"
        if self.level.lost then
            if self.game.player.lives > 0 then
                text = "Click anywhere to try again!"
            else
                text = "Click anywhere to continue!"
            end
        else
            if self.game.player.level == 10 then
                text = "Click anywhere to continue!"
            end
        end
        --local alpha = (math.sin((self.resultsAnimation - 4.5) * math.pi) + 2) / 3
        local alpha = 0.5 + (self.resultsAnimation % 2) * 0.5
        if self.resultsAnimation % 2 > 1 then
            alpha = 1 + (1 - self.resultsAnimation % 2) * 0.5
        end
        self.game.font:draw(text, Vec2(xMid, 150), Vec2(0.5), nil, alpha)
    end
end

---Draws the game over screen.
function LevelUI:drawGameOver()
    if not self.gameOverAnimation then
        return
    end
    local natRes = _Game:getNativeResolution()
    if self.gameOverAnimation > 5 then
        local alpha = math.min((17 - self.gameOverAnimation) / 4, 1)
        self.game.font:draw("GAME", natRes / 2, Vec2(0.5, 1), Color(1, 0, 0), alpha, 5)
        self.game.font:draw("OVER", natRes / 2, Vec2(0.5, 0), Color(1, 0, 0), alpha, 5)
    end
end

---Draws the game win screen.
function LevelUI:drawGameWin()
    if not self.gameWinAnimation then
        return
    end
    local natRes = _Game:getNativeResolution()
    if self.gameWinAnimation > 0.5 and self.gameWinAnimation <= 9 then
        local alpha = math.max(self.gameWinAnimation * 2 - 0.5, 0)
        if self.gameWinAnimation > 7 then
            alpha = math.min((9 - self.gameWinAnimation) / 2, 1)
        end
        _DrawFillRect(Vec2(), _Game:getNativeResolution(), _Utils.getRainbowColor(math.min((self.gameWinAnimation - 2) / 2, 1.3)), alpha)
        self.game.font:draw("YOU", natRes / 2, Vec2(0.5, 1), Color(0, 0, 0), 1, 5)
        self.game.font:draw("WIN!", natRes / 2, Vec2(0.5, 0), Color(0, 0, 0), 1, 5)
    elseif self.gameWinAnimation > 9 then
        local alpha = math.min(math.max((self.gameWinAnimation - 9) * 2, 0), 1)
        self.game.font:draw("Congratulations!", Vec2(100, 10), Vec2(0.5), Color(1, 1, 0), alpha)
        local yOffset = math.max((11 - self.gameWinAnimation) * 150, 0)
        local text = {
            "You've beaten all ten levels!",
            "But... is that the end? Well, I hope not!",
            "This is just a demo I've made in one week.",
            "I have a few more ideas for the full game!",
            --"I've had the concept for this game",
            --"sitting in my head for past few months!",
            "I hope you've enjoyed this journey.",
            "Were some levels too hard?",
            "Did you not like something?",
            "Or maybe you have some cool ideas?",
            "I'd love your feedback!"
        }
        for i, line in ipairs(text) do
            self.game.font:draw(line, Vec2(100, 20 + i * 10 + yOffset), Vec2(0.5))
        end
    end
    if self.gameWinAnimation > 11.5 then
        local text = "Click anywhere to continue!"
        local alpha = 0.5 + (self.gameWinAnimation % 2) * 0.5
        if self.gameWinAnimation % 2 > 1 then
            alpha = 1 + (1 - self.gameWinAnimation % 2) * 0.5
        end
        self.game.font:draw(text, Vec2(100, 130), Vec2(0.5), nil, alpha)
    end
end

---Draws the game results.
function LevelUI:drawGameResults()
    if not self.gameResultsAnimation then
        return
    end
    local alpha = math.min(math.max((self.gameResultsAnimation - 0.5) * 2, 0), 1)
    self.game.font:draw("Game Results", Vec2(100, 10), Vec2(0.5), nil, alpha)
    if self.gameResultsAnimation > 1.2 then
        self.game.font:draw("Chains Destroyed:", Vec2(20, 30), Vec2(0, 0.5))
    end
    if self.gameResultsAnimation > 1.3 then
        self.game.font:draw(tostring(_Game.chainsDestroyed), Vec2(180, 30), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.gameResultsAnimation > 1.6 then
        self.game.font:draw("Largest Link:", Vec2(20, 40), Vec2(0, 0.5))
    end
    if self.gameResultsAnimation > 1.7 then
        self.game.font:draw(tostring(self.game.player.largestGroup), Vec2(180, 40), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.gameResultsAnimation > 2 then
        self.game.font:draw("Max Combo:", Vec2(20, 50), Vec2(0, 0.5))
    end
    if self.gameResultsAnimation > 2.1 then
        self.game.font:draw(tostring(self.game.player.maxCombo), Vec2(180, 50), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.gameResultsAnimation > 2.4 then
        self.game.font:draw("Attempts per Level:", Vec2(20, 60), Vec2(0, 0.5))
    end
    if self.gameResultsAnimation > 2.5 then
        --self.game.font:draw(string.format("%s / %s = %.2f", _Game.levelsStarted, _Game.levelsBeaten + 1, _Game.levelsStarted / (_Game.levelsBeaten + 1)), Vec2(180, 60), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.gameResultsAnimation > 2.8 then
        self.game.font:draw("Total Time:", Vec2(20, 70), Vec2(0, 0.5))
    end
    if self.gameResultsAnimation > 2.9 then
        self.game.font:draw(string.format("%.1d:%.2d", self.game.player.timeElapsed / 60, self.game.player.timeElapsed % 60), Vec2(180, 70), Vec2(1, 0.5), Color(1, 1, 0))
    end
    if self.gameResultsAnimation > 3.4 then
        self.game.font:draw("Final Score:", Vec2(100, 90), Vec2(0.5))
    end
    if self.gameResultsAnimation > 3.8 then
        self.game.font:draw(tostring(self.game.player.score), Vec2(100, 105), Vec2(0.5), _Utils.getRainbowColor(_TotalTime / 4), nil, 2)
    end
    if self.gameResultsAnimation > 4.5 then
        local text = "Click anywhere to go to main menu!"
        alpha = 0.5 + (self.gameResultsAnimation % 2) * 0.5
        if self.gameResultsAnimation % 2 > 1 then
            alpha = 1 + (1 - self.gameResultsAnimation % 2) * 0.5
        end
        self.game.font:draw(text, Vec2(100, 130), Vec2(0.5), nil, alpha)
    end
end

return LevelUI