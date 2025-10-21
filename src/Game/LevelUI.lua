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

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.timerSprite = _Game.resourceManager:getSprite("sprites/hud_timer.json")
    self.powerSprite = _Game.resourceManager:getSprite("sprites/hud_power.json")
    self.powerCrystalSprite = _Game.resourceManager:getSprite("sprites/hud_power_crystal.json")
    self.flashShader = _Game.resourceManager:getShader("shaders/whiten.glsl")

    self.scoreDisplay = self.game.player.score
    self.powerMeterDisplay = 0
    self.multiplierProgressDisplay = 0
    self.pauseAnimation = 0

    self.hudAlpha = 0
    self.hudAlphaTarget = 0
    self.hudComboAlpha = 0
    self.hudComboValue = 0
    self.hudExtraTimeAlpha = 0
    self.hudExtraTimeValue = 0
    self.POWER_METER_COLORS = {
        [0] = Color(1, 0.9, 0.8),
        Color(1, 0.1, 0.3),
        Color(0.1, 0.4, 1),
        Color(1, 0.5, 0.1),
        --[0] = {1, 1, 1},
        --{0.1, 0.4, 0.9},
        --{1, 0.4, 0},
        --{0.9, 0.1, 0.3}
    }
    self.POWER_CRYSTAL_CENTER_POS = Vec2(284, 45)

    self.powerCrystalFlashTime = nil
    self.powerCrystalBopProgress = 0 -- Counts from 0 to 1
    self.powerChargeSound = nil
end

---Notifies the UI that extra time has been added to the timer.
---@param time number The added time in seconds.
function LevelUI:notifyExtraTime(time)
    self.hudExtraTimeAlpha = 2
    self.hudExtraTimeValue = self.hudExtraTimeValue + time
end

---Flashes the power crystal.
function LevelUI:flashPowerCrystal()
    self.powerCrystalFlashTime = 0.05
end

---Resets the power crystal's bopping animation.
function LevelUI:centerPowerCrystal()
    self.powerCrystalBopProgress = 0
end

---Shoots a laser from the power crystal at the given position. Does NOT play a laser sound.
---This is a purely visual effect and should be used in conjunction with actual logic.
---@param pos Vector2 The global onscreen position which is the laser target.
function LevelUI:shootLaserFromPowerCrystal(pos)
    self.game:spawnParticles("power_laser", pos, self.POWER_CRYSTAL_CENTER_POS)
    self:flashPowerCrystal()
end

---Returns `true` if any UI animation is being played right now.
---@return boolean
function LevelUI:isAnimationPlaying()
    return self.game.sceneManager.scene:isActive()
end

---Returns `true` if the pause screen is visible in any capacity.
---@return boolean
function LevelUI:isPauseVisible()
    return self.pauseAnimation > 0
end

---Sets the desired HUD alpha.
---@param alpha number Desired alpha. `1` - HUD visible, `0` - HUD hidden.
function LevelUI:setHUDAlpha(alpha)
    self.hudAlphaTarget = alpha
end

