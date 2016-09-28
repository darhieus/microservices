local BasePlugin = require "kong.plugins.base_plugin"
local url = require "socket.url"

local HeaderRouterHandler = BasePlugin:extend()

function HeaderRouterHandler:new()
  HeaderRouterHandler.super.new(self, "HeaderRouter")
end

function HeaderRouterHandler:access(conf)
  HeaderRouterHandler.super.access(self)

  local header_value = ngx.req.get_headers()[conf.header_name]
  if header_value and header_value == conf.header_value then
    local parsed_url = url.parse(ngx.ctx.upstream_url)
    ngx.ctx.upstream_url = conf.upstream_url..parsed_url.path
  end
end

HeaderRouterHandler.PRIORITY = 801

return HeaderRouterHandler