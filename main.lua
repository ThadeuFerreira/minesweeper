if arg[2] == "debug" then
    require("lldebugger").start()
end

-- import gamestate
local GameController = require("gamecontroller")
local utils = require("utils")
local Displays = require("displays.displays")
local SevenSegments = require("displays.sevensegments")


function love.load()
    GC = GameController:new()
    GC:nextLevel()
    
    -- Create SevenSegment instance first
    SS = SevenSegments()
    SS:load()
    
    local margin = 10
    local width = 100
    local height = 30
    local x = love.graphics.getWidth() - width - margin
    local y = margin
    GC:addComponent(Displays.NewGameButton(x, y))
    y = y + height + margin
    GC:addComponent(Displays.Timer(x, y, SS)) -- Pass SevenSegment instance
    y = y + 60 + margin -- Use Timer's new height (60)
    GC:addComponent(Displays.BombCounter(x, y))
    y = y + height + margin
    GC:addComponent(Displays.CellsHiddenCounter(x, y))
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level: " .. GC.currentLevel, 10, 10)
    love.graphics.print("Score: " .. GC.currentScore, 10, 30)
    love.graphics.print("Total Mines: " .. GC.currentField.mineCount, 10, 50)
    GC:draw()
end

function love.update(dt)
    GC:update(dt)
end

function love.mousepressed(x, y, button)
    GC:mousepressed(x, y, button)
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