MineField = {
    width = 0,
    height = 0,
    board = {},
    mineCount = 0,
    isInitialized = false,
    cellSize = 20,
    offsetX = 0,
    offsetY = 0,
    pressedCell = nil, -- Track which cell is currently pressed
}



CellState = {
    HIDDEN = 0,
    MINE = 1,
    FLAGGED = 2,
    REVEALED = 3,
    PRESSED = 4,
}
MineField.__index = MineField

function MineField:new(width, height, mineCount, cellSize, offsetX, offsetY)
    local instance = setmetatable({}, MineField)
    instance.width = width
    instance.height = height
    instance.mineCount = mineCount
    instance.cellSize = cellSize or 20
    instance.offsetX = offsetX or 0
    instance.offsetY = offsetY or 0


    -- Initialize the minefield with mines and flags
    for i = 1, width do
        for j = 1, height do
            instance.board[i] = instance.board[i] or {}
            instance.board[i][j] = {
                state = CellState.HIDDEN, -- Cell state: HIDDEN, MINE, FLAGGED, REVEALED
                flagged = false,         -- Is this cell flagged?
                value = 0,            -- Value for revealed cells (number of surrounding mines)
                revealed = false,        -- Is this cell revealed?
                isMine = false,         -- Is this cell a mine?
            }
        end
    end

    -- New properties for hover management:
    instance.hoverPressedCells = {}
    instance.hoverCenter = nil

    return instance
end

-- New function: clear hover pressed cells
function MineField:clearHoverCells()
    for _, coord in ipairs(self.hoverPressedCells) do
        local x, y = coord.x, coord.y
        if self.board[x][y].state == CellState.PRESSED then
            self.board[x][y].state = CellState.HIDDEN
        end
    end
    self.hoverPressedCells = {}
    self.hoverCenter = nil
end

-- New function: update hover pressed cells
function MineField:updateHoverCells(newX, newY, button)
    if not self.hoverCenter or self.hoverCenter.x ~= newX or self.hoverCenter.y ~= newY or self.hoverCenter.button ~= button then
        self:clearHoverCells()
        self.hoverCenter = {x = newX, y = newY, button = button}
    end
    local newCoords = {}
    table.insert(newCoords, {x = newX, y = newY})
    if button == 3 then
        local neighbors = {
            {x = -1, y = -1}, {x = 0, y = -1}, {x = 1, y = -1},
            {x = -1, y = 0},                {x = 1, y = 0},
            {x = -1, y = 1},  {x = 0, y = 1}, {x = 1, y = 1},
        }
        for _, offset in ipairs(neighbors) do
            table.insert(newCoords, {x = newX + offset.x, y = newY + offset.y})
        end
    end
    for _, coord in ipairs(newCoords) do
        local x, y = coord.x, coord.y
        if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
            local cell = self.board[x][y]
            if cell.state == CellState.HIDDEN then
                cell.state = CellState.PRESSED
                table.insert(self.hoverPressedCells, {x = x, y = y})
            end
        end
    end
end

function MineField:hoverCells(gridX, gridY, button)
    if gridX < 1 or gridX > self.width or gridY < 1 or gridY > self.height then
        return -- Invalid cell
    end
    self:updateHoverCells(gridX, gridY, button)
end

function MineField:hoverOutCells(gridX, gridY, button)
    self:clearHoverCells()
end

local function countFlagsAround(board, gridX, gridY, width, height)
    local flags = 0
    local next_cells = {
        {x = -1, y = -1}, {x = 0, y = -1}, {x = 1, y = -1},
        {x = -1, y = 0}, {x = 1, y = 0},
        {x = -1, y = 1}, {x = 0, y = 1}, {x = 1, y = 1}
    }
    for _, offset in ipairs(next_cells) do
        local nx = gridX + offset.x
        local ny = gridY + offset.y
        if nx >= 1 and nx <= width and ny >= 1 and ny <= height then
            if board[nx][ny].state == CellState.FLAGGED then
                flags = flags + 1
            end
        end
    end
    return flags
end

