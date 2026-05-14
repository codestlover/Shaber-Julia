# Shaber-Julia docs

A walkthrough of every function on the Shaber Julia client, grouped by what
they talk to on the server. Response shapes (JSON keys, types, what each
field means) live in the API docs at https://shaber.sherolld.com/docs. This
page covers the Julia side: signatures, what they take, what they return.

## Setup

```julia
using Shaber
c = Client()
```

`Client` keyword args:

```julia
Client(;
    userAgent = "my-bot",   # defaults to "shaber-julia"
    timeout   = 30,         # seconds; defaults to 30
)
```

Every function below returns a parsed `JSON3.Object` (or `JSON3.Array`) on
success. Access fields with `.field` or `[:field]`. Non-200 responses throw
`ShaberError`:

```julia
try
    user(c, "does-not-exist")
catch e isa ShaberError
    @info "missing" e.status e.path
end
```

## Meta

| Function | What it does |
|---|---|
| `manifest(c)` | The self-describing manifest at `/api`. List of every endpoint with method, path, summary, category. |
| `health(c)`   | Liveness check. `(ok, uptimeSeconds)`. |

## Daily stats

| Function | What it does |
|---|---|
| `stats(c)` | One-shot snapshot of the Spore.com counters (uploads, users, ratings, ...). Cached upstream for 5 min. |

## Creatures

| Function | What it does |
|---|---|
| `creature(c, id)` | The full attribute sheet for a creature: stats, parts, tags, dimensions. |

## Assets

These cover every kind of asset (creatures, vehicles, buildings, adventures,
captains, sporecasts).

| Function | What it does |
|---|---|
| `asset(c, id)`                                     | Asset metadata: id, type, name, tagline, owner, ratings, tags. |
| `assetComments(c, id; start=0, len=10)`            | Comment thread on an asset. |
| `assetDownload(c, id)`                             | The legacy XML payload (`xml_data`) needed to import an asset back into Spore. |
| `assetLineage(c, id)`                              | Parent/remix chain of an asset. |

## Users

| Function | What it does |
|---|---|
| `user(c, name)`                                    | User profile: id, tagline, image. |
| `userAssets(c, name; start=0, len=10)`             | Assets the user uploaded. |
| `userSporecasts(c, name)`                          | Sporecasts the user owns. |
| `userAchievements(c, name; start=0, len=10)`       | Achievement history. |
| `userBuddies(c, name; start=0, len=10)`            | Outgoing buddy list. |
| `userSubscribers(c, name; start=0, len=10)`        | Users subscribed to this one. |
| `userTrophies(c, name)`                            | Trophies / badges. |
| `userCaptain(c, name)`                             | The user's space-stage captain (if any). |
| `userStats(c, name)`                               | Aggregate counts: uploads, downloads, subscribers, total ratings. |

## Sporecasts

| Function | What it does |
|---|---|
| `sporecastAssets(c, id; start=0, len=10)` | Every asset in a sporecast. |

## Search & catalog

| Function | What it does |
|---|---|
| `search(c; view, type, start=0, len=10)`  | Browse-style search. `view` is the sort (e.g. `"NEWEST"`, `"TOP_RATED"`), `type` filters by asset kind. |
| `searchText(c, q; type)`                  | Full-text Sporepedia search for `q`. |
| `trending(c, range)`                      | Trending uploads. `range` is `"today"`, `"week"`, `"month"`, ... |
| `featuredAssets(c)`                       | Maxis-featured assets. |
| `featuredSporecasts(c)`                   | Maxis-featured sporecasts. |
| `tags(c)`                                 | The site-wide tag cloud, sorted by use count. |

## Adventures & captains

| Function | What it does |
|---|---|
| `adventureLeaderboard(c, id; scope="global")` | Leaderboard rows for an adventure. |
| `captain(c, assetId)`                         | Captain build for an asset id (the space-stage incarnation). |

## Wiki

