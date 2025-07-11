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

return BombCounter