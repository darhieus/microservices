local stringy = require "stringy"
local cjson = require "cjson"

local type = type
local string_len = string.len
local string_find = string.find
local pcall = pcall
local ipairs = ipairs

local _M = {}

local PUBLISH_URL = "^%s/pushpin/publish(/?(\\?[^\\s]*)?)$"

local CONTENT_TYPE = "content-type"
local CONTENT_LENGTH = "content-length"

local function parse_json(body)
  if body then
    local status, res = pcall(cjson.decode, body)
    if status then
      return res
    end
  end
end

function _M.update_channels(json, api_id)
  if json and json.items and type(json.items) == "table" then
    for _, item in ipairs(json.items) do
      if item and type(item) == "table" and item.channel and type(item.channel) == "string" then
        item.channel = api_id.."-"..item.channel
      end
    end
  end
  return json
end

local function handle_publish(conf)
  local content_type_value = ngx.req.get_headers()[CONTENT_TYPE]
  if content_type_value and string_find(content_type_value:lower(), "application/json", nil, true) then
    -- Only if the content-type is json
    ngx.req.read_body()
    local json = parse_json(ngx.req.get_body_data())
    local new_json = _M.update_channels(json)
    if new_json then
      local new_body = cjson.encode(new_json)
      ngx.req.set_body_data(new_body)
      ngx.req.set_header(CONTENT_LENGTH, string_len(new_body))
    end
  end
end

function _M.execute(conf)
  -- Check if the API has a request_path and if it's being invoked with the path resolver
  local path_prefix = (ngx.ctx.api.request_path and stringy.startswith(ngx.var.request_uri, ngx.ctx.api.request_path)) and ngx.ctx.api.request_path or ""
  if stringy.endswith(path_prefix, "/") then
    path_prefix = path_prefix:sub(1, path_prefix:len() - 1)
  end

  if ngx.req.get_method() == "POST" then
    if ngx.re.match(ngx.var.request_uri, string.format(PUBLISH_URL, path_prefix)) then
      handle_publish(conf)
    end
  end
end

return _M
