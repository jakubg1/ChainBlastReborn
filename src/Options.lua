local class = require "com.class"

---Represents the Game options. Not to be mistaken with Engine Settings!
---@class Options
---@overload fun():Options
local Options = class:derive("Options")

---Constructs an Options object.
function Options:new()
	self.data = {
		-- Audio
		mute = false,
		globalVolume = 0.25,
		musicVolume = 1,
		musicCueVolume = 1,
		soundVolume = 1,
		-- Video
		fullscreen = false,
		reducedParticles = false,
		screenFlashStrength = 1,
		screenShakeStrength = 1,
		autoPause = true,
		-- Handicap
		handicapTime = false
	}
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
---@param category string? The sound category for which the volume should be calculated.
---@return number
function Options:getEffectiveSoundVolume(category)
	if category == "musicCue" then
		return self.data.mute and 0 or self.data.musicCueVolume * self.data.globalVolume
	end
	return self.data.mute and 0 or self.data.soundVolume * self.data.globalVolume
end

---Returns the effective volume for music cues.
---@return number
function Options:getEffectiveMusicCueVolume()
	return self.data.mute and 0 or self.data.musicCueVolume * self.data.globalVolume
end

---Returns Options' data, ready to be saved in JSON format.
---@return table
function Options:serialize()
	return self.data
end

---Loads previously saved data into the Options.
---@param t table Data previously saved with `:serialize()`.
function Options:deserialize(t)
	self.data = t
end

return Options