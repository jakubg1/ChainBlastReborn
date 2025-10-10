local class = require "com.class"

---@class GameMain
---@overload fun(params):GameMain
local GameMain = class:derive("GameMain")

local Settings = require("src.Game.Settings")
local Player = require("src.Game.Player")
local SceneManager = require("src.Game.SceneManager")
local Particle2 = require("src.Game.Particle2")
local ChainFragment = require("src.Game.ChainFragment")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")

---Constructs the actual game class.
---@param game Game The base game instance.
function GameMain:new(game)
	self.game = game

	self.smallFont = self.game.resourceManager:getFont("fonts/small.json")

	self.settings = Settings()
	self.player = Player(self)
	self.sceneManager = SceneManager(self)

	self.particles = {}
	self.screenShakes = {}
	self.screenShakeTotal = Vec2()
end

---Updates the game.
---@param dt number Time delta in seconds.
function GameMain:update(dt)
	self.sceneManager:update(dt)
	self:updateParticles(dt)
	self:updateScreenshake(dt)
end

---Updates particles.
---@param dt number Time delta in seconds.
function GameMain:updateParticles(dt)
	for i, particle in ipairs(self.particles) do
		particle:update(dt)
	end
	_Utils.removeDeadObjects(self.particles)
end

---Updates the screenshake animations.
---@param dt number Time delta in seconds.
function GameMain:updateScreenshake(dt)
	self.screenShakeTotal = Vec2()
	for i, shake in ipairs(self.screenShakes) do
		-- Count shake power.
		local decayFactor = _Utils.mapValue(shake.time, 0, shake.maxTime, 1, 0)
		-- The following is a quadratic falloff, personally I feel like it is much more headache-inducing
		--local decayFactor = 1 - _Utils.mapValue(shake.time, 0, shake.maxTime, 0, 1) ^ 2
		local t = math.sin((shake.time * shake.frequency) * math.pi * 2) * decayFactor
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

---Spawns a new Particle.
---@param pos Vector2 The initial position of the Particle.
---@param type string The type of the Particle. TODO: Replace with data.
---@param amount integer? The amount of Particles of this type to spawn.
---@param rangeMean number? If specified, the particles will spawn around `pos` in this range.
---@param rangeDev number? If specified, uses standard deviation to determine the spawning position. Use with `rangeMean`.
---@param color Color? The starting color of the Particle. TODO: Replace with data.
---@param pos2 Vector2? The second position of the Particle. If `type` is `"lightning"`, this is the second lightning position (`pos` -> `pos2`). If `type` is `"power_spark"`, this is the position the particle will gravitate towards. TODO: Replace with data.
function GameMain:spawnParticle(pos, type, amount, rangeMean, rangeDev, color, pos2)
	for i = 1, amount or 1 do
		local spawnPos = pos
		if rangeMean and rangeDev then
			spawnPos = spawnPos + Vec2(love.math.randomNormal(rangeDev, rangeMean), love.math.randomNormal(rangeDev, rangeMean))
		end
		table.insert(self.particles, Particle2(self, spawnPos, type, color, pos2))
	end
end

---Spawns a bunch of new Particle Fragments.
---@param pos Vector2 The initial position of the Particle.
---@param type string The type of the Particle. TODO: Replace with data.
---@param sprite Sprite The split sprite. A new particle will be created for each state.
---@param state integer The state ID to pick a frame from.
---@param frame integer The frame ID to be picked. This will determine a single frame which will be split.
---@param maxParticles integer? Maximum number of fragments that can spawn.
function GameMain:spawnParticleFragments(pos, type, sprite, state, frame, maxParticles)
	local splitSprite = sprite:split(state, frame)
	for i = 1, math.min(splitSprite:getStateCount(), maxParticles or math.huge) do
		table.insert(self.particles, ChainFragment(self, pos, type, splitSprite, i))
	end
end

---Shakes the screen. A few screen shakes can be active at once.
---The offset is calculated once per frame and is stored in the `screenShakeTotal` field.
---@param power number The power of the shake, in pixels.
---@param direction number? The direction of the shake, in radians. 0 is left. If omitted, a random angle will be chosen for this shake, but horizontal direction will be preferred.
---@param frequency number The frequency of the shake, in 1/s.
---@param duration number How long will the shake persist until it is removed, in seconds.
function GameMain:shakeScreen(power, direction, frequency, duration)
	if not direction then
		-- Prefer horizontal shake because it is said that people tolerate it better
		-- (bias towards 0 or math.pi)
		direction = math.random() < 0.5 and 0 or math.pi
		direction = direction + love.math.randomNormal(math.pi / 8, 0)
	end
	table.insert(self.screenShakes, {
		vector = Vec2(power, 0):rotate(direction),
		frequency = frequency,
		maxTime = duration,
		time = 0
	})
end

---Draws the game.
function GameMain:draw()
	-- Clear the display.
    local natRes = _Game:getNativeResolution()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, natRes.x, natRes.y)

	self.sceneManager:drawLevel()
	for i, particle in ipairs(self.particles) do
		particle:draw()
	end
	self.sceneManager:drawScene()
	self.sceneManager:drawTransition()

	-- Debug
	self.smallFont:draw("mouse: " .. _MousePos.x .. "," .. _MousePos.y, Vec2(), Vec2())
	self.smallFont:draw("transition: " .. tostring(self.sceneManager.transition.time) .. "," .. tostring(self.sceneManager.transition.state), Vec2(0, 6), Vec2())
	self.smallFont:draw("scene: " .. self.sceneManager.scene.name, Vec2(0, 12), Vec2())
	self.smallFont:draw(" next: " .. (self.sceneManager.nextScene and self.sceneManager.nextScene.name or "----"), Vec2(0, 18), Vec2())
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function GameMain:mousepressed(x, y, button)
	self.sceneManager:mousepressed(x, y, button)
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function GameMain:mousereleased(x, y, button)
	self.sceneManager:mousereleased(x, y, button)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function GameMain:keypressed(key)
	self.sceneManager:keypressed(key)
	-- Debug measures:
	if key == "p" then
		_Game.game:spawnParticle(Vec2(200, 100), "lavalamp", 15, 0, 4)
	elseif key == "o" then
		for i = 1, 10 do
			_Game:playSound("sound_events/ice_break.json")
		end
	end
end

return GameMain
