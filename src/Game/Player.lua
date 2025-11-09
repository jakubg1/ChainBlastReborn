local class = require "com.class"
local Session = require("src.Game.Session")

---@class Player
---@overload fun(game):Player
local Player = class:derive("Player")

---Constructs a Player.
---@param game GameMain The main game class this Player belongs to.
function Player:new(game)
    self.game = game

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
    if score > (self.levelRecords[level] or 0) then
        self.levelRecords[level] = score
        return true
    end
    return false
end

return Player