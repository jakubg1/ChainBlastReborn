local class = require "com.class"

---@class Level
---@overload fun(game):Level
local Level = class:derive("Level")

-- Place your imports here
local Board = require("src.Game.Board")
local LevelStar = require("src.Game.LevelStar")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



---Constructs a Level.
---@param game GameMain The main game class instance this Level belongs to.
function Level:new(game)
    self.game = game
    self.data = _Game.resourceManager:getLevelConfig("levels/level_" .. tostring(self.game.player.level) .. ".json")

    self.board = nil

    self.score = 0
    self.scoreDisplay = self.game.player.score
    self.maxTime = self.data.time
    self.time = self.maxTime
    self.timeCounting = false
    self.combo = 0
    self.multiplier = 1
    self.multiplierProgress = 0
    self.multiplierProgressDisplay = 0
    self.lost = false
    self.pause = false
    self.pauseAnimation = 0

    self.bombMeter = 0
    self.bombMeterTime = nil
    self.bombMeterCoords = {}

    self.timeElapsed = 0
    self.maxCombo = 0
    self.largestGroup = 0

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
    self.clockAlarm = nil
    self.dangerMusicFlag = false

    self.levelMusic = _Game.resourceManager:getMusic("music_tracks/level_music.json")
    self.dangerMusic = _Game.resourceManager:getMusic("music_tracks/danger_music.json")

    _Game:playSound("sound_events/level_start.json")
    self.levelMusic:play()

    self.stars = {}
    for i = 1, 1500 do
        self.stars[i] = LevelStar(true)
    end
end



