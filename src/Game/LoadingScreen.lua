local class = require "com.class"

---@class LoadingScreen
---@overload fun(game):LoadingScreen
local LoadingScreen = class:derive("LoadingScreen")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



---Constructs the Loading Screen.
---@param game GameMain The main game class this Player belongs to.
function LoadingScreen:new(game)
    self.game = game

    self.sprite = _Game.resourceManager:getSprite("sprites/chain_red.json")
	self.spriteTime = 0
	self.endTime = nil
    self.ending = false
	
	-- Play the music.
	_Game.resourceManager:getMusic("music_tracks/menu_music.json"):play(1, 1)
end



---Updates the Loading Screen.
---@param dt number Time delta in seconds.
function LoadingScreen:update(dt)
	self.spriteTime = self.spriteTime + dt
	if not self.endTime then
		if _Game.resourceManager:getLoadProgress("main") == 1 then
			self.endTime = 0
			_Game.resourceManager:getMusic("music_tracks/menu_music.json"):stop(2)
		end
	else
		self.endTime = self.endTime + dt
        if not self.ending and self.endTime > 2 then
            self.game:changeScene("menu", true)
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
	self.game.font:drawWithShadow("Loading...", Vec2(150, 90), Vec2(0, 0.5), nil, alpha)
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



return LoadingScreen