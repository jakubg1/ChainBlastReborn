local Scene = require("src.Game.Scenes.Scene")
local Vec2 = require("src.Essentials.Vector2")
local Particle2 = require("src.Game.Particle2")

---@class Benchmark : Scene
---@overload fun(game):Benchmark
local Benchmark = Scene:derive("Benchmark")

function Benchmark:new(game)
    self.name = "benchmark"
    self.game = game

    self.particles = {}
    for i = 1, 10000 do
        self.particles[i] = Particle2(game, Vec2(10), "spark")
    end
end

function Benchmark:update(dt)
    for i, particle in ipairs(self.particles) do
        particle:update(dt)
    end
end

function Benchmark:draw()
    local t = love.timer.getTime()
    for i, particle in ipairs(self.particles) do
        particle:draw()
    end
    t = love.timer.getTime() - t

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Frame drawn in %.1fms", t * 1000))
end

return Benchmark