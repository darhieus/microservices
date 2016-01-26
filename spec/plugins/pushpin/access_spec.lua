local access = require "kong.plugins.pushpin.access"

local spec_helper = require "spec.spec_helpers"
local utils = require "kong.tools.utils"
local http_client = require "kong.tools.http_client"
local cjson = require "cjson"
local rex = require "rex_pcre"

local PROXY_URL = spec_helper.PROXY_URL

local PUSHPIN_HOST = "192.168.1.133"
local PUSHPIN_PORT = 5561

describe("Pushpin Plugin", function()

  setup(function()
    spec_helper.prepare_db()
    spec_helper.insert_fixtures {
      api = {
        {name = "pushpin", request_host = "pushpin.com", upstream_url = "http://mockbin.com"}
      },
      plugin = {
        { name = "pushpin", config = {
          kong_host = "127.0.0.1", 
          kong_port = 8100,
          pushpin_host = PUSHPIN_HOST, 
          pushpin_port = PUSHPIN_PORT
        }, __api = 1 }
      }
    }
    spec_helper.start_kong()
  end)

  teardown(function()
    spec_helper.stop_kong()
  end)

  it("should prepend channels with API ID", function()
    assert.falsy(access.update_channels(nil, "hello"))
    assert.are.same({}, access.update_channels({}, "hello"))
    assert.are.same({items = {}}, access.update_channels({items = {}}, "hello"))

    assert.are.same({items = {
      {channel = "hello-test"}
    }}, access.update_channels({items = {
      {channel = "test"}
    }}, "hello"))

    assert.are.same({items = {
      {channel = "hello-test"}, {channel = "hello-test2"}
    }}, access.update_channels({items = {
      {channel = "test"}, {channel = "test2"}
    }}, "hello"))
  end)

end)