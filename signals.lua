local function Signal()
    local self = {
        className = "Signal",
        topics = {}, -- topic -> list of callbacks
        queue = {} -- topic -> list of queued messages
    }

    function self:subscribe(topic, callback, priority, scope)
        if not self.topics[topic] then
            self.topics[topic] = {}
        end
        local subscription = {callback = callback, priority = priority or 0, scope = scope}
        table.insert(self.topics[topic], subscription)

        -- Sort callbacks by priority
        table.sort(self.topics[topic], function(a, b)
            return a.priority > b.priority
        end)

        -- Deliver queued messages for this topic
        if self.queue[topic] then
            for _, message in ipairs(self.queue[topic]) do
                callback(table.unpack(message))
            end
            self.queue[topic] = nil -- Clear the queue after processing
        end

        -- Return the subscription for manual management
        return subscription
    end

    function self:unsubscribe(topic, callback)
        if not self.topics[topic] then return end
        for i, cb in ipairs(self.topics[topic]) do
            if cb == callback then
                table.remove(self.topics[topic], i)
                break
            end
        end
    end

    function self:publish(topic, ...)
        if not self.topics[topic] then
            -- Queue the message if no subscribers exist
            if not self.queue[topic] then
                self.queue[topic] = {}
            end
            table.insert(self.queue[topic], {...})
            return
        end

         -- Deliver the message to all subscribers
        for _, subscription in ipairs(self.topics[topic]) do
            subscription.callback(...)
        end
    end

    function self:unsubscribeScope(scope)
        for topic, subscribers in pairs(self.topics) do
            for i = #subscribers, 1, -1 do
                if subscribers[i].scope == scope then
                    table.remove(subscribers, i)
                end
            end
        end
    end

    function self:debug()
        for topic, subscribers in pairs(self.topics) do
            print("Topic:", topic)
            for _, subscriber in ipairs(subscribers) do
                print("  Callback:", subscriber.callback, "Priority:", subscriber.priority or 0)
            end
        end
    end

    return self
end

-- Singleton instance
local singleton = Signal()
return singleton