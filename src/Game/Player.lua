local class = require "com.class"

---@class Player
---@overload fun(game):Player
local Player = class:derive("Player")

---Constructs a Player.
---@param game GameMain The main game class this Player belongs to.
function Player:new(game)
    self.game = game

    self.score = 0
    self.level = 1 -- math.random(1, 10)
    self.lives = 3

    self.largestGroup = 0
    self.maxCombo = 0
    self.timeElapsed = 0
end

---Advances the player to the next level.
function Player:advanceLevel()
    self.level = self.level + 1
    self.lives = 3
end

---Submits the largest group size of a played level. If it is higher than recorded so far, it is increased.
---@param largestGroup integer The largest group achieved as a partial result.
function Player:submitLargestGroup(largestGroup)
    self.largestGroup = math.max(self.largestGroup, largestGroup)
end

---Submits the max combo of a played level. If it is higher than recorded so far, it is increased.
---@param maxCombo integer The max combo achieved as a partial result.
function Player:submitMaxCombo(maxCombo)
    self.maxCombo = math.max(self.maxCombo, maxCombo)
end

---Submits the time elapsed on a played level. It is added to the total time played in this game.
---@param timeElapsed number Time elapsed on a level.
function Player:submitTimeElapsed(timeElapsed)
    self.timeElapsed = self.timeElapsed + timeElapsed
end

return Player