function MineField:clickCell(gridX, gridY)
    local cell = self.board[gridX][gridY]
        
    if cell.state == CellState.REVEALED or  cell.state == CellState.FLAGGED then
            return -- Cell already revealed
        end
    if cell.isMine then
        -- Handle mine hit logic here
        print("Game Over! You hit a mine!")
        cell.state = CellState.REVEALED -- Reveal the mine
        -- Optionally, you can reveal all mines or end the game here
        for i = 1, self.width do
            for j = 1, self.height do
                if self.board[i][j].isMine then
                    self.board[i][j].state = CellState.REVEALED -- Reveal all mines
                end
            end
        end
        return
    end

    self:revealCell(gridX, gridY)
end


function MineField:placeMines(ix, iy)
    local placedMines = 0
    while placedMines < self.mineCount do
        local x = math.random(1, self.width)
        local y = math.random(1, self.height)

        -- Ensure we don't place a mine on the initial position
        if self.board[x][y].state == CellState.HIDDEN and (x ~= ix or y ~= iy) then
            self.board[x][y].isMine = true
            placedMines = placedMines + 1
        end
    end

    local next_cells = {
            {x = -1, y = -1}, {x = 0, y = -1}, {x = 1, y = -1},
            {x = -1, y = 0}, {x = 1, y = 0},
            {x = -1, y = 1}, {x = 0, y = 1}, {x = 1, y = 1}
        }
    
    -- Afer placing mines, calculate the number of surrounding mines for each cell
    for i = 1, self.width do
        for j = 1, self.height do
            local cell = self.board[i][j]
            if not cell.isMine then
                local minesAround = 0
                for _, offset in ipairs(next_cells) do
                        local nx = i + offset.x
                        local ny = j+ offset.y
                        if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height and 
                            self.board[nx][ny].isMine then
                                minesAround = minesAround + 1
                        end
                    end   
                cell.value = minesAround
            end
        end
    end
                 
end

function MineField:revealCell(gridX, gridY)
    if gridX < 1 or gridX > self.width or gridY < 1 or gridY > self.height then
        return -- Out of bounds
    end

    if self.board[gridX] == nil or self.board[gridX][gridY] == nil then
        return -- Invalid cell
    end
    local cell = self.board[gridX][gridY]

    if cell.state == CellState.REVEALED then
        return -- Cell already revealed
    end
    if cell.isMine then
        --  Do not reveal mines directly, handle them in the click handler
        return
    end
    if cell.state == CellState.FLAGGED then
        -- Do not reveal flagged cells
        return
    end
    if cell.state ~= CellState.REVEALED then
        if cell.value ~= CellState.HIDDEN then
             -- If the cell has a value, just reveal it
            cell.state = CellState.REVEALED
            return
        end
        -- Check surrounding cells for mines
        local next_cells = {
            {x = -1, y = -1}, {x = 0, y = -1}, {x = 1, y = -1},
            {x = -1, y = 0}, {x = 1, y = 0},
            {x = -1, y = 1}, {x = 0, y = 1}, {x = 1, y = 1}
        }
        
        -- If no mines around, reveal adjacent cells recursively
        cell.state = CellState.REVEALED
        for _, offset in ipairs(next_cells) do
            local nx = gridX + offset.x
            local ny = gridY + offset.y
            if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
                self:revealCell(nx, ny)
            end
        end
    end

end



