# sops.nvim

[SOPS](https://github.com/getsops/sops) support for neovim.

## Installation (lazy.nvim)

```lua
{
    "diogo464/sops.nvim",
    -- see the configuration section bellow for available options.
    opts = {}
}
```

## Configuration
```lua
{
    --- custom path for the sops binary
    sops_path = "", 
    --- create user commands
    user_commands = true,
}
```

## User Commands

- `SopsEncrypt`: encrypts the current buffer.
- `SopsDecrypt`: decrypts the current buffer.
- `SopsView`: decrypts the current buffer and shows the output in a scratch buffer.
- `SopsEdit`: decrypts the current buffer and re-encrypts it on write.


## API

```lua
---encrypt the given buffer
---@param bufnr? number
sops.encrypt(bufnr)

---decrypt the given buffer
---@param bufnr? number
sops.decrypt(bufnr)

---edit the given buffer.
---this will decrypt it and re-encrypt it on the next write.
---@param bufnr? number
sops.edit(bufnr)

---decrypt the buffer and show the output on a scratch buffer
---@param bufnr? number
sops.view(bufnr)
```

