local function Timer(x, y, sevenSegments)
    -- Center timer horizontally at the top
    local windowWidth = love.graphics.getWidth()
    local timerWidth = 300 -- Should match self.width below
    x = (windowWidth - timerWidth) / 2
    y = 10 -- Top margin

    local self = {
        elapsed = 0,
        running = true,
        width = 300, -- Increased width for 4 digits + decimal point
        height = 60, -- Increased height for seven segment display
        margin = 10,
        x = x,
        y = y,
        className = "Timer",
        sevenSegments = sevenSegments,
        digitWidth = 30, -- Width of each digit box
        digitHeight = 35, -- Height of each digit box
        digitSpacing = 4 -- Space between digits
    }
    
    -- Precompute scale and offset for seven segment digits
    self.sevenSegmentScaleX = self.digitWidth / self.sevenSegments.digitWidth
    self.sevenSegmentScaleY = self.digitHeight / self.sevenSegments.digitHeight
    self.sevenSegmentOffsetX = (self.digitWidth - self.digitWidth) / 2
    self.sevenSegmentOffsetY = (self.digitHeight - self.digitHeight) / 2

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
        -- Draw background
        love.graphics.setColor(0.1, 0.1, 0.3)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        
        -- Format time as 000.0 to 999.9
        local time = math.min(self.elapsed, 999.9) -- Cap at 999.9
        local timeStr = string.format("%04.1f", time) -- Format as 000.0
        
        -- Draw each digit
        local currentX = self.x + 10
        local currentY = self.y + 5
        
        for i = 1, 5 do -- 5 characters: 3 digits, decimal point, 1 digit
            local char = timeStr:sub(i, i)
            
            if char == "." then
                -- Draw decimal point
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("fill", currentX + self.digitWidth/2, currentY + self.digitHeight - 5, 3)
            else
                -- Draw digit box
                love.graphics.setColor(0.2, 0.2, 0.2)
                love.graphics.rectangle("fill", currentX, currentY, self.digitWidth, self.digitHeight)
                
                -- Draw seven segment digit
                local digit = tonumber(char)
                if digit ~= nil and self.sevenSegments then
                    local img, quad = self.sevenSegments:getNumberImage(digit)
                    if img and quad then
                        love.graphics.setColor(1, 1, 1)
                        -- Use precomputed scale and offset
                        love.graphics.draw(
                            img, quad,
                            currentX + self.sevenSegmentOffsetX,
                            currentY + self.sevenSegmentOffsetY,
                            0,
                            self.sevenSegmentScaleX,
                            self.sevenSegmentScaleY
                        )
                    end
                end
            end
            
            currentX = currentX + self.digitWidth + self.digitSpacing
        end
    end
    
    return self
end

return Timer