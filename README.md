<p align="center">
  <img src="./logo.webp" alt="Shaber" width="320">
</p>

# Shaber-Julia

Julia bindings for the Shaber API. Shaber is a JSON re-host of the
Spore.com archive: it pulls Spore's creaky XML/HTML endpoints and
re-emits them as clean, pretty-printed JSON, exposes the Sporepedia
catalog that the official site only hands out over DWR/AJAX, proxies the
Spore Fandom wiki across ten languages, and live-streams the OST as Opus
over WebSocket. This package wraps the whole surface so you can stay in
Julia instead of fighting HTTP, JSON and WebSocket plumbing.

Handy for:

- batch-analysing creature, asset and sporecast data in DataFrames
- plotting Spore stats (uploads, users, ratings) over time
- pulling wiki articles into a notebook for NLP / text mining
- recording the OST stream to disk or a DSP pipeline

API:      https://shaber.sherolld.com
API DOCS: https://shaber.sherolld.com/docs

Want a client in a different language? Roll your own from
https://shaber.sherolld.com/docs.

Targets Julia 1.6 and up.

## Install

Until this lands in the General registry, add by path:

```julia
using Pkg
Pkg.develop(path="/path/to/Shaber-Julia")
```

Or, from inside the cloned repo:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Deps (resolved by Pkg): `HTTP`, `JSON3`, `URIs`.

## Use it

```julia
using Shaber

c = Client()

println(health(c).uptimeSeconds)
println(stats(c).totalUsers)
println(wikiRandom(c, "en").title)
```

Every `/api/*` endpoint is a top-level function that takes a `Client` first.
Query params become keyword arguments. Responses come back as `JSON3.Object`,
which you can access with `.field` or `[:field]`. Non-200 throws
`ShaberError`.

```julia
asset(c, "500005649853").name      # "WhatThePig"
asset(c, "500005649853")[:tags]    # ["pig", "spore", ...]
```

If you're hitting big endpoints, bump the timeout:

```julia
c = Client(; timeout=60)
```

Full function reference, parameter docs and event payloads: [DOCS.md](./DOCS.md).

## Radio

```julia
using Shaber, Shaber.Radio

io = open("out.opus", "w")

Radio.run(Client()) do conn
    onevent!(conn, :hello)  do m; @info "catalog" m.count end
    onevent!(conn, :track)  do m; @info m.name            end
    onevent!(conn, :binary) do d; write(io, d)            end
    onevent!(conn, :end)    do _; Radio.next!(conn)       end
end

close(io)
```

Commands: `next!`, `prev!`, `shuffle!`, `order!`, `pick`, `list!`, `close!`.
Events: `:hello`, `:state`, `:track`, `:binary`, `:end`, `:interrupt`,
`:error`.

The radio URL is derived from the client's base URL (so `Client()` connects
to `wss://shaber.sherolld.com/api/radio` automatically).

---

BSD-3-Clause.
