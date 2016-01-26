local events = require "kong.core.events"
local http_client = require "kong.tools.http_client"

local function generate_payload(method, host, port, path, body)
  local payload = string.format(
    "%s %s HTTP/1.1\r\nHost: %s\r\nConnection: Keep-Alive\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %s\r\n\r\n%s",
    method:upper(), path, host..":"..tostring(port), string.len(body), body)
  return payload
end

local function send_to_pushpin(message_t)
  if message_t.collection == "plugins" and message_t.entity.name == "pushpin" then
    local host = message_t.entity.config.pushpin_host
    local port = message_t.entity.config.pushpin_port

    local body = ngx.encode_args({
      target_host = message_t.entity.config.kong_host,
      target_port = message_t.entity.config.kong_port,
      target_ssl = tostring(false),
      target_over_http = tostring(true)
    })

    local sock = ngx.socket.tcp()
    sock:settimeout(10000)

    local ok, err = sock:connect(host, port)
    if not ok then
      ngx.log(ngx.ERR, "[pushpin] failed to connect to "..host..":"..tostring(port)..": ", err)
      return
    end

    ok, err = sock:send(generate_payload("PUT", host, port, "/config", body))
    if not ok then
      ngx.log(ngx.ERR, "[pushpin] failed to send data to "..host..":"..tostring(port)..": ", err)
    end

    ok, err = sock:setkeepalive(60000)
    if not ok then
      ngx.log(ngx.ERR, "[pushpin] failed to keepalive to "..host..":"..tostring(port)..": ", err)
      return
    end
  end
end

return {
  [events.TYPES.ENTITY_CREATED] = function(message_t)
    send_to_pushpin(message_t)
  end,
  [events.TYPES.ENTITY_UPDATED] = function(message_t)
    send_to_pushpin(message_t)
  end
}