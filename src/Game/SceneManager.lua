local class = require "com.class"
local Benchmark = require("src.Game.Scenes.Benchmark")
local LoadingScreen = require("src.Game.Scenes.LoadingScreen")
local Intro = require("src.Game.Scenes.Intro")
local MenuMain = require("src.Game.Scenes.MenuMain")
local MenuSettings = require("src.Game.Scenes.MenuSettings")
local MenuCredits = require("src.Game.Scenes.MenuCredits")
local MenuBackground = require("src.Game.Scenes.MenuBackground")
local SceneLevel = require("src.Game.Scenes.Level")
local LevelIntro = require("src.Game.Scenes.LevelIntro")
local LevelComplete = require("src.Game.Scenes.LevelComplete")
local LevelFailed = require("src.Game.Scenes.LevelFailed")
local LevelResults = require("src.Game.Scenes.LevelResults")
local LevelBackground = require("src.Game.Scenes.LevelBackground")
local GameWin = require("src.Game.Scenes.GameWin")
local GameOver = require("src.Game.Scenes.GameOver")
local GameResults = require("src.Game.Scenes.GameResults")
local Transition = require("src.Game.Scenes.Transition")
local Level = require("src.Game.Level")

---@class SceneManager
---@overload fun(game):SceneManager
local SceneManager = class:derive("SceneManager")

---Creates a Scene Manager.
---@param game GameMain The main game class this scene manager belongs to.
function SceneManager:new(game)
    self.game = game

	-- The scenes are drawn in order: background scene, level, (foreground) scene, transition.
	-- The background slot can be used for the menu stars or the level background.
	-- The foreground slot can be used for interactable UI, both in the menu and ingame.
	self.layers = {
		background = nil,
		level = nil,
		foreground = LoadingScreen(self.game),
		transition = Transition(self.game)
	}
	self.layerOrder = {"background", "level", "hud", "foreground", "transition"}
	self.nextLayers = {}

	self.skipFadeOut = false -- Whether the transition fadeout will be skipped.
	-- The main menu's intro animation state is lost each time we are switching to a different scene.
	-- That scene can be a level, but also can be the game's settings or credits.
	-- When we go back from these screens, we don't want to wait until the animation plays all over again when browsing through menus.
	-- This flag preserves the state of whether the intro animation should be played this time.
	-- This flag turns off after the intro has played, and should be turned back on if required.
	self.playMenuIntro = true

	self.SCENE_CONSTRUCTORS = {
		loading = LoadingScreen,
		intro = Intro,
		menu_main = MenuMain,
		menu_settings = MenuSettings,
		menu_credits = MenuCredits,
		menu_background = MenuBackground,
        level = SceneLevel,
		level_intro = LevelIntro,
		level_complete = LevelComplete,
		level_failed = LevelFailed,
		level_results = LevelResults,
		level_background = LevelBackground,
		game_win = GameWin,
		game_over = GameOver,
		game_results = GameResults
	}
end

---Updates the Scene Manager.
---@param dt number Time delta in seconds.
function SceneManager:update(dt)
	if self:areNextScenesScheduled() and self.layers.transition:isShown() then
		self:loadNextScene()
	end
	for i, layer in ipairs(self.layerOrder) do
		if self.layers[layer] then
			self.layers[layer]:update(dt)
		end
	end
end

---Changes the scenes on specified layers with an optional transition animation.
---@param layers table<string, string> A table which maps the layer name to the scene name. Scenes on specified layers will be replaced with respective new scenes.
---@param fadeIn boolean? If `true`, the screen will have a fadeout (transition fadein). By default, no transition will happen.
---@param fadeOut boolean? If `true`, the screen will have a fadein (transition fadeout). By default, no transition will happen.
function SceneManager:changeScene(layers, fadeIn, fadeOut)
	for layer, sceneName in pairs(layers) do
		self.nextLayers[layer] = sceneName
	end
	self.skipFadeOut = not fadeOut
	if fadeIn then
		self.layers.transition:startFadeIn()
	else
		self:loadNextScene()
	end
