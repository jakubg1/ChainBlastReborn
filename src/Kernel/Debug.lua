local class = require "com.class"

---@class Debug
---@overload fun():Debug
local Debug = class:derive("Debug")

local Vec2 = require("src.Essentials.Vector2")

local Profiler = require("src.Kernel.Profiler")
local Console = require("src.Kernel.Console")

local Expression = require("src.Expression")



function Debug:new()
	self.console = Console()

	self.commands = {
		t = {description = "Adjusts the speed scale of the game. 1 = default.", parameters = {{name = "scale", type = "number", optional = false}}},
		test = {description = "Spawns a test particle.", parameters = {}},
		crash = {description = "Crashes the game.", parameters = {}},
		expr = {description = "Evaluates an Expression.", parameters = {{name = "expression", type = "string", optional = false, greedy = true}}},
		exprt = {description = "Breaks down an Expression and shows the list of RPN steps.", parameters = {{name = "expression", type = "string", optional = false, greedy = true}}},
		ex = {description = "Debugs an Expression: shows detailed tokenization and list of RPN steps.", parameters = {{name = "expression", type = "string", optional = false, greedy = true}}},
		help = {description = "Displays this list.", parameters = {}},
		o = {description = "Sets a parameter for this game. Displays a list if executed without parameters.", parameters = {{name = "option", type = "string", optional = true}, {name = "value", type = "number", optional = true}}},
		win = {description = "Wins the current level on the next move.", parameters = {}},
		power = {description = "Immediately charges a power ready for use.", parameters = {{name = "color", type = "integer", optional = false}}}
	}
	self.commandNames = {}
	for commandName, commandData in pairs(self.commands) do
		table.insert(self.commandNames, commandName)
	end
	table.sort(self.commandNames)

	self.profUpdate = Profiler("Update")
	self.profDraw = Profiler("Draw")
	self.profDraw2 = Profiler("Draw")
	self.profDrawLevel = Profiler("Draw: Level")
	self.prof3 = Profiler("Draw: Level2")
	self.profMusic = Profiler("Music volume")

	self.profVisible = false
	self.profPage = 1
	self.profPages = {self.profUpdate, self.profMusic, self.profDrawLevel, self.prof3}

	self.uiDebugVisible = false
	self.uiDebugOffset = 0
	self.uiWidgetCount = 0
	self.e = false



	self.particleSpawnersVisible = false
	self.gameDebugVisible = false
	self.fpsDebugVisible = false
	self.chainDebug = false

	-- widget debug variables
	self.uiWidgetDebugCount = 0
	self.uiMouse = Vec2()
	self.uiMousePressed = false
	self.uiScrollPressOffset = nil
	self.uiHoveredEntry = nil
	self.uiCollapsedEntries = {}
	self.uiAutoCollapseInvisible = false
end



function Debug:update(dt)
	self.console:update(dt)
end

