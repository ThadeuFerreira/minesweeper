local function NewGameButton(x, y)
    local self = {
        width = 100,
        height = 30,
        margin = 10,
        x = x,
        y = y,
        className = "NewGameButton",
        subscription = nil -- Store the subscription for later use
    }

    -- Subscribe to the "mouseClick" signal when the button is instantiated
    self.subscription = Signals:subscribe("mouseClick", function(mx, my, button)
        if button == 1 and self:isClicked(mx, my) then
            Signals:publish("newGame")
            print("New Game button clicked")
        end
    end, 0, self)

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

return NewGameButton