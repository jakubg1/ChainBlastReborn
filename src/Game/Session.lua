local class = require "com.class"

---@class Session
---@overload fun(player):Session
local Session = class:derive("Session")

---Creates a new Session.
---@param player Player The player this session is for.
function Session:new(player)
    self.player = player

    self.score = 0
    self.previousScore = 0
    self.level = 101 -- math.random(1, 10)

    self.largestGroup = 0
    self.maxCombo = 0
    self.timeElapsed = 0
    self.chainsDestroyed = 0
    self.levelsStarted = 0
    self.levelsCompleted = 0
end

---Notifies that the level has been restarted - reduces score to prior to the level starting.
function Session:restartLevel()
    self.score = self.previousScore
end

---Advances the Session to the next level.
function Session:advanceLevel()
    self.level = self.level + 1
    self.previousScore = self.score
end

---Increments the amount of levels started in this session.
function Session:incrementLevelsStarted()
    self.levelsStarted = self.levelsStarted + 1
end

---Increments the amount of levels completed in this session.
function Session:incrementLevelsCompleted()
    self.levelsCompleted = self.levelsCompleted + 1
end

---Registers an extra chain destroyed in this session.
function Session:incrementChainsDestroyed()
    self.chainsDestroyed = self.chainsDestroyed + 1
end

---Adds the provided amount of points to the player's score in this session.
---@param score integer The extra score to be added.
function Session:addScore(score)
    self.score = self.score + score
end

---Submits the largest group size of a played level. If it is higher than recorded so far, it is increased.
---@param largestGroup integer The largest group achieved as a partial result.
function Session:submitLargestGroup(largestGroup)
    self.largestGroup = math.max(self.largestGroup, largestGroup)
end

---Submits the max combo of a played level. If it is higher than recorded so far, it is increased.
---@param maxCombo integer The max combo achieved as a partial result.
function Session:submitMaxCombo(maxCombo)
    self.maxCombo = math.max(self.maxCombo, maxCombo)
end

---Submits the time elapsed on a played level. It is added to the total time played in this game.
---@param timeElapsed number Time elapsed on a level.
function Session:submitTimeElapsed(timeElapsed)
    self.timeElapsed = self.timeElapsed + timeElapsed
end

---Serializes this Session's data to be stored for later.
---@return table
function Session:serialize()
    return {
        score = self.score,
        previousScore = self.previousScore,
        level = self.level,
        largestGroup = self.largestGroup,
        maxCombo = self.maxCombo,
        timeElapsed = self.timeElapsed,
        chainsDestroyed = self.chainsDestroyed,
        levelsStarted = self.levelsStarted,
        levelsCompleted = self.levelsCompleted
    }
end

---Restores this Session's state from data acquired by `:serialize()`.
---@param t table Data to be restored from.
function Session:deserialize(t)
    self.score = t.score
    self.previousScore = t.previousScore
    self.level = t.level
    self.largestGroup = t.largestGroup
    self.maxCombo = t.maxCombo
    self.timeElapsed = t.timeElapsed
    self.chainsDestroyed = t.chainsDestroyed
    self.levelsStarted = t.levelsStarted
    self.levelsCompleted = t.levelsCompleted
end

return Session