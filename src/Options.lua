local class = require "com.class"

---Represents the Game options. Not to be mistaken with Engine Settings!
---@class Options
---@overload fun(data):Options
local Options = class:derive("Options")

---Constructs an Options object.
---@param data table The data to be read.
function Options:new(data)
	self.data = data
	-- Audio
	self.data.mute = self.data.mute == true
	self.data.globalVolume = self.data.globalVolume or 0.25
	self.data.musicVolume = self.data.musicVolume or 1
	self.data.musicCueVolume = self.data.musicCueVolume or 1
	self.data.soundVolume = self.data.soundVolume or 1
	-- Video
	self.data.fullscreen = self.data.fullscreen == true
	self.data.reducedParticles = self.data.reducedParticles == true
	self.data.screenFlashStrength = self.data.screenFlashStrength or 1
	self.data.screenShakeStrength = self.data.screenShakeStrength or 1
	self.data.autoPause = self.data.autoPause ~= false
	-- Handicap
	self.data.handicapTime = self.data.handicapTime == true
end

---Sets a setting based on its key.
---@param key string The setting key.
---@param value any The setting value.
function Options:setSetting(key, value)
	self.data[key] = value
end

---Gets a setting based on its key.
---@param key string The setting key.
---@return any
function Options:getSetting(key)
	return self.data[key]
end

---Returns `0` if the mute flag is set, else the current music volume.
---@return number
function Options:getEffectiveMusicVolume()
	return self.data.mute and 0 or self.data.musicVolume * self.data.globalVolume
end

---Returns `0` if the mute flag is set, else the current sound volume.
---@return number
function Options:getEffectiveSoundVolume()
	return self.data.mute and 0 or self.data.soundVolume * self.data.globalVolume
end

---Returns the effective volume for music cues.
---@return number
function Options:getEffectiveMusicCueVolume()
	return self.data.mute and 0 or self.data.musicCueVolume * self.data.globalVolume
end

return Options