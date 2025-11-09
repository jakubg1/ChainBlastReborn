local class = require "com.class"

---@class GameMain
---@overload fun(params):GameMain
local GameMain = class:derive("GameMain")

local Vec2 = require("src.Essentials.Vector2")
local Settings = require("src.Game.Settings")
local Player = require("src.Game.Player")
local SceneManager = require("src.Game.SceneManager")
local Particle2 = require("src.Game.Particle2")
local ChainFragment = require("src.Game.ChainFragment")
local Shaker = require("src.Game.Shaker")

-- TODO: Extract particle effects to a separate class.
local PARTICLE_EFFECT_TYPES = {
	power_bomb = {
		{type = "lavalamp", amount = 15, rangeMean = 0, rangeDev = 4}
	},
	power_lightning = {
		{type = "lightning", amount = 7}
	},
	power_laser = {
		-- TODO: This is used both as the actual laser powerup strike, as well as the bomb/lightning ignition. Split this off.
		{type = "laser"}
	},
	power_spark = {
		{type = "power_spark", amount = 1, rangeMean = 0, rangeDev = 2, full = true}
	},
	crate_damage = {
		{type = "chip", amount = 5, rangeMean = 0, rangeDev = 2, full = true}
	},
	chain_destroy = {
		{type = "chain_explosion", chainExplosionStyle = "legacy"},
		{type = "flare", chainExplosionStyle = "new"},
		--{type = "spark", amount = 8, rangeMean = 0, rangeDev = 3, full = true}
	},
	crate_destroy = {
		{type = "chain_explosion"},
		{type = "chip", amount = 20, rangeMean = 0, rangeDev = 2, full = true},
		--{type = "spark", amount = 4, rangeMean = 0, rangeDev = 3, full = true}
	},
	rock_destroy = {
		{type = "chain_explosion"},
		{type = "spark", amount = 10, rangeMean = 0, rangeDev = 3, full = true}
	},
	missile_trail = {
		{type = "spark"}
	},
	spark_trail = {
		{type = "spark_trail"}
	},
	debug = {
		{type = "lavalamp", amount = 15, rangeMean = 0, rangeDev = 4}
	}
}

---Constructs the actual game class.
---@param game Game The base game instance.
function GameMain:new(game)
	self.game = game

	self.smallFont = self.game.resourceManager:getFont("fonts/small.json")

	self.settings = Settings()
	self.player = Player(self)
	self.sceneManager = SceneManager(self)

	self.particles = {}
	self.screenShaker = Shaker()
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
	self.screenShaker:update(dt)
end

---Spawns a new Particle.
---@private
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

---Spawns particles from a particle effect. See `PARTICLE_EFFECT_TYPES` in `src/Game/Main.lua`.
---@param type string Particle type.
---@param pos Vector2 Where the particles should be spawned.
---@param pos2 Vector2? Secondary position, used for specific particles, such as lightning or power sparks.
---@param color Color? The color of the particles, used for certain particles, such as lightning or power sparks.
function GameMain:spawnParticles(type, pos, pos2, color)
	local data = PARTICLE_EFFECT_TYPES[type]
	for i, item in ipairs(data) do
		local spawn = true
		-- Don't spawn an item if the item requires reduced particles to be turned off, but they are turned on.
		if item.full and _Game.runtimeManager.options:getSetting("reducedParticles") then
			spawn = false
		end
		-- Don't spawn if the chain explosion style doesn't match the current setting.
		if item.chainExplosionStyle and item.chainExplosionStyle ~= _Game.game.settings.chainExplosionStyle then
			spawn = false
		end
		if spawn then
			self:spawnParticle(pos, item.type, item.amount, item.rangeMean, item.rangeDev, color, pos2)
		end
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
---The offset is calculated once per frame and can be retrieved with `:getScreenshakeOffset()`.
---@param power number The power of the shake, in pixels.
---@param direction number? The direction of the shake, in radians. 0 is left. If omitted, a random angle will be chosen for this shake, but horizontal direction will be preferred.
---@param frequency number The frequency of the shake, in 1/s.
---@param duration number How long will the shake persist until it is removed, in seconds.
function GameMain:shakeScreen(power, direction, frequency, duration)
	self.screenShaker:shake(power, direction, frequency, duration)
end

---Returns the current screenshake offset.
---@return Vector2
function GameMain:getScreenshakeOffset()
	return self.screenShaker:getOffset()
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
	if _Debug.uiDebugVisible then
		self.smallFont:draw("mouse: " .. _MousePos.x .. "," .. _MousePos.y, Vec2(), Vec2())
		self.smallFont:draw("transition: " .. tostring(self.sceneManager.transition.time) .. "," .. tostring(self.sceneManager.transition.state), Vec2(0, 6), Vec2())
		self.smallFont:draw("scene: " .. self.sceneManager.scene.name, Vec2(0, 12), Vec2())
		self.smallFont:draw(" next: " .. (self.sceneManager.nextScene and self.sceneManager.nextScene.name or "----"), Vec2(0, 18), Vec2())
	end
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
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
function GameMain:mousemoved(x, y, dx, dy)
	self.sceneManager:mousemoved(x, y, dx, dy)
end

---Callback from `main.lua`.
---@param x integer X movement of the mouse wheel.
---@param y integer Y movement of the mouse wheel.
function GameMain:wheelmoved(x, y)
	self.sceneManager:wheelmoved(x, y)
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function GameMain:keypressed(key)
	self.sceneManager:keypressed(key)
	-- Debug measures:
	if key == "p" then
		_Game.game:spawnParticles("debug", Vec2(200, 100))
	elseif key == "o" then
		for i = 1, 10 do
			_Game:playSound("sound_events/ice_break.json")
		end
	end
end

return GameMain
