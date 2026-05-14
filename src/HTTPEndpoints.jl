# Every Shaber HTTP endpoint as a top-level function. Each is 1:1 with the
# manifest at /api. Order matches `src/Shaber/Api/Index.hs`.

# ------------------------------------------------------------------ meta

"""    manifest(c::Client)

`GET /api` — self-describing API manifest.
"""
manifest(c::Client) = _get(c, "/api")

"""    health(c::Client)

`GET /api/health` — server liveness + uptime.
"""
health(c::Client) = _get(c, "/api/health")

# ------------------------------------------------------------------ legacy mirror

"""    stats(c::Client)

`GET /api/stats` — daily site stats.
"""
stats(c::Client) = _get(c, "/api/stats")

"""    creature(c::Client, id)

`GET /api/creatures/:id` — creature attribute sheet.
"""
creature(c::Client, id) = _get(c, "/api/creatures/$id")

asset(c::Client, id) = _get(c, "/api/assets/$id")

assetComments(c::Client, id; start::Int=0, len::Int=10) =
    _get(c, "/api/assets/$id/comments"; query=(start=start, len=len))

assetDownload(c::Client, id) = _get(c, "/api/assets/$id/download")
assetLineage(c::Client, id)  = _get(c, "/api/assets/$id/lineage")

user(c::Client, name) = _get(c, "/api/users/$(URIs.escapeuri(name))")

userAssets(c::Client, name; start::Int=0, len::Int=10) =
    _get(c, "/api/users/$(URIs.escapeuri(name))/assets"; query=(start=start, len=len))

userSporecasts(c::Client, name) =
    _get(c, "/api/users/$(URIs.escapeuri(name))/sporecasts")

userAchievements(c::Client, name; start::Int=0, len::Int=10) =
    _get(c, "/api/users/$(URIs.escapeuri(name))/achievements"; query=(start=start, len=len))

userBuddies(c::Client, name; start::Int=0, len::Int=10) =
    _get(c, "/api/users/$(URIs.escapeuri(name))/buddies"; query=(start=start, len=len))

userSubscribers(c::Client, name; start::Int=0, len::Int=10) =
    _get(c, "/api/users/$(URIs.escapeuri(name))/subscribers"; query=(start=start, len=len))

sporecastAssets(c::Client, id; start::Int=0, len::Int=10) =
    _get(c, "/api/sporecasts/$id/assets"; query=(start=start, len=len))

"""
    search(c::Client; view="TOP_RATED", type=nothing, start=0, len=10)

`GET /api/search` — browse assets by view + type.
"""
search(c::Client; view::AbstractString="TOP_RATED",
                  type::Union{Nothing,AbstractString}=nothing,
                  start::Int=0, len::Int=10) =
    _get(c, "/api/search"; query=(view=view, type=type, start=start, len=len))

# ------------------------------------------------------------------ sporepedia

searchText(c::Client, q::AbstractString; type::Union{Nothing,AbstractString}=nothing) =
    _get(c, "/api/search/text"; query=(q=q, type=type))

userTrophies(c::Client, name) = _get(c, "/api/users/$(URIs.escapeuri(name))/trophies")

featuredAssets(c::Client)     = _get(c, "/api/featured/assets")
featuredSporecasts(c::Client) = _get(c, "/api/featured/sporecasts")

"""    trending(c::Client, range)

`GET /api/trending/:range` — range ∈ {"day", "week", "month", "all"}.
"""
trending(c::Client, range::AbstractString) = _get(c, "/api/trending/$range")

adventureLeaderboard(c::Client, id; scope::AbstractString="world") =
    _get(c, "/api/adventures/$id/leaderboard"; query=(scope=scope,))

captain(c::Client, assetId) = _get(c, "/api/captains/$assetId")

userCaptain(c::Client, name) = _get(c, "/api/users/$(URIs.escapeuri(name))/captain")
userStats(c::Client, name)   = _get(c, "/api/users/$(URIs.escapeuri(name))/stats")