function Debug:draw()
	-- Profilers
	if self.profVisible then
		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(_FONT)
		self.profPages[self.profPage]:draw(Vec2(0, _DisplaySize.y))
		self.profDraw:draw(Vec2(400, _DisplaySize.y))
		self.profDraw2:draw(Vec2(400, _DisplaySize.y))

		self:drawVisibleText("Debug Keys:", Vec2(10, 10), 15)
		self:drawVisibleText("[F1] Performance", Vec2(10, 25), 15)
		self:drawVisibleText("[F2] UI Tree", Vec2(10, 40), 15)
		self:drawVisibleText("    [Ctrl+F2] Collapse all invisible UI Nodes", Vec2(10, 55), 15)
		self:drawVisibleText("[F3] Particle spawners", Vec2(10, 70), 15)
		self:drawVisibleText("[F4] Miscellaneous (FPS, level data, etc.)", Vec2(10, 85), 15)
		self:drawVisibleText("[F5] FPS Counter", Vec2(10, 100), 15)
		self:drawVisibleText("[F6] Chain debug", Vec2(10, 115), 15)
	end

	-- Console
	self.console:draw()

	-- UI tree
	self.uiHoveredEntry = nil
	if self.uiDebugVisible then
		-- Scrolling logic.
		local height = love.graphics.getHeight()
		local mousePos = _PosOnScreen(_MousePos)
		local scrollbarWidth = 15
		local scrollbarHeight = 50
		local logicalHeight = height - scrollbarHeight
		local maxWidgets = height / 15
		local maxOffset = (self.uiWidgetDebugCount - maxWidgets) * 15 + 30

		-- if the mouse is in clicked state then move the rectangle here
		if love.mouse.isDown(1) then
			if not self.uiScrollPressOffset then
				self.uiScrollPressOffset = self.uiDebugOffset - mousePos.y * (maxOffset / logicalHeight)
			end
			if self.uiMouse.x < scrollbarWidth then
				self.uiDebugOffset = mousePos.y * (maxOffset / logicalHeight) + self.uiScrollPressOffset
			end
		else
			self.uiScrollPressOffset = nil
		end

		-- Enforce the limits.
		self.uiDebugOffset = math.max(math.min(self.uiDebugOffset, maxOffset), 0)

		-- Which one we've hovered?
		local hover = nil
		if mousePos.x > 15 and mousePos.x < 500 then
			hover = math.floor((self.uiDebugOffset + mousePos.y) / 15)
		end

		-- Draw stuff.
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.rectangle("fill", 0, 0, 500, height)
		for i, line in ipairs(self:getUITreeText()) do
			local y = i * 15 - self.uiDebugOffset
			if i == hover then
				love.graphics.setColor(1, 0, 1, 0.3)
				love.graphics.rectangle("fill", 15, y, 485, 15)
				self.uiHoveredEntry = line[10]
			elseif self.uiAutoCollapseInvisible and line[11] then
				love.graphics.setColor(0, 0, 1, 0.3)
				love.graphics.rectangle("fill", 15, y, 485, 15)
			end
			love.graphics.setColor(1, 1, 1)
			love.graphics.print({line[9],line[1]}, 20, y)
			love.graphics.print(line[2], 260, y)
			love.graphics.print(line[3], 270, y)
			love.graphics.print(line[4], 280, y)
			love.graphics.print(line[5], 310, y)
			love.graphics.print(line[6], 340, y)
			love.graphics.print(line[7], 370, y)
			love.graphics.print(line[8], 410, y)
		end

		-- draw the scroll rectangle
		if self.uiWidgetDebugCount > maxWidgets then
			local yy = self.uiDebugOffset / maxOffset * logicalHeight
			love.graphics.setColor(0, 1, 0)
			love.graphics.rectangle("fill", 0, yy, scrollbarWidth, scrollbarHeight)
			love.graphics.setColor(1, 1, 1)
			love.graphics.setLineWidth(2)
			love.graphics.line(scrollbarWidth, 0, scrollbarWidth, height)
		end
	end

	-- Draw some debug stuff with the hovered widget.
	if self.uiHoveredEntry then
		self.uiHoveredEntry:drawDebug()
	end

	-- Game and spheres
	if self.gameDebugVisible then self:drawDebugInfo() end
	if self.fpsDebugVisible then self:drawFpsInfo() end
end

