local class = require "com.class"

---@class Sprite
---@overload fun(data, path):Sprite
local Sprite = class:derive("Sprite")

local SpriteConfig = require("src.Configs.Sprite")
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local Image = require("src.Essentials.Image")



---Constructs a new Sprite.
---@param data table The parsed JSON data of the sprite.
---@param path string A path to the sprite file.
function Sprite:new(data, path)
	self.path = path
	self.config = SpriteConfig(data, path)

	self.size = self.config.image.size
	---@type [{frameCount: integer, frames: [love.Quad]}]
	self.states = {}
	for i, state in ipairs(self.config.states) do
		local s = {}
		s.frameCount = state.frames.x * state.frames.y
		s.frames = {}
		local frameSize = self:getFrameSize(i)
		for j = 1, state.frames.x do
			for k = 1, state.frames.y do
				local p = frameSize * (Vec2(j, k) - 1) + state.pos
				s.frames[(k - 1) * state.frames.x + j] = love.graphics.newQuad(p.x, p.y, frameSize.x, frameSize.y, self.size.x, self.size.y)
			end
		end
		self.states[i] = s
	end
end



---Returns a `love.Quad` object for use in drawing functions.
---@param state integer The state ID of this sprite.
---@param frame integer Which frame of that state should be returned.
---@return love.Quad
function Sprite:getFrame(state, frame)
	local s = self.states[state]
	return s.frames[(frame - 1) % s.frameCount + 1]
end



---Returns the frame size for a given state.
---@param state integer The state ID of this sprite.
---@return Vector2
function Sprite:getFrameSize(state)
	local s = self.config.states[state]
	assert(s, string.format("Tried to get state %s, but the sprite %s only has %s states!", state, self.path, #self.states))
	return s.frameSize or self.config.frameSize
end



---Returns the top left position of the given frame on this Sprite's image.
---@param state integer The state ID of this sprite.
---@param frame integer The frame of which the top left position will be returned.
---@return Vector2
function Sprite:getFramePos(state, frame)
	local s = self.config.states[state]
	return s.pos + Vec2((frame - 1) % s.frames.x, math.floor((frame - 1) / s.frames.x)) * self.config.frameSize
end



---Returns the amount of states in this Sprite.
---@return integer
function Sprite:getStateCount()
	return #self.states
end



---Draws this Sprite onto the screen.
---@param pos Vector2 The sprite position.
---@param align Vector2? The sprite alignment. `(0, 0)` is the top left corner. `(1, 1)` is the bottom right corner. `(0.5, 0.5)` is in the middle.
---@param state integer? The state ID to be drawn.
---@param frame integer? The state's frame to be drawn.
---@param rot number? The sprite rotation in radians.
---@param color Color? The sprite color.
---@param alpha number? Sprite transparency. `0` is fully transparent. `1` is fully opaque.
---@param scale Vector2? The scale of this sprite.
---@param shader Shader? The shader to be used when drawing this sprite. Does not apply to the shadow.
function Sprite:draw(pos, align, state, frame, rot, color, alpha, scale, shader)
	align = align or Vec2()
	state = state or 1
	frame = frame or 1
	rot = rot or 0
	color = color or Color()
	alpha = alpha or 1
	scale = scale or Vec2(1)
	local size = self:getFrameSize(state)
	if _Game.configManager:isCanvasRenderingEnabled() then
		-- If all stuff is rendered on canvases, the canvas itself will be scaled.
		pos = pos - (align * scale * size):rotate(rot)
	else
		pos = _PosOnScreen(pos - (align * scale * size):rotate(rot))
		scale = scale * _GetResolutionScale()
	end
	love.graphics.setColor(color.r, color.g, color.b, alpha)
	local oldShader = love.graphics.getShader()
	if shader then
		love.graphics.setShader(shader.shader)
	end
	self.config.image:draw(self:getFrame(state, frame), pos.x, pos.y, rot, scale.x, scale.y)
	if shader then
		love.graphics.setShader(oldShader)
	end
end



---Draws this Sprite onto the screen, along with a black semitransparent copy one pixel down and to the right.
---@param pos Vector2 The sprite position.
---@param align Vector2? The sprite alignment. `(0, 0)` is the top left corner. `(1, 1)` is the bottom right corner. `(0.5, 0.5)` is in the middle.
---@param state integer? The state ID to be drawn.
---@param frame integer? The state's frame to be drawn.
---@param rot number? The sprite rotation in radians.
---@param color Color? The sprite color.
---@param alpha number? Sprite transparency. `0` is fully transparent. `1` is fully opaque.
---@param scale Vector2? The scale of this sprite.
---@param shader Shader? The shader to be used when drawing this sprite. Does not apply to the shadow.
---@param shadowAlpha number? The alpha of this sprite's shadow.
function Sprite:drawWithShadow(pos, align, state, frame, rot, color, alpha, scale, shader, shadowAlpha)
	shadowAlpha = shadowAlpha or 0.5
	self:draw(pos + 1, align, state, frame, rot, Color(0, 0, 0), (alpha or 1) * shadowAlpha, scale)
	self:draw(pos, align, state, frame, rot, color, alpha, scale, shader)
end



local DIRS = {
	{x = 0, y = -1},
	{x = 1, y = 0},
	{x = 0, y = 1},
	{x = -1, y = 0}
}

---Takes a single frame from this Sprite and splits it into multiple "puzzles".
---The resulting Sprite will have one state per piece. All pieces have one frame.
---@param state integer The state ID to pick a frame from.
---@param frame integer The frame ID to be picked. This will determine a single frame which will be split.
---@return Sprite
function Sprite:split(state, frame)
	local pxOffset = self:getFramePos(state, frame)
	local frameSize = self:getFrameSize(state)
	-- Generate a splitmap to determine which pixel should land on which texture.
	local splitmap = love.image.newImageData(frameSize.x, frameSize.y)
	-- Determine kernel positions.
	local kernelShots = 0
	local kernelHits = 0
	while kernelShots < 7 or kernelHits < 2 do
		-- Generate a random point on the texture.
		kernelShots = kernelShots + 1
		local x, y = math.random(0, frameSize.x - 1), math.random(0, frameSize.y - 1)
		-- Check the pixel at that location.
		local r, g, b, a = self.config.image.data:getPixel(x + pxOffset.x, y + pxOffset.y)
		if a > 0 then
			-- We still need to check, maybe we are accidentally overwriting a pixel?
			local sr, sg, sb, sa = splitmap:getPixel(x, y)
			if sr == 0 then
				-- Hit: save this kernel on the splitmap.
				kernelHits = kernelHits + 1
				splitmap:setPixel(x, y, kernelHits / 255, 0, 0, 1)
			end
		end
	end
	-- Pop the kernels.
	local scratchpad = love.image.newImageData(frameSize.x, frameSize.y)
	local pixelsMissing = true
	local passes = 0
	while pixelsMissing do
		-- This will be set back to `true` if another pass is necessary.
		pixelsMissing = false
		passes = passes + 1
		-- For each pass, we will copy the splitmap to the scratchpad.
		-- We will use it to determine the new splitmap. We will grow the kernels in a kind of a flood fill algorithm.
		scratchpad:paste(splitmap, 0, 0, 0, 0, frameSize.x, frameSize.y)
		for x = 0, frameSize.x - 1 do
			for y = 0, frameSize.y - 1 do
				local r, g, b, a = scratchpad:getPixel(x, y)
				if r == 0 then
					-- This pixel hasn't been occupied by any fragment yet. Let's check the neighbors.
					local nr, ng, nb, na
					local dir = math.random(1, 4)
					for i = 1, 4 do
						local nx = x + DIRS[dir].x
						local ny = y + DIRS[dir].y
						if nx >= 0 and nx < frameSize.x and ny >= 0 and ny < frameSize.y then
							nr, ng, nb, na = scratchpad:getPixel(nx, ny)
							if nr > 0 then
								break
							end
						end
						dir = dir % 4 + 1
					end
					if nr > 0 then
						-- Apply the gathered pixel to the actual splitmap.
						splitmap:setPixel(x, y, nr, ng, nb, na)
					else
						-- If the pixel is kept black, make sure to perform another iteration.
						pixelsMissing = true
					end
				end
			end
		end
		-- Forcefully break the iteration if we've exceeded the theoretically maximum number of steps.
		if passes > frameSize.x + frameSize.y then
			print("ERROR: `Sprite:split()` got stuck for too long!")
			break
		end
	end
	-- Generate an image which will contain all pieces.
	-- The amount of kernel hits is the number of pieces generated.
	-- For each piece, mask out all irrelevant parts of the splitmap.
	local imgData = love.image.newImageData(frameSize.x * kernelHits, frameSize.y)
	for i = 1, kernelHits do
		for x = 0, frameSize.x - 1 do
			for y = 0, frameSize.y - 1 do
				local sr, sg, sb, sa = splitmap:getPixel(x, y)
				if sr == i / 255 then
					local r, g, b, a = self.config.image.data:getPixel(x + pxOffset.x, y + pxOffset.y)
					imgData:setPixel(x + (i - 1) * frameSize.x, y, r, g, b, a)
				end
			end
		end
	end
	local img = Image(imgData)
	local spriteData = {
		path = img,
		frameSize = {x = frameSize.x, y = frameSize.y},
		states = {}
	}
	for i = 1, kernelHits do
		spriteData.states[i] = {pos = {x = (i - 1) * frameSize.x, y = 0}, frames = {x = 1, y = 1}}
	end
	return Sprite(spriteData)
end



return Sprite
