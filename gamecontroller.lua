local MineField = require("minefield")
local utils = require("utils")

GameController = {
    currentLevel = 1,
    mineFields = {},
    currentField = nil,
    currentScore = 0,
    screenWidth = 800,
    screenHeight = 600,
    CellSprites = {}
}

GameController.__index = GameController



CellSpritesNames = {
    EMPTY = "empty_cell.png",
    HIDDEN = "hidden_cell.png",
    MINE_DEFUSED = "mine_defused.png",
    MINE_EXPLODED = "mine_exploded.png",
    MINE_FOUND = "mine_found.png",
    FLAGGED = "flagged_cell.png",
    REVEALED = "mine_found.png",
    Number = {
        [1] = "number_1.png",
        [2] = "number_2.png",
        [3] = "number_3.png",
        [4] = "number_4.png",
        [5] = "number_5.png",
        [6] = "number_6.png",
        [7] = "number_7.png",
        [8] = "number_8.png",
    }
}


local function loadCellSprites()
    local assetsPath = "assets/single-files/"
    local cellSprites = {
        Number = {}, -- Initialize Number as a table to hold numbered sprites
    }
    --Build the CellSprites table with the paths to the sprites
    for key, sprite in pairs(CellSpritesNames) do
        
        if type(sprite) == "table" then
            cellSprites[sprite] = {}
            for number, spriteName in pairs(sprite) do
                local spritePath = assetsPath .. spriteName
                -- Check if the sprite file exists
                if not love.filesystem.getInfo(spritePath) then
                    print("Warning: Sprite file not found: " .. spritePath)
                else
                    -- If the sprite file exists, add it to the CellSprites table
                    cellSprites[key][number] = love.graphics.newImage(spritePath)
                end
            end
        else
            local spritePath = assetsPath .. sprite
            cellSprites[key] = love.graphics.newImage(spritePath)
        end
    end
    
    -- Check if all required sprites are loaded
    for key, sprite in pairs(CellSpritesNames) do
        if type(sprite) == "table" then
            for number, spriteName in pairs(sprite) do
                if not cellSprites[key][number] then
                    print("Error: Sprite not loaded: " .. spriteName)
                end
            end
        else
            if not cellSprites[key] then
                print("Error: Sprite not loaded: " .. sprite)
            end
        end
    end

    return cellSprites
end

function GameController:initializeField(width, height, mineCount, cellSize, offsetX, offsetY)
    local field = MineField:new(width, height, mineCount, cellSize, offsetX, offsetY)
    table.insert(self.mineFields, field)
    self.currentField = field
end

-- BombCounter component (now part of GameController)
local BombCounter = {
    width = 100,
    height = 30,
    margin = 10,
    x = 0,
    y = 0,
    count = 0
}
function BombCounter:updatePosition(timerY, timerHeight)
    self.x = love.graphics.getWidth() - self.width - self.margin
    self.y = timerY + timerHeight + self.margin
end
function BombCounter:update(field)
    if field then
        local flags = 0
        for i = 1, field.width do
            for j = 1, field.height do
                if field.board[i][j].state == 2 then -- FLAGGED
                    flags = flags + 1
                end
            end
        end
        self.count = field.mineCount - flags
    else
        self.count = 0
    end