function Debug:keypressed(key)
	if not self.console.active then
		if key == "f1" then self.profVisible = not self.profVisible end
		if key == "f2" then
			if love.keyboard.isDown("lctrl", "rctrl") then
				self.uiAutoCollapseInvisible = not self.uiAutoCollapseInvisible
				self.console:print({_COLORS.aqua, string.format("[UI Debug] Auto-collapsing hidden UI elements: %s", self.uiAutoCollapseInvisible and "ON" or "OFF")})
			else
				self.uiDebugVisible = not self.uiDebugVisible
			end
		end
		if key == "f3" then self.particleSpawnersVisible = not self.particleSpawnersVisible end
		if key == "f4" then self.gameDebugVisible = not self.gameDebugVisible end
		if key == "f5" then self.fpsDebugVisible = not self.fpsDebugVisible end
		if key == "f6" then self.chainDebug = not self.chainDebug end
		if key == "kp-" and self.profPage > 1 then self.profPage = self.profPage - 1 end
		if key == "kp+" and self.profPage < #self.profPages then self.profPage = self.profPage + 1 end
		if key == "pagedown" then self.uiDebugOffset = self.uiDebugOffset + 300 end
		if key == "pageup" then self.uiDebugOffset = self.uiDebugOffset - 300 end
		if key == "f9" then
			local newOption = not _Game.game.settings.goldTileAnimation
			_Game.game.settings.goldTileAnimation = newOption
			self.console:print({_COLORS.yellow, "Gold tile animation ", _COLORS.green, newOption and "enabled" or "disabled"})
		end
		if key == "f10" then
			local newOption = _Game.game.settings.chainExplosionStyle == "legacy" and "new" or "legacy"
			_Game.game.settings.chainExplosionStyle = newOption
			self.console:print({_COLORS.yellow, "Chain explosion style set to ", _COLORS.green, newOption})
		end
		if key == "f11" then
			local newOption = _Game.game.settings.goldTileStyle == "old" and "new" or "old"
			_Game.game.settings.goldTileStyle = newOption
			self.console:print({_COLORS.yellow, "Gold tile style set to ", _COLORS.green, newOption})
		end
		if key == "f12" then
			local newOption = not _Game.game.settings.smoothHoverMovement
			_Game.game.settings.smoothHoverMovement = newOption
			self.console:print({_COLORS.yellow, "Smooth tile hover movement ", _COLORS.green, newOption and "enabled" or "disabled"})
		end
	end

	self.console:keypressed(key)
end

function Debug:keyreleased(key)
	self.console:keyreleased(key)
end

function Debug:textinput(t)
	self.console:textinput(t)
end

function Debug:mousepressed(x, y, button)
	if button == 1 then
		self.uiMouse = Vec2(x, y)
	end
end

function Debug:mousereleased(x, y, button)
	if button == 1 then
		self.uiMouse = Vec2(x, y)
		if self.uiHoveredEntry then
			if self.uiCollapsedEntries[self.uiHoveredEntry] then
				self.uiCollapsedEntries[self.uiHoveredEntry] = nil
			else
				self.uiCollapsedEntries[self.uiHoveredEntry] = true
			end
		end
	end
end

function Debug:wheelmoved(x, y)
	self.uiDebugOffset = self.uiDebugOffset - y * 45
end



function Debug:getUITreeText(node, rowTable, indent)
	if not node then
		self.uiWidgetDebugCount = 0
	end

	local ui2 = _Game.configManager.config.useUI2
	if ui2 then
		node = node or _Game.uiManager.rootNodes["root"] or _Game.uiManager.rootNodes["splash"]
	else
		node = node or _Game.uiManager.widgets.root or _Game.uiManager.widgets.splash
	end
	rowTable = rowTable or {}
	indent = indent or 0

	if node then
		local forAutoCollapsing = not ui2 and (node:hasChildren() and not node:isVisible() and node:isNotAnimating())
		local collapsed = node:hasChildren() and self.uiCollapsedEntries[node] or (self.uiAutoCollapseInvisible and forAutoCollapsing)

		local name = node.name
		for i = 1, indent do name = "    " .. name end
		if collapsed then
			name = name .. " ..."
		end
		local visible = ""
		local visible2 = ""
		if not ui2 then
			visible = node.visible and "X" or ""
			visible2 = node:isVisible() and "V" or ""
		end
		local active = node:isActive() and "A" or ""
		local alpha = string.format("%.1f", node.alpha)
		local alpha2
		if ui2 then
			alpha2 = string.format("%.1f", node:getGlobalAlpha())
		else
			alpha2 = string.format("%.1f", node:getAlpha())
		end
		local time = ""
		if not ui2 then
			time = node.time and tostring(math.floor(node.time * 100) / 100) or "-"
		end
		local pos = tostring(node.pos)
		local color = node.debugColor or {1, 1, 1}

		table.insert(rowTable, {name, visible, visible2, active, alpha, alpha2, time, pos, color, node, forAutoCollapsing})
		self.uiWidgetDebugCount = self.uiWidgetDebugCount + 1

		if not collapsed then
			local children = {}
			for childN, child in pairs(node.children) do
				table.insert(children, child)
			end
			table.sort(children, function(a, b) return a.name < b.name end)
			for i, child in ipairs(children) do
				self:getUITreeText(child, rowTable, indent + 1)
			end
		end
	end

	return rowTable
