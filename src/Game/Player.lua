local class = require "com.class"
local Session = require("src.Game.Session")

---@class Player
---@overload fun():Player
local Player = class:derive("Player")

---Constructs a Player.
function Player:new()
    self.session = Session(self)
    ---@type table<integer, integer>
    self.levelRecords = {}
end

---Resets all player progress.
function Player:resetSession()
    self.session = Session(self)
end

---Compares the provided level's highscore against the provided score.
---If it's higher than current, saves it and returns `true`. Otherwise does not change the record and returns `false`.
---@param level integer The level ID for which to check the highscore.
---@param score integer The score earned for that level.
---@return boolean
function Player:checkAndSaveLevelHighscore(level, score)
    if score > (self.levelRecords[tostring(level)] or 0) then
        self.levelRecords[tostring(level)] = score
        return true
    end
    return false
end

---Serializes this Player's data to be stored for later.
---@return table
function Player:serialize()
    return {
        session = self.session:serialize(),
        levelRecords = self.levelRecords
    }
end

---Restores this Player's state from data acquired by `:serialize()`.
---@param t table Data to be restored from.
function Player:deserialize(t)
    self.session:deserialize(t.session)
    self.levelRecords = t.levelRecords
end

return Player