end

---Loads the next scenes stored in `self.nextScene` and `self.nextBackgroundScene` and starts the fadeout transition,
---if not skipped by passing an appropriate parameter to `:changeScene()`.
---Starts a new level if scheduled.
---@private
function SceneManager:loadNextScene()
	-- Load the next scenes into the respective scene slots.
	for i, layer in ipairs(self.layerOrder) do
		local sceneName = self.nextLayers[layer]
		if sceneName then
			assert(self.SCENE_CONSTRUCTORS[sceneName], string.format("Unknown scene: %s", sceneName))
			self.layers[layer] = self.SCENE_CONSTRUCTORS[sceneName](self.game)
			self.nextLayers[layer] = nil
		end
	end
	-- Skip the transition if that's what `:changeScene()` said.
	if self.skipFadeOut then
		self.layers.transition:skipOut()
		self.skipFadeOut = false
	else
		self.layers.transition:startFadeOut()
	end
end

---Returns `true` if next scenes are scheduled in the Scene Manager.
---@return boolean
function SceneManager:areNextScenesScheduled()
	return not _Utils.tableIsEmpty(self.nextLayers)
end

---Returns whether the scene should receive input callbacks.
---Usually `false` if a transition is ongoing.
---@return boolean
function SceneManager:isSceneActive()
    -- Scenes will not accept any input until the transition is done.
	if self.layers.transition:isFadingIn() or self.layers.transition:isShown() then
        return false
    end
    return (self.layers.foreground.isActive and self.layers.foreground:isActive()) ~= false
end

---Starts a new level.
function SceneManager:startLevel()
    self.layers.level = Level(self.game)
end

---Destroys the current level.
function SceneManager:endLevel()
    self.layers.level = nil
end

---Returns the current level, if one is being played.
---@return Level?
function SceneManager:getLevel()
    return self.layers.level
end

---Draws the current background scene on the screen.
function SceneManager:drawBackgroundScene()
	if self.layers.background then
		self.layers.background:draw()
	end
end

---Draws the current level on the screen, if any.
function SceneManager:drawLevel()
    if self.layers.level then
        self.layers.level:draw()
    end
end

---Draws the current foreground scene on the screen.
function SceneManager:drawScene()
	self.layers.foreground:draw()
end

---Draws the active transition on the screen.
function SceneManager:drawTransition()
	self.layers.transition:draw()
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function SceneManager:mousepressed(x, y, button)
	if self.layers.transition:isFadingIn() and self:areNextScenesScheduled() then
		self:loadNextScene()
	elseif self:isSceneActive() then
		self.layers.foreground:mousepressed(x, y, button)
    elseif self.layers.level then
        self.layers.level:mousepressed(x, y, button)
	end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function SceneManager:mousereleased(x, y, button)
	if self:isSceneActive() then
		self.layers.foreground:mousereleased(x, y, button)
    elseif self.layers.level then
        self.layers.level:mousereleased(x, y, button)
	end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
function SceneManager:mousemoved(x, y, dx, dy)
	if self:isSceneActive() and self.layers.foreground.mousemoved then
		self.layers.foreground:mousemoved(x, y, dx, dy)
	end
end

---Callback from `main.lua`.
---@param x integer X movement of the mouse wheel.
---@param y integer Y movement of the mouse wheel.
function SceneManager:wheelmoved(x, y)
	if self:isSceneActive() and self.layers.foreground.wheelmoved then
		self.layers.foreground:wheelmoved(x, y)
	end
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function SceneManager:keypressed(key)
	if self:isSceneActive() and self.layers.foreground.keypressed then
		self.layers.foreground:keypressed(key)
    elseif self.layers.level then
        self.layers.level:keypressed(key)
	end
end

return SceneManager