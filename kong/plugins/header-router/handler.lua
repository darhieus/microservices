local BasePlugin = require "kong.plugins.base_plugin"
local pl_stringx = require "pl.stringx"
local url = require "socket.url"
local utils = require "kong.tools.utils"

local HeaderRouterHandler = BasePlugin:extend()

function HeaderRouterHandler:new()
  HeaderRouterHandler.super.new(self, "HeaderRouter")
end

function HeaderRouterHandler:access(conf)
  HeaderRouterHandler.super.access(self)

  for _, v in pairs(conf.rules) do
    local header_value = ngx.req.get_headers()[v.header_name]
    if header_value and utils.table_contains(v.header_values, pl_stringx.strip(header_value)) then
      local parsed_url = url.parse(ngx.ctx.upstream_url)
      ngx.ctx.upstream_url = v.upstream_url..parsed_url.path
    end
  end
end

HeaderRouterHandler.PRIORITY = 801

return HeaderRouterHandler