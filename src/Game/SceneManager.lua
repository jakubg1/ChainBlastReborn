local class = require "com.class"
local Benchmark = require("src.Game.Scenes.Benchmark")
local LoadingScreen = require("src.Game.Scenes.LoadingScreen")
local Intro = require("src.Game.Scenes.Intro")
local Menu = require("src.Game.Scenes.Menu")
local SceneLevel = require("src.Game.Scenes.Level")
local LevelIntro = require("src.Game.Scenes.LevelIntro")
local LevelComplete = require("src.Game.Scenes.LevelComplete")
local LevelFailed = require("src.Game.Scenes.LevelFailed")
local LevelResults = require("src.Game.Scenes.LevelResults")
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

	self.level = nil
	self.scene = LoadingScreen(self.game)
	self.nextScene = nil
	self.skipFadeOut = false
	self.transition = Transition()

	self.SCENE_CONSTRUCTORS = {
		loading = LoadingScreen,
		intro = Intro,
		menu = Menu,
        level = SceneLevel,
		level_intro = LevelIntro,
		level_complete = LevelComplete,
		level_failed = LevelFailed,
		level_results = LevelResults,
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
    if self.level then
        self.level:update(dt)
    end
	self.scene:update(dt)
	self.transition:update(dt)
end

---Changes the scene with an optional transition animation.
---@param scene string The scene name to transition to. Available values are `"loading"`, `"menu"` and `"level"`.
---@param skipFadeIn boolean? If `true`, the screen will immediately go black.
---@param skipFadeOut boolean? If `true`, the screen will immediately show the next scene.
function SceneManager:changeScene(scene, skipFadeIn, skipFadeOut)
	if skipFadeIn then
		self.scene = self.SCENE_CONSTRUCTORS[scene](self.game)
		if not skipFadeOut then
			self.transition:startFadeOut()
		end
	else
		self.nextScene = self.SCENE_CONSTRUCTORS[scene](self.game)
		self.transition:startFadeIn()
		self.skipFadeOut = skipFadeOut
	end
end

---Loads the scene stored in `self.nextScene` into the main scene slot and starts the fadeout transition,
---if not skipped by passing an appropriate parameter to `:changeScene()`.
---@private
function SceneManager:loadNextScene()
	-- Load the next scene into the main slot.
	self.scene = self.nextScene
	self.nextScene = nil
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

---Draws the current scene on the screen.
function SceneManager:drawScene()
	self.scene:draw()
end

---Draws the current level on the screen, if any.
function SceneManager:drawLevel()
    if self.level then
        self.level:draw()
    end
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