end
function BombCounter:draw()
    love.graphics.setColor(0.3, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Bombs: " .. tostring(self.count), self.x + 10, self.y + 8)
end

-- CellsHiddenCounter component (now part of GameController)
local function checkHiddenAndFlags(field)
    local hidden = 0
    local allHiddenAreMines = true
    local allFlagsCorrect = true
    for i = 1, field.width do
        for j = 1, field.height do
            local cell = field.board[i][j]
            if cell.state == 0 or cell.state == 4 then -- HIDDEN or PRESSED
                hidden = hidden + 1
                if not cell.isMine then
                    allHiddenAreMines = false
                end
            end
            if cell.state == 2 then -- FLAGGED
                if not cell.isMine then
                    allFlagsCorrect = false
                end
            end
        end
    end
    return hidden, allHiddenAreMines, allFlagsCorrect
end

local CellsHiddenCounter = {
    width = 100,
    height = 30,
    margin = 10,
    x = 0,
    y = 0,
    count = 0,
    gameWon = false
}
function CellsHiddenCounter:updatePosition(bombY, bombHeight)
    self.x = love.graphics.getWidth() - self.width - self.margin
    self.y = bombY + bombHeight + self.margin
end
function CellsHiddenCounter:update(field)
    self.gameWon = false
    if field then
        local hidden, allHiddenAreMines, allFlagsCorrect = checkHiddenAndFlags(field)
        self.count = hidden
        if hidden > 0 and allHiddenAreMines and allFlagsCorrect then
            self.gameWon = true
        end
    else
        self.count = 0
        self.gameWon = false
    end
end
function CellsHiddenCounter:draw()
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

-- NewGameButton component (now part of GameController)
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

-- Timer component (now part of GameController)
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

-- Add components to GameController
GameController.NewGameButton = NewGameButton
GameController.TimerComponent = Timer
GameController.BombCounter = BombCounter
GameController.CellsHiddenCounter = CellsHiddenCounter

function GameController:new()
    local instance = setmetatable({}, GameController)
    instance.currentLevel = 0
    instance.currentScore = 0
    instance.mineFields = {}
    instance.currentField = nil
    instance.screenWidth = love.graphics.getWidth()
    instance.screenHeight = love.graphics.getHeight()

    -- Load cell sprites or any other resources needed
    instance.CellSprites = loadCellSprites()
    return instance
end


function GameController:update(dt)
    local hoverX, hoverY, button = self:mouseHover()
    
    if hoverX ~= -1 and hoverY ~= -1 then
        print("Mouse hover at: " .. hoverX .. ", " .. hoverY .. " with button: " .. button)
        if not self.currentHoverX or not self.currentHoverY then
            self.currentHoverX = hoverX
            self.currentHoverY = hoverY
            self.currentField:hoverCells(hoverX, hoverY, button)
        elseif hoverX ~= self.currentHoverX or hoverY ~= self.currentHoverY then
            self.currentField:hoverOutCells(self.currentHoverX, self.currentHoverY, button)
            -- Update hover position only if it has changed
            self.currentHoverX = hoverX
            self.currentHoverY = hoverY
            self.currentField:hoverCells(hoverX, hoverY, button)
        end
    elseif self.currentHoverX or self.currentHoverY then
        -- If we were hovering but now are not, clear the hover state
        self.currentField:hoverOutCells(self.currentHoverX, self.currentHoverY, button)
        self.currentHoverX = nil
        self.currentHoverY = nil
    end

    -- Update components
    self.NewGameButton:updatePosition()
    self.TimerComponent:update(dt)
    self.TimerComponent:updatePosition()
    local timerY = self.TimerComponent.y or 0
    local timerHeight = self.TimerComponent.height or 0
    self.BombCounter:updatePosition(timerY, timerHeight)
    self.BombCounter:update(self.currentField)
    self.CellsHiddenCounter:updatePosition(self.BombCounter.y, self.BombCounter.height)
    self.CellsHiddenCounter:update(self.currentField)

    if self.currentField then
        self.currentField:update(dt)
    end
end

function GameController:mouseHover()
    if not self.currentField then
        return -1, -1, 0 -- No field to hover over
    end
    local mouseX, mouseY = love.mouse.getPosition()
    local gridX, gridY = utils.calculateGridPosition(
        mouseX, mouseY, 
        self.currentField.offsetX, self.currentField.offsetY, 
        self.currentField.cellSize, 
        self.currentField.width, self.currentField.height
    )
    
    if gridX == -1 then
        return -1, -1, 0 -- Out of bounds
    end
    
    local button = 0 -- Default button value for hover
    if love.mouse.isDown(1) and love.mouse.isDown(2) then
        button = 3 -- Handle both buttons pressed
    elseif love.mouse.isDown(1) then
        button = 1 -- Left button pressed
    elseif love.mouse.isDown(2) then
        button = 2 -- Right button pressed
    end
    return gridX, gridY, button -- Return the grid coordinates for hovering
end

function GameController:saveGame()
    local gameData = {
        currentLevel = self.currentLevel,
        currentScore = self.currentScore,
        mineFields = self.mineFields,
    }
    -- Here you would typically serialize gameData to a file or database
    -- For example, using love.filesystem.write or similar

   print("Game saved:", gameData)
end

function GameController:restartGame()
    self.currentLevel = 0
    self.currentScore = 0
    self.mineFields = {}
    self.currentField = nil
end

function GameController:nextLevel()
    self.currentLevel = self.currentLevel + 1
    -- Logic to increase difficulty, e.g., more mines, larger field, etc.
    local newMineCount = math.min(5 + self.currentLevel * 2, 50) -- Example logic
    local newWidth = 10 + self.currentLevel -- Example logic
    local newHeight = 10 + self.currentLevel -- Example logic
    local cellSize = math.floor(math.min(self.screenWidth / newWidth, self.screenHeight / newHeight) * 0.8)
    local offsetX = (self.screenWidth - (cellSize * newWidth)) / 2
    local offsetY = (self.screenHeight - (cellSize * newHeight)) / 2

    self:initializeField(newWidth, newHeight, newMineCount, cellSize, offsetX, offsetY)
end

function GameController:drawComponents()
    self.NewGameButton:draw()
    self.TimerComponent:draw()
    self.BombCounter:draw()
    self.CellsHiddenCounter:draw()
end

return GameController