---Updates the level UI.
---@param dt number Time delta in seconds.
function LevelUI:update(dt)
    self:updatePause(dt)
    self:updateHUD(dt)
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
    -- Hide/show animation
    if self.hudAlpha < self.hudAlphaTarget then
        self.hudAlpha = math.min(self.hudAlpha + dt * 2, self.hudAlphaTarget)
    elseif self.hudAlpha > self.hudAlphaTarget then
        self.hudAlpha = math.max(self.hudAlpha - dt * 2, self.hudAlphaTarget)
    end

    -- Score animation
    if self.scoreDisplay < self.game.player.score then
        self.scoreDisplay = self.scoreDisplay + math.ceil((self.game.player.score - self.scoreDisplay) / 8)
    end

    -- Power meter gradual increase
    if self.powerMeterDisplay < self.level.powerMeter then
        self.powerMeterDisplay = math.min(self.powerMeterDisplay + 50 * dt, self.level.powerMeter)
    elseif self.powerMeterDisplay > self.level.powerMeter then
        self.powerMeterDisplay = math.max(self.powerMeterDisplay - 400 * dt, self.level.powerMeter)
        self:centerPowerCrystal()
    end
    -- Power meter charge sound
    local progress = math.min((self.powerMeterDisplay / self.level.maxPowerMeter) ^ 3, 1)
    if self.powerMeterDisplay < self.level.powerMeter then
        if not self.powerChargeSound then
            self.powerChargeSound = _Game:playSound("sound_events/power_charge.json")
        end
        self.powerChargeSound:setPitch(0.6 + progress * 1.1)
    else
        if self.powerChargeSound then
            self.powerChargeSound:setVolume(self.powerChargeSound.sounds[1].volume - dt / 0.25 * 0.3)
            if self.powerChargeSound.sounds[1].volume <= 0 then
                self.powerChargeSound:stop()
                self.powerChargeSound = nil
            end
        end
    end
    -- Power crystal bop animation
    self.powerCrystalBopProgress = (self.powerCrystalBopProgress + dt * progress) % 1
    -- Power crystal flash animation
    if self.powerCrystalFlashTime then
        self.powerCrystalFlashTime = self.powerCrystalFlashTime - dt
        if self.powerCrystalFlashTime <= 0 then
            self.powerCrystalFlashTime = nil
        end
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

---Draws the level UI (level intro, pause screen, HUD, win/lose screens, game win/game over screens, game results).
function LevelUI:draw()
    self:drawPause()
    self:drawHUD()
end

---Draws the pause screen.
function LevelUI:drawPause()
    if self.pauseAnimation == 0 then
        return
    end
    local natRes = _Game:getNativeResolution()
    _DrawFillRect(Vec2(57, 0), Vec2(180, 200), Color(0, 0, 0), self.pauseAnimation)
    self.font:draw("Game Paused", natRes / 2 + Vec2(0, -5), Vec2(0.5), Color(1, 1, 0), self.pauseAnimation)
    local alpha = 0.5 + (_TotalTime % 2) * 0.5
    if _TotalTime % 2 > 1 then
        alpha = 1 + (1 - _TotalTime % 2) * 0.5
    end
    self.font:draw("Click to continue", natRes / 2 + Vec2(0, 5), Vec2(0.5), nil, self.pauseAnimation * alpha)
end

