local class = require "com.class"

---@class GameMain
---@overload fun(params):GameMain
local GameMain = class:derive("GameMain")

local Settings = require("src.Game.Settings")
local Player = require("src.Game.Player")
local Benchmark = require("src.Game.Benchmark")
local LoadingScreen = require("src.Game.LoadingScreen")
local Menu = require("src.Game.Menu")
local Level = require("src.Game.Level")
local Transition = require("src.Game.Transition")
local Particle2 = require("src.Game.Particle2")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



---Constructs the actual game class.
---@param game Game The base game instance.
function GameMain:new(game)
    self.game = game

    self.font = self.game.resourceManager:getFont("fonts/standard.json")

	self.settings = Settings()
	self.player = Player(self)
	self.scene = LoadingScreen(self)
	self.nextScene = nil
	self.skipTransition = false
	self.transition = Transition()
	self.particles = {}

	self.screenShakes = {}
	self.screenShakeTotal = Vec2()

	self.SCENE_CONSTRUCTORS = {
		loading = LoadingScreen,
		menu = Menu,
		level = Level
	}
end



---Updates the game.
---@param dt number Time delta in seconds.
function GameMain:update(dt)
	self.scene:update(dt)
	self.transition:update(dt)
	for i, particle in ipairs(self.particles) do
		particle:update(dt)
	end
	_Utils.removeDeadObjects(self.particles)

	if self.nextScene then
		if not self.transition.playing and self.transition.state then
			self.scene = self.nextScene
			self.nextScene = nil
			-- Skip the transition if we were told to do so.
			if self.skipTransition then
				self.transition:clear()
				self.skipTransition = false
			else
				self.transition:hide()
			end
		end
	end

	-- Calculate all screen shakes.
	self.screenShakeTotal = Vec2()
	for i, shake in ipairs(self.screenShakes) do
		-- Count shake power.
		local t = math.sin((shake.time * shake.frequency) * math.pi * 2) * _Utils.mapValue(shake.time, 0, shake.maxTime, 1, 0)
		self.screenShakeTotal = self.screenShakeTotal + shake.vector * t
		-- Count time.
		shake.time = shake.time + dt
		if shake.time >= shake.maxTime then
			shake.delQueue = true
		end
	end
	-- Remove all finished shakes.
	_Utils.removeDeadObjects(self.screenShakes)
	-- Round the screen shake value.
	self.screenShakeTotal = (self.screenShakeTotal + 0.5):floor()
end



---Changes the scene with a transition animation.
---@param scene string The scene name to transition to. Available values are `"loading"`, `"menu"` and `"level"`.
---@param skipFadeIn boolean? If `true`, the screen will immediately go black.
---@param skipFadeOut boolean? If `true`, the screen will immediately show the next scene.
function GameMain:changeScene(scene, skipFadeIn, skipFadeOut)
	if skipFadeIn then
		self.scene = self.SCENE_CONSTRUCTORS[scene](self)
		if not skipFadeOut then
			self.transition:show()
			self.transition:hide()
		end
	else
		self.nextScene = self.SCENE_CONSTRUCTORS[scene](self)
		self.transition:show()
		self.skipTransition = skipFadeOut
	end
end



---Spawns a new Particle.
---@param pos Vector2 The initial position of the Particle.
---@param type string The type of the Particle. TODO: Replace with data.
---@param color Color? The starting color of the Particle. TODO: Replace with data.
function GameMain:spawnParticle(pos, type, color)
	table.insert(self.particles, Particle2(self, pos, type, color))
end



---Shakes the screen. A few screen shakes can be active at once.
---The offset is calculated once per frame and is stored in the `screenShakeTotal` field.
---@param power number The power of the shake, in pixels.
---@param direction number? The direction of the shake, in radians. 0 is left. If omitted, a random angle will be chosen for this shake.
---@param frequency number The frequency of the shake, in 1/s.
---@param duration number How long will the shake persist until it is removed, in seconds.
function GameMain:shakeScreen(power, direction, frequency, duration)
	table.insert(self.screenShakes, {
		vector = Vec2(power, 0):rotate(direction or math.random() * math.pi * 2),
		frequency = frequency,
		maxTime = duration,
		time = 0
	})
end



---Draws the game.
function GameMain:draw()
	_DrawFillRect(Vec2(0, 0), Vec2(320, 180), Color(0, 0, 0))
	--_DrawRect(Vec2(0, 0), Vec2(320, 180), Color(0, 1, 0))
	--_DrawFillRect(Vec2(10, 10), Vec2(10, 10), Color(1, 0, 0))

	self.scene:draw()
	for i, particle in ipairs(self.particles) do
		particle:draw()
	end
	self.transition:draw()
end



---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function GameMain:mousepressed(x, y, button)
	self.scene:mousepressed(x, y, button)
end



---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function GameMain:mousereleased(x, y, button)
	self.scene:mousereleased(x, y, button)
end



return GameMain