tags(c::Client) = _get(c, "/api/tags")

# ------------------------------------------------------------------ wiki

const WIKI_LANGS = ("en", "ru", "de", "es", "fi", "it", "nl", "nn", "pl", "pt", "tr")

wikiSearch(c::Client, lang::AbstractString, q::AbstractString;
           limit::Int=10, offset::Int=0) =
    _get(c, "/api/wiki/$lang/search"; query=(q=q, limit=limit, offset=offset))

"""
    wikiPage(c::Client, lang, title; format="both")

`GET /api/wiki/:lang/page/:title` — format ∈ {"html", "wikitext", "both"}.
"""
wikiPage(c::Client, lang::AbstractString, title::AbstractString;
         format::AbstractString="both") =
    _get(c, "/api/wiki/$lang/page/$(URIs.escapeuri(title))"; query=(format=format,))

wikiRandom(c::Client, lang::AbstractString) = _get(c, "/api/wiki/$lang/random")

wikiCategory(c::Client, lang::AbstractString, name::AbstractString;
             limit::Int=10, cursor::Union{Nothing,AbstractString}=nothing) =
    _get(c, "/api/wiki/$lang/category/$(URIs.escapeuri(name))";
         query=(limit=limit, cursor=cursor))

wikiRecent(c::Client, lang::AbstractString;
           limit::Int=10, cursor::Union{Nothing,AbstractString}=nothing) =
    _get(c, "/api/wiki/$lang/recent"; query=(limit=limit, cursor=cursor))

wikiPages(c::Client, lang::AbstractString;
          limit::Int=20, cursor::Union{Nothing,AbstractString}=nothing) =
    _get(c, "/api/wiki/$lang/pages"; query=(limit=limit, cursor=cursor))

wikiInfo(c::Client, lang::AbstractString) = _get(c, "/api/wiki/$lang/info")

wikiLanglinks(c::Client, lang::AbstractString, title::AbstractString) =
    _get(c, "/api/wiki/$lang/page/$(URIs.escapeuri(title))/langlinks")

wikiCategories(c::Client, lang::AbstractString, title::AbstractString) =
    _get(c, "/api/wiki/$lang/page/$(URIs.escapeuri(title))/categories")

wikiBacklinks(c::Client, lang::AbstractString, title::AbstractString;
              limit::Int=10, cursor::Union{Nothing,AbstractString}=nothing) =
    _get(c, "/api/wiki/$lang/page/$(URIs.escapeuri(title))/backlinks";
         query=(limit=limit, cursor=cursor))

wikiEmbeddedIn(c::Client, lang::AbstractString, title::AbstractString;
               limit::Int=10, cursor::Union{Nothing,AbstractString}=nothing) =
    _get(c, "/api/wiki/$lang/page/$(URIs.escapeuri(title))/embeddedin";
         query=(limit=limit, cursor=cursor))

wikiImages(c::Client, lang::AbstractString;
           limit::Int=10, cursor::Union{Nothing,AbstractString}=nothing) =
    _get(c, "/api/wiki/$lang/images"; query=(limit=limit, cursor=cursor))

wikiFile(c::Client, lang::AbstractString, name::AbstractString) =
    _get(c, "/api/wiki/$lang/file/$(URIs.escapeuri(name))")

# ------------------------------------------------------------------ exports

export manifest, health, stats, creature, asset, assetComments, assetDownload,
       assetLineage, user, userAssets, userSporecasts, userAchievements,
       userBuddies, userSubscribers, sporecastAssets, search, searchText,
       userTrophies, featuredAssets, featuredSporecasts, trending,
       adventureLeaderboard, captain, userCaptain, userStats, tags,
       wikiSearch, wikiPage, wikiRandom, wikiCategory, wikiRecent, wikiPages,
       wikiInfo, wikiLanglinks, wikiCategories, wikiBacklinks, wikiEmbeddedIn,
       wikiImages, wikiFile,
       WIKI_LANGS
