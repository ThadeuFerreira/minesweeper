Signals = require("signals")


local function NextLevelButton(x, y)
    local self = {
        width = 100,
        height = 30,
        margin = 10,
        x = x,
        y = y,
        className = "NextLevelButton",
        subscription = nil -- Store the subscription for later use
    }

    -- Subscribe to the "mouseClick" signal when the button is instantiated
    Signals:subscribe("mouseClick", function(mx, my, button)
        if button == 1 and self:isClicked(mx, my) then
            Signals:publish("nextLevel")
            print("Next Level button clicked")
            self:destroySelf() -- Destroy the button after clicking
        end
    end, self)

    function self:draw()
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Next Level", self.x + 10, self.y + 8)
    end
    function self:isClicked(mx, my)
        return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
    end

    function self:destroy()
         -- Unsubscribe from the "mouseClick" signal when the button is destroyed
        
        Signals:unsubscribeScope(self)
        self.subscription = nil -- Clear the subscription reference
        
        print("Destroying NextLevelButton")
    end

    function self:destroySelf()
        -- Notify the parent to remove this component
        if self.parent then
            self.parent:removeComponent(self)
        end
    end
    return self
end

return NextLevelButton