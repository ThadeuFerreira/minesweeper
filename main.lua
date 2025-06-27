if arg[2] == "debug" then
    require("lldebugger").start()
end

-- import gamestate
local GameController = require("gamecontroller")
local utils = require("utils")


function love.load()
    GC = GameController:new()
    GC:nextLevel() -- Start at level 1
end

-- New Game button component
local NewGameButton = {
    width = 100,
    height = 30,
    margin = 10,
    x = 0,
    y = 0
}

function NewGameButton:updatePosition()
    self.x = love.graphics.getWidth() - self.width - self.margin
    self.y = self.margin
end

function NewGameButton:draw()
    self:updatePosition()
    love.graphics.setColor(0.2, 0.6, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("New Game", self.x + 10, self.y + 8)
end

function NewGameButton:isClicked(mx, my)
    return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
end

function love.draw()
    if GC.currentField then
        GC.currentField:draw(GC.CellSprites)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level: " .. GC.currentLevel, 10, 10)
    love.graphics.print("Score: " .. GC.currentScore, 10, 30)
    love.graphics.print("Total Mines: " .. GC.currentField.mineCount, 10, 50)
    NewGameButton:draw()
end

-- Constants for frame rate control
local TARGET_FPS = 60
local FRAME_DURATION = 1/TARGET_FPS
local frameTimer = 0

function love.update(dt)
    -- Accumulate time since last frame
    frameTimer = frameTimer + dt
    
    -- Only update when enough time has passed for a 60 FPS update
    if frameTimer >= FRAME_DURATION then
        GC:update(FRAME_DURATION) -- Pass fixed time step
        frameTimer = frameTimer - FRAME_DURATION -- Subtract the time used for this frame
        
        -- If we're severely behind, reset the timer to avoid spiral of death
        if frameTimer > FRAME_DURATION * 3 then
            frameTimer = 0
        end
    end
end


function love.mousepressed(x, y, button)
    -- Use the NewGameButton component for click detection
    NewGameButton:updatePosition()
    if NewGameButton:isClicked(x, y) then
        GC:restartGame()
        GC:nextLevel()
        return
    end

    -- ...existing mouse click logic...
    print("Mouse pressed at: " .. x .. ", " .. y .. " with button: " .. button)
    if GC.currentField then
        local gridX, gridY = require("utils").calculateGridPosition(
            x, y, 
            GC.currentField.offsetX, GC.currentField.offsetY, 
            GC.currentField.cellSize, 
            GC.currentField.width, GC.currentField.height
        )
        if gridX ~= -1 and GC.currentField.handleClick then
            if love.mouse.isDown(1) and love.mouse.isDown(2) then
                button = "both" -- Handle both buttons pressed
            end
            GC.currentField:handleClick(gridX, gridY, button)
        end
    end
end

function love.mousereleased(x, y, button)
    if GC.currentField then
        local gridX, gridY = utils.calculateGridPosition(
            x, y, 
            GC.currentField.offsetX, GC.currentField.offsetY, 
            GC.currentField.cellSize, 
            GC.currentField.width, GC.currentField.height
        )
        if gridX ~= -1 and GC.currentField.handleRelease then -- Ensure method exists
            if love.mouse.isDown(1) and love.mouse.isDown(2) then
                button = "both" -- Handle both buttons released
            end
            GC.currentField:handleRelease(gridX, gridY, button)
        end
    end
end

local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
---@diagnostic disable-next-line: undefined-global
    if lldebugger then
        error(msg, 2)
    else
        return love_errorhandler(msg)
    end
end
