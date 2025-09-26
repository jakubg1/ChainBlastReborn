local class = require "com.class"

---@class Image
---@overload fun(data, path):Image
local Image = class:derive("Image")

local Vec2 = require("src.Essentials.Vector2")

---Constructs a new Image.
---@param data love.ImageData? If specified, the image will be loaded directly from this data and the `path` field will be ignored.
---@param path string? Path to the image.
function Image:new(data, path)
	self.path = path

	if data then
		self.data = data
	elseif path then
		self.data = _Utils.loadImageData(_ParsePath(path))
	end
	assert(self.data, "Failed to load image data: " .. tostring(path))
	self.img = love.graphics.newImage(self.data)
	self.size = Vec2(self.img:getDimensions())
end

---Draws the Image onto the screen.
---This is an alias to `love.graphics.draw(Image.img, ...)`.
function Image:draw(...)
	love.graphics.draw(self.img, ...)
end

return Image
