-- Used for synchronous event handling in the game
-- Components can subscribe to topics and receive messages
-- The order of execution is determined by the order of subscription
-- Don´t use this if you need the execution order to be guaranteed
-- Each entity should have only one callback per topic
-- This is a singleton module
local function Signal()
    local self = {
        className = "Signal",
        topics = {},      -- topic -> { entity = { callbacks... } }
        entityTopics = {}, -- entity -> { topics... }
        queue = {}        -- topic -> list of queued messages
    }

    -- Subscribe to a topic with a callback and entity reference
    function self:subscribe(topic, callback, entity)
        -- Use callback as entity if none provided
        if entity == nil then entity = callback end
        -- Create topic entry if it doesn't exist
        if not self.topics[topic] then
            self.topics[topic] = {}
        end
        
        -- Create entity entry in the topic if it doesn't exist
        if not self.topics[topic][entity] then
            self.topics[topic][entity] = {}
        end
        
        -- Create entity tracking entry if it doesn't exist
        if not self.entityTopics[entity] then
            self.entityTopics[entity] = {}
        end
        
        -- Add topic to entity's tracked topics list
        if not table.contains(self.entityTopics[entity], topic) then
            table.insert(self.entityTopics[entity], topic)
        end
        
        -- Add callback to entity's callback list for this topic
        table.insert(self.topics[topic][entity], callback)
        
        return callback -- Return callback for reference
    end



    -- Publish a message to all subscribers of a topic
    function self:publish(topic, ...)
        if not self.topics[topic] or next(self.topics[topic]) == nil then
            -- Queue the message if no subscribers exist
            if not self.queue[topic] then
                self.queue[topic] = {}
            end
            table.insert(self.queue[topic], {...})
            return
        end

        -- Debug: Print the topic and arguments being published
        print("[Signal Debug] Publishing topic:", topic, "with args:", ...)

        -- Deliver the message to all callbacks of each entity
        for entity, callbacks in pairs(self.topics[topic]) do
            for _, callback in ipairs(callbacks) do
                callback(...)
            end
        end
    end

        -- Unsubscribe a specific callback from a topic for an entity
    function self:unsubscribe(topic, entity, callback)
        if not self.topics[topic] or not self.topics[topic][entity] then 
            return 
        end
        
        -- Find and remove the specific callback
        local callbacks = self.topics[topic][entity]
        for i, cb in ipairs(callbacks) do
            if cb == callback then
                table.remove(callbacks, i)
                break
            end
        end
        
        -- If no callbacks left for this entity on this topic, clean up
        if #callbacks == 0 then
            self.topics[topic][entity] = nil
            
            -- Remove topic from entity's tracked topics
            for i, t in ipairs(self.entityTopics[entity] or {}) do
                if t == topic then
                    table.remove(self.entityTopics[entity], i)
                    break
                end
            end
            
            -- If no entities left for this topic, remove the topic entry
            local hasEntities = false
            for _ in pairs(self.topics[topic]) do
                hasEntities = true
                break
            end
            if not hasEntities then
                self.topics[topic] = nil
            end
        end
    end

    -- Unsubscribe all callbacks for an entity from all topics
    function self:unsubscribeScope(entity)
        --topics subscribed by the entity
        local topics = self.entityTopics[entity]
        if not topics then return end

        for _, topic in ipairs(topics) do
            -- Remove the entity from the topic's callbacks
            if self.topics[topic] and self.topics[topic][entity] then
                self.topics[topic][entity] = nil
            end
            
            -- If no callbacks left for this topic, clean up
            local hasEntities = false
            for _ in pairs(self.topics[topic]) do
                hasEntities = true
                break
            end
            if not hasEntities then
                self.topics[topic] = nil
            end
        end
    end

    -- Helper function to check if a table contains a value
    function table.contains(tbl, value)
        for _, v in ipairs(tbl) do
            if v == value then
                return true
            end
        end
        return false
    end

    -- Debug function to show all subscriptions
    function self:debug()
        print("\n--- Signal Debug ---")
        for topic, entities in pairs(self.topics) do
            print("Topic:", topic)
            for entity, callbacks in pairs(entities) do
                print("  Entity:", entity, "Callbacks:", #callbacks)
            end
        end
        print("--- Entity Subscriptions ---")
        for entity, topics in pairs(self.entityTopics) do
            print("Entity:", entity)
            for _, topic in ipairs(topics) do
                print("  Topic:", topic)
            end
        end
        print("--- End Signal Debug ---\n")
    end

    return self
end

-- Singleton instance
local singleton = Signal()
return singleton