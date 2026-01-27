local class = require "com.class"
local Player = require("src.Game.Player")
local Options = require("src.Options")

---A wrapper class for Highscores, Options and Profile Manager. Packs it up neatly into one file called `runtime.json`.
---@class RuntimeManager
---@overload fun():RuntimeManager
local RuntimeManager = class:derive("RuntimeManager")

---Constructs a Runtime Manager.
function RuntimeManager:new()
	_Log:printt("RuntimeManager", "Initializing RuntimeManager...")

	self.player = Player()
	self.options = Options()

	self:load()
end

---Loads runtime data from `runtime.json`. If the file doesn't exist or is corrupted, generates a new runtime and prints a message to the log.
function RuntimeManager:load()
	-- if runtime.json exists, then load it
	local data = _Utils.loadJson("runtime.json")
	if data and data.player then
		self.player:deserialize(data.player)
	end
	if data and data.options then
		self.options:deserialize(data.options)
	end
end

---Saves runtime data to `runtime.json`.
function RuntimeManager:save()
	local data = {}

	data.player = self.player:serialize()
	data.options = self.options:serialize()

	_Utils.saveJson("runtime.json", data)
end

return RuntimeManager
