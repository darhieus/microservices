local log = require "kong.cmd.utils.log"
local Serf = require "kong.serf"
local pl_path = require "pl.path"
local http = require "resty.http"
local DAOFactory = require "kong.dao.factory"
local conf_loader = require "kong.conf_loader"
local cjson = require "cjson"
local pl_stringx = require "pl.stringx"
local pl_tablex = require "pl.tablex"
local url = require "socket.url"

local function parse_address(v)
  if v then
    local parts = pl_stringx.split(v, ":")
    if #parts == 2 and tonumber(parts[2]) then
      return {
        address = tostring(parts[1]),
        port = tonumber(parts[2])
      }
    end
  end
end

-- HTTP Client
local function http_client(host, port, timeout)
  timeout = timeout or 10000
  local client = assert(http.new())
  assert(client:connect(host, port))
  client:set_timeout(timeout)
  return client
end

local function read(response, status)
  if not response then return nil, "failed to make request" end

  if response.status == status then
    local body, err = response:read_body()
    if err then return nil, err end
    if body and body ~= "" then
      return cjson.decode(body)
    end
    return true
  end
  return nil, "invalid status received: "..response.status
end

-- Utilities

local function check_versions(from_client, to_client)
  local version_from, version_to

  local res = assert(from_client:request {method = "GET", path = "/", headers = {}})
  local body = assert(read(res, 200))
  version_from = body.version

  local res = assert(to_client:request {method = "GET", path = "/", headers = {}})
  local body = assert(read(res, 200))
  version_to = body.version

  if version_from and version_to and version_from == version_to then
    return version_from
  end

  return nil, "different versions were found on the two clusters"
end

local function check_plugins(from_client, to_client)
  local plugins_from, plugins_to

  local res = assert(from_client:request {method = "GET", path = "/"})
  local body = assert(read(res, 200))
  plugins_from = body.plugins.available_on_server

  local res = assert(to_client:request {method = "GET", path = "/"})
  local body = assert(read(res, 200))
  plugins_to = body.plugins.available_on_server

  if plugins_from and plugins_to and pl_tablex.compare(plugins_from, plugins_to, function(a, b) return a == b end) then
    return pl_tablex.keys(plugins_from)
  end

  return nil, "different plugins available where found on the two clusters"
end

function response_iter(client, path)
  local res = assert(client:request {method = "GET", path = path})
  local body = assert(read(res, 200))

  local i = 0
  local n = table.getn(body.data)

  return function ()
    i = i + 1
    if i <= n then 
      return body.data[i]
    elseif body.next then
      local parsed_url = url.parse(body.next)
      local res = assert(client:request {method = "GET", path = parsed_url.path.."?"..parsed_url.query})
      body = assert(read(res, 200))
      i = 1
      n = table.getn(body.data)
      return body.data[i]
    end
  end
end

local function do_transfer(client, path, element, index)
  local res, err = client:request {
    method = "POST",
    path = path,
    body = cjson.encode(element),
    headers = {
      ["Content-Type"] = "application/json"
    }
  }

  assert(res:read_body())

  if res then
    if res.status == 409 then
      log.warn("path %s, conflict for %s", path, element.id)
    elseif res.status == 201 then
      log("path %s, transfer done for #%d", path, index)
    else
      error("an error occured during the transfer")
    end
  end
end

local function migrate(from_client, to_client, path, relation)
  log("starting transfer for %s%s", path, relation and "{id}/"..relation.."/" or "")

  local i = 0
  for element in response_iter(from_client, path) do
    i = i + 1
    if relation then
      local relation_path = path..element.id.."/"..relation.."/"
      local t = 0
      for relation in response_iter(from_client, relation_path) do
        t = t + 1
        do_transfer(to_client, relation_path, relation, t)
      end
    else
      do_transfer(to_client, path, element, i)
    end
  end
end

local function execute(args)
  local from = parse_address(args.from)
  assert(from ~= nil, "Invalid \"from\" address format")
  local to = parse_address(args.to)
  assert(to ~= nil, "Invalid \"to\" address format")

  local from_client = http_client(from.address, from.port)
  local to_client = http_client(to.address, to.port)

  -- Check versions
  local version = assert(check_versions(from_client, to_client))
  log("initializing transfer across clusters with version: %s", version)

  -- Check the plugins installed are the same
  local plugins = assert(check_plugins(from_client, to_client))
  log("detected %d available plugins", pl_tablex.size(plugins))  

  -- Everything looks good, we can start the actual transfer now
  migrate(from_client, to_client, "/apis/")
  migrate(from_client, to_client, "/consumers/")
  migrate(from_client, to_client, "/plugins/")

  local consumer_relations = { "acls", "basic-auth", "hmac-auth", "jwt", "key-auth", "oauth2" }
  for _, v in ipairs(consumer_relations) do
    migrate(from_client, to_client, "/consumers/", v)
  end

  migrate(from_client, to_client, "/oauth2_tokens/")

  log("done")
end

local lapp = [[
Usage: kong transfer [OPTIONS]

Transfer data between two different Kong clusters using the Admin API.

Options:
 -f,--from   (string) host:admin_port of the node to copy data from
 -t,--to     (string) host:admin_port of the node to copy data to
]]

return {
  lapp = lapp,
  execute = execute
}
