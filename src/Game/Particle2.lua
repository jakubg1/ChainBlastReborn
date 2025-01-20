local class = require "com.class"

---@class Particle2
---@overload fun(game, pos, type, color):Particle2
local Particle2 = class:derive("Particle2")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



---Constructs a new Particle 2.
---@param game GameMain The game this Particle belongs to.
---@param pos Vector2 The initial position of the Particle.
---@param type string The type of the Particle. TODO: Replace with data.
---@param color Color? The starting color of the Particle. TODO: Replace with data.
function Particle2:new(game, pos, type, color)
    self.game = game
    self.pos = pos
    self.type = type

    self.time = 0
    self.colorTimeOffset = math.random() * 0.3
    self.colorTimeMultiplier = 1 + math.random() * 0.5

    if self.type == "spark" then
        --self.speed = Vec2()
        --self.acceleration = Vec2()
        self.speed = Vec2(love.math.randomNormal(20, 70), 0):rotate(math.random() * math.pi * 2)
        self.acceleration = Vec2(0, 100)
        self.colorGrading = {
            {t = 0, color = Color(1.0, 1.0, 0.4)},
            {t = 0.5, color = Color(1.0, 0.8, 0.2)},
            {t = 1.0, color = Color(1.0, 0.6, 0.2)},
            {t = 2.0, color = Color(0.6, 0.2, 0.2)},
            {t = 3.0, color = Color(0.2, 0.2, 0.2)}
        }
        self.alpha = 1
        self.sprite = _Game.resourceManager:getSprite("sprites/spark.json")
    elseif self.type == "spark_trail" then
        self.speed = Vec2()
        self.acceleration = Vec2()
        self.color = color
        self.alpha = 1
        self.sprite = _Game.resourceManager:getSprite("sprites/spark.json")
    elseif self.type == "flare" then
        self.speed = Vec2()
        self.acceleration = Vec2()
        self.alpha = 1
        self.sprite = _Game.resourceManager:getSprite("sprites/flare.json")
    elseif self.type == "chain_explosion" then
        self.speed = Vec2()
        self.acceleration = Vec2()
        self.alpha = 1
        self.sprite = _Game.resourceManager:getSprite("sprites/chain_explosion.json")
        self.spriteAnimationSpeed = 20
    elseif self.type == "chip" then
        self.speed = Vec2(love.math.randomNormal(40, 100), 0):rotate(love.math.random() * math.pi * 2)
        self.acceleration = Vec2(0, 200)
        self.color = Color(love.math.randomNormal(0.1, 0.6), love.math.randomNormal(0.05, 0.3), love.math.randomNormal(0.05, 0.1))
        self.darkColor = self.color * 0.75
        self.size = math.max(love.math.randomNormal(2, 3), 1)
        self.angle = love.math.random() * math.pi * 2
    end


    self.delQueue = false
end



---Updates the Particle 2.
---@param dt number Time delta, in seconds.
function Particle2:update(dt)
    self.time = self.time + dt

    self.speed = self.speed + self.acceleration * dt
    self.pos = self.pos + self.speed * dt

    if self.pos.y > _Game:getNativeResolution().y then
        self.delQueue = true
    end

    if self.type == "spark" then
        self.game:spawnParticle(self.pos, "spark_trail", self:getColor())
    elseif self.type == "spark_trail" then
        self.alpha = self.alpha - dt / 0.3
        if self.alpha <= 0 then
            self.delQueue = true
        end
    elseif self.type == "flare" then
        self.alpha = self.alpha - dt / 0.15
        if self.alpha <= 0 then
            self.delQueue = true
        end
    elseif self.type == "chain_explosion" then
        if self.time >= 0.45 then
            self.delQueue = true
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
    if self.sprite then
        self.sprite:draw(self.pos, Vec2(0.5), 1, self:getAnimationFrame(), nil, self:getColor(), self.alpha)
    else
        local pd = Vec2(self.size, 0):rotate(self.angle)
        local p1 = self.pos - pd
        local p2 = self.pos + pd
        _DrawLine(p1, p2, self.color, nil, 2)
        local colorVector = Vec2(0, 0.5):rotate(self.angle)
        _DrawLine(p1 + colorVector, p2 + colorVector, self.darkColor, nil)
    end
end



return Particle2