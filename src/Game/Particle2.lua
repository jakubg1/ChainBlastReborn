local class = require "com.class"

---@class Particle2
---@overload fun(game, pos, type, color, pos2):Particle2
local Particle2 = class:derive("Particle2")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



---Constructs a new Particle 2.
---@param game GameMain The game this Particle belongs to.
---@param pos Vector2 The initial position of the Particle.
---@param type string The type of the Particle. TODO: Replace with data.
---@param color Color? The starting color of the Particle. TODO: Replace with data.
---@param pos2 Vector2? The second position of the Particle. If `type` is `"lightning"`, this is the second lightning position (`pos` -> `pos2`). If `type` is `"power_spark"`, this is the position the particle will gravitate towards. TODO: Replace with data.
function Particle2:new(game, pos, type, color, pos2)
    self.game = game
    self.pos = pos
    self.type = type

    self.time = 0

    if self.type == "spark" then
        self.speed = Vec2(love.math.randomNormal(20, 70), 0):rotate(math.random() * math.pi * 2)
        self.acceleration = Vec2(0, 100)
        self.colorGrading = {
            {t = 0, color = Color(1.0, 1.0, 0.4)},
            {t = 0.5, color = Color(1.0, 0.8, 0.2)},
            {t = 1.0, color = Color(1.0, 0.6, 0.2)},
            {t = 2.0, color = Color(0.6, 0.2, 0.2)},
            {t = 3.0, color = Color(0.2, 0.2, 0.2)}
        }
        self.colorTimeOffset = math.random() * 0.3
        self.colorTimeMultiplier = 1 + math.random() * 0.5
        self.alpha = 1
        self.sprite = _Game.resourceManager:getSprite("sprites/spark.json")
    elseif self.type == "spark_trail" then
        self.speed = Vec2()
        self.acceleration = Vec2()
        self.color = color
        self.alpha = 1
        self.alphaFadeDuration = 0.3
        self.sprite = _Game.resourceManager:getSprite("sprites/spark.json")
    elseif self.type == "flare" then
        self.speed = Vec2()
        self.acceleration = Vec2()
        self.alpha = 1
        self.alphaFadeDuration = 0.15
        self.sprite = _Game.resourceManager:getSprite("sprites/flare.json")
    elseif self.type == "chain_explosion" then
        self.speed = Vec2()
        self.acceleration = Vec2()
        self.alpha = 1
        self.sprite = _Game.resourceManager:getSprite("sprites/chain_explosion.json")
        self.spriteAnimationSpeed = 20
        self.lifetime = 0.45
    elseif self.type == "chip" then
        self.speed = Vec2(love.math.randomNormal(40, 100), 0):rotate(love.math.random() * math.pi * 2)
        self.acceleration = Vec2(0, 200)
        self.color = Color(love.math.randomNormal(0.04, 0.6), love.math.randomNormal(0.02, 0.3), love.math.randomNormal(0.02, 0.1))
        self.darkColor = self.color * 0.75
        self.size = math.max(love.math.randomNormal(2, 3), 1)
        self.angle = love.math.random() * math.pi * 2
    elseif self.type == "lightning" then
        self.time = math.min(love.math.randomNormal(0.15, -0.1), 0)
        self.speed = Vec2()
        self.acceleration = Vec2()
        self.alpha = 1
        self.alphaFadeDuration = math.max(love.math.randomNormal(0.1, 0.3), 0.1)
        self.color = Color(love.math.randomNormal(0.5, 0.5), 1, 1)
        self.pos2 = pos2
        self.sectionLength = 20
        self.points = nil
        self.pointRegenTime = 0
        self.pointRegenInterval = 0
    elseif self.type == "power_spark" then
        self.speed = Vec2(love.math.randomNormal(30, 100), 0):rotate(math.random() * math.pi * 2)
        self.acceleration = Vec2()
        self.decceleration = 8
        self.alpha = 1
        self.alphaFadeDuration = 400
        self.sprite = _Game.resourceManager:getSprite("sprites/spark2.json")
        self.colorGrading = {
            {t = 0, color = Color(1.0, 1.0, 1.0)},
            {t = 0.2, color = color},
            {t = 0.4, color = Color(1.0, 1.0, 1.0)},
            {t = 0.6, color = color},
            {t = 0.8, color = Color(1.0, 1.0, 1.0)},
            {t = 1, color = color},
            {t = 1.2, color = Color(1.0, 1.0, 1.0)},
            {t = 1.4, color = color},
            {t = 1.6, color = Color(1.0, 1.0, 1.0)},
            {t = 1.8, color = color},
            {t = 2, color = Color(1.0, 1.0, 1.0)},
            {t = 2.2, color = color},
        }
        self.colorTimeOffset = math.random() * 0.2
        self.colorTimeMultiplier = 1
        self.targetPos = pos2
        self.targetAcceleration = 700
        self.catchRadius = 5
    end

    self.delQueue = false