---Draws the HUD.
function LevelUI:drawHUD()
    if self.hudAlpha == 0 then
        return
    end
    --self.font:draw("10200", Vec2(160, 5), Vec2(0.5, 0), nil, nil, 2)

    -- Score
    self.font:draw(tostring(self.scoreDisplay), Vec2(160, 0), Vec2(0.5, 0), nil, self.hudAlpha, 2)
    if self.hudComboAlpha > 0 then
        --self.font:draw(string.format("x%s", self.hudComboValue), Vec2(78, 50), Vec2(1, 0), nil, self.hudAlpha * self.hudComboAlpha)
    end

    -- Timer
    if not self.level:isTimerDisabled() then
        self.font:draw("Time", Vec2(35, 20), Vec2(0.5, 0), nil, self.hudAlpha)
        -- Bar
        local t = math.min(self.level.time / self.level.maxTime, 1)
        _DrawFillRect(Vec2(33, 40 + 108 * (1 - t)), Vec2(5, 110 * t), Color(0.1, 0.4, 0.9), self.hudAlpha)
        _DrawFillRect(Vec2(33, 40 + 108 * (1 - t)), Vec2(5, 1), Color(0.85, 0.95, 1), self.hudAlpha)
        -- Timer box
        self.timerSprite:draw(Vec2(19, 33), nil, nil, nil, nil, nil, self.hudAlpha)
        -- Text display
        local time = math.max(self.level.time, 0)
        if time < 9.9 then
            if time > 5 or not self.level:isTimerTicking() or _TotalTime % 0.25 < 0.125 then
                self.font:draw(string.format("%.2f", time), Vec2(36, 150), Vec2(0.5, 0), Color(1, 0, 0), self.hudAlpha)
            end
        else
            self.font:draw(string.format("%.1d:%.2d", time / 60, time % 60), Vec2(36, 150), Vec2(0.5, 0), nil, self.hudAlpha)
        end
    end

    -- Old power (bomb) meter
    --[[
    self.font:draw("Power", Vec2(285, 20), Vec2(0.5, 0), nil, self.hudAlpha)
    _DrawRect(Vec2(281, 34), Vec2(7, 112), Color(0.7, 0.5, 0.3), self.hudAlpha)
    if self.bombMeterTime then
        if _TotalTime % 0.3 < 0.15 then
            _DrawFillRect(Vec2(29, 112), Vec2(48, 9), Color(1, 0, 0), self.hudAlpha)
        end
        self.font:draw(string.format("BOMBS: %s", math.max(3 - math.floor(self.bombMeterTime / 0.5), 0)), Vec2(76, 110), Vec2(1, 0), nil, self.hudAlpha)
    else
        local color = (self.bombMeter > 90 and _TotalTime % 0.3 < 0.15) and Color(1, 1, 1) or Color(1, 0.7, 0)
        local t = math.min(self.bombMeter / 100, 1)
        _DrawFillRect(Vec2(282, 35 + 110 * (1 - t)), Vec2(5, 110 * t), color, self.hudAlpha)
        self.font:draw(tostring(self.bombMeter), Vec2(286, 150), Vec2(1, 0), nil, self.hudAlpha)
    end
    ]]

    -- New power meter
    self.font:draw("Power", Vec2(285, 20), Vec2(0.5, 0), nil, self.hudAlpha)
    -- Bar
    local color = (self.powerMeterDisplay >= self.level.maxPowerMeter and _TotalTime % 0.3 < 0.15) and Color(1, 1, 1) or self.POWER_METER_COLORS[self.level.powerColor]
    local progress = math.min(self.powerMeterDisplay / self.level.maxPowerMeter, 1)
    _DrawFillRect(Vec2(282, 65 + 80 * (1 - progress)), Vec2(5, 80 * progress), color, self.hudAlpha)
    -- Power box
    self.powerSprite:draw(Vec2(268, 33), nil, nil, nil, nil, nil, self.hudAlpha)
    -- Power crystal
    local offset = math.sin(self.powerCrystalBopProgress * math.pi * 2)
    local shader = self.powerCrystalFlashTime and self.flashShader
    local frame = 1
    if self.powerMeterDisplay >= self.level.maxPowerMeter * 0.8 then
        frame = 3
    elseif self.powerMeterDisplay >= self.level.maxPowerMeter * 0.4 then
        frame = 2
    end
    self.powerCrystalSprite:draw(Vec2(278, 39 + offset), nil, nil, frame, nil, nil, self.hudAlpha, nil, shader)

    -- Multiplier
    if self.level.config.multiplierEnabled then
        self.font:draw("Multiplier", Vec2(50, 165), Vec2(1, 0), nil, self.hudAlpha)
        _DrawFillRect(Vec2(55, 168), Vec2(150, 7), Color(0.3, 0.3, 0.3), self.hudAlpha)
        _DrawFillRect(Vec2(55, 168), Vec2(150 * self.multiplierProgressDisplay, 7), Color(0, 1, 0), self.hudAlpha)
        self.font:draw(string.format("x%s", self.level.multiplier), Vec2(210, 165), Vec2(), nil, self.hudAlpha)
    end

    self.font:draw("Pause [Esc]", Vec2(310, 165), Vec2(1, 0), Color(0.5, 0.5, 0.5))
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function LevelUI:mousepressed(x, y, button)
    if button == 1 then
        if self.level.pause then
            self.level:togglePause()
        end
    end
end

return LevelUI