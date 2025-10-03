local class = require "com.class"

---@class Level
---@overload fun(game):Level
local Level = class:derive("Level")

local Board = require("src.Game.Board")
local LevelUI = require("src.Game.LevelUI")
local LevelStar = require("src.Game.LevelStar")

---Constructs a Level.
---@param game GameMain The main game class instance this Level belongs to.
function Level:new(game)
    self.game = game
    self.data = _Game.resourceManager:getLevelConfig("levels/level_" .. tostring(self.game.player.level) .. ".json")

    self.board = nil
    self.ui = LevelUI(self)

    self.score = 0
    self.maxTime = self.data.time
    self.time = self.maxTime
    self.timeCounting = false
    self.combo = 0
    self.multiplier = 1
    self.multiplierProgress = 0
    self.lost = false
    self.pause = false

    self.bombMeter = 0
    self.bombMeterTime = nil
    self.bombMeterCoords = {}

    self.powerMeter = 0
    self.powerColor = 0

    self.timeElapsed = 0
    self.maxCombo = 0
    self.largestGroup = 0

    self.clockAlarm = nil
    self.dangerMusicFlag = false
    self.forcedWin = false

    self.levelMusic = _Game.resourceManager:getMusic("music_tracks/level_music.json")
    self.dangerMusic = _Game.resourceManager:getMusic("music_tracks/danger_music.json")

    _Game:playSound("sound_events/level_start.json")
    self.levelMusic:play()

    self.stars = {}
    for i = 1, 1500 do
        --self.stars[i] = LevelStar(true)
    end
end

---Updates the Level.
---@param dt number Time delta in seconds.
function Level:update(dt)
    if not self.ui:isPauseVisible() and self.board then
        self.board:update(dt)
        self:updateTime(dt)
        self:updateInactivityPause(dt)
        self:updateMultiplier(dt)
        self:updateBombs(dt)

        -- Delete the board if it is dead and start the results animation.
        if self.board.delQueue then
            self.board = nil
            self.bombMeterTime = nil
            self:addScore(self:getTimeBonus())
            self.ui:notifyResults()
        end
    end

    self:updateSounds(dt)
    self:updateMusic(dt)
    self.ui:update(dt)
    self:updateBackground(dt)
end

---Updates timing on this level. Trips the loss flag if the timer reaches zero.
---This same function is also counting IGT up to show on various stat screens.
---@param dt number Time delta in seconds.
function Level:updateTime(dt)
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
end

---Updates the inactivity pause mechanism.
---@param dt number Time delta in seconds.
function Level:updateInactivityPause(dt)
    -- Halt the inactivity pausing when the timer is not ticking yet (level not started or a long combo)
    -- or when the player is currently dragging through chains.
    if not self:isTimerTicking() or self.board:isSelectionActive() then
        return
    end
    -- Pause the game when 3 seconds from any mouse movement have passed.
    -- TODO: This might be annoying and should be able to be turned off from the settings menu.
    if self.lastMousePos == _MousePos then
        self.mouseIdleTime = self.mouseIdleTime + dt
        if not self.pause and self.mouseIdleTime > 3 then
            self:togglePause()
            self.mouseIdleTime = 0
        end
    else
        self.mouseIdleTime = 0
    end
    self.lastMousePos = _MousePos
end

---Updates the score multiplier (currently unused).
---@param dt number Time delta in seconds.
function Level:updateMultiplier(dt)
    if not self.data.multiplierEnabled then
        return
    end
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

---Updates the bombs (currently unused).
---@param dt number Time delta in seconds.
function Level:updateBombs(dt)
    -- No bomb spawning happens when the bomb meter is not engaged or when a shuffle is in progress.
    if not self.bombMeterTime or self.board.shufflingChainCount > 0 then
        return
    end
    -- Every 0.5 seconds, spawn a bomb (check if we moved into another interval).
    local n = math.floor(self.bombMeterTime / 0.5)
    self.bombMeterTime = self.bombMeterTime + dt
    if n ~= math.floor(self.bombMeterTime / 0.5) and n < 3 then
        local tile = self.board:getRandomNonGoldTile(self.bombMeterCoords)
        if tile then
            self.board:spawnBomb(tile.coords)
            table.insert(self.bombMeterCoords, tile.coords)
        end
    end
    -- When all three intervals are finished, end the spawning process.
    if self.bombMeterTime >= 1.5 and #self.board.bombs == 0 then
        self.bombMeterTime = nil
        self.bombMeterCoords = {}
    end
end

