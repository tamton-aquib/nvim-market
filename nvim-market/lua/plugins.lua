local path = vim.fn.stdpath("data") .. "/plugins.json"

local file = io.open(path, "r")
if file then
    local contents = file:read("*a")
    file:close()
    return vim.iter(vim.json.decode(contents)):map(function(i) return {i, config=true} end):totable()
end
