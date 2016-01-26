local json = require "cjson"
local http_client = require "kong.tools.http_client"
local spec_helper = require "spec.spec_helpers"
local cache = require "kong.tools.database_cache"

local STUB_GET_URL = spec_helper.STUB_GET_URL
local API_URL = spec_helper.API_URL

local PUSHPIN_HOST = "192.168.1.133"
local PUSHPIN_PORT = 5561

describe("Pushpin Hooks", function()

  setup(function()
    spec_helper.prepare_db()
  end)

  teardown(function()
    spec_helper.stop_kong()
  end)

  before_each(function()
    spec_helper.restart_kong()

    spec_helper.drop_db()
    spec_helper.insert_fixtures {
      api = {
        {name = "pushpin", request_host = "pushpin.com", upstream_url = "http://mockbin.com"}
      }
    }
  end)

  it("should work when manually sending the request to pushpin", function()
    -- TODO
  end)

  it("should send a request to pushpin when the plugin is being installed", function()
    local _, status = http_client.post(API_URL.."/apis/pushpin/plugins/", {
      name="pushpin", 
      ["config.kong_host"] = "127.0.0.1", 
      ["config.kong_port"] = 8100,
      ["config.pushpin_host"] = PUSHPIN_HOST, 
      ["config.pushpin_port"] = PUSHPIN_PORT,
    })

    assert.equal(201, status)

    os.execute("sleep 6")
  end)
end)
