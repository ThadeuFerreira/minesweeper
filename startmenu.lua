local function isOverComponent(x, y, component)
    return x >= component.x and x <= component.x + component.w and y >= component.y and y <= component.y + component.h
end

local function addComponent(parent, component)
    table.insert(parent.components, component)
    if not parent.componentsByName[component.className] then
        parent.componentsByName[component.className] = {}
    end
    table.insert(parent.componentsByName[component.className], component)
    local lastId = parent.lastComponentId or 0
    component.id = lastId + 1
    parent.lastComponentId = component.id
    parent.componentsById[component.id] = component -- Store by ID for quick access
    component.parent = parent -- Set parent reference for the component
end 

local function optionButton(parent, x, y, label, scene, mode, difficulty, color)
    local self = {
        className = "OptionButton",
        x = x,
        y = y,
        w = 200,
        h = 50,
        label = label,
        scene = scene,
        mode = mode,
        difficulty = difficulty
    }
    function self:draw()
        love.graphics.setColor(color or {0.2, 0.6, 0.2})
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.label, self.x, self.y + 20, self.w, "center")
    end
    function self:isClicked(mx, my)
        return isOverComponent(mx, my, self)
    end
    addComponent(parent, self)
    return self
end

-- Start Menu Scene
local function StartMenu(x, y)
    
    local self = {
        className = "StartMenu",
        x = x,
        y = y,
        -- Button components for menu options
        components = {},
        componentsByName = {},
        componentsById = {}, -- Store components by ID for quick access
        lastComponentId = 0 -- Track the last assigned component ID
    }
    

    self.__index = self

    function self:load()
        -- Define button options
        local labels = {
            {text = "Traditional - Easy", scene = "game", mode = "traditional", difficulty = "easy", color = {0.2, 0.6, 0.2}},
            {text = "Traditional - Medium", scene = "game", mode = "traditional", difficulty = "medium", color = {0.6, 0.6, 0.2}},
            {text = "Traditional - Hard", scene = "game", mode = "traditional", difficulty = "hard", color = {0.8, 0.4, 0.2}},
            {text = "Traditional - Insane", scene = "game", mode = "traditional", difficulty = "insane", color = {0.8, 0.4, 0.2}},
            {text = "Campaign", scene = "campaign"},
            {text = "Custom", scene = "custom"},
            {text = "High Scores", scene = "highscores"},
        }
        local buttonW, buttonH, margin = 200, 50, 10
        for i, v in ipairs(labels) do
            addComponent(self, optionButton(self, 10, 
                10 + (i - 1) * (buttonH + margin), 
                v.text, v.scene, v.mode, v.difficulty, v.color))
        end
    end
    function self:draw()
        love.graphics.setColor(1, 1, 1)
        for _, component in ipairs(self.components) do
            component:draw()
        end
    end
    function self:update(dt) end

    function self:mousepressed(x, y, button)
        for _, btn in ipairs(self.components) do
            if button == 1 and isOverComponent(x, y, btn) then
                return true -- Consume the event!
            end
        end
        return false
    end

    function self:mousereleased(x, y, button)
        for _, btn in ipairs(self.components) do
            if button == 1 and isOverComponent(x, y, btn) then
                -- Switch to the selected scene (mode and difficulty handled in scene setup)
                switchScene(btn.scene)
                return true
            end
        end
        return false
    end
    return self
end

return StartMenu