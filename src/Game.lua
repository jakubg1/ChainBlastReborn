local class = require "com.class"

---Main class for a Game. Handles everything the Game has to do.
---@class Game
---@overload fun(name):Game
local Game = class:derive("Game")



local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

local Timer = require("src.Timer")

local ConfigManager = require("src.ConfigManager")
local ResourceManager = require("src.ResourceManager")
local RuntimeManager = require("src.RuntimeManager")

local UIManager = require("src.UI.Manager")
local UI2Manager = require("src.UI2.Manager")
local ParticleManager = require("src.Particle.Manager")

local GameMain = require("src.Game.Main")



---Constructs a new instance of Game.
---@param name string The name of the game, equivalent to the folder name in `games` directory.
function Game:new(name)
	self.name = name

	self.hasFocus = false

	self.configManager = nil
	self.resourceManager = nil
	self.runtimeManager = nil

	self.uiManager = nil
	self.particleManager = nil

	self.game = nil

	self.renderCanvas = nil

	-- revert to original font size
	love.graphics.setFont(_FONT)
end



---Initializes the game and all its components.
function Game:init()
	_Log:printt("Game", "Selected game: " .. self.name)

	-- Step 1. Load the config
	self.configManager = ConfigManager()
	self.configManager:loadStuffBeforeResources()

	-- Step 2. Initialize the window and canvas if necessary
	local res = self:getNativeResolution()
	love.window.setMode(res.x * 4, res.y * 4, {resizable = true})
	love.window.setTitle(self.configManager:getWindowTitle())
	if self.configManager:isCanvasRenderingEnabled() then
		self.renderCanvas = love.graphics.newCanvas(res.x, res.y)
		self.renderCanvas:setFilter("nearest", "nearest")
		love.graphics.setDefaultFilter("nearest", "nearest")
		love.graphics.setLineStyle("rough")
	end
	_DisplaySize = res * 4

	-- Step 3. Initialize RNG and timer
	self.timer = Timer()
	local _ = math.randomseed(os.time())

	-- Step 4. Create a resource bank
	self.resourceManager = ResourceManager()

	-- Step 5. Create a runtime manager
	self.runtimeManager = RuntimeManager()

	-- Step 6. Set up the UI Manager or the experimental UI2 Manager
	--self.uiManager = self.configManager.config.useUI2 and UI2Manager() or UIManager()
	--self.uiManager:initSplash()
	self:loadMain()

	-- Step 7. Create the game
	self.game = GameMain(self)

	-- test sprite
	--self.testSprites = {}
	--for i = 1, 10 do
	--	self.testSprites[i] = self.resourceManager:getSprite("sprites/chain_blue.json"):split(1, 1)
	--end
end



---Loads all game resources.
function Game:loadMain()
	self.resourceManager:startLoadCounter("main")
	self.resourceManager:scanResources()
	self.resourceManager:stopLoadCounter("main")
end



---Initializes the game session, as well as UI and particle managers.
function Game:initSession()
	-- Load whatever needs loading the new way from config.
	self.configManager:loadStuffAfterResources()
	-- Setup the UI and particles
	--self.uiManager:init()
	self.particleManager = ParticleManager()
end



---Updates the game.
---@param dt number Delta time in seconds.
function Game:update(dt) -- callback from main.lua
	self.timer:update(dt)
	local frames, delta = self.timer:getFrameCount()
	for i = 1, frames do
		self:tick(delta)
	end

	self:setFullscreen(self.runtimeManager.options:getSetting("fullscreen"))
end



---Updates the game logic.
---@param dt number Delta time in seconds.
function Game:tick(dt)
	self.resourceManager:update(dt)

	--self.uiManager:update(dt)

	if self.particleManager then
		self.particleManager:update(dt)
	end

	self.game:update(dt)

	if self.configManager.config.richPresence.enabled then
		self:updateRichPresence()
	end
end



---Updates the game's Rich Presence information.
function Game:updateRichPresence()
	local line1 = "Playing: " .. self.configManager:getGameName()
	local line2 = ""

	_DiscordRPC:setStatus(line1, line2)
end



