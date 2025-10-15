local class = require "com.class"
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---@class LoadingScreen
---@overload fun(game):LoadingScreen
local LoadingScreen = class:derive("LoadingScreen")

---Constructs the Loading Screen.
---@param game GameMain The main game class this scene belongs to.
function LoadingScreen:new(game)
    self.name = "loading"
	self.game = game

	self.font = _Game.resourceManager:getFont("fonts/standard.json")
    self.sprite = _Game.resourceManager:getSprite("sprites/chain_red.json")
	self.spriteTime = 0
	self.endTime = nil
    self.ending = false
end

---Returns whether this scene should accept any input.
---@return boolean
function LoadingScreen:isActive()
    return true
end

---Updates the Loading Screen.
---@param dt number Time delta in seconds.
function LoadingScreen:update(dt)
	self.spriteTime = self.spriteTime + dt
	if not self.endTime then
		if _Game.resourceManager:getLoadProgress("main") == 1 then
			-- Everything's loaded. Start the fade out.
			self.endTime = 0
		end
	else
		self.endTime = self.endTime + dt
        if not self.ending and self.endTime > 1.2 then
            self.game.sceneManager:changeScene("menu", true, true)
            self.ending = true
        end
	end
end

---Draws the Loading Screen.
function LoadingScreen:draw()
	local spriteTime = 0.075
	local state = math.floor(self.spriteTime / (spriteTime * 4)) % 2 + 1
	local frame = math.floor(self.spriteTime / spriteTime) % 4 + 1
	local alpha = 1 - ((self.endTime or 0) / 1)
	_DrawFillRect(Vec2(0, 0), Vec2(320, 180), Color(0, 0, 0), 1 - alpha)
	self.sprite:drawWithShadow(Vec2(140, 90), Vec2(0.5), state, frame, nil, nil, alpha)
	self.font:drawWithShadow("Loading...", Vec2(150, 90), Vec2(0, 0.5), nil, alpha)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function LoadingScreen:mousepressed(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function LoadingScreen:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function LoadingScreen:keypressed(key)
end

return LoadingScreen