---Updates the level sounds (alarm clock).
---@param dt number Time delta in seconds.
function Level:updateSounds(dt)
    if not self.clockAlarm and self.time < 5 and self:isTimerTicking() then
        self.clockAlarm = _Game:playSound("sound_events/clock_alarm.json")
    end

    if self.clockAlarm and (self.time > 5 or not self:isTimerTicking()) then
        self.clockAlarm:stop()
        self.clockAlarm = nil
    end
end

---Updates the level music (fade between level and danger music).
---@param dt number Time delta in seconds.
function Level:updateMusic(dt)
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
end

---Updates the level background.
---@param dt number Time delta in seconds.
function Level:updateBackground(dt)
    for i, star in ipairs(self.stars) do
        star:update(dt)
        if star.delQueue then
            self.stars[i] = LevelStar()
        end
    end
end

---Creates a Board for this Level.
function Level:startBoard()
    self.board = Board(self)
end

---Nukes all chains on the board for this level.
function Level:nukeBoard()
    self.board:nukeEverything()
end

---Starts a fadeout animation for this level's Board.
function Level:finishBoard()
    self.board:startEndAnimation()
end

---Adds score to this level.
---@param amount integer The amount of score to be added.
function Level:addScore(amount)
    self.score = self.score + amount
    self.game.player.score = self.game.player.score + amount
end

---Adds time to this level's timer.
---@param amount number The amount of seconds to be added to the clock.
function Level:addTime(amount)
    self.time = self.time + amount
    self.ui:notifyExtraTime(amount)
end

---Starts counting time down in this level.
function Level:startTimer()
    if self.timeCounting or self.game.player.disableTimeLimit then
        return
    end
    self.timeCounting = true
    _Game:playSound("sound_events/clock.json")
end

---Returns `true` if the time in this level is ticking down.
---@return boolean
function Level:isTimerTicking()
    return self.board and self.board.playerControl and self.timeCounting and not self.ui:isAnimationPlaying()
end

---Returns `true` if the game can be paused, `false` if only unpaused.
---@return boolean
function Level:canPause()
    return not self.ui:isAnimationPlaying()
end

---Toggles the pause state on or off.
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

---Adds the given amount of power points to the power gauge.
---If the current power color is 0 (any), the power gauge takes on that color.
---If the given color is different to the current power color, the power points are discarded.
---@param amount integer The amount of the power points.
---@param color integer Color of the power.
function Level:addToPowerMeter(amount, color)
    if self.powerColor ~= 0 and self.powerColor ~= color then
        return
    end
    if self.powerColor == 0 then
        self.powerColor = color
    end
    self.powerMeter = self.powerMeter + amount
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
    _Game:playSound("sound_events/level_win.json")
    self.levelMusic:stop(0.25)
    self.dangerMusic:stop(0.25)
    self.ui:notifyWin()
end

---Loses this Level by stopping the music, playing the level lose sound, starting the lose animation and panicking the board.
---Also, takes one attempt away from the player.
function Level:lose()
    self.lost = true
    self.board:panicChains()
    self.game.player.lives = self.game.player.lives - 1

    _Game:playSound("sound_events/level_lose.json")
    self.levelMusic:stop(0.25)
    self.dangerMusic:stop(0.25)
    self.ui:notifyLose()
end

---Returns the current total time bonus the player will get based on the current timer value.
---@return integer
function Level:getTimeBonus()
    return math.ceil(self.time * 10) * 30
end

---Draws the Level.
function Level:draw()
    self:drawBackground()
    self:drawBoard()
    self.ui:draw()
end

---Draws the level background.
function Level:drawBackground()
    for i, star in ipairs(self.stars) do
        star:draw()
    end
end

---Draws the level board.
function Level:drawBoard()
    if self.board then
        self.board:draw()
    end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Level:mousepressed(x, y, button)
    if self.board and not self.pause then
    	self.board:mousepressed(x, y, button)
    end

    -- Dialog confirmations
    if button == 1 then
        if self.pause then
            self:togglePause()
        end
        if self.ui:isResultsAnimationFinished() then
            self.game.player:submitLargestGroup(self.largestGroup)
            self.game.player:submitMaxCombo(self.maxCombo)
            self.game.player:submitTimeElapsed(self.timeElapsed)
            if self.game.player.lives == 0 then
                self.ui:notifyGameResults()
            elseif not self.lost and self.game.player.level == 10 then
                self.ui:notifyGameWin()
            else
                if not self.lost then
                    self.game.player:advanceLevel()
                end
                self.game:changeScene("level", true, true)
            end
            _Game:playSound("sound_events/ui_select.json")
        elseif self.ui:isGameWinAnimationFinished() then
            self.ui:notifyGameResults()
        elseif self.ui:isGameResultsAnimationFinished() then
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