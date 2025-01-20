local class = require "com.class"

---@class UI2Node
---@overload fun(manager, config, name, parent):UI2Node
local UI2Node = class:derive("UI2Node")

-- Place your imports here
local UI2WidgetRectangle = require("src.UI2.WidgetRectangle")
local UI2WidgetSprite = require("src.UI2.WidgetSprite")
local UI2WidgetSpriteButton = require("src.UI2.WidgetSpriteButton")
local UI2WidgetSpriteProgress = require("src.UI2.WidgetSpriteProgress")
local UI2WidgetText = require("src.UI2.WidgetText")



---Constructs a new UI2Node.
---@param manager UI2Manager The UI2 Manager this Node belongs to.
---@param config UI2NodeConfig The UI2 Node Config which describes this Node.
---@param name string Specifies the name of this Node. Should match with this Parent's child of this name, or "root" / "splash" if no parent specified.
---@param parent UI2Node? The UI2 Node which is a parent of this Node. If not specified, this will be a root node.
function UI2Node:new(manager, config, name, parent)
    self.manager = manager
    self.config = config
    self.name = name
    self.parent = parent

    -- Data
    self.pos = config.pos
    self.scale = config.scale
    self.alpha = config.alpha
    -- Layers are here and not in Widgets, because the layers can be inherited. We need this for purposes of including the same Nodes in different places.
    self.layer = config.layer

    -- Activation
    self.active = false

    -- Animations
    -- Each element in this table has properties: "property", "from", "to", "duration", "time", and an optional property "sequence" (sequence to resume).
    self.activeAnimations = {}

    -- Children
    self.children = {}
    for childN, child in pairs(config.children) do
        local childConfig = child
        if type(childConfig) == "string" then
            -- Load from another file.
            childConfig = _Game.resourceManager:getUINodeConfig(childConfig)
        end
        self.children[childN] = UI2Node(manager, childConfig, childN, self)
    end

    -- Widget
    local w = config.widget
    if w then
        if w.type == "rectangle" then
            self.widget = UI2WidgetRectangle(self, w.align, w.size, w.color)
        elseif w.type == "sprite" then
            self.widget = UI2WidgetSprite(self, w.align, w.sprite)
        elseif w.type == "spriteButton" then
            self.widget = UI2WidgetSpriteButton(self, w.align, w.sprite, w.shape, w.callbacks)
        elseif w.type == "spriteProgress" then
            self.widget = UI2WidgetSpriteProgress(self, w.align, w.sprite, w.value, w.smooth)
        elseif w.type == "text" then
            self.widget = UI2WidgetText(self, w.align, w.font, w.text, w.color)
        end
    end
end



---Updates this Node and its children.
---@param dt number Time delta in seconds.
function UI2Node:update(dt)
    -- Update the animations.
    for i = #self.activeAnimations, 1, -1 do
        local animation = self.activeAnimations[i]
        animation.time = animation.time + dt
        local progress = math.min(animation.time / animation.duration, 1)
        local value = animation.from * (1 - progress) + animation.to * progress
        if animation.property == "alpha" then
            self.alpha = value
        elseif animation.property == "pos" then
            self.pos = value
        elseif animation.property == "posX" then
            self.pos.x = value
        elseif animation.property == "posY" then
            self.pos.y = value
        elseif animation.property == "scale" then
            self.scale = value
        elseif animation.property == "scaleX" then
            self.scale.x = value
        elseif animation.property == "scaleY" then
            self.scale.y = value
        end
        -- Kill the animation once it's finished.
        if progress == 1 then
            if animation.sequence then
                animation.sequence:releaseLock()
            end
            table.remove(self.activeAnimations, i)
        end
    end

    -- Update the Widget itself.
    if self.widget and self.widget.update then
        self.widget:update(dt)
    end

    -- Update all children.
    for childN, child in pairs(self.children) do
        child:update(dt)
    end
end



---Plays an Animation on this Node.
---@param config UI2AnimationConfig The config of the animation to be applied.
---@param sequence UI2Sequence? The UI Sequence which has called this Animation.
---@param sequenceStep integer? The specific step of the UI Sequence which has called this Animation.
function UI2Node:playAnimation(config, sequence, sequenceStep)
    -- Prepend the current value if not specified.
    local from = config.from
    if not from then
        if config.property == "alpha" then
            from = self.alpha
        elseif config.property == "pos" then
            from = self.pos
        elseif config.property == "posX" then
            from = self.pos.x
        elseif config.property == "posY" then
            from = self.pos.y
        elseif config.property == "scale" then
            from = self.scale
        elseif config.property == "scaleX" then
            from = self.scale.x
        elseif config.property == "scaleY" then
            from = self.scale.y
        end
    end

    -- Insert to the active animation list.
    table.insert(self.activeAnimations, {
        property = config.property,
        from = from,
        to = config.to,
        duration = config.duration,
        time = 0,
        sequence = sequence,
        sequenceStep = sequenceStep
    })
end



---Returns the current effective position of this Node.
---@return Vector2
function UI2Node:getGlobalPos()
    if not self.parent then
        return self.pos
    end
    return self.parent:getGlobalPos() + self.pos * self.parent.scale
end