---Draws the game contents.
function Game:draw()
	--love.graphics.setDefaultFilter("nearest", "nearest")

	_Debug:profDraw2Start()

	-- Session and level
	_Debug:profDraw2Checkpoint()

	-- Start drawing on canvas (if canvas mode set)
	if self.renderCanvas then
		love.graphics.setCanvas({self.renderCanvas, stencil = true})
	end

	-- Particles and UI
	-- NOTE: The game below clears the screen, so the result of these actions specifically does nothing?
	if self.particleManager then
		self.particleManager:draw()
	end
	--self.uiManager:draw()
	_Debug:profDraw2Checkpoint()

	-- Game
	self.game:draw()

	-- Finish drawing on canvas (if canvas mode set)
	if self.renderCanvas then
		love.graphics.setCanvas()
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(self.renderCanvas, _GetDisplayOffsetX(), _GetDisplayOffsetY(), 0, _GetResolutionScale())
	end

	-- Borders
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", 0, 0, _GetDisplayOffsetX(), _DisplaySize.y)
	love.graphics.rectangle("fill", _DisplaySize.x - _GetDisplayOffsetX(), 0, _GetDisplayOffsetX(), _DisplaySize.y)

	-- Test sprite
	--[[
	love.graphics.setColor(1, 1, 1)
	for i, sprite in ipairs(self.testSprites) do
		for j = 1, sprite:getStateCount() do
			sprite:draw(Vec2(56 * (j - 1), 56 * (i - 1)), nil, j, 1, nil, nil, nil, Vec2(4))
		end
	end
	]]
	
	--love.graphics.setColor(1, 1, 1)
	--self.resourceManager:getSprite("sprites/game/ball_1.json").config.image:draw(0, 0)
	_Debug:profDraw2Stop()
end



---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function Game:mousepressed(x, y, button)
	--if self.uiManager:isButtonHovered() then
	--	self.uiManager:mousepressed(x, y, button)
	--end
	self.game:mousepressed(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function Game:mousereleased(x, y, button)
	--self.uiManager:mousereleased(x, y, button)
	self.game:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
function Game:mousemoved(x, y, dx, dy)
	self.game:mousemoved(x, y, dx, dy)
end

---Callback from `main.lua`.
---@param x integer X movement of the mouse wheel.
---@param y integer Y movement of the mouse wheel.
function Game:wheelmoved(x, y)
	self.game:wheelmoved(x, y)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function Game:keypressed(key)
	--self.uiManager:keypressed(key)
	self.game:keypressed(key)
end

---Callback from `main.lua`.
---@param key string The released key code.
function Game:keyreleased(key)
end

---Callback from `main.lua`.
---@param t string Something which makes text going.
function Game:textinput(t)
	--self.uiManager:textinput(t)
end



---Saves the game.
function Game:save()
	self.runtimeManager:save()
end



---Plays a sound and returns its instance for modification.
---@param name string|SoundEvent The name of the Sound Effect to be played.
---@param pos Vector2? The position of the sound.
---@return SoundInstance
function Game:playSound(name, pos)
	-- TODO: Unmangle this code. Will the string representation be still necessary after we fully move to Config Classes?
	if type(name) == "string" then
		return self.resourceManager:getSoundEvent(name):play(pos)
	else
		return name:play(pos)
	end
end



---Spawns and returns a particle packet.
---@param name string The name of a particle packet.
---@param pos Vector2 The position for the particle packet to be spawned.
---@param layer string? The layer the particles are supposed to be drawn on. If `nil`, they will be drawn as a part of the game, and not UI.
---@return ParticlePacket
function Game:spawnParticle(name, pos, layer)
	return self.particleManager:spawnParticlePacket(name, pos, layer)
end



---Returns the native resolution of this Game.
---@return Vector2
function Game:getNativeResolution()
	return self.configManager:getNativeResolution()
end



---Enables or disables fullscreen.
---@param fullscreen boolean Whether the fullscreen mode should be active.
function Game:setFullscreen(fullscreen)
	if fullscreen == love.window.getFullscreen() then return end
	if fullscreen then
		local _, _, flags = love.window.getMode()
		_DisplaySize = Vec2(love.window.getDesktopDimensions(flags.display))
	else
		_DisplaySize = self:getNativeResolution() * 4
	end
	love.window.setMode(_DisplaySize.x, _DisplaySize.y, {fullscreen = fullscreen, resizable = true})
end



---Exits the game.
---@param forced boolean? If `true`, the engine will exit completely even if the "Return to Boot Screen" option is enabled.
function Game:quit(forced)
	self:save()
	self.resourceManager:unload()
	if _EngineSettings:getBackToBoot() and not forced then
		love.window.setMode(800, 600) -- reset window size
		_LoadBootScreen()
	else
		love.event.quit()
	end
end



return Game