The Spore Fandom MediaWiki proxied across ten languages. `lang` is a
two-letter code: `"en"`, `"de"`, `"es"`, `"fr"`, `"it"`, `"ja"`, `"pl"`,
`"pt"`, `"ru"`, `"zh"`.

| Function | What it does |
|---|---|
| `wikiSearch(c, lang, q; limit=10, offset=0)`        | Full-text wiki search. |
| `wikiPage(c, lang, title; format="both")`           | Fetch a page. `format` is `"html"`, `"wikitext"` or `"both"`. |
| `wikiRandom(c, lang)`                                | A random page. |
| `wikiCategory(c, lang, name; limit=10, cursor)`     | Members of a category. |
| `wikiRecent(c, lang; limit=10, cursor)`             | Recent edits. |
| `wikiPages(c, lang; limit=10, cursor)`              | All pages (paginated). |
| `wikiInfo(c, lang)`                                  | Per-language wiki stats: page count, edits, users. |
| `wikiLanglinks(c, lang, title)`                      | Translations of a page in other languages. |
| `wikiCategories(c, lang, title)`                     | Categories a page belongs to. |
| `wikiBacklinks(c, lang, title; limit=10, cursor)`   | Pages that link to this one. |
| `wikiEmbeddedIn(c, lang, title; limit=10, cursor)`  | Pages that transclude this template. |
| `wikiImages(c, lang; limit=10, cursor)`             | Image files on the wiki. |
| `wikiFile(c, lang, name)`                            | Metadata + URL for a single image. |

Pagination knobs vary by endpoint: most accept `limit` + `cursor` (server
returns the next cursor in the response), a few use `start` + `len`.

## Radio

The `/api/radio` WebSocket lives in a sub-module:

```julia
using Shaber, Shaber.Radio

Radio.run(Client()) do conn
    onevent!(conn, :hello)  do m; @info "catalog" m.count end
    onevent!(conn, :track)  do m; @info m.name            end
    onevent!(conn, :binary) do d; write(io, d)            end
    onevent!(conn, :end)    do _; Radio.next!(conn)       end
end
```

`Radio.run` opens a WS to `wss://shaber.sherolld.com/api/radio`. The block
runs once with the connection object (register handlers there) and the
function blocks until the peer closes or `close!(conn)` is called.

### Event handlers

```julia
onevent!(conn, event::Symbol, fn)
# or, with do-block:
onevent!(conn, :hello) do msg
    ...
end
```

Events:

| Event | Payload | When |
|---|---|---|
| `:hello`     | `(count, tracks)` | Once per connection. `tracks` is the full catalog. |
| `:state`     | `(mode,)`         | Mode change (`"order"` or `"shuffle"`). |
| `:track`     | `(index, name, file, mime, bytes)` | About to send a new track. |
| `:binary`    | `Vector{UInt8}`   | An audio chunk. |
| `:end`       | empty             | Current track fully delivered. |
| `:interrupt` | empty             | Track aborted because you sent `next`/`prev`/`pick`. |
| `:error`     | `(message,)`      | Server-side or socket error. |

### Commands

| Function | Wire | Effect |
|---|---|---|
| `Radio.next!(conn)`     | `next`     | Advance one track. |
| `Radio.prev!(conn)`     | `prev`     | Back one track. |
| `Radio.shuffle!(conn)`  | `shuffle`  | Toggle shuffle on. |
| `Radio.order!(conn)`    | `order`    | Toggle shuffle off. |
| `Radio.list!(conn)`     | `list`     | Re-send the `hello` catalog. |
| `Radio.pick(conn, q)`   | `=<q>`     | Jump to the first track whose filename contains `q`. |
| `Radio.close!(conn)`    | --         | Graceful shutdown of the socket. |

## Errors

`ShaberError` carries `status`, `path`, and `body` (the first 200 chars).

```julia
try
    user(c, "does-not-exist")
catch e isa ShaberError
    @info "missing user" e.status e.path
end
```
