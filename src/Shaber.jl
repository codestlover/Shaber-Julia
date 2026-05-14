"""
    Shaber

Julia client for the Shaber API.

```julia
using Shaber
c = Client()
println(health(c).uptimeSeconds)
println(wikiRandom(c, "en").title)
```

Every `/api/*` endpoint is a top-level function that takes a `Client` first.
Query params map to keyword args. Responses come back as `JSON3.Object`
(use `.field` or `[:field]`). Non-200 throws `ShaberError`.
"""
module Shaber

using HTTP, JSON3, URIs

export Client, ShaberError

# ------------------------------------------------------------------- types

"""
    Client(; baseUrl="https://shaber.sherolld.com", userAgent="shaber-julia", timeout=30)

HTTP client config. Cheap to build, safe to share across calls.
"""
struct Client
    baseUrl::String
    headers::Vector{Pair{String,String}}
    timeout::Int
end

function Client(; baseUrl::String="https://shaber.sherolld.com",
                  userAgent::String="shaber-julia",
                  timeout::Int=30)
    headers = ["Accept" => "application/json", "User-Agent" => userAgent]
    Client(baseUrl, headers, timeout)
end

"""
    ShaberError(status, path, body)

Thrown when a Shaber endpoint replies with a non-200 status.
"""
struct ShaberError <: Exception
    status::Int
    path::String
    body::String
end
Base.showerror(io::IO, e::ShaberError) =
    print(io, "Shaber HTTP $(e.status) on $(e.path): ", first(e.body, 200))

# ------------------------------------------------------------------- internal

# Build a `?k=v&…` query string from a NamedTuple or Dict, dropping nothing/empty.
function _qs(query)
    isnothing(query) && return ""
    parts = String[]
    for (k, v) in pairs(query)
        v === nothing && continue
        v isa AbstractString && isempty(v) && continue
        push!(parts, string(k) * "=" * URIs.escapeuri(string(v)))
    end
    isempty(parts) ? "" : "?" * join(parts, "&")
end

function _get(c::Client, path::AbstractString; query=nothing)
    url = c.baseUrl * path * _qs(query)
    resp = HTTP.get(url; headers=c.headers, readtimeout=c.timeout,
                    status_exception=false, retry=false)
    if resp.status != 200
        throw(ShaberError(resp.status, path, String(resp.body)))
    end
    return isempty(resp.body) ? nothing : JSON3.read(resp.body)
end

include("HTTPEndpoints.jl")
include("Radio.jl")

end # module Shaber
