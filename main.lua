if arg[2] == "debug" then
    require("lldebugger").start()
end

-- import gamestate
local GameController = require("gamecontroller")
local utils = require("utils")


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

-- Timer component
local Timer = {
    elapsed = 0,
    running = true,
    width = 100,
    height = 30,
    margin = 10,
    x = 0,
    y = 0
}

function Timer:reset()
    self.elapsed = 0
    self.running = true
end

function Timer:update(dt)
    if self.running then
        self.elapsed = self.elapsed + dt
    end
end

function Timer:updatePosition()
    self.x = love.graphics.getWidth() - self.width - self.margin
    self.y = NewGameButton.y + NewGameButton.height + self.margin
end

function Timer:draw()
    self:updatePosition()
    love.graphics.setColor(0.1, 0.1, 0.3)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
    local tenths = math.floor(self.elapsed * 10)
    love.graphics.print(string.format("Time: %.1f", tenths / 10), self.x + 10, self.y + 8)
end

-- Bomb Counter component
local BombCounter = {
    width = 100,
    height = 30,
    margin = 10,
    x = 0,
    y = 0,
    count = 0
}

function BombCounter:updatePosition()
    self.x = love.graphics.getWidth() - self.width - self.margin
    self.y = Timer.y + Timer.height + self.margin
end

function BombCounter:update()
    if GC.currentField then
        local flags = 0
        for i = 1, GC.currentField.width do
            for j = 1, GC.currentField.height do
                if GC.currentField.board[i][j].state == 2 then -- FLAGGED
                    flags = flags + 1
                end
            end
        end
        self.count = GC.currentField.mineCount - flags
    else
        self.count = 0
    end
end

function BombCounter:draw()
    self:updatePosition()
    love.graphics.setColor(0.3, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Bombs: " .. tostring(self.count), self.x + 10, self.y + 8)
end

-- Cells Hidden Counter component
local CellsHiddenCounter = {
    width = 100,
    height = 30,
    margin = 10,
    x = 0,
    y = 0,
    count = 0,
    gameWon = false
}

function CellsHiddenCounter:updatePosition()
    self.x = love.graphics.getWidth() - self.width - self.margin
    self.y = BombCounter.y + BombCounter.height + self.margin
end

-- Utility function to check hidden, flagged, and win state
local function checkHiddenAndFlags(field)
    local hidden = 0
    local allHiddenAreMines = true
    local allFlagsCorrect = true
    for i = 1, field.width do
        for j = 1, field.height do
            local cell = field.board[i][j]
            -- Count hidden or pressed cells
            if cell.state == 0 or cell.state == 4 then -- HIDDEN or PRESSED
                hidden = hidden + 1
                if not cell.isMine then
                    allHiddenAreMines = false
                end
            end
            -- Check if all flags are on mines
            if cell.state == 2 then -- FLAGGED
                if not cell.isMine then
                    allFlagsCorrect = false
                end
            end
        end
    end
    return hidden, allHiddenAreMines, allFlagsCorrect
end

function CellsHiddenCounter:update()
    self.gameWon = false
    if GC.currentField then
        local hidden, allHiddenAreMines, allFlagsCorrect = checkHiddenAndFlags(GC.currentField)
        self.count = hidden
        -- Win if all hidden cells are mines and all flags are correct
        if hidden > 0 and allHiddenAreMines and allFlagsCorrect then
            self.gameWon = true
        end
    else
        self.count = 0
        self.gameWon = false
    end
end

function CellsHiddenCounter:draw()
    self:updatePosition()
    love.graphics.setColor(0.2, 0.3, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Cells: " .. tostring(self.count), self.x + 10, self.y + 8)
    if self.gameWon then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("Game Win!", self.x + 10, self.y + self.height + 5)
        love.graphics.setColor(1, 1, 1)
    end
end

function love.load()
    GC = GameController:new()
    GC:nextLevel() -- Start at level 1
    Timer:reset()
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
    Timer:draw()
    BombCounter:draw()
    CellsHiddenCounter:draw()
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
        Timer:update(FRAME_DURATION)
        BombCounter:update()
        CellsHiddenCounter:update()
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
        Timer:reset()
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
