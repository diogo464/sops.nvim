local config = {
    --- sops binary path
    ---@type string | nil
    sops_path = nil,
}

function config.resolve_sops_path()
    if config.sops_path == nil then
        return vim.fn.exepath("sops")
    else
        return config.sops_path
    end
end

---apply user options
---@param opts table
function config.apply_options(opts)
    opts = opts or {}
    opts = vim.deepcopy(opts, true)

    function merge(lhs, rhs)
        assert(type(lhs) == "table")
        assert(type(rhs) == "table")

        for key, val in pairs(lhs) do
            if type(val) ~= "function" then
                if rhs[key] ~= nil then
                    if type(rhs[key]) == "table" and type(lhs[key]) == "table" then
                        merge(lhs[key], rhs[key])
                    else
                        lhs[key] = rhs[key]
                    end
                end
            end
        end
    end

    merge(config, opts)
end

return config