---Updates the Level.
---@param dt number Time delta in seconds.
function Level:update(dt)
    if self.pause then
        self.pauseAnimation = math.min(self.pauseAnimation + dt, 1)
    elseif self.pauseAnimation > 0 then
        self.pauseAnimation = math.max(self.pauseAnimation - dt, 0)
    else
        if self.board then
            self.board:update(dt)

            -- Tick the time.
            if self:isTimerTicking() then
                self.time = self.time - dt
                if self.time < 10 and math.floor(self.time) ~= math.floor(self.time + dt) then
                    _Game:playSound("sound_events/clock.json")
                end
                if self.time <= 0 then
                    self.time = 0
                    if not self.bombMeterTime then
                        self:lose()
                    end
                end
            end

            -- Count IGT (In-Game Time).
            if not self.board.startAnimation and not self.board.endAnimation then
                self.timeElapsed = self.timeElapsed + dt
            end

            -- Pause the game after 3 seconds of inactivity.
            if self.lastMousePos == _MousePos and self:isTimerTicking() then
                self.mouseIdleTime = self.mouseIdleTime + dt
                if not self.pause and self.mouseIdleTime > 3 then
                    self:togglePause()
                    self.mouseIdleTime = 0
                end
            else
                self.mouseIdleTime = 0
            end
            self.lastMousePos = _MousePos

            -- Multiplier
            if self.data.multiplierEnabled then
                -- Decrease the value of the bar naturally.
                if self.board.playerControl then
                    self.multiplierProgress = self.multiplierProgress - 0.05 * dt * self.multiplier
                end
                if self.multiplierProgress <= 0 then
                    -- Decrease the multiplier if the bar is empty.
                    self.multiplierProgress = 0
                    if self.multiplier > 1 then
                        self.multiplier = self.multiplier - 1
                        self.multiplierProgress = 1
                    end
                end
            end

            -- Delete the board if it is dead and start the results animation.
            if self.board.delQueue then
                self.board = nil
                self.bombMeterTime = nil
                self:addScore(self:getTimeBonus())
                self.resultsAnimation = 0
            end
        end

        -- Bombs
        if self.bombMeterTime and self.board.shufflingChainCount == 0 then
            local n = math.floor(self.bombMeterTime / 0.5)
            self.bombMeterTime = self.bombMeterTime + dt
            if n ~= math.floor(self.bombMeterTime / 0.5) and n < 3 then
                local tile = self.board:getRandomNonGoldTile(self.bombMeterCoords)
                if tile then
                    self.board:spawnBomb(tile.coords)
                    table.insert(self.bombMeterCoords, tile.coords)
                end
            end
            if self.bombMeterTime >= 1.5 and #self.board.bombs == 0 then
                self.bombMeterTime = nil
                self.bombMeterCoords = {}
            end
        end

        -- Score animation
        if self.scoreDisplay < self.game.player.score then
            self.scoreDisplay = self.scoreDisplay + math.ceil((self.game.player.score - self.scoreDisplay) / 8)
        end

        -- Multiplier animation
        self.multiplierProgressDisplay = self.multiplierProgressDisplay * 0.9 + self.multiplierProgress * 0.1

        -- Combo visualization
        if self.combo >= 2 then
            self.hudComboAlpha = 1
            self.hudComboValue = self.combo
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

    -- Clock alarm (repeated beeps)
    if not self.clockAlarm and self.time < 5 and self:isTimerTicking() then
        self.clockAlarm = _Game:playSound("sound_events/clock_alarm.json")
    end

    if self.clockAlarm and (self.time > 5 or not self:isTimerTicking()) then
        self.clockAlarm:stop()
        self.clockAlarm = nil
    end

    -- Danger music
    if not self.dangerMusicFlag and self.time < 10 and self:isTimerTicking() then
        self.dangerMusicFlag = true
        self.levelMusic:play(0, 0.5)
        self.dangerMusic:play()
    end

    if self.dangerMusicFlag and self.time > 15 and self:isTimerTicking() then
        self.dangerMusicFlag = false
        self.levelMusic:play(1, 2)
        self.dangerMusic:stop(1)
    end

    -- Level start animation
    if self.startAnimation then
        self.startAnimation = self.startAnimation + dt
        self.hudAlpha = math.max((self.startAnimation - 4) * 2, 0)
        if self.startAnimation >= 2.5 and not self.board then
            self.board = Board(self)
        end
        if self.startAnimation >= 7.5 then
            self.startAnimation = nil
            self.hudAlpha = 1
        end
    end

    -- Level win animation
    if self.winAnimation then
        self.winAnimation = self.winAnimation + dt
        if self.winAnimation >= 5 then
            self.winAnimation = nil
            self.board:startEndAnimation()
        end
    end

    -- Level lose animation
    if self.loseAnimation then
        self.loseAnimation = self.loseAnimation + dt
        if self.loseAnimation >= 1 and not self.loseAnimationBoardNuked then
            self.loseAnimationBoardNuked = true
            self.board:nukeEverything()
            if self.game.player.lives == 0 then
                self.loseAnimation = nil
                self.board = nil
                self.bombMeterTime = nil
                self.game.particles = {}
                self.gameOverAnimation = 0
            end
        elseif self.loseAnimation >= 12.5 then
            self.loseAnimation = nil
            self.board:startEndAnimation()
        end
    end

    -- Level results animation
    if self.resultsAnimation then
        self.resultsAnimation = self.resultsAnimation + dt
        self.hudAlpha = math.max(1 - self.resultsAnimation * 2, 0)
        local threshold = self.RESULTS_ANIMATION_SOUND_STEPS[self.resultsAnimationSoundStep]
        if threshold and self.resultsAnimation >= threshold then
            _Game:playSound("sound_events/ui_stats.json")
            self.resultsAnimationSoundStep = self.resultsAnimationSoundStep + 1
        end
    end

    -- Game over animation
    if self.gameOverAnimation then
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

    -- Game win animation
    if self.gameWinAnimation then
        self.gameWinAnimation = self.gameWinAnimation + dt
        if not self.gameWinChimePlayed and self.gameWinAnimation >= 1 then
            _Game:playSound("sound_events/game_win.json")
            self.gameWinChimePlayed = true
        end
    end

    -- Game results animation
    if self.gameResultsAnimation then
        self.gameResultsAnimation = self.gameResultsAnimation + dt
        local threshold = self.GAME_RESULTS_ANIMATION_SOUND_STEPS[self.gameResultsAnimationSoundStep]
        if threshold and self.gameResultsAnimation >= threshold then
            _Game:playSound("sound_events/ui_stats.json")
            self.gameResultsAnimationSoundStep = self.gameResultsAnimationSoundStep + 1
        end
    end

    -- Stars in the background
    for i, star in ipairs(self.stars) do
        star:update(dt)
        if star.delQueue then
            self.stars[i] = LevelStar()
        end
    end
