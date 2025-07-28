local function ReturnToMainMenuButton(x, y)
    local self = {
        width = 100,
        height = 30,
        margin = 10,
        x = x,
        y = y,
        className = "ReturnToMainMenuButton",
        subscription = nil -- Store the subscription for later use
    }

    -- Subscribe to the "mouseClick" signal when the button is instantiated
    self.subscription = Signals:subscribe("mouseClick", function(mx, my, button)
        if button == 1 and self:isClicked(mx, my) then
            Signals:publish("returnToMainMenu")
            print("Return To Main Menu button clicked")
        end
    end, self)

    function self:draw()
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Return To Main Menu", self.x + 10, self.y + 8)
    end
    function self:isClicked(mx, my)
        return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
    end

    function self:unload()
        if self.subscription then
            Signals:unsubscribeScope(self)
            self.subscription = nil
        end
    end

    return self
end

return ReturnToMainMenuButton