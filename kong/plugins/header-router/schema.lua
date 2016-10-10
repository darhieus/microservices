return {
  fields = {
    rules = {
      type = "table",
      flexible = true,
      fields = {
        header_name = {type = "string", required = true},
        header_values = {type = "array", required = true},
        upstream_url =  {type = "string", required = true}
      }
    }
  }
}