end



---Adds score to this level.
---TODO: Score Events?
---@param amount integer The amount of score to be added.
function Level:addScore(amount)
    self.score = self.score + amount
    self.game.player.score = self.game.player.score + amount
end



---Adds time to this level's timer.
---@param amount number The amount of seconds to be added.
function Level:addTime(amount)
    self.time = self.time + amount
    self.hudExtraTimeAlpha = 2
    self.hudExtraTimeValue = self.hudExtraTimeValue + amount
end



---Starts counting time down in this level.
function Level:startTimer()
    self.timeCounting = true
end



---Returns `true` if the time in this level is ticking down.
---@return boolean
function Level:isTimerTicking()
    return self.board and self.board.playerControl and self.timeCounting and self.pauseAnimation == 0
end



function Level:canPause()
    return not (self.startAnimation or self.winAnimation or self.loseAnimation or self.resultsAnimation or self.gameOverAnimation or self.gameWinAnimation or self.gameResultsAnimation)
end



function Level:togglePause()
    self.pause = not self.pause
    if self:canPause() then
        if self.pause then
            self.levelMusic:play(0, 1)
            self.dangerMusic:play(0, 1)
        else
            if self.dangerMusicFlag then
                self.dangerMusic:play(1, 0.5)
            else
                self.levelMusic:play(1, 1)
            end
        end
    else
        self.pause = false
    end
end



---Increments the combo counter.
function Level:addCombo()
    self.combo = self.combo + 1
    self.maxCombo = math.max(self.maxCombo, self.combo)
end



---Adds the given number of units to the power meter and triggers bombing if the meter has reached 100.
---@param amount integer The amount of units to be added.
function Level:addToBombMeter(amount)
    -- Cooldown before next bombs
    if self.bombMeterTime or self.lost then
        return
    end
    self.bombMeter = self.bombMeter + amount
    if self.bombMeter >= 100 then
        self.bombMeter = 0
        self.bombMeterTime = 0
        _Game:playSound("sound_events/bomb_alarm.json")
    end
end



---Adds the given amount to the multiplier progress. 1 is the full bar.
---@param amount number The progress to be given.
function Level:addToMultiplier(amount)
    if not self.data.multiplierEnabled then
        return
    end
    self.multiplierProgress = self.multiplierProgress + amount
    if self.multiplierProgress >= 1 then
        -- Increase the multiplier if the bar is full.
        self.multiplier = self.multiplier + 1
        self.multiplierProgress = 0.2
        _Vars:set("multiplier", self.multiplier)
        _Game:playSound("sound_events/multiplier_increase.json")
        _Vars:unset("multiplier")
    end
end



---Wins this Level by stopping the music, playing the level win sound and starting the win animation.
function Level:win()
    self.winAnimation = 0
    _Game:playSound("sound_events/level_win.json")
    self.levelMusic:stop(0.25)
    self.dangerMusic:stop(0.25)
end



---Loses this Level by stopping the music, playing the level lose sound, starting the lose animation and panicking the board.
---Also, takes one attempt away from the player.
function Level:lose()
    self.lost = true
    self.board:panicChains()
    self.game.player.lives = self.game.player.lives - 1

    self.loseAnimation = 0
    _Game:playSound("sound_events/level_lose.json")
    self.levelMusic:stop(0.25)
    self.dangerMusic:stop(0.25)
end



---Returns the current total time bonus the player will get based on the current timer value.
---@return integer
function Level:getTimeBonus()
    return math.ceil(self.time * 10) * 30
end



