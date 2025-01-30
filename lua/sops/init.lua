local log = require("sops.log")
local config = require("sops.config")

local M = {}

---run sops with the given arguments
---@param sops_args table
---@return string stdout
local function sops_run(sops_args)
    local sops_path = config.resolve_sops_path()
    local args = vim.list_extend({ sops_path }, sops_args)
    local proc = vim.system(args):wait()
    if proc.code ~= 0 then
        local error_message = string.format("failed to run sops command: %s\n%s", table.concat(args, " "), proc.stderr)
        log.error(error_message)
        error(error_message)
    end
    return proc.stdout
end

---write the buffer to disk
---@param bufnr number
local function buffer_save(bufnr)
    vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("silent! write")
    end)
end

---reload the buffer content from disk
---@param bufnr number
local function buffer_reload(bufnr)
    vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("silent! e")
    end)
end

---show lines on a scratch buffer
---@param lines string[]
---@param filetype? string
local function buffer_scratch_show(lines, filetype)
    -- Create a new scratch buffer
    local bufnr = vim.api.nvim_create_buf(false, true) -- (listed=false, scratch=true)

    -- Set buffer options (optional)
    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile") -- Prevent file write prompts
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe") -- Auto-delete buffer when closed
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)   -- No swap file

    if filetype ~= nil then
        vim.bo[bufnr].filetype = filetype
    end

    -- Set lines in the buffer
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Open in a horizontal split
    vim.api.nvim_command("split")

    -- Set the new buffer as the active buffer in the split
    vim.api.nvim_set_current_buf(bufnr)
end

function M.setup(opts)
    log.debug("user options = ", opts)
    config.apply_options(opts)
    log.debug("using configuration = ", config)

    if config.user_commands then
        log.debug("creating user commands")
        M.create_user_commands()
    end
end

---encrypt the given buffer
---@param bufnr? number
function M.encrypt(bufnr)
    bufnr = bufnr or 0
    local filepath = vim.api.nvim_buf_get_name(bufnr)

    buffer_save(bufnr)
    sops_run({ "encrypt", "-i", filepath })
    buffer_reload(bufnr)
end

---decrypt the given buffer
---@param bufnr? number
function M.decrypt(bufnr)
    bufnr = bufnr or 0
    local filepath = vim.api.nvim_buf_get_name(bufnr)

    buffer_save(bufnr)
    sops_run({ "decrypt", "-i", filepath })
    buffer_reload(bufnr)
end

---edit the given buffer.
---this will decrypt it and re-encrypt it on the next write.
---@param bufnr? number
function M.edit(bufnr)
    bufnr = bufnr or 0
    local filepath = vim.api.nvim_buf_get_name(bufnr)

    buffer_save(bufnr)
    sops_run({ "decrypt", "-i", filepath })
    buffer_reload(bufnr)
    vim.api.nvim_create_autocmd("BufWritePost", {
        once = true,
        buffer = bufnr,
        callback = function()
            M.encrypt(bufnr)
        end
    })
end

---decrypt the buffer and show the output on a scratch buffer
---@param bufnr? number
function M.view(bufnr)
    bufnr = bufnr or 0
    local filepath = vim.api.nvim_buf_get_name(bufnr)

    buffer_save(bufnr)
    local content = sops_run({ "decrypt", filepath })
    local lines = vim.split(content, "\n")
    buffer_scratch_show(lines, vim.bo[bufnr].filetype)
end

function M.create_user_commands()
    vim.api.nvim_create_user_command("SopsEncrypt", function()
        M.encrypt(0)
    end, { desc = "Encrypt the current file using sops" })

    vim.api.nvim_create_user_command("SopsDecrypt", function()
        M.decrypt(0)
    end, { desc = "Decrypt the current file using sops" })

    vim.api.nvim_create_user_command("SopsEdit", function()
        M.edit(0)
    end, { desc = "Edit the current file using sops. The file will be encrypted again on write." })

    vim.api.nvim_create_user_command("SopsView", function()
        M.view(0)
    end, { desc = "Decrypt and view the current file on another buffer." })
end

return M
