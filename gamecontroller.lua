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

function GameController:new()
    local instance = setmetatable({}, GameController)
    instance.currentLevel = 1
    instance.currentScore = 0
    instance.mineFields = {}
    instance.currentField = nil
    instance.screenWidth = love.graphics.getWidth()
    instance.screenHeight = love.graphics.getHeight()

    -- Load cell sprites or any other resources needed
    instance.CellSprites = loadCellSprites()
    return instance
end

function GameController:initializeField(width, height, mineCount, cellSize, offsetX, offsetY)
    local field = MineField:new(width, height, mineCount, cellSize, offsetX, offsetY)
    table.insert(self.mineFields, field)
    self.currentField = field
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
    self.currentLevel = 1
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

return GameController