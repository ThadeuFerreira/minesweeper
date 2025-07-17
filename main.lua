if arg[2] == "debug" then
    require("lldebugger").start()
end

-- import gamestate
local GameController = require("gamecontroller")
local StartMenu = require("startmenu")
local event = require("event")

-- Scene manager
local scenes = {}
local currentScene = nil

-- Instantiate scenes as objects
local startMenuScene = StartMenu()
local gameScene = GameController()

scenes = {
    startmenu = startMenuScene,
    game = gameScene
}


local function switchScene(name)
    if currentScene and currentScene.unload then currentScene:unload() end
    currentScene = scenes[name]
    if currentScene and currentScene.load then currentScene:load() end
end
_G.switchScene = switchScene

function love.load()
    switchScene("startmenu")
end

function love.draw()
    if currentScene and currentScene.draw then currentScene:draw() end
end

function love.update(dt)
    if currentScene and currentScene.update then currentScene:update(dt) end
end

function love.mousepressed(x, y, button)
    if currentScene and currentScene.mousepressed then 
        local handled = currentScene:mousepressed(x, y, button)
        if handled then
            return         
        end
    end
end

function love.mousereleased(x, y, button)
    if currentScene and currentScene.mousereleased then
        local handled = currentScene:mousereleased(x, y, button)
        if handled then
            return
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