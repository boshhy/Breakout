--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Boshhy
    boshhy101@yahoo.com

    Represents the powerup available.

]]

Powerup = Class{}

function Powerup:init(brick_x, brick_y, skin)
    self.x = brick_x + 8
    self.y = brick_y

    self.dy = math.random(50,90)

    self.width = 16
    self.height = 16

    self.skin = math.random(1,10)
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

function Powerup:collides(target)
    if self.x > target.x + target.width or self.x + self.width < target.x then
        return false
    end

    if self.y > target.y + target.height or self.y + self.height < target.y then
        return false
    end

    return true
end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerup'][self.skin], self.x, self.y)
end