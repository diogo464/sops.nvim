local log = require("sops.log")
local config = require("sops.config")

local M = {}

function M.setup(opts)
    log.debug("user options = ", opts)
    config.apply_options(opts)
    log.debug("using configuration = ", config)
    print("Hello")
end

return M
