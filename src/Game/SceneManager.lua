local class = require "com.class"
local Benchmark = require("src.Game.Scenes.Benchmark")
local LoadingScreen = require("src.Game.Scenes.LoadingScreen")
local Intro = require("src.Game.Scenes.Intro")
local MenuMain = require("src.Game.Scenes.MenuMain")
local MenuSettings = require("src.Game.Scenes.MenuSettings")
local MenuCredits = require("src.Game.Scenes.MenuCredits")
local MenuBackground = require("src.Game.Scenes.MenuBackground")
local LevelUI = require("src.Game.Scenes.LevelUI")
local LevelPause = require("src.Game.Scenes.LevelPause")
local LevelIntro = require("src.Game.Scenes.LevelIntro")
local LevelComplete = require("src.Game.Scenes.LevelComplete")
local LevelFailed = require("src.Game.Scenes.LevelFailed")
local LevelResults = require("src.Game.Scenes.LevelResults")
local LevelBackground = require("src.Game.Scenes.LevelBackground")
local GameWin = require("src.Game.Scenes.GameWin")
local GameOver = require("src.Game.Scenes.GameOver")
local GameResults = require("src.Game.Scenes.GameResults")
local Transition = require("src.Game.Scenes.Transition")
local Level = require("src.Game.Scenes.Level")

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
	---@type table<string, Scene?>
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
		level_ui = LevelUI,
		level_pause = LevelPause,
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
	if self:areNextScenesScheduled() and self:getTransition():isShown() then
		self:loadNextScene()
	end
	for i, layer in ipairs(self.layerOrder) do
		if self.layers[layer] then
			self.layers[layer]:update(dt)
		end
	end
end

---Changes the scenes on specified layers with an optional transition animation.
---@param layers table<string, string> A table which maps the layer name to the scene name. Scenes on specified layers will be replaced with respective new scenes. Specifying an empty string will remove the current scene from its layer without making a new one.
---@param fadeIn boolean? If `true`, the screen will have a fadeout (transition fadein). By default, no transition will happen.
---@param fadeOut boolean? If `true`, the screen will have a fadein (transition fadeout). By default, no transition will happen.
function SceneManager:changeScene(layers, fadeIn, fadeOut)
	for layer, sceneName in pairs(layers) do
		self.nextLayers[layer] = sceneName
	end
	self.skipFadeOut = not fadeOut
	if fadeIn then
		self:getTransition():startFadeIn()
	else
		self:loadNextScene()
	end
end

---Loads the next scenes stored in `self.nextScene` and `self.nextBackgroundScene` and starts the fadeout transition,
---if not skipped by passing an appropriate parameter to `:changeScene()`.
---@private
function SceneManager:loadNextScene()
	-- Load the next scenes into the respective scene slots.
	for i, layer in ipairs(self.layerOrder) do
		local sceneName = self.nextLayers[layer]
		if sceneName then
			if sceneName == "" then
				-- Remove the scene if an empty scene name has been provided.
				self.layers[layer] = nil
			else
				assert(self.SCENE_CONSTRUCTORS[sceneName], string.format("Unknown scene: %s", sceneName))
				self.layers[layer] = self.SCENE_CONSTRUCTORS[sceneName](self.game)
			end
			self.nextLayers[layer] = nil
		end
	end
	-- Skip the transition if that's what `:changeScene()` said.
	if self.skipFadeOut then
		self:getTransition():skipOut()
		self.skipFadeOut = false
	else
		self:getTransition():startFadeOut()
	end
end

---Returns `true` if next scenes are scheduled in the Scene Manager.
---@return boolean
function SceneManager:areNextScenesScheduled()
	return not _Utils.tableIsEmpty(self.nextLayers)
end

---Returns whether the scenes should receive input callbacks.
---Usually `false` if a transition is ongoing.
---@return boolean
function SceneManager:isInputActive()
    -- Scenes will not accept any input until the transition is done.
	local transition = self:getTransition()
	if transition:isFadingIn() or transition:isShown() then
        return false
    end
	return true
end

---Starts a new level.
function SceneManager:startLevel()
    self.layers.level = Level(self.game)
	self.layers.hud = LevelUI(self.game)
end

---Destroys the current level.
function SceneManager:endLevel()
    self.layers.level = nil
	self.layers.hud = nil
end

---Returns the current level, if one is being played.
---@return Level?
function SceneManager:getLevel()
	---@diagnostic disable-next-line: return-type-mismatch
    return self.layers.level
end

---Returns the current level HUD, if a level is being played.
---@return LevelUI?
function SceneManager:getLevelHUD()
	---@diagnostic disable-next-line: return-type-mismatch
    return self.layers.hud
end

---Returns the transition scene.
---@return Transition
function SceneManager:getTransition()
	---@diagnostic disable-next-line: return-type-mismatch
    return self.layers.transition
end

---Draws all scenes on the screen.
function SceneManager:draw()
	for i, layer in ipairs(self.layerOrder) do
		if self.layers[layer] then
			self.layers[layer]:draw()
		end
		-- Particles are drawn just after the HUD layer.
		if layer == "hud" then
			self.game:drawParticles()
		end
	end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function SceneManager:mousepressed(x, y, button)
	if button == 1 and self:getTransition():isFadingIn() and self:areNextScenesScheduled() then
		-- Skip the fade in animation if we've pressed the left mouse button.
		self:loadNextScene()
	end
	-- Block inputs if a transition is in progress.
	if not self:isInputActive() then
		return
	end
	-- Handle actual scene input.
	for i, layer in ipairs(self.layerOrder) do
		local scene = self.layers[layer]
		if scene then
			local consumed = scene:mousepressed(x, y, button)
			if consumed then
				break
			end
		end
	end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function SceneManager:mousereleased(x, y, button)
	-- Block inputs if a transition is in progress.
	if not self:isInputActive() then
		return
	end
	-- Handle actual scene input.
	for i, layer in ipairs(self.layerOrder) do
		local scene = self.layers[layer]
		if scene then
			local consumed = scene:mousereleased(x, y, button)
			if consumed then
				break
			end
		end
	end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
function SceneManager:mousemoved(x, y, dx, dy)
	-- Handle actual scene input.
	for i, layer in ipairs(self.layerOrder) do
		local scene = self.layers[layer]
		if scene then
			local consumed = scene:mousemoved(x, y, dx, dy)
			if consumed then
				break
			end
		end
	end
end

---Callback from `main.lua`.
---@param x integer X movement of the mouse wheel.
---@param y integer Y movement of the mouse wheel.
function SceneManager:wheelmoved(x, y)
	-- Block inputs if a transition is in progress.
	if not self:isInputActive() then
		return
	end
	-- Handle actual scene input.
	for i, layer in ipairs(self.layerOrder) do
		local scene = self.layers[layer]
		if scene then
			local consumed = scene:wheelmoved(x, y)
			if consumed then
				break
			end
		end
	end
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function SceneManager:keypressed(key)
	-- Block inputs if a transition is in progress.
	if not self:isInputActive() then
		return
	end
	-- Handle actual scene input.
	for i, layer in ipairs(self.layerOrder) do
		local scene = self.layers[layer]
		if scene then
			local consumed = scene:keypressed(key)
			if consumed then
				break
			end
		end
	end
end

return SceneManager