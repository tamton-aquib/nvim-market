local Spinner = {}

local timer
local list = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local idx=1

Spinner.start = function(buf, ns, r, c)
    ---@diagnostic disable-next-line: undefined-field
    timer = vim.uv.new_timer()

    local id = vim.api.nvim_buf_set_extmark(
        buf, ns, r, c,
        {
            virt_text_pos = 'eol',
            virt_text={{list[idx+1], 'Function'}}
        }
    )

    timer:start(0, 100, vim.schedule_wrap(function()
        idx = (idx + 1) % #list
        vim.api.nvim_buf_set_extmark(
            buf,
            ns,
            r, c,
            { virt_text = {{list[idx+1], 'Function'}}, id=id }
        )
    end))

    return {
        id = id, buf=buf, ns=ns, r=r, c=c, t=timer
    }
end

function Spinner.shut(s, ns)
    vim.api.nvim_buf_del_extmark(s.buf, ns, s.id)
    s.t:stop()
end

return Spinner
