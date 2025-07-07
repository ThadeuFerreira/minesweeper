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

return NextLevelButton