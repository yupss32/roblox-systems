# Roblox Systems — Code Sample

A small slice of how I build Roblox games: modular, server-authoritative, and
written so the next person can actually read it.

This isn't a full game. It's a focused sample of the systems I get asked for
most — player data, currency, a shop, and anticheat — wired together the way
I'd structure a real project. Everything important happens on the server; the
client only ever asks.

## What's in here

```
src/
  ServerScriptService/
    init.server.lua          -- bootstrap: loads data on join, starts anticheat
    Services/
      DataService.lua        -- datastore wrapper: session lock, retry/backoff,
                                autosave, guaranteed save on leave, migrations
      CoinService.lua        -- server-authoritative currency
      ShopService.lua        -- coin shop, prices live on the server only
    Anticheat/
      MovementGuard.lua      -- server-side speed / teleport / fly check
      RateLimiter.lua        -- token-bucket limiter for RemoteEvents
  ReplicatedStorage/
    Modules/
      Cooldown.lua           -- small reusable cooldown
```

## A few things worth pointing out

- **DataService uses a session lock.** A profile can't be loaded on two servers
  at once, which is what stops the classic "join two servers and dupe" exploit.
  Saves retry with backoff so a temporary DataStore outage doesn't cost anyone
  their progress, and old saves get migrated forward instead of wiped.
- **The shop never trusts the client.** Prices live in a catalog on the server.
  The client sends an item id and nothing else; the server checks the price,
  spends the coins, and grants the item. There's no client path to set a price
  or grant yourself something for free.
- **Anticheat is flag-and-review, not insta-ban.** MovementGuard measures real
  horizontal speed server-side and racks up strikes instead of banning on one
  spike, so players with bad ping don't get punished.

## Notes

This is my own showcase code, not from a client project. It's here so you can
see how I write and structure things before working together. Happy to walk
through any of it or do a small paid test task.

— Yeps32 · Discord: Yupss32 · Roblox: REALIFTERv4
