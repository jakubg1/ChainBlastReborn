local class = require "com.class"

---@class GameSettings
---@overload fun():GameSettings
local GameSettings = class:derive("GameSettings")

-- Place your imports here



---Constructs game settings. This is meant ONLY FOR DEBUG for now...
function GameSettings:new()
    self.chainExplosionStyle = "legacy" -- new | legacy
    self.goldTileStyle = "new" -- new | old
    self.goldTileAnimation = false
    self.displaySeamsOnChains = false
    self.smoothHoverMovement = false
end



return GameSettings