end



function Debug:isUITreeHovered()
	return self.uiDebugVisible and _PosOnScreen(_MousePos).x < 500
end



function Debug:getDebugMain()
	local s = ""

	s = s .. "Version = " .. _VERSION .. "\n"
	s = s .. "Game = " .. _Game.name .. "\n"
	s = s .. "FPS = " .. tostring(love.timer.getFPS()) .. "\n"
	s = s .. "Drawcalls = " .. tostring(love.graphics.getStats().drawcalls) .. "\n"
	s = s .. "DrawcallsSaved = " .. tostring(love.graphics.getStats().drawcallsbatched) .. "\n"
	s = s .. "UIWidgetCount = " .. tostring(self.uiWidgetCount) .. "\n"

	return s
end

function Debug:getDebugParticle()
	local s = ""

	s = s .. "ParticlePacket# = " .. tostring(_Game.particleManager:getParticlePacketCount()) .. "\n"
	s = s .. "ParticleSpawner# = " .. tostring(_Game.particleManager:getParticleSpawnerCount()) .. "\n"
	s = s .. "Particle# = " .. tostring(_Game.particleManager:getParticlePieceCount()) .. "\n"

	return s
end

function Debug:getDebugBoard(board)
	local s = ""
	
	s = s .. "FallingObjectCount = " .. tostring(board.fallingObjectCount) .. "\n"
	s = s .. "RotatingChainCount = " .. tostring(board.rotatingChainCount) .. "\n"
	s = s .. "ShufflingChainCount = " .. tostring(board.shufflingChainCount) .. "\n"
	s = s .. "PrimedObjectCount = " .. tostring(board.primedObjectCount) .. "\n"

	return s
end

function Debug:getDebugOptions()
	local s = ""

	s = s .. "MusicVolume = " .. tostring(_Game.runtimeManager.options:getMusicVolume()) .. "\n"
	s = s .. "SoundVolume = " .. tostring(_Game.runtimeManager.options:getSoundVolume()) .. "\n"
	s = s .. "FullScreen = " .. tostring(_Game.runtimeManager.options:getFullscreen()) .. "\n"
	s = s .. "Mute = " .. tostring(_Game.runtimeManager.options:getMute()) .. "\n"
	s = s .. "\n"
	s = s .. "EffMusicVolume = " .. tostring(_Game.runtimeManager.options:getEffectiveMusicVolume()) .. "\n"
	s = s .. "EffSoundVolume = " .. tostring(_Game.runtimeManager.options:getEffectiveSoundVolume()) .. "\n"

	return s
end

function Debug:getDebugInfo()
	local s = ""

	s = s .. "===== MAIN =====\n"
	s = s .. self:getDebugMain()
	s = s .. "\n===== PARTICLE =====\n"
	if _Game.particleManager then
		s = s .. self:getDebugParticle()
	end
	s = s .. "\n===== BOARD =====\n"
	if _Game.game and _Game.game.scene and _Game.game.scene.board then
		s = s .. self:getDebugBoard(_Game.game.scene.board)
	end
	s = s .. "\n===== OPTIONS =====\n"
	if _Game.runtimeManager then
		s = s .. self:getDebugOptions()
	end

	-- table.insert(s, "")
	-- table.insert(s, "===== EXTRA =====")
	-- if game.widgets.root then
		-- local a = game:getWidget({"root", "Game", "Hud"}).actions
		-- for k, v in pairs(a) do
			-- table.insert(s, k .. " -> ")
			-- for k2, v2 in pairs(v) do
				-- local n = "    " .. k2 .. " = {"
				-- for k3, v3 in pairs(v2) do
					-- n = n .. k3 .. ":" .. tostring(v3) .. ", "
				-- end
				-- n = n .. "}"
				-- table.insert(s, n)
			-- end
		-- end
	-- end

	return s
