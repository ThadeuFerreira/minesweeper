local Signals = require("signals")

local function Timer(x, y, sevenSegments)
    -- Center timer horizontally at the top
    local windowWidth = love.graphics.getWidth()

    local digitWidth = 30
    local digitHeight = 35
    local digitSpacing = 4
    local leftPadding = 10
    local rightPadding = 10
    local decimalWidth = 8
    local decimalPadding = 2

    -- Calculate box width: left padding + (digitWidth + digitSpacing)*3 + decimal width + decimal padding + digitWidth + right padding
    local boxWidth = leftPadding + (digitWidth + digitSpacing) * 3 + decimalWidth + decimalPadding + digitWidth + rightPadding

    local self = {
        elapsed = 0,
        running = true,
        width = boxWidth,
        height = 60,
        margin = 10,
        x = (windowWidth - boxWidth) / 2,
        y = 10,
        className = "Timer",
        sevenSegments = sevenSegments,
        digitWidth = digitWidth,
        digitHeight = digitHeight,
        digitSpacing = digitSpacing,
        leftPadding = leftPadding,
        rightPadding = rightPadding,
        decimalWidth = decimalWidth,
        decimalPadding = decimalPadding
    }

    -- Precompute scale and offset for seven segment digits
    self.sevenSegmentScaleX = self.digitWidth / self.sevenSegments.digitWidth
    self.sevenSegmentScaleY = self.digitHeight / self.sevenSegments.digitHeight
    self.sevenSegmentOffsetX = 0
    self.sevenSegmentOffsetY = 0

    Signals:subscribe("gameover", function(reason)
        self.running = false
    end, 0, self)

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
        local time = math.min(self.elapsed, 999.9)
        local timeStr = string.format("%05.1f", time)

        -- Draw each digit
        local currentX = self.x + self.leftPadding
        local currentY = self.y + 5

        for i = 1, 5 do
            local char = timeStr:sub(i, i)

            if char == "." then
                -- Draw decimal point
                love.graphics.setColor(1, 0, 0)
                love.graphics.circle("fill", currentX + self.decimalWidth / 2, currentY + self.digitHeight - 5, self.decimalWidth / 2)
                currentX = currentX + self.decimalWidth + self.decimalPadding
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
                currentX = currentX + self.digitWidth + self.digitSpacing
            end
        end
    end

    function self:destroy()
        -- Unsubscribe all signals for this component
        Signals:unsubscribeScope(self)
        -- (Optional) Release other resources here
    end

    return self
end

return Timer