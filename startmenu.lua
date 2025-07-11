
local function isOverComponent(x, y, component)
    return x >= component.x and x <= component.x + component.w and y >= component.y and y <= component.y + component.h
end

-- Start Menu Scene
local function StartMenu()
    
    local self = {
        className = "StartMenu",
        button = {
            w = 200,
            h = 50,
        }
    }

    self.__index = self

    function self:load()
        -- No-op for now
        self.button.x = (love.graphics.getWidth() - self.button.w) / 2
        self.button.y = (love.graphics.getHeight() - self.button.h) / 2
    end
    function self:draw()
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("MINESWEEPER", 0, 100, love.graphics.getWidth(), "center")
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", self.button.x, self.button.y, self.button.w, self.button.h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Start Game", self.button.x, self.button.y + 20, self.button.w, "center")
    end
    function self:update(dt) end

    function self:mousepressed(x, y, button)
        if button == 1 and isOverComponent(x, y, self.button) then
            return true -- Consume the event!
        end
        return false
    end

    function self:mousereleased(x, y, button)
        if button == 1 and isOverComponent(x, y, self.button) then
            switchScene("game")
            return true
        end
        return false
    end
    return self
end

return StartMenu