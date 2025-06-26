local utils = {}

-- Calculate grid position from mouse coordinates
-- Returns gridX, gridY if valid, or -1, -1 if outside the grid
function utils.calculateGridPosition(mouseX, mouseY, offsetX, offsetY, cellSize, width, height)
    local gridX = math.floor((mouseX - offsetX) / cellSize) + 1
    local gridY = math.floor((mouseY - offsetY) / cellSize) + 1
    
    if gridX < 1 or gridX > width or gridY < 1 or gridY > height then
        return -1, -1 -- Out of bounds
    end
    
    return gridX, gridY
end

return utils
