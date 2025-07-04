local MineField = require("minefield")
local utils = require("utils")
local Displays = require("displays")

GameController = {
    currentLevel = 1,
    mineFields = {},
    currentField = nil,
    currentScore = 0,
    screenWidth = 800,
    screenHeight = 600,
    CellSprites = {},
    components = {}
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


function GameController:initializeField(width, height, mineCount, cellSize, offsetX, offsetY)
    local field = MineField:new(width, height, mineCount, cellSize, offsetX, offsetY)
    table.insert(self.mineFields, field)
    self.currentField = field
end


function GameController:new()
    local instance = setmetatable({}, GameController)
    instance.currentLevel = 0
    instance.currentScore = 0
    instance.mineFields = {}
    instance.currentField = nil
    instance.screenWidth = love.graphics.getWidth()
    instance.screenHeight = love.graphics.getHeight()
    
    -- Use both array and map for components
    instance.components = {}
    instance.componentsByName = {}
    
    return instance
end

function GameController:update(dt)
    local hoverX, hoverY, button = self:mouseHover()

    local cellHidenCounter = self:getComponent("CellsHiddenCounter")
    if not cellHidenCounter then
        print("Error: CellsHiddenCounter component not found!")
        return
    end
    local gameWon = cellHidenCounter.gameWon
    if gameWon then
        if self:getComponent("NextLevelButton") then
            print("Next level button already exists, skipping creation.")
            return
        end
        print("Game won! Level: " .. self.currentLevel .. ", Score: " .. self.currentScore)
        -- Here you can add logic to handle game win, like showing a message
        local nextLevelButton = Displays.NextLevelButton(
            self.screenWidth - 120, 
            self.screenHeight - 50
        )
        if nextLevelButton then
            print("Next level button found, clicking it to proceed.")
        end
        self:addComponent(nextLevelButton)
        return
    end
    
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

    -- Update all components
    for _, comp in ipairs(self.components) do
        if comp.update then
            comp:update(dt, self)
        end
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
    if love.mouse.isDown(1) then
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

function GameController:draw()
    -- Draw all components
    for _, comp in ipairs(self.components) do
        if comp.draw then
            comp:draw()
        end
    end
    if self.currentField then
        self.currentField:draw()
    end
end

function GameController:mousepressed(x, y, button)
    -- Let components handle mouse press if they want

    local newGameButton = self:getComponent("NewGameButton")
    if newGameButton and newGameButton.isClicked and newGameButton:isClicked(x, y) then
        self:restartGame()
        self:nextLevel()
        
        -- Use the lookup method instead of linear search
        local timerComponent = self:getComponent("Timer")
        if timerComponent and timerComponent.reset then
            timerComponent:reset()
        end

        -- Resets game won state
        local cellHidenCounter = self:getComponent("CellsHiddenCounter")
        if cellHidenCounter then
            cellHidenCounter.count = 0
            cellHidenCounter.gameWon = false
        end
        
        -- Remove the NextLevelButton if it exists
        local nextLevelButton = self:getComponent("NextLevelButton")
        if nextLevelButton then
            self:removeComponent(nextLevelButton)
        end
        print("New game button clicked, restarting game.")
        return
    end

    local nextLevelButton = self:getComponent("NextLevelButton")
    if nextLevelButton and nextLevelButton.isClicked and nextLevelButton:isClicked(x, y) then
        print("Next level button clicked, proceeding to next level.")
        self:nextLevel()
        -- Reset timer if it exists
        local timerComponent = self:getComponent("Timer")
        if timerComponent and timerComponent.reset then
            timerComponent:reset()
        end

        -- Resets game won state
        local cellHidenCounter = self:getComponent("CellsHiddenCounter")
        if cellHidenCounter then
            cellHidenCounter.count = 0
            cellHidenCounter.gameWon = false
        end

        -- Remove the NextLevelButton after clicking
        self:removeComponent(nextLevelButton)
        return
    end

end

-- Add ECS-style component management
function GameController:addComponent(component)
    -- Add to array for iteration
    table.insert(self.components, component)
    
    -- Add to lookup table for direct access if it has a name/class
    if component.className then
        self.componentsByName[component.className] = component
    end
    
    return component
end

function GameController:removeComponent(component)
    -- Remove from array
    for i, c in ipairs(self.components) do
        if c == component then
            table.remove(self.components, i)
            break
        end
    end
    
    -- Remove from lookup table
    if component.className and self.componentsByName[component.className] == component then
        self.componentsByName[component.className] = nil
    end
end

function GameController:getComponent(name)
    return self.componentsByName[name]
end

return GameController