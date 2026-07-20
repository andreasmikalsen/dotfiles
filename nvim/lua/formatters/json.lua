local nvim = vim
local M = {}

local function encode(value, indent)
  indent = indent or 0
  local pad = string.rep("  ", indent)

  if type(value) == "table" then
    local is_array = true
    local count = 0

    for k in pairs(value) do
      count = count + 1
      if type(k) ~= "number" then
        is_array = false
        break
      end
    end

    if count == 0 then
      return is_array and "[]" or "{}"
    end

    local out = {}

    if is_array then
      table.insert(out, "[")
      for i, v in ipairs(value) do
        table.insert(out,
          string.rep("  ", indent + 1)
          .. encode(v, indent + 1)
          .. (i < #value and "," or "")
        )
      end
      table.insert(out, pad .. "]")
    else
      table.insert(out, "{")

      local keys = {}
      for k in pairs(value) do
        table.insert(keys, k)
      end
      table.sort(keys)

      for i, k in ipairs(keys) do
        table.insert(out,
          string.rep("  ", indent + 1)
            .. nvim.json.encode(k)
            .. ": "
            .. encode(value[k], indent + 1)
            .. (i < #keys and "," or "")
        )
      end

      table.insert(out, pad .. "}")
    end

    return table.concat(out, "\n")
  end

  return nvim.json.encode(value)
end

function M.format()
  local buf = nvim.api.nvim_get_current_buf()

  local text = table.concat(
    nvim.api.nvim_buf_get_lines(buf, 0, -1, false),
    "\n"
  )

  local ok, obj = pcall(nvim.json.decode, text)

  if not ok then
    nvim.notify("Invalid JSON", nvim.log.levels.ERROR)
    return
  end

  local formatted = encode(obj)

  nvim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    nvim.split(formatted, "\n", { plain = true })
  )
end

return M
