
-- A B C D E F G H
-- I J K L M N O P
-- Q R S T U V W X
-- Y Z 0 1 2 3 4 5
-- 6 7 8 9 
local function SevenSegments()
    local self = {
        className = "SevenSegments",
    }

    function self:load()
        -- Load png seveseg.png in assetsPath
        self.sevesegImage = love.graphics.newImage("assets/seveseg.png")
        self.x_offset = 39
        self.y_offset = 37
        self.digitWidth = 146 - self.x_offset
        self.digitHeight = 225 - self.y_offset
        self.x_padding = 225 - 146
        self.y_padding = 275 - 225
        self.letters = {
            A = {x = 1, y = 1}, B = {x = 2, y = 1}, C = {x = 3, y = 1}, D = {x = 4, y = 1}, E = {x = 5, y = 1}, F = {x = 6, y = 1}, G = {x = 7, y = 1}, H = {x = 8, y = 1},
            I = {x = 1, y = 2}, J = {x = 2, y = 2}, K = {x = 3, y = 2}, L = {x = 4, y = 2}, M = {x = 5, y = 2}, N = {x = 6, y = 2}, O = {x = 7, y = 2}, P = {x = 8, y = 2},
            Q = {x = 1, y = 3}, R = {x = 2, y = 3}, S = {x = 3, y = 3}, T = {x = 4, y = 3}, U = {x = 5, y = 3}, V = {x = 6, y = 3}, W = {x = 7, y = 3}, X = {x = 8, y = 3},
            Y = {x = 1, y = 4}, Z = {x = 2, y = 4}
        }
        self.numbers = {{x = 3, y = 4}, {x = 4, y = 4}, {x = 5, y = 4}, {x = 6, y = 4}, {x = 7, y = 4}, {x = 8, y = 4},
                         {x = 1, y = 5}, {x = 2, y = 5}, {x = 3, y = 5}, {x = 4, y = 5} }
    end

    function self:getLetterImage(letter)
        local coords = self.letters[letter:upper()]
        if not coords then
            return nil
        end
        local x = self.x_offset + (coords.x - 1) * self.digitWidth + (coords.x - 1) * self.x_padding
        local y = self.y_offset + (coords.y - 1) * self.digitHeight + (coords.y - 1) * self.y_padding
        return self.sevesegImage, love.graphics.newQuad(x, y, self.digitWidth, self.digitHeight, self.sevesegImage:getDimensions())
    end

    function self:getNumberImage(number)
        if number < 0 or number > 9 then
            return nil
        end
        local coords = self.numbers[number + 1]
        local x = self.x_offset + (coords.x - 1) * self.digitWidth + (coords.x - 1) * self.x_padding
        local y = self.y_offset + (coords.y - 1) * self.digitHeight + (coords.y - 1) * self.y_padding
        local quad = love.graphics.newQuad(x, y, self.digitWidth, self.digitHeight, self.sevesegImage)
        return self.sevesegImage, quad
    end

    return self
end

return SevenSegments