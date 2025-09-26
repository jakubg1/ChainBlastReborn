local class = require "com.class"

---@class LevelConfig
---@overload fun(data, path):LevelConfig
local LevelConfig = class:derive("LevelConfig")

local u = require("src.Configs.utils")



---Constructs a new Level Config.
---@param data table Raw level data.
---@param path string Path to the file. The file is not loaded here, but is used in error messages.
function LevelConfig:new(data, path)
    self._path = path

    self.name = u.parseString(data.name, path, "name")
    self.time = u.parseNumber(data.time, path, "time")
    self.multiplierEnabled = u.parseBoolean(data.multiplierEnabled, path, "multiplierEnabled")
    self.enablePowerups = u.parseBoolean(data.enablePowerups, path, "enablePowerups")

    self.key = {}
    for n, _ in pairs(data.key) do
        self.key[n] = {}

        if data.key[n].tile then
            self.key[n].tile = {}
            self.key[n].tile.type = u.parseString(data.key[n].tile.type, path, "key." .. tostring(n) .. ".tile.type")
            self.key[n].tile.gold = u.parseBooleanOpt(data.key[n].tile.gold, path, "key." .. tostring(n) .. ".tile.gold") or false
        end
        if data.key[n].chain then
            self.key[n].chain = {}
            self.key[n].chain.type = u.parseString(data.key[n].chain.type, path, "key." .. tostring(n) .. ".chain.type")
            self.key[n].chain.color = u.parseIntegerOpt(data.key[n].chain.color, path, "key." .. tostring(n) .. ".chain.color")
            self.key[n].chain.health = u.parseIntegerOpt(data.key[n].chain.health, path, "key." .. tostring(n) .. ".chain.health")
        end
    end

    self.layout = {}
    for i = 1, #data.layout do
        self.layout[i] = u.parseString(data.layout[i], path, "layout[" .. tostring(i) .. "]")
    end
end



return LevelConfig