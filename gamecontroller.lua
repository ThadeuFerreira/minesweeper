local MineField = require("minefield")
local utils = require("utils")
local Displays = require("displays.displays")
local Signals = require("signals")

local function GameController(mode, difficulty)
    local self = {
        className = "GameController",
        CellSprites = {},

        currentScore = 0,
        currentLevel = 0,
        mineFields = {},
        currentField = nil,
        screenWidth = love.graphics.getWidth(),
        screenHeight = love.graphics.getHeight(),

        components = {},
        componentsByName = {},

        mineDensity = 5, -- Starting number of mines
    }

    self.mode = mode or "traditional"
    self.difficulty = difficulty or "easy"
    self.endless = (self.mode == "endless")
    self.__index = self

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

    Signals:subscribe("gameover", function(reason)
        print("Game over! Reason:", reason)
        
        -- save the game score
        self:saveGame()
    end, self)

    Signals:subscribe("mouseClick", function(mx, my, button)
        print("Mouse clicked at: " .. mx .. ", " .. my .. " with button: " .. button)
    end, self)


    function self:initializeField(width, height, mineCount, cellSize, offsetX, offsetY)
        local field = MineField:new(width, height, mineCount, cellSize, offsetX, offsetY)
        table.insert(self.mineFields, field)
        self.currentField = field
    end

    function self:update(dt)
        -- Allow returning to menu with ESC
        if love.keyboard.isDown("escape") then
            if self.returnToMenu then self:returnToMenu() end
            return
        end
        local hoverX, hoverY, button = self:mouseHover()
        local cellHidenCounter = self:getComponent("CellsHiddenCounter")
        if not cellHidenCounter then
            print("Error: CellsHiddenCounter component not found!")
            return
        end
        local gameWon = cellHidenCounter.gameWon
        if gameWon then
            if not self.endless then
                -- Traditional mode completes here; return to menu or await new game
                return
            end
            if self:getComponent("NextLevelButton") then
                print("Next level button already exists, skipping creation.")
                return
            end
            print("Game won! Level: " .. self.currentLevel .. ", Score: " .. self.currentScore)
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
            -- print("Mouse hover at: " .. hoverX .. ", " .. hoverY .. " with button: " .. button)
            if not self.currentHoverX or not self.currentHoverY then
                self.currentHoverX = hoverX
                self.currentHoverY = hoverY
                self.currentField:hoverCells(hoverX, hoverY, button)
            elseif hoverX ~= self.currentHoverX or hoverY ~= self.currentHoverY then
                self.currentField:hoverOutCells(self.currentHoverX, self.currentHoverY, button)
                self.currentHoverX = hoverX
                self.currentHoverY = hoverY
                self.currentField:hoverCells(hoverX, hoverY, button)
            end
        elseif self.currentHoverX or self.currentHoverY then
            self.currentField:hoverOutCells(self.currentHoverX, self.currentHoverY, button)
            self.currentHoverX = nil
            self.currentHoverY = nil
        end
        for _, comp in ipairs(self.components) do
            if comp.update then
                comp:update(dt, self)
            end
        end
        if self.currentField then
            self.currentField:update(dt)
        end
    end

    function self:mouseHover()
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

    function self:saveGame()
        local gameData = {
            currentLevel = self.currentLevel,
            currentScore = self.currentScore,
            mineFields = self.mineFields,
        }
        -- Here you would typically serialize gameData to a file or database
        -- For example, using love.filesystem.write or similar

        print("Game saved:", gameData)
    end

    function self:restartGame()
        self.currentLevel = 0
        self.currentScore = 0
        self.mineFields = {}
        self.currentField = nil
    end

    function self:nextLevel()
        self.currentLevel = self.currentLevel + 1

        local newWidth = 10 + self.currentLevel
        local newHeight = 10 + self.currentLevel

        -- mine density follows a discrete sigmoid-like curve
        -- from level 1 to 10, linear, from 10 to 20, exponential, from 20+ linear again
        local numCells = newWidth * newHeight
        local nextLevelDensity = self.mineDensity
        if self.currentLevel <= 10 then
            nextLevelDensity = self.mineDensity + self.currentLevel *1.5 -- Linear increase
        elseif self.currentLevel <= 20 then
            nextLevelDensity = self.mineDensity + (self.currentLevel - 10) * (self.currentLevel - 10) * 0.5
        else
            nextLevelDensity = self.mineDensity + (self.currentLevel - 20) * 1.5
        end
        local newMineCount = math.floor(numCells * nextLevelDensity / 100) -- Convert density to mine count
        print("Next level: " .. self.currentLevel .. ", Width: " .. newWidth .. ", Height: " .. newHeight .. ", Mines: " .. newMineCount)

        
        -- Calculate available width excluding UI sidebar
        local sidebarMargin, sidebarWidth = 10, 100
        local availableW = self.screenWidth - (sidebarWidth + sidebarMargin)
        -- Compute cell size based on available area
        local cellSize = math.floor(math.min(availableW / newWidth, self.screenHeight / newHeight) * 0.8)
        local fieldW, fieldH = cellSize * newWidth, cellSize * newHeight
        -- Center field within available area
        local offsetX = (availableW - fieldW) / 2
        local offsetY = (self.screenHeight - fieldH) / 2

        self:initializeField(newWidth, newHeight, newMineCount, cellSize, offsetX, offsetY)
    end

    function self:draw()
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Level: " .. tostring(self.currentLevel), 10, 10)
        love.graphics.print("Score: " .. tostring(self.currentScore), 10, 30)
        if self.currentField then
            love.graphics.print("Total Mines: " .. tostring(self.currentField.mineCount), 10, 50)
        end
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

    Signals:subscribe("nextLevel", function()
        print("Next level button clicked, proceeding to next level.")
        self:nextLevel()
        local timerComponent = self:getComponent("Timer")
        if timerComponent and timerComponent.reset then
            timerComponent:reset()
        end
        local cellHidenCounter = self:getComponent("CellsHiddenCounter")
        if cellHidenCounter then
            cellHidenCounter.count = 0
            cellHidenCounter.gameWon = false
        end
    end, self)

    Signals:subscribe("newGame", function()
        print("Restarting game.")

        local timerComponent = self:getComponent("Timer")
        if timerComponent and timerComponent.reset then
            timerComponent:reset()
        end
        local cellHidenCounter = self:getComponent("CellsHiddenCounter")
        if cellHidenCounter then
            cellHidenCounter.count = 0
            cellHidenCounter.gameWon = false
        end
        self:unload() -- Clear current state
        self:load()
    end, self)

    Signals:subscribe("returnToMainMenu", function()
        print("Return to main menu signal received.")
        self:returnToMenu()
    end, self)

    function self:mousepressed(x, y, button)
        -- Let components handle mouse press if they want
        Signals:publish("mouseClick", x, y, button)
    end

    function self:mousereleased(x, y, button)
        if self.currentField then
            local gridX, gridY = utils.calculateGridPosition(
                x, y, 
                self.currentField.offsetX, self.currentField.offsetY, 
                self.currentField.cellSize, 
                self.currentField.width, self.currentField.height
            )
            if gridX ~= -1 and self.currentField.handleRelease then
                self.currentField:handleRelease(gridX, gridY, button)
            end
        end
    end

    -- Add ECS-style component management
    function self:addComponent(component)
        -- Pass a reference to the parent components
        component.parent = self

        -- Add to array for iteration
        table.insert(self.components, component)
        
        -- Add to lookup table for direct access if it has a name/class
        if component.className then
            self.componentsByName[component.className] = component
        end
        
        return component
    end

    function self:removeComponent(component)
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

        -- Call destroy method if it exists
        if component.destroy then
            component:destroy()
        end
    end

    function self:getComponent(name)
        return self.componentsByName[name]
    end

    function self:load()
        -- Called when the game scene is entered; initialize field based on mode
        if self.mode == "traditional" then
            -- Preset configurations
            local presets = {
                easy = {width = 9, height = 9, mines = 10},
                medium = {width = 16, height = 16, mines = 40},
                hard = {width = 30, height = 16, mines = 99},
                insane = {width = 30, height = 24, mines = 200},
            }
            local p = presets[self.difficulty] or presets.easy
            self.currentLevel = 1
            -- Calculate available width excluding UI sidebar
            local sidebarMargin, sidebarWidth = 10, 100
            local availableW = self.screenWidth - (sidebarWidth + sidebarMargin)
            -- Compute cell size based on available area
            local cellSize = math.floor(math.min(availableW / p.width, self.screenHeight / p.height) * 0.8)
            local fieldW, fieldH = cellSize * p.width, cellSize * p.height
            local offsetX = (availableW - fieldW) / 2
            local offsetY = (self.screenHeight - fieldH) / 2
            self:initializeField(p.width, p.height, p.mines, cellSize, offsetX, offsetY)
        elseif self.mode == "endless" then
            -- Endless starts at level 1 via nextLevel logic
            self.currentLevel = 0
            self:nextLevel()
        else
            -- Default behavior
            self:nextLevel()
        end
        -- Create SevenSegment instance first
        if not self.SS then
            local SevenSegments = require("displays.sevensegments")
            self.SS = SevenSegments()
            self.SS:load()
        end
        local Displays = require("displays.displays")
        local margin = 10
        local width = 100
        local height = 30
        local x = love.graphics.getWidth() - width - margin
        local y = margin
        self:addComponent(Displays.NewGameButton(x, y))
        y = y + height + margin
        self:addComponent(Displays.ReturnToMainMenuButton(x, y))
        y = y + height + margin
        self:addComponent(Displays.Timer(x, y, self.SS))
        y = y + 60 + margin
        self:addComponent(Displays.BombCounter(x, y))
        y = y + height + margin
        self:addComponent(Displays.CellsHiddenCounter(x, y))
    end

    function self:unload()
        for _, comp in ipairs(self.components) do
            if comp.unload then
                comp:unload()
            end
        end
        -- Called when the game scene is exited
        self.components = {}
        self.componentsByName = {}
        self.mineFields = {}
        self.currentField = nil
        self.currentLevel = 0
    end

    function self:returnToMenu()
        self:unload()
        if _G.switchScene then
            _G.switchScene("startmenu")
        end
    end

    return self

end

return GameController