end



---Updates the Particle 2.
---@param dt number Time delta, in seconds.
function Particle2:update(dt)
    self.time = self.time + dt
    if self.time < 0 then
        -- The projectile didn't spawn yet.
        return
    end

    if self.targetPos and self.targetAcceleration then
        self.acceleration = Vec2(self.targetAcceleration, 0):rotate((self.targetPos - self.pos):angle())
    end

    self.speed = self.speed + self.acceleration * dt
    if self.decceleration then
        local linearSpeed = self.speed:len()
        if linearSpeed > self.decceleration then
            self.speed = self.speed - Vec2(self.decceleration, 0):rotate(self.speed:angle())
        else
            self.speed = Vec2()
        end
    end
    self.pos = self.pos + self.speed * dt

    if self.pos.y > _Game:getNativeResolution().y then
        self.delQueue = true
    end
    if self.lifetime and self.time >= self.lifetime then
        self.delQueue = true
    end
    if self.alphaFadeDuration then
        self.alpha = self.alpha - dt / self.alphaFadeDuration
        if self.alpha <= 0 then
            self.delQueue = true
        end
    end
    if self.catchRadius then
        if (self.targetPos - self.pos):len() <= self.catchRadius then
            self.delQueue = true
        end
    end

    if self.type == "spark" then
        self.game:spawnParticle(self.pos, "spark_trail", self:getColor())
    elseif self.type == "lightning" then
        self.pointRegenTime = self.pointRegenTime + dt
        if self.pointRegenTime >= self.pointRegenInterval then
            self.pointRegenTime = self.pointRegenTime - self.pointRegenInterval
            self.pointRegenInterval = 0.02 + math.random() * 0.05
            -- (Re)generate points for this lightning particle.
            self.points = {}
            -- Make a list of positions, by dividing a line into sections.
            local sections = math.ceil((self.pos - self.pos2):len() / self.sectionLength)
            for i = 0, sections do
                table.insert(self.points, _Utils.lerp(self.pos, self.pos2, i / sections))
            end
            -- Randomly offset each node to give variety.
            for i, point in ipairs(self.points) do
                -- `roam` is 0.2, 0.6, 1, ..., 1, 0.6, 0.2. This helps concentrate the lightning on the endpoints.
                local roamN = 2
                local roamFall = 0.4
                local roam = 1 - (math.max(roamN + 1 - i, 0) + math.max(roamN + i - #self.points, 0)) * roamFall
                self.points[i] = point + Vec2(love.math.randomNormal(self.sectionLength / 8, self.sectionLength / 4) * roam, 0):rotate(math.random() * math.pi * 2)
            end
        end
    end
end



function Particle2:getAnimationFrame()
    if self.spriteAnimationSpeed then
        return math.floor(self.time * self.spriteAnimationSpeed) + 1
    end
    return 1
end



function Particle2:getColor()
    if self.color then
        return self.color
    end
    if self.colorGrading then
        local t = self.colorTimeOffset + self.time * self.colorTimeMultiplier
        for i = 1, #self.colorGrading do
            if t <= self.colorGrading[i].t then
                if i == 1 then
                    return self.colorGrading[i].color
                else
                    local prev = self.colorGrading[i - 1]
                    local this = self.colorGrading[i]
                    local t2 = (t - prev.t) / (this.t - prev.t)
                    return prev.color * (1 - t2) + this.color * t2
                end
            end
        end
        return self.colorGrading[#self.colorGrading].color
    end
    return Color(1, 1, 1)
end



---Draws the Particle 2 on the screen.
function Particle2:draw()
    if self.time < 0 then
        -- The projectile didn't spawn yet.
        return
    end
    if self.sprite then
        self.sprite:draw(self.pos, Vec2(0.5), 1, self:getAnimationFrame(), nil, self:getColor(), self.alpha)
    elseif self.type == "chip" then
        local pd = Vec2(self.size, 0):rotate(self.angle)
        local p1 = self.pos - pd
        local p2 = self.pos + pd
        _DrawLine(p1, p2, self.color, nil, 2)
        local colorVector = Vec2(0, 0.5):rotate(self.angle)
        _DrawLine(p1 + colorVector, p2 + colorVector, self.darkColor, nil)
    elseif self.type == "lightning" then
        -- Draw the lines.
        if self.points then
            for i = 1, 5 do
                local alpha = (i * 0.2) ^ 4
                local width = (7 - i) * (6 - i) / 2
                love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha * alpha)
                love.graphics.setLineWidth(width)
                love.graphics.line(_Utils.vectorsToValueList(self.points))
            end
        end
    end
end



return Particle2