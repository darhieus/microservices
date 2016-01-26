local stringy = require "stringy"
local utils = require "kong.tools.utils"
local cache = require "kong.tools.database_cache"
local responses = require "kong.tools.responses"
local constants = require "kong.constants"
local timestamp = require "kong.tools.timestamp"

local _M = {}

local PUBLISH_URL = "^%s/pushpin/publish(/?(\\?[^\\s]*)?)$"

local function publish(conf)
  -- TODO
end

function _M.execute(conf)
  -- Check if the API has a request_path and if it's being invoked with the path resolver
  local path_prefix = (ngx.ctx.api.request_path and stringy.startswith(ngx.var.request_uri, ngx.ctx.api.request_path)) and ngx.ctx.api.request_path or ""
  if stringy.endswith(path_prefix, "/") then
    path_prefix = path_prefix:sub(1, path_prefix:len() - 1)
  end

  if ngx.req.get_method() == "POST" then
    if ngx.re.match(ngx.var.request_uri, string.format(PUBLISH_URL, path_prefix)) then
      publish(conf)
    end
  end

  
end

return _M