end



function Debug:drawVisibleText(text, pos, height, width, alpha, shadow)
	alpha = alpha or 1

	if text == "" then
		return
	end

	love.graphics.setColor(0, 0, 0, 0.7 * alpha)
	if width then
		love.graphics.rectangle("fill", pos.x - 3, pos.y, width - 3, height)
	else
		love.graphics.rectangle("fill", pos.x - 3, pos.y, love.graphics.getFont():getWidth(_Utils.strUnformat(text)) + 6, height)
	end
	if shadow then
		love.graphics.setColor(0, 0, 0, alpha)
		love.graphics.print(text, pos.x + 2, pos.y + 2)
	end
	love.graphics.setColor(1, 1, 1, alpha)
	love.graphics.print(text, pos.x, pos.y)
end

function Debug:drawDebugInfo()
	-- Debug screen
	--local p = posOnScreen(Vec2())
	local p = Vec2()

	local spl = _Utils.strSplit(self:getDebugInfo(), "\n")

	for i, l in ipairs(spl) do
		self:drawVisibleText(l, p + Vec2(0, 15 * (i - 1)), 15)
	end
end

function Debug:drawFpsInfo()
	local s = "FPS = " .. tostring(love.timer.getFPS())

	self:drawVisibleText(s, Vec2(), 15, 65)
end