function MineField:draw(cellSprites)
    love.graphics.setColor(1, 1, 1) -- Reset color to white
    local sprite 
    
    for i = 1, self.width do
        for j = 1, self.height do
            local cell = self.board[i][j]
            if cell.isMine and cell.state == CellState.REVEALED then
                sprite = cellSprites.MINE_EXPLODED
            elseif cell.state == CellState.FLAGGED then
                sprite = cellSprites.FLAGGED
            elseif cell.state == CellState.PRESSED then
                sprite = cellSprites.EMPTY -- Use empty sprite for pressed cells
                --love.graphics.setColor(0.8, 0.3, 0.3) -- Reddish color for pressed cells
            elseif cell.state == CellState.REVEALED then
                local value = cell.value
                -- select sprite based on the value of the cell
                if value == 0 then
                    sprite = cellSprites.EMPTY
                elseif value == 1 then
                    sprite = cellSprites.Number[1]
                elseif value == 2 then
                    sprite = cellSprites.Number[2]
                elseif value == 3 then
                    sprite = cellSprites.Number[3]
                elseif value == 4 then
                    sprite = cellSprites.Number[4]
                elseif value == 5 then
                    sprite = cellSprites.Number[5]
                elseif value == 6 then
                    sprite = cellSprites.Number[6]
                elseif value == 7 then
                    sprite = cellSprites.Number[7]
                elseif value == 8 then
                    sprite = cellSprites.Number[8]
                else
                    sprite = cellSprites.HIDDEN
                end
            else
                sprite = cellSprites.HIDDEN -- Default sprite for hidden cells
            end

            -- Draw the cell background rectangle
            love.graphics.rectangle(
                "fill",
                self.offsetX + (i - 1) * self.cellSize,
                self.offsetY + (j - 1) * self.cellSize,
                self.cellSize,
                self.cellSize
            )
            
            -- Draw the cell sprite based on its state
            love.graphics.draw(
                sprite,
                self.offsetX + (i - 1) * self.cellSize,
                self.offsetY + (j - 1) * self.cellSize,
                0,
                self.cellSize / sprite:getWidth(),
                self.cellSize / sprite:getHeight()
            )
            
            -- Reset color to white for next cell
            love.graphics.setColor(1, 1, 1)
        end
    end
end

function MineField:handleRelease(gridX, gridY, button)
    if not self.isInitialized then
        -- Place mines only once, avoiding the initial click position
        if button == 1 then
            self:placeMines(gridX, gridY)
            self.isInitialized = true
        else
            return -- Do not handle right click or both buttons until mines are placed
        end
    end

    local cell = self.board[gridX][gridY]

    if button == 1 then -- Left click release
        if cell.state == CellState.PRESSED or cell.state == CellState.HIDDEN then
            self:clickCell(gridX, gridY)
        end
    elseif button == 2 then -- Right click release
        --place or remove a flag
        if cell.state == CellState.HIDDEN or cell.state == CellState.PRESSED then
            cell.state = CellState.FLAGGED
        elseif cell.state == CellState.FLAGGED then
            cell.state = CellState.HIDDEN
        end
            
    elseif button == "both" then -- Both buttons released
        if cell.state == CellState.PRESSED then
            self:revealSurroundingCells(gridX, gridY)
        end
    end
end

function MineField:countFlagsAround(gridX, gridY)
    local flagsCount = 0
    local next_cells = {
        {x = -1, y = -1}, {x = 0, y = -1}, {x = 1, y = -1},
        {x = -1, y = 0}, {x = 1, y = 0},
        {x = -1, y = 1}, {x = 0, y = 1}, {x = 1, y = 1}
    }
    
    for _, offset in ipairs(next_cells) do
        local nx = gridX + offset.x
        local ny = gridY + offset.y
        if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
            if self.board[nx][ny].state == CellState.FLAGGED then
                flagsCount = flagsCount + 1
            end
        end
    end
    
    return flagsCount
end

function MineField:revealSurroundingCells(gridX, gridY)
    local next_cells = {
        {x = -1, y = -1}, {x = 0, y = -1}, {x = 1, y = -1},
        {x = -1, y = 0}, {x = 1, y = 0},
        {x = -1, y = 1}, {x = 0, y = 1}, {x = 1, y = 1}
    }
    
    for _, offset in ipairs(next_cells) do
        local nx = gridX + offset.x
        local ny = gridY + offset.y
        if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
            local cell = self.board[nx][ny]
            if cell.state == CellState.HIDDEN then
                if cell.isMine then
                    -- Hit a mine - game over
                    print("Game Over! You hit a mine!")
                    cell.state = CellState.REVEALED
                    -- Reveal all mines
                    for i = 1, self.width do
                        for j = 1, self.height do
                            if self.board[i][j].isMine then
                                self.board[i][j].state = CellState.REVEALED
                            end
                        end
                    end
                    return
                else
                    self:revealCell(nx, ny)
                end
            end
        end
    end
end

function MineField:update(dt)
    -- Update logic for the minefield if needed
    -- This can include animations, timers, etc.
end

return MineField