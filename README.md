# roblox-systems

bit of my code so you can see how i write before working together. not a full game, just the systems i get asked for most — saving, coins, a shop, and anticheat. all server side, the client just asks.

## layout

```
src/
  ServerScriptService/
    init.server.lua        -- boot: load data on join, start anticheat
    Services/
      DataService.lua      -- saving w/ session lock, retries, autosave, migrations
      CoinService.lua      -- coins, server side only
      ShopService.lua      -- coin shop, prices live on the server
    Anticheat/
      MovementGuard.lua    -- speed / teleport / fly check
      RateLimiter.lua      -- token bucket for remotes
  ReplicatedStorage/
    Modules/
      Cooldown.lua         -- reusable cooldown
```

## stuff worth pointing out

- **DataService has a session lock** so the same profile cant load on two servers at once. thats the thing that stops the join-two-servers dupe. saves retry if datastore is being slow, and old saves get patched to the new template instead of wiped.
- **shop prices live on the server only.** client sends an item id, server checks the price, spends the coins, grants the item. no way to fake a price or grab something free.
- **anticheat builds strikes instead of insta banning.** one weird reading gets logged, repeat offenders get kicked. people with bad wifi dont get booted off one spike.

this is my own showcase code, not from a client project. happy to walk through any of it or do a small paid test task.

— yeps32 · discord: yupss32 · roblox: REALIFTERv4