function Debug:runCommand(command)
	local words = _Utils.strSplit(command, " ")

	-- Get basic command stuff.
	local command = words[1]
	local commandData = self.commands[command]
	if not commandData then
		self.console:print({_COLORS.red, string.format("Command \"%s\" not found. Type \"help\" to see available commands.", words[1])})
		return
	end

	-- Obtain all necessary parameters.
	local parameters = {}
	for i, parameter in ipairs(commandData.parameters) do
		local raw = words[i + 1]
		if not raw then
			if not parameter.optional then
				self.console:print({_COLORS.red, string.format("Missing parameter: \"%s\", expected: %s", parameter.name, parameter.type)})
				return
			end
		else
			if parameter.type == "number" or parameter.type == "integer" then
				raw = tonumber(raw)
				if not raw then
					self.console:print({_COLORS.red, string.format("Failed to convert to number: \"%s\", expected: %s", words[i + 1], parameter.type)})
					return
				end
			end
			-- Greedy parameters can only be strings and are always last (taking the rest of the command).
			if parameter.type == "string" and parameter.greedy then
				for j = i + 2, #words do
					raw = raw .. " " .. words[j]
				end
			end
		end
		table.insert(parameters, raw)
	end

	-- Command handling
	if command == "help" then
		self.console:print({_COLORS.purple, "This is a still pretty rough console of OpenSMCE!    ...wait, what?"})
		self.console:print({_COLORS.green, "Available commands:"})
		for i, name in ipairs(self.commandNames) do
			local commandData = self.commands[name]
			local msg = {_COLORS.yellow, name}
			for i, parameter in ipairs(commandData.parameters) do
				local name = parameter.name
				if parameter.greedy then
					name = name .. "..."
				end
				if parameter.optional then
					table.insert(msg, _COLORS.aqua)
					table.insert(msg, string.format(" [%s]", name))
				else
					table.insert(msg, _COLORS.aqua)
					table.insert(msg, string.format(" <%s>", name))
				end
			end
			table.insert(msg, _COLORS.white)
			table.insert(msg, " - " .. commandData.description)
			self.console:print(msg)
		end
	elseif command == "fs" then
		--toggleFullscreen()
		self.console:print("Fullscreen toggled")
	elseif command == "t" then
		_TimeScale = parameters[1]
		self.console:print("Time scale set to " .. tostring(parameters[1]))
	elseif command == "test" then
		_Game:spawnParticle("particles/collapse_vise.json", Vec2(100, 400))
	elseif command == "crash" then
		return "crash"
	elseif command == "expr" then
		local result = _Vars:evaluateExpression(parameters[1])
		self.console:print(string.format("expr(%s): %s", parameters[1], result))
	elseif command == "exprt" then
		local ce = Expression(parameters[1], true)
		for i, step in ipairs(ce.data) do
			_Log:printt("Debug", string.format("%s   %s", step.type, step.value))
		end
		self.console:print(string.format("exprt(%s): %s", parameters[1], ce:getDebug()))
	elseif command == "ex" then
		local ce = Expression("2", true)
		self.console:print(string.format("ex(%s):", parameters[1]))
		local tokens = ce:tokenize(parameters[1])
		for i, token in ipairs(tokens) do
			self.console:print(string.format("%s   %s", token.value, token.type))
		end
		self.console:print("")
		self.console:print("")
		self.console:print("Compilation result:")
		ce.data = ce:compile(tokens)
		for i, step in ipairs(ce.data) do
			self.console:print(string.format("%s   %s", step.type, step.value))
		end
		self.console:print(string.format("ex(%s): %s", parameters[1], ce:evaluate()))
	elseif command == "o" then
		local option = parameters[1]
		local value = parameters[2]
		if option == "expl" then
			if value == 0 then
				_Game.game.settings.chainExplosionStyle = "legacy"
			elseif value == 1 then
				_Game.game.settings.chainExplosionStyle = "new"
			else
				self.console:print("expl - Chain explosion style.")
				self.console:print(" 0 - old, known from the original demo.")
				self.console:print(" 1 - new, with a flash Looks meh.")
			end
		elseif option == "gold" then
			if value == 0 then
				_Game.game.settings.goldTileStyle = "old"
			elseif value == 1 then
				_Game.game.settings.goldTileStyle = "new"
			else
				self.console:print("gold - Gold tile style.")
				self.console:print(" 0 - old, brigher and might be more eye-soaring?")
				self.console:print(" 1 - new, a bit darker but does not look as good?")
			end
		elseif option == "hmov" then
			if value == 0 then
				_Game.game.settings.smoothHoverMovement = false
			elseif value == 1 then
				_Game.game.settings.smoothHoverMovement = true
			else
				self.console:print("hmov - Board hover movement style.")
				self.console:print(" 0 - Instant.")
				self.console:print(" 1 - Smooth, but a bit less snappy.")
			end
		else
			self.console:print("Available options:")
			self.console:print(" expl - Chain explosion style.")
			self.console:print(" gold - Gold tile style.")
			self.console:print(" hmov - Board hover movement style.")
			self.console:print("")
			self.console:print({_COLORS.green, "Or for the fuck's sake, just press F10, F11 or F12!"})
		end
	elseif command == "win" then
		_Game.game.scene.forcedWin = true
		self.console:print("Just one more move and you're done!")
	elseif command == "power" then
		local level = _Game.game.scene
		level:chargeMaxPower(parameters[1])
		self.console:print("Charged!")
	else
		self.console:print({_COLORS.red, "Unrecognized command"})
	end
end

function Debug:profUpdateStart()
	self.profUpdate:start()
end

function Debug:profUpdateStop()
	self.profUpdate:stop()
end

function Debug:profDrawStart()
	self.profDraw:start()
end

function Debug:profDrawStop()
	self.profDraw:stop()
end

function Debug:profDraw2Start()
	self.profDraw2:start()
end

function Debug:profDraw2Checkpoint(n)
	self.profDraw2:checkpoint(n)
end

function Debug:profDraw2Stop()
	self.profDraw2:stop()
end

function Debug:profDrawLevelStart()
	self.profDrawLevel:start()
end

function Debug:profDrawLevelCheckpoint(n)
	self.profDrawLevel:checkpoint(n)
end

function Debug:profDrawLevelStop()
	self.profDrawLevel:stop()
end



function Debug:getWitty()
	local witties = _Utils.strSplit(_Utils.loadFile("assets/eggs_crash.txt"), "\n")
	return witties[math.random(1, #witties)]
end



return Debug
