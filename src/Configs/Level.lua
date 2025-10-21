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

    self.spawns = {}
    for i = 1, #data.spawns do
        self.spawns[i] = {}
        self.spawns[i].weight = u.parseInteger(data.spawns[i].weight, path, "spawns[" .. tostring(i) .. "].weight")
        self.spawns[i].type = u.parseString(data.spawns[i].type, path, "spawns[" .. tostring(i) .. "].type")
        self.spawns[i].initialOnly = u.parseBooleanOpt(data.spawns[i].initialOnly, path, "spawns[" .. tostring(i) .. "].initialOnly")
        self.spawns[i].fillOnly = u.parseBooleanOpt(data.spawns[i].fillOnly, path, "spawns[" .. tostring(i) .. "].fillOnly")
    end

    self.extraSpawns = {}
    if data.extraSpawns then
        for i = 1, #data.extraSpawns do
            self.extraSpawns[i] = {}
            self.extraSpawns[i].amount = u.parseInteger(data.extraSpawns[i].amount, path, "extraSpawns[" .. tostring(i) .. "].amount")
            self.extraSpawns[i].type = u.parseString(data.extraSpawns[i].type, path, "extraSpawns[" .. tostring(i) .. "].type")
        end
    end
end



return LevelConfig