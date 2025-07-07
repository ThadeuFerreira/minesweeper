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

return Timer