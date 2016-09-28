local helpers = require "spec.helpers"
local cjson = require "cjson"

describe("Plugin: header-router (access)", function()
  local client, admin_client
  setup(function()
    assert(helpers.start_kong())
    client = helpers.proxy_client()
    admin_client = helpers.admin_client()

    local api1 = assert(helpers.dao.apis:insert {
      request_host = "header-router.com",
      upstream_url = "http://mockbin.com"
    })
    local api2 = assert(helpers.dao.apis:insert {
      request_path = "/test",
      strip_request_path = true,
      upstream_url = "http://mockbin.com"
    })
    
    assert(helpers.dao.plugins:insert {
      name = "header-router",
      api_id = api1.id,
      config = {
        header_name = "x-hello",
        header_value = "yes",
        upstream_url = "http://httpbin.org"
      }
    })

    assert(helpers.dao.plugins:insert {
      name = "header-router",
      api_id = api2.id,
      config = {
        header_name = "x-hello",
        header_value = "yes",
        upstream_url = "http://httpbin.org"
      }
    })
  end)
  teardown(function()
    if client and admin_client then
      client:close()
      admin_client:close()
    end
    helpers.stop_kong()
  end)

  describe("host resolver", function()
    it("routes when header matches", function()
      local res = assert(client:send {
        method = "GET",
        path = "/get",
        headers = {
          ["Host"] = "header-router.com",
          ["x-hello"] = "yes"
        }
      })
      local body = cjson.decode(assert.res_status(200, res))
      assert.equal("http://header-router.com/get", body.url)
    end)
    it("does not route when header does not match", function()
      local res = assert(client:send {
        method = "GET",
        path = "/request",
        headers = {
          ["Host"] = "header-router.com",
          ["x-hello"] = "yesa"
        }
      })
      local body = cjson.decode(assert.res_status(200, res))
      assert.equal("http://header-router.com/request", body.url)
    end)
  end)

  describe("path resolver", function()
    it("routes when header matches #only", function()
      local res = assert(client:send {
        method = "GET",
        path = "/test/get",
        headers = {
          ["x-hello"] = "yes"
        }
      })
      local body = cjson.decode(assert.res_status(200, res))
      assert.equal("http://mockbin.com/get", body.url)
    end)
    it("does not route when header does not match", function()
      local res = assert(client:send {
        method = "GET",
        path = "/test/request",
        headers = {
          ["x-hello"] = "yesa"
        }
      })
      local body = cjson.decode(assert.res_status(200, res))
      assert.equal("http://mockbin.com/request", body.url)
    end)
  end)
end)