---Draws the Level.
function Level:draw()
    local natRes = _Game:getNativeResolution()

    -- Stars in the background
    for i, star in ipairs(self.stars) do
        star:draw()
    end

    -- Board
    if self.board then
        self.board:draw()
    end

    -- Pause screen
    if self.pauseAnimation > 0 then
        _DrawRect(Vec2(57, 0), Vec2(143, 150), Color(0, 0, 0), self.pauseAnimation)
        self.game.font:draw("Game Paused", Vec2(128, 70), Vec2(0.5), Color(1, 1, 0), self.pauseAnimation)
        local alpha = 0.5 + (_TotalTime % 2) * 0.5
        if _TotalTime % 2 > 1 then
            alpha = 1 + (1 - _TotalTime % 2) * 0.5
        end
        self.game.font:draw("Click to continue", Vec2(128, 80), Vec2(0.5), nil, self.pauseAnimation * alpha)
    end

    -- Level start
    if self.startAnimation then
        local alpha = math.min(self.startAnimation, 1)
        if self.startAnimation >= 6.5 then
            alpha = math.min(7.5 - self.startAnimation, 1)
        end
        if self.game.player.lives == 1 then
            self.game.font:drawWithShadow(string.format("Level %s", self.data.name), natRes / 2 + Vec2(0, -10), Vec2(0.5), nil, alpha)
            alpha = math.max(math.min(self.startAnimation - 1.5, 1))
            if self.startAnimation >= 6.5 then
                alpha = math.min(7.5 - self.startAnimation, 1)
            end
            self.game.font:drawWithShadow("This is your last chance!", natRes / 2, Vec2(0.5), Color(1, 0, 0), alpha)
            self.game.font:drawWithShadow("Don't screw up!", natRes / 2 + Vec2(0, 10), Vec2(0.5), Color(1, 0, 0), alpha)
        else
            self.game.font:drawWithShadow(string.format("Level %s", self.data.name), natRes / 2, Vec2(0.5), nil, alpha)
        end
    end

    -- Main HUD
    if self.hudAlpha > 0 then
        --self.font:draw("10200", Vec2(160, 5), Vec2(0.5, 0), nil, nil, 2)

        -- Score
        self.game.font:draw(tostring(self.scoreDisplay), Vec2(160, 0), Vec2(0.5, 0), nil, self.hudAlpha, 2)
        if self.hudComboAlpha > 0 then
            --self.game.font:draw(string.format("x%s", self.hudComboValue), Vec2(78, 50), Vec2(1, 0), nil, self.hudAlpha * self.hudComboAlpha)
        end

        -- Timer
        self.game.font:draw("Time", Vec2(35, 20), Vec2(0.5, 0), nil, self.hudAlpha)
        if self.time < 9.9 then
            if self.time > 5 or not self:isTimerTicking() or _TotalTime % 0.25 < 0.125 then
                self.game.font:draw(string.format("%.2f", self.time), Vec2(36, 150), Vec2(0.5, 0), Color(1, 0, 0), self.hudAlpha)
            end
        else
            self.game.font:draw(string.format("%.1d:%.2d", self.time / 60, self.time % 60), Vec2(36, 150), Vec2(0.5, 0), nil, self.hudAlpha)
        end
        _DrawRect(Vec2(32, 34), Vec2(7, 112), Color(0.7, 0.5, 0.3), self.hudAlpha)
        _DrawFillRect(Vec2(33, 35), Vec2(5, 110), Color(0.1, 0.1, 0.1), self.hudAlpha)
        local t = math.min(self.time / self.maxTime, 1)
        _DrawFillRect(Vec2(33, 35 + 110 * (1 - t)), Vec2(5, 110 * t), Color(1, 0.7, 0.1), self.hudAlpha)
        if self.hudExtraTimeAlpha > 0 then
            --self.game.font:draw(string.format("+%s", self.hudExtraTimeValue), Vec2(78, 75), Vec2(1, 0), nil, self.hudAlpha * self.hudExtraTimeAlpha)
        end

        -- Power meter
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

        if self.data.multiplierEnabled then
            self.game.font:draw("Multiplier", Vec2(50, 165), Vec2(1, 0), nil, self.hudAlpha)
            _DrawFillRect(Vec2(55, 168), Vec2(150, 7), Color(0.3, 0.3, 0.3), self.hudAlpha)
            _DrawFillRect(Vec2(55, 168), Vec2(150 * self.multiplierProgressDisplay, 7), Color(0, 1, 0), self.hudAlpha)
            self.game.font:draw(string.format("x%s", self.multiplier), Vec2(210, 165), Vec2(), nil, self.hudAlpha)
        end

        self.game.font:draw("Pause [Esc]", Vec2(310, 165), Vec2(1, 0), Color(0.5, 0.5, 0.5))
    end

    -- Level complete animation
    if self.winAnimation then
        local alpha = math.min(self.winAnimation, 0.5)
        if self.winAnimation >= 4.5 then
            alpha = 5 - self.winAnimation
        end
        _DrawFillRect(Vec2(), natRes, Color(0, 0, 0), alpha)
        local textPos = natRes / 2 + Vec2(math.max(1 - self.winAnimation / 0.5, 0) * 150, 0)
        local textAlpha = math.min(5 - self.winAnimation, 1)
        self.game.font:drawWithShadow("Level Complete!", textPos, Vec2(0.5), Color(0, 1, 0), textAlpha)
    end

    -- Level lost animation
    if self.loseAnimation then
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

    -- Level results
    if self.resultsAnimation then
        local alpha = math.min(math.max((self.resultsAnimation - 0.5) * 2, 0), 1)
        self.game.font:draw(string.format("Level %s", self.data.name), Vec2(100, 10), Vec2(0.5), nil, alpha)
        if self.lost then
            self.game.font:draw("Failed!", Vec2(100, 20), Vec2(0.5), Color(1, 0, 0), alpha)
        else
            self.game.font:draw("Complete!", Vec2(100, 20), Vec2(0.5), Color(0, 1, 0), alpha)
        end
        if self.resultsAnimation > 1.2 then
            self.game.font:draw("Time Elapsed:", Vec2(20, 40), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 1.3 then
            self.game.font:draw(string.format("%.1d:%.2d", self.timeElapsed / 60, self.timeElapsed % 60), Vec2(180, 40), Vec2(1, 0.5), Color(1, 1, 0))
        end
        if self.resultsAnimation > 1.6 then
            self.game.font:draw("Max Combo:", Vec2(20, 50), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 1.7 then
            self.game.font:draw(tostring(self.maxCombo), Vec2(180, 50), Vec2(1, 0.5), Color(1, 1, 0))
        end
        if self.resultsAnimation > 2 then
            self.game.font:draw("Largest Link:", Vec2(20, 60), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 2.1 then
            self.game.font:draw(tostring(self.largestGroup), Vec2(180, 60), Vec2(1, 0.5), Color(1, 1, 0))
        end
        if self.resultsAnimation > 2.4 then
            self.game.font:draw("Time Bonus:", Vec2(20, 70), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 2.5 then
            local text = "No Bonus!"
            if not self.lost then
                text = string.format("%.1fs = %s", self.time, self:getTimeBonus())
            end
            self.game.font:draw(text, Vec2(180, 70), Vec2(1, 0.5), Color(1, 1, 0))
        end
        if self.resultsAnimation > 2.8 then
            self.game.font:draw("Level Score:", Vec2(20, 80), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 2.9 then
            self.game.font:draw(tostring(self.score), Vec2(180, 80), Vec2(1, 0.5), Color(1, 1, 0))
        end
        if self.resultsAnimation > 3.4 then
            self.game.font:draw("Total Score:", Vec2(20, 100), Vec2(0, 0.5))
        end
        if self.resultsAnimation > 3.8 then
            self.game.font:draw(tostring(self.game.player.score), Vec2(180, 100), Vec2(1, 0.5), Color(1, 1, 0))
        end
        if self.resultsAnimation > 4.5 then
            local text = "Click anywhere to start next level!"
            if self.lost then
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
            self.game.font:draw(text, Vec2(100, 130), Vec2(0.5), nil, alpha)
        end
    end

    -- Game over
    if self.gameOverAnimation then
        if self.gameOverAnimation > 5 then
            local alpha = math.min((17 - self.gameOverAnimation) / 4, 1)
            self.game.font:draw("GAME", natRes / 2, Vec2(0.5, 1), Color(1, 0, 0), alpha, 5)
            self.game.font:draw("OVER", natRes / 2, Vec2(0.5, 0), Color(1, 0, 0), alpha, 5)
        end
    end

    -- Game win
    if self.gameWinAnimation then
        if self.gameWinAnimation > 0.5 and self.gameWinAnimation <= 9 then
            local alpha = math.max(self.gameWinAnimation * 2 - 0.5, 0)
            if self.gameWinAnimation > 7 then
                alpha = math.min((9 - self.gameWinAnimation) / 2, 1)
            end
            _DrawFillRect(Vec2(), _Game:getNativeResolution(), _Utils.getRainbowColor(math.min((self.gameWinAnimation - 2) / 2, 1.3)), alpha)
            self.game.font:draw("YOU", natRes / 2, Vec2(0.5, 1), Color(0, 0, 0), 5)
            self.game.font:draw("WIN!", natRes / 2, Vec2(0.5, 0), Color(0, 0, 0), 5)
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

    -- Game results
    if self.gameResultsAnimation then
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
            self.game.font:draw(tostring(_Game.largestGroup), Vec2(180, 40), Vec2(1, 0.5), Color(1, 1, 0))
        end
        if self.gameResultsAnimation > 2 then
            self.game.font:draw("Max Combo:", Vec2(20, 50), Vec2(0, 0.5))
        end
        if self.gameResultsAnimation > 2.1 then
            self.game.font:draw(tostring(_Game.maxCombo), Vec2(180, 50), Vec2(1, 0.5), Color(1, 1, 0))
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
            --self.game.font:draw(string.format("%.1d:%.2d", _Game.timeElapsed / 60, _Game.timeElapsed % 60), Vec2(180, 70), Vec2(1, 0.5), Color(1, 1, 0))
        end
        if self.gameResultsAnimation > 3.4 then
            self.game.font:draw("Final Score:", Vec2(100, 90), Vec2(0.5))
        end
        if self.gameResultsAnimation > 3.8 then
            self.game.font:draw(tostring(self.game.player.score), Vec2(100, 105), Vec2(0.5), _Utils.getRainbowColor(_TotalTime / 4), nil, 2)
        end
        if self.gameResultsAnimation > 4.5 then
            local text = "Click anywhere to go to main menu!"
            local alpha = 0.5 + (self.gameResultsAnimation % 2) * 0.5
            if self.gameResultsAnimation % 2 > 1 then
                alpha = 1 + (1 - self.gameResultsAnimation % 2) * 0.5
            end
            self.game.font:draw(text, Vec2(100, 130), Vec2(0.5), nil, alpha)
        end
    end
end



---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Level:mousepressed(x, y, button)
    if self.board then
    	self.board:mousepressed(x, y, button)
    end

    -- Dialog confirmations
    if button == 1 then
        if self.pause then
            self:togglePause()
        end
        if self.resultsAnimation and self.resultsAnimation > 4.5 then
            --_Game.largestGroup = math.max(_Game.largestGroup, self.largestGroup)
            --_Game.maxCombo = math.max(_Game.maxCombo, self.maxCombo)
            --_Game.timeElapsed = _Game.timeElapsed + self.timeElapsed
            if self.game.player.lives == 0 then
                self.resultsAnimation = nil
                self.gameResultsAnimation = 0
            elseif not self.lost and self.game.player.level == 10 then
                self.resultsAnimation = nil
                self.gameWinAnimation = 0
            else
                if not self.lost then
                    self.game.player:advanceLevel()
                end
                self.game:changeScene("level", true, true)
            end
            _Game:playSound("sound_events/ui_select.json")
        elseif self.gameWinAnimation and self.gameWinAnimation > 11.5 then
            self.gameWinAnimation = nil
            self.gameResultsAnimation = 0
        elseif self.gameResultsAnimation and self.gameResultsAnimation > 4.5 then
            --_Game:endGame()
            self.game:changeScene("menu")
            _Game:playSound("sound_events/ui_select.json")
        end
    end
end



---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function Level:mousereleased(x, y, button)
    if self.board then
    	self.board:mousereleased(x, y, button)
    end
end



return Level