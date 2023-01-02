--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = {}
    table.insert(self.balls, params.ball)
    self.countBalls = 1
    self.level = params.level
    self.powerups = {}
    self.gotkey = params.gotkey

    -- Used to keep track of paddle grow points
    self.recoverPoints = params.recoverPoints
    self.growPoints = 2000
    self.growScore = params.growScore

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end

    -- update power positions based on velocity
    for k, power in pairs(self.powerups) do
        power:update(dt)
    end

    for k, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with all balls
    for k, ball in pairs(self.balls) do
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then
                if not brick.isLocked then
                    self.growScore = self.growScore + (brick.tier * 200 + brick.color * 25)
                    -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)

                    -- trigger the brick's hit function, which removes it from play
                    --if brick.tier == 0 and brick.color == 1 then
                    x = math.random(4)
                    if x == 1 then
                        brick:hit()
                        table.insert(self.powerups, Powerup(brick.x, brick.y, 1))
                    elseif x == 2 then
                        brick:hit()
                        table.insert(self.powerups, Powerup(brick.x, brick.y, 2))
                    else
                        brick:hit()
                    end
                elseif self.gotkey and brick.green then
                    -- Give player extra points for unlocking a brick
                    self.score = self.score + 200
                    self.growScore = self.growScore + 200

                    -- Unlock the brick only if key is already picked up
                    brick:unlockSingle()
                    brick.green = false
                    brick.isLocked = false

                    gSounds['brick-hit-unlocked']:stop()
                    gSounds['brick-hit-unlocked']:play()
                else
                    brick:hit()
                end

                self:updateGrowScore()

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = ball,
                        recoverPoints = self.recoverPoints,
                        growScore = self.growScore
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    for k, power in pairs(self.powerups) do
        if power:collides(self.paddle) then
            -- Add two balls to the game
            if power.skin == 1 then
                for i = 1, 2 do
                    b = Ball(math.random(1, 7))
                    b.x = power.x + power.width/2 - 4
                    b.y = self.paddle.y - 8
                    b.dx = math.random(-200, 200)
                    b.dy = math.random(-50, -60)
                    table.insert(self.balls, b)
                end
                gSounds['powerup-multi']:stop()
                gSounds['powerup-multi']:play()
                self.countBalls = self.countBalls + 2
                table.remove(self.powerups, k)
            else
                if self.gotkey == false then
                    for k, brick in pairs(self.bricks) do
                        -- Changed no-green locked to green locked bricks
                        if not brick.green and brick.isLocked then
                            brick:unlocked()
                        end
                        brick.green = true
                    end
                end
                self.gotkey = true
                gSounds['powerup-unlocked']:stop()
                gSounds['powerup-unlocked']:play()
                table.remove(self.powerups, k)
                self.score = self.score + 50
                self.growScore = self.growScore + 50
            end
        end
    end
    -- if ball goes below bounds, revert to serve state and decrease health
    for k, ball in pairs(self.balls) do
        -- If last ball goes below bounds, then shrink paddle
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, k)
            self.countBalls = self.countBalls - 1
            if self.countBalls == 0 then
                self.health = self.health - 1
                if self.paddle.size > 1 then
                    self.paddle:shrink()
                end
                gSounds['hurt']:play()

                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints,
                        growScore = self.growScore,
                        gotkey = self.gotkey
                    })
                end
            end
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    for k, power in pairs(self.powerups) do
        power:render(dt)
    end

    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)
    self:renderGrowScore()

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

-- Used to render how many points needed for next paddle growth
function PlayState:renderGrowScore()
    left = self.growPoints - self.growScore
    love.graphics.setFont(gFonts['small'])
    love.graphics.print('Points left to grow:', 212, 5)
    love.graphics.printf(tostring(left), 280, 5, 40, 'right')
end

-- Used to update the score for paddle growth
function PlayState:updateGrowScore()
    left = self.growPoints - self.growScore
    if left <= 0 and self.paddle.size < 4 then
        self.growPoints = math.floor(self.growPoints * 1.25) - math.floor(self.growPoints * 1.25) % 5
        self.growScore = 0
        self.paddle:grow()
        gSounds['paddle-grow']:stop()
        gSounds['paddle-grow']:play()
    elseif left <= 0 then
        self.growPoints = math.floor(self.growPoints * 1.25) - math.floor(self.growPoints * 1.25) % 5
        self.growScore = 0
    end
end
