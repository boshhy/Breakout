--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Boshhy
    boshhy101@yahoo.com

    Represents the powerups available.

]]

Powerup = Class{}

function Powerup:init(brick_x, brick_y, skin)
    -- Positional and dimensional variables
    self.x = brick_x + 8
    self.y = brick_y

    -- Get random gravity
    self.dy = math.random(32,64)

    self.width = 16
    self.height = 16

    -- Used to change from multi and key powerups
    self.skin = skin
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

-- Check to see if powerup collides with target
function Powerup:collides(target)
    if self.x > target.x + target.width or self.x + self.width < target.x then
        return false
    end

    if self.y > target.y + target.height or self.y + self.height < target.y then
        return false
    end

    return true
end

-- Render the powerup on the screen
function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerup'][self.skin], self.x, self.y)
end
