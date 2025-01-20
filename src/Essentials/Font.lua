local class = require "com.class"

---@class Font
---@overload fun(data, path):Font
local Font = class:derive("Font")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



function Font:new(data, path)
	self.path = path

	self.type = data.type

	if self.type == "image" then
		self.image = _Game.resourceManager:getImage(data.image)
		self.height = self.image.size.y
		self.characters = {}
		for characterN, character in pairs(data.characters) do
			self.characters[characterN] = {
				quad = love.graphics.newQuad(character.offset, 0, character.width, self.image.size.y, self.image.size.x, self.image.size.y),
				width = character.width
			}
		end

		self.reportedCharacters = {}
	elseif self.type == "imageLove" then
		self.font = love.graphics.newImageFont(_Utils.loadImageData(_ParsePath(data.image)), data.characters, 1)
		self.color = Color(1, 1, 1)
	elseif self.type == "truetype" then
		self.font = _Utils.loadFont(_ParsePath(data.path), data.size)
		self.color = _ParseColor(data.color)
	end
end

-- Image type only
function Font:getCharacter(character)
	local b = character:byte()
	local c = self.characters[character]
	if c then
		return c
	elseif b >= 97 and b <= 122 then
		-- if lowercase character does not exist, we try again with an uppercase character
		return self:getCharacter(string.char(b - 32))
	else
		-- report only once
		if not self.reportedCharacters[character] then
			_Log:printt("Font", "ERROR: No character " .. tostring(character) .. " was found in font " .. self.path)
			self.reportedCharacters[character] = true
		end
		return self.characters["0"]
	end
end

function Font:getTextSize(text)
	if self.type == "image" then
		local size = Vec2(0, self.height)
		local lineWidth = 0
		for i = 1, text:len() do
			local character = text:sub(i, i)
			if character == "\n" then
				size.x = math.max(size.x, lineWidth)
				lineWidth = 0
				size.y = size.y + self.height
			else
				lineWidth = lineWidth + self:getCharacter(character).width
			end
		end
		size.x = math.max(size.x, lineWidth)
		return size
	elseif self.type == "imageLove" or self.type == "truetype" then
		local size = Vec2(self.font:getWidth(text), self.font:getHeight())
		for i = 1, text:len() do
			local character = text:sub(i, i)
			if character == "\n" then
				size.y = size.y + self.font:getHeight()
			end
		end
		return size
	end
end

function Font:draw(text, pos, align, color, alpha, scale)
	align = align or Vec2(0.5)
	color = color or Color()
	alpha = alpha or 1
	scale = scale or 1

	if self.type == "image" then
		love.graphics.setColor(color.r, color.g, color.b, alpha)

		local y = pos.y - self:getTextSize(text).y * align.y
		local line = ""
		for i = 1, text:len() do
			local character = text:sub(i, i)
			if character == "\n" then
				self:drawLine(line, Vec2(pos.x, y), align.x)
				line = ""
				y = y + self.height
			else
				line = line .. character
			end
		end
		self:drawLine(line, Vec2(pos.x, y), align.x)
	elseif self.type == "imageLove" or self.type == "truetype" then
		local oldFont = love.graphics.getFont()

		love.graphics.setColor(color.r * self.color.r, color.g * self.color.g, color.b * self.color.b, alpha)
		love.graphics.setFont(self.font)
		if _Game.configManager:isCanvasRenderingEnabled() then
			local p = pos - self:getTextSize(text) * align * scale
			love.graphics.print(text, p.x, p.y, 0, scale)
		else
			local p = _PosOnScreen(pos - self:getTextSize(text) * align * scale)
			love.graphics.print(text, p.x, p.y, 0, scale * _GetResolutionScale())
		end

		love.graphics.setFont(oldFont)
	end
end

function Font:drawWithShadow(text, pos, align, color, alpha, scale)
	self:draw(text, pos + 1, align, Color(0, 0, 0), (alpha or 1) * 0.5, scale)
	self:draw(text, pos, align, color, alpha, scale)
end

-- Image type only
function Font:drawLine(text, pos, align)
	pos.x = pos.x - self:getTextSize(text).x * align
	for i = 1, text:len() do
		local character = text:sub(i, i)
		self:drawCharacter(character, pos)
		pos.x = pos.x + self:getCharacter(character).width
	end
end

-- Image type only
function Font:drawCharacter(character, pos)
	pos = _PosOnScreen(pos)
	--if self.characters[character] then
	self.image:draw(self:getCharacter(character).quad, math.floor(pos.x), math.floor(pos.y), 0, _GetResolutionScale())
	--else
	--	print("ERROR: Unexpected character: " .. character)
	--end
end

return Font
