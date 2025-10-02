local class = require "com.class"

---@class Player
---@overload fun(game):Player
local Player = class:derive("Player")

---Constructs a Player.
---@param game GameMain The main game class this Player belongs to.
function Player:new(game)
    self.game = game

    self.score = 0
    self.level = math.random(1, 10)
    self.lives = 3
    self.disableTimeLimit = false
end

---Advances the player to the next level.
function Player:advanceLevel()
    self.level = self.level + 1
    self.lives = 3
end

return Player