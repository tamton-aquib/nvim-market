-- Plugin search on first line in installer window: M.install_picker()
-- Remove installed plugins by pressing enter on removed window: M.remove_picker()
local M = {}
local ns = vim.api.nvim_create_namespace("nvim-market")

local gline, buf, win
local plugin_list = {}
local plugin_lines = {}
local curl = require("plenary.curl")
local lua_path = vim.fn.stdpath("data") .. "/plugins.json"
local Spinner = require("nvim-market.spinner")

local actions = {
    get_plugins = function()
        local file = io.open(lua_path, "r")
        if file then
            local content = file:read("*a")
            file:close()
            return vim.json.decode(content)
        else
            error("Error in get_plugins!")
        end
    end,

    set_plugins = function()
        local file = io.open(lua_path, 'w')
        if file then
            local decoded = vim.fn.json_encode(plugin_list)
            file:write(decoded)
            file:close()
        else
            error("Error writing to file!")
        end
    end
}

local update_lazy_window = function(dir, plug)
    require("lazy.core.plugin").load()
    -- vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
    vim.cmd("Lazy "..dir.." "..plug)
    -- require("lazy.manage").install()
end

local remove_selected_plugin = function()
    local selected = vim.trim(vim.api.nvim_get_current_line())
    local ps = actions.get_plugins()
    -- if not ps then return end
    local found = false

    for k, _ in pairs(ps) do
        if k == selected then
            found = true
            plugin_list[selected] = nil
            break
        end
    end
    if found then
        actions.set_plugins()
    else
        vim.notify("Dint find such plugin! (impossible?)")
    end

    vim.api.nvim_del_current_line()
    update_lazy_window("clean", selected)
end

local install_selected_plugin = function()
    local result = vim.trim(vim.api.nvim_get_current_line())
    local selected = plugin_lines[result].full_name

    local ps = actions.get_plugins()
    for _, line in ipairs(ps) do
        local matched = line:match("'"..vim.pesc(selected).."'")
        if matched then
            vim.notify("Plugin already exists!")
            return
        end
    end

    plugin_list[selected] = {config=true}
    actions.set_plugins()
    update_lazy_window("install", result)
end

local update_lines = function(d, s)
    plugin_lines = vim.json.decode(d.body)
    vim.schedule(function()
        vim.api.nvim_buf_set_lines(buf, 1, -1, false, {})
        local t = vim.tbl_keys(plugin_lines)
        vim.api.nvim_buf_set_lines(buf, 1, 2, false, t)
        Spinner.shut(s, ns)
    end)
end

local search_plugins = function()
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, true)[1]

    if vim.bo.ft ~= "lazy_search" or line:len() < 3 or line == gline then
        return
    end

    local s = Spinner.start(buf, ns, 0, 0)
    curl.get("https://api.nvimplugnplay.repl.co/search?max_count=10&query="..line, {
        callback=function(d) update_lines(d, s) end
    })

    gline = line
end

local picker_base = function()
    ---@diagnostic disable-next-line: undefined-field
    if not vim.uv.fs_stat(lua_path) then
        actions.set_plugins()
    end

    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].ft = "lazy_search"
    local w = math.floor(vim.api.nvim_win_get_width(0)/2)-1
    win = vim.api.nvim_open_win(buf, true, {
        relative='win', style='minimal', -- anchor="NE",
        width=w,
        height=vim.api.nvim_win_get_height(0) - 5,
        row=4, col=w
    })
end

M.install_picker = function()
    if vim.bo.ft ~= "lazy" then
        vim.print("Not in lazy window")
        return
    end
    picker_base()
    vim.api.nvim_buf_set_extmark(0, ns, 0, 0, { sign_text = " ", sign_hl_group = "Function" })
    vim.api.nvim_buf_add_highlight(buf, ns, "Keyword", 0, 0, -1)
    vim.keymap.set({"i", "n"}, "<CR>", install_selected_plugin, { buffer=buf })
    vim.api.nvim_create_autocmd('CursorHoldI', { callback=search_plugins }) -- :h timeoutlen?
end

M.remove_picker = function()
    if vim.bo.ft ~= "lazy" then
        vim.print("Not in lazy window")
        return
    end
    picker_base()
    vim.schedule_wrap(function() vim.wo[win].winbar = "%#Keyword#Installed:" end)
    vim.api.nvim_buf_add_highlight(buf, ns, "Keyword", 0, 0, -1)

    local ps = actions.get_plugins()
    local newly = vim.tbl_keys(ps)

    vim.api.nvim_put(newly, "", false, false)
    vim.cmd [[syntax match Keyword "\zs[a-zA-Z0-9\-\._]*\/\ze\w*" conceal cchar= ]]
    vim.keymap.set({"i", "n"}, "<CR>", remove_selected_plugin, { buffer=buf })
end


return M
