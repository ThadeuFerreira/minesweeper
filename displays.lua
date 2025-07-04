-- CellsHiddenCounter component (now part of GameController)
local function checkHiddenAndFlags(field)
    local hidden = 0
    local allHiddenAreMines = true
    local allFlagsCorrect = true
    for i = 1, field.width do
        for j = 1, field.height do
            local cell = field.board[i][j]
            if cell.current_state == 0 or cell.current_state == 4 then -- HIDDEN or PRESSED
                hidden = hidden + 1
                if not cell.isMine then
                    allHiddenAreMines = false
                end
            end
            if cell.current_state == 2 then -- FLAGGED
                if not cell.isMine then
                    allFlagsCorrect = false
                end
            end
        end
    end
    return hidden, allHiddenAreMines, allFlagsCorrect
end

local function CellsHiddenCounter(x, y)
    local self = {
        width = 100,
        height = 30,
        margin = 10,
        x = x,
        y = y,
        count = 0,
        gameWon = false,
        className = "CellsHiddenCounter"
    }
    function self:update(dt, gc)
        -- No position update, just logic
        local bomb = nil
        for _, comp in ipairs(gc.components) do
            if comp.className == "BombCounter" then
                bomb = comp
                break
            end
        end
        if not bomb then
            print("Error: BombCounter component not found!")
            return
        end
        -- Update count and win state
        self.gameWon = false
        local field = gc.currentField
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

    function self:draw()
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
    function self:isClicked(mx, my)
        return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
    end
    return self
end

local function NewGameButton(x, y)
    local self = {
        width = 100,
        height = 30,
        margin = 10,
        x = x,
        y = y,
        className = "NewGameButton"
    }
    function self:draw()
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("New Game", self.x + 10, self.y + 8)
    end
    function self:isClicked(mx, my)
        return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
    end
    return self
end

local function Timer(x, y)
    local self = {
        elapsed = 0,
        running = true,
        width = 100,
        height = 30,
        margin = 10,
        x = x,
        y = y,
        className = "Timer"
    }
    function self:reset()
        self.elapsed = 0
        self.running = true
    end
    function self:update(dt, gc)
        if self.running then
            self.elapsed = self.elapsed + dt
        end
    end
    function self:draw()
        love.graphics.setColor(0.1, 0.1, 0.3)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 1, 1)
        local tenths = math.floor(self.elapsed * 10)
        love.graphics.print(string.format("Time: %.1f", tenths / 10), self.x + 10, self.y + 8)
    end
    return self
end

local function BombCounter(x, y)
    local self = {
        width = 100,
        height = 30,
        margin = 10,
        x = x,
        y = y,
        count = 0,
        className = "BombCounter"
    }
    function self:update(dt, gc)
        local field = gc.currentField
        if field then
            local flags = 0
            for i = 1, field.width do
                for j = 1, field.height do
                    local cell = field.board[i][j]
                    if cell.current_state == 2 then -- FLAGGED
                        flags = flags + 1
                    end
                end
            end
            self.count = field.mineCount - flags
        else
            self.count = 0
        end
    end
    function self:draw()
        love.graphics.setColor(0.3, 0.2, 0.2)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Bombs: " .. tostring(self.count), self.x + 10, self.y + 8)
    end
    function self:isClicked(mx, my)
        return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
    end
    return self
end

local function NextLevelButton(x, y)
    local self = {
        width = 100,
        height = 30,
        margin = 10,
        x = x,
        y = y,
        className = "NextLevelButton"
    }
    function self:draw()
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Next Level", self.x + 10, self.y + 8)
    end
    function self:isClicked(mx, my)
        return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
    end
    return self
end

return {
    NewGameButton = NewGameButton,
    Timer = Timer,
    CellsHiddenCounter = CellsHiddenCounter,
    BombCounter = BombCounter,
    NextLevelButton = NextLevelButton
}