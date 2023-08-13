# nvim-market
An extension market place plugin for neovim. <br />
Made for personal use, but feel free to fork/contribute/extend anyway you like.

https://github.com/tamton-aquib/nvim-market/assets/77913442/ebb5a354-d767-4e0c-8880-d5f5b7a8fff3

### Installation
```lua
{ 'tamton-aquib/nvim-market', import="nvim-market.plugins" },
```
### Configuration
*No config options as of now*

### NOTE
- The code is extremely ugly (Just nearly 200 LOC).
- Searches plugins from a database of 3k plugins remotely.
- Just a PoC until real packspec stuff gets standardised. (refer: https://github.com/folke/lazy.nvim/pull/910, https://github.com/neovim/packspec)

### TODO
- [ ] Cleanify keybinds, create setup function, etc
- [ ] Make UI good, add highlight, etc
- [ ] interactive `opts` update
- [ ] Move the state file from stdpath "data" to "config"? (for VCS)
