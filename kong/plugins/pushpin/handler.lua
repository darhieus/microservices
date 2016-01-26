local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.pushpin.access"

local Pushpin = BasePlugin:extend()

function Pushpin:new()
  Pushpin.super.new(self, "pushpin")
end

function Pushpin:access(conf)
  Pushpin.super.access(self)
  access.execute(conf)
end

return Pushpin