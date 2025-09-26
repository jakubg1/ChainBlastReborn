local class = require "com.class"

---@class Shader
---@overload fun(data, path, namespace, batches):Shader
local Shader = class:derive("Shader")

function Shader:new(data, path, namespace, batches)
	self.path = path
	self.shader = _Utils.loadShader(_ParsePath(path))
	assert(self.shader, "Failed to load shader: " .. path)
end

return Shader