---Returns the current effective scale of this Node.
---@return Vector2
function UI2Node:getGlobalScale()
    if not self.parent then
        return self.scale
    end
    return self.parent:getGlobalScale() * self.scale
end

---Returns the current effective alpha value of this Node.
---@return number
function UI2Node:getGlobalAlpha()
    if not self.parent then
        return self.alpha
    end
    return self.parent:getGlobalAlpha() * self.alpha
end



---Returns the current layer this Node is on.
---@return string
function UI2Node:getLayer()
    if self.layer then
        return self.layer
    end
    if self.parent then
        return self.parent:getLayer()
    end
    return "MAIN"
end



---Returns a child of this Node with a given name if it exists.
---@return UI2Node?
function UI2Node:getChild(name)
    return self.children[name]
end



---Returns whether this Node is visible.
---@return boolean
function UI2Node:isVisible()
    return self:getGlobalAlpha() > 0
end



---Returns whether this Node is active, i.e. it can be interacted with.
---@return boolean
function UI2Node:isActive()
	return self.widget and self:isVisible() and self.active
end



---Marks this Node and all its children as active. Active Nodes along with the associated Widgets are the only ones which the player can interact with.
---@param append boolean? If `true`, the previously active Nodes will remain active. Otherwise, all already active Nodes will be deactivated first.
function UI2Node:setActive(append)
    if not append then
        self.manager:resetActive()
    end
    self.active = true
    for childN, child in pairs(self.children) do
        child:setActive(true)
    end
end



---Deactivates this Node and all its children, which means the associated Widget can no longer be interacted with.
function UI2Node:resetActive()
    self.active = false
    for childN, child in pairs(self.children) do
        child:resetActive()
    end
end



---If the Widget attached to this Node is a button, set its enabled state.
---@param enabled boolean Whether the button should be enabled.
function UI2Node:buttonSetEnabled(enabled)
    if self.widget and self.widget.type == "spriteButton" then
        self.widget:setEnabled(enabled)
    end
end



---Returns whether a meaningful Node (which is either this or its child) like a button has been hovered.
---@return boolean
function UI2Node:isButtonHovered()
    if self.widget and self.widget.type == "spriteButton" and self.widget.hovered then
        return true
    end

    for childN, child in pairs(self.children) do
        if child:isButtonHovered() then
            return true
        end
    end
    return false
end



---Returns the full path to this Node.
---@return string
function UI2Node:getPath()
    if not self.parent then
        return self.name
    end
    return self.parent:getPath() .. "/" .. self.name
end



---Prepares this Node and all its children to draw their Widgets by writing them to the drawing list if applicable.
---@param layers table A table with layer names as keys and another tables as values. References to UI Nodes will be stored there.
function UI2Node:generateDrawData(layers)
	for childN, child in pairs(self.children) do
		child:generateDrawData(layers)
	end
	if self.widget then
        -- There's no point to draw widgets with alpha = 0.
		if self:isVisible() then
			table.insert(layers[self:getLayer()], self)
		end
		--if self.widget.type == "text" then
		--	self.widget.textTmp = self.widget.text
		--end
	end
end



---Draws ONLY this Node's Widget, if it exists.
function UI2Node:draw()
    if self.widget then
        self.widget:draw()
    end
    self:drawDebug()
end



---Draws this Node's debug marks, such as the Widget's hitbox.
function UI2Node:drawDebug()
    if self.widget then
        local p = self.widget:getPos()
        local s = self.widget:getSize()
        love.graphics.setColor(1, 1, 0, self:getGlobalAlpha())
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", p.x, p.y, s.x, s.y)
    end
end



---Callback from Game.lua.
---@see Game.mousepressed
---@param x number
---@param y number
---@param button number
function UI2Node:mousepressed(x, y, button)
    if self.widget and self.widget.mousepressed then
        self.widget:mousepressed(x, y, button)
    end
    for childN, child in pairs(self.children) do
        child:mousepressed(x, y, button)
    end
end



---Callback from Game.lua.
---@see Game.mousereleased
---@param x number
---@param y number
---@param button number
function UI2Node:mousereleased(x, y, button)
    if self.widget and self.widget.mousereleased then
        self.widget:mousereleased(x, y, button)
    end
    for childN, child in pairs(self.children) do
        child:mousereleased(x, y, button)
    end
end



---Callback from Game.lua.
---@see Game.keypressed
---@param key string
function UI2Node:keypressed(key)
    if self.widget and self.widget.keypressed then
        self.widget:keypressed(key)
    end
    for childN, child in pairs(self.children) do
		child:keypressed(key)
	end
end



---Callback from Game.lua.
---@see Game.textinput
---@param t string
function UI2Node:textinput(t)
    if self.widget and self.widget.textinput then
        self.widget:textinput(t)
    end
    for childN, child in pairs(self.children) do
        child:textinput(t)
    end
end



---Debug function. Prints this Widget's tree.
---@param depth number? Used in recursion.
function UI2Node:printTree(depth)
    depth = depth or 0
    local s = ""
    for i = 1, depth do
        s = s .. "    "
    end
    s = s .. self.name
    print(s)
    for childN, child in pairs(self.children) do
        child:printTree(depth + 1)
    end
end



return UI2Node