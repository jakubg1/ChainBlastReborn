local class = require "com.class"
local Benchmark = require("src.Game.Scenes.Benchmark")
local LoadingScreen = require("src.Game.Scenes.LoadingScreen")
local Intro = require("src.Game.Scenes.Intro")
local Menu = require("src.Game.Scenes.Menu")
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
local Level = require("src.Game.Level")
local Transition = require("src.Game.Transition")

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
	self.scene = LoadingScreen(self.game)
	self.backgroundScene = nil
	self.level = nil
	self.transition = Transition()

	self.nextScene = nil -- Stores the name of the next scene.
	self.nextBackgroundScene = nil -- Stores the name of the next background scene.
	self.levelScheduled = false -- If `true` and the transition fades in (screen out), a level is started.
	self.skipFadeOut = false -- Whether the transition fadeout will be skipped.

	self.SCENE_CONSTRUCTORS = {
		loading = LoadingScreen,
		intro = Intro,
		menu = Menu,
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
	if self.nextScene and self.transition:isShown() then
		self:loadNextScene()
	end
	if self.backgroundScene then
		self.backgroundScene:update(dt)
	end
    if self.level then
        self.level:update(dt)
    end
	self.scene:update(dt)
	self.transition:update(dt)
end

---Schedules a new scene to be displayed.
---After calling this, call `:changeScene()`.
---@param name string The scene name to transition to.
function SceneManager:scheduleScene(name)
	self.nextScene = name
end

---Schedules a new background scene to be displayed.
---After calling this, call `:changeScene()`.
---@param name string The background scene name to transition to.
function SceneManager:scheduleBackgroundScene(name)
	self.nextBackgroundScene = name
end

---Schedules a level to appear during the next transition animation.
---Normally unused because it turns out it's not necessary, but it's worth keeping the code anyways (at least for now).
function SceneManager:scheduleLevel()
	self.levelScheduled = true
end

---Changes the scene with an optional transition animation.
---Call `:scheduleScene()` and/or `:scheduleBackgroundScene()` to set the new scenes.
---@param fadeIn boolean? If `true`, the screen will have a fadeout (transition fadein). By default, no transition will happen.
---@param fadeOut boolean? If `true`, the screen will have a fadein (transition fadeout). By default, no transition will happen.
function SceneManager:changeScene(fadeIn, fadeOut)
	self.skipFadeOut = not fadeOut
	if fadeIn then
		self.transition:startFadeIn()
	else
		self:loadNextScene()
	end
end

---Instantly loads a new scene into the foreground layer. The old scene is removed.
---@param name string Name of the scene.
function SceneManager:loadScene(name)
	assert(self.SCENE_CONSTRUCTORS[name], string.format("Unknown scene: %s", name))
	self.scene = self.SCENE_CONSTRUCTORS[name](self.game)
end

---Instantly loads a new scene into the background layer. The old scene is removed.
---@param name string Name of the scene.
function SceneManager:loadBackgroundScene(name)
	assert(self.SCENE_CONSTRUCTORS[name], string.format("Unknown scene: %s", name))
	self.backgroundScene = self.SCENE_CONSTRUCTORS[name](self.game)
end

---Loads the next scenes stored in `self.nextScene` and `self.nextBackgroundScene` and starts the fadeout transition,
---if not skipped by passing an appropriate parameter to `:changeScene()`.
---Starts a new level if scheduled.
---@private
function SceneManager:loadNextScene()
	-- Load the level.
	if self.levelScheduled then
		self:startLevel()
		self.levelScheduled = false
	end
	-- Load the next scenes into the respective scene slots.
	if self.nextScene then
		self:loadScene(self.nextScene)
		self.nextScene = nil
	end
	if self.nextBackgroundScene then
		self:loadBackgroundScene(self.nextBackgroundScene)
		self.nextBackgroundScene = nil
	end
	-- Skip the transition if that's what `:changeScene()` said.
	if self.skipFadeOut then
		self.transition:skipOut()
		self.skipFadeOut = false
	else
		self.transition:startFadeOut()
	end
end

---Returns whether the scene should receive input callbacks.
---Usually `false` if a transition is ongoing.
---@return boolean
function SceneManager:isSceneActive()
    -- Scenes will not accept any input until the transition is done.
	if self.transition:isFadingIn() or self.transition:isShown() then
        return false
    end
    return self.scene:isActive()
end

---Starts a new level.
function SceneManager:startLevel()
    self.level = Level(self.game)
end

---Destroys the current level.
function SceneManager:endLevel()
    self.level = nil
end

---Returns the current level, if one is being played.
---@return Level?
function SceneManager:getLevel()
    return self.level
end

---Draws the current background scene on the screen.
function SceneManager:drawBackgroundScene()
	if self.backgroundScene then
		self.backgroundScene:draw()
	end
end

---Draws the current level on the screen, if any.
function SceneManager:drawLevel()
    if self.level then
        self.level:draw()
    end
end

---Draws the current foreground scene on the screen.
function SceneManager:drawScene()
	self.scene:draw()
end

---Draws the active transition on the screen.
function SceneManager:drawTransition()
	self.transition:draw()
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was pressed.
function SceneManager:mousepressed(x, y, button)
	if self.transition:isFadingIn() and self.nextScene then
		self:loadNextScene()
	elseif self:isSceneActive() then
		self.scene:mousepressed(x, y, button)
    elseif self.level then
        self.level:mousepressed(x, y, button)
	end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button which was released.
function SceneManager:mousereleased(x, y, button)
	if self:isSceneActive() then
		self.scene:mousereleased(x, y, button)
    elseif self.level then
        self.level:mousereleased(x, y, button)
	end
end

---Callback from `main.lua`.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
function SceneManager:mousemoved(x, y, dx, dy)
	if self:isSceneActive() and self.scene.mousemoved then
		self.scene:mousemoved(x, y, dx, dy)
	end
end

---Callback from `main.lua`.
---@param x integer X movement of the mouse wheel.
---@param y integer Y movement of the mouse wheel.
function SceneManager:wheelmoved(x, y)
	if self:isSceneActive() and self.scene.wheelmoved then
		self.scene:wheelmoved(x, y)
	end
end

---Callback from `main.lua`.
---@param key string The pressed key code.
function SceneManager:keypressed(key)
	if self:isSceneActive() then
		self.scene:keypressed(key)
    elseif self.level then
        self.level:keypressed(key)
	end
end

return SceneManager