GameState = {
    level = 1,
    score = 0,
    screenWidth = 800,
    screenHeight = 600,
}

GameState.__index = GameState

function GameState.new()
    local instance = setmetatable({}, GameState)
    instance.level = 1
    instance.score = 0
    return instance
end

function GameState:reset()
    self.level = 1
    self.score = 0
end

return GameState