local _M = {}


--[[
{
  method = "GET",
  host = "",
  port
  path
}
--]]

local function generate_payload(options_t)

  

end

function _M.request(options_t)
  local sock = ngx.socket.tcp()
  sock:settimeout(options_t.timeout and options_t.timeout or 5000)

  local ok, err = sock:connect(options_t.host, options_t.port)
  if not ok then
    ngx.log(ngx.ERR, "[http] failed to connect to "..options_t.host..":"..tostring(options_t.port)..": ", err)
    return
  end

  ok, err = sock:send(generate_payload(options_t).."\r\n")
  if not ok then
    ngx.log(ngx.ERR, "[http-log] failed to send data to "..host..":"..tostring(port)..": ", err)
  end

  ok, err = sock:setkeepalive(conf.keepalive)
  if not ok then
    ngx.log(ngx.ERR, "[http-log] failed to keepalive to "..host..":"..tostring(port)..": ", err)
    return
  end

end


return _M