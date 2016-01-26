local events = require "kong.core.events"
local cache = require "kong.tools.database_cache"

local function post_to_pushpin(message_t)
  if message_t.collection == "plugins" and message_t.entity.name == "pushpin" then
    -- Create PUT request

    local body = cjson.encode(message)
    local payload = string.format(
      "PUT %s HTTP/1.1\r\nHost: %s\r\nConnection: Close\r\nContent-Type: application/json\r\nContent-Length: %s\r\n\r\n%s",
      "/some/path", "somehost.com", string.len(body), body)
  end
end

return {
  [events.TYPES.ENTITY_CREATED] = function(message_t)
    post_to_pushpin(message_t)
  end,
  [events.TYPES.ENTITY_UPDATED] = function(message_t)
    post_to_pushpin(message_t)
  end
}