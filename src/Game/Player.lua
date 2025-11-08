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
end

---Resets all player progress.
function Player:resetSession()
    self.session = Session(self)
end

return Player