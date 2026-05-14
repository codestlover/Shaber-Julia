"""
    Radio

WebSocket client for Shaber's `/api/radio`. Audio chunks come as binary
frames, control messages as JSON.

```julia
using Shaber, Shaber.Radio

c = Client()
io = open("out.opus", "w")

Radio.run(c) do conn
    onevent!(conn, :hello)  do m; @info "catalog \$(m.count) tracks"  end
    onevent!(conn, :track)  do m; @info "now playing \$(m.name)"      end
    onevent!(conn, :binary) do d; write(io, d)                        end
    onevent!(conn, :end)    do _; Radio.next!(conn)                   end
end
```

The block blocks until the peer closes or you call `close!(conn)`. Handlers
all run on the same task.
"""
module Radio

using HTTP, JSON3
import ..Shaber: Client

export RadioConn, onevent!, send_cmd, next!, prev!, shuffle!, order!, pick, list!, close!, run

const EVENTS = (:hello, :state, :track, :end, :interrupt, :error, :binary)

mutable struct RadioConn
    ws::Any
    handlers::Dict{Symbol,Vector{Function}}
    open::Bool
end

RadioConn() = RadioConn(nothing, Dict(e => Function[] for e in EVENTS), true)

"""    onevent!(conn, event::Symbol, fn)

Register an event handler. `event` is one of `:hello`, `:state`, `:track`,
`:end`, `:interrupt`, `:error`, `:binary`. Multiple handlers per event run
in registration order.

Returns `conn` so you can chain.
"""
function onevent!(conn::RadioConn, event::Symbol, fn::Function)
    haskey(conn.handlers, event) || error("Shaber.Radio: unknown event :$event")
    push!(conn.handlers[event], fn)
    return conn
end
# variant for `do`-block syntax: onevent!(conn, :hello) do m … end
onevent!(fn::Function, conn::RadioConn, event::Symbol) = onevent!(conn, event, fn)

send_cmd(conn::RadioConn, cmd::AbstractString) =
    (HTTP.WebSockets.send(conn.ws, cmd); conn)

next!(c)    = send_cmd(c, "next")
prev!(c)    = send_cmd(c, "prev")
shuffle!(c) = send_cmd(c, "shuffle")
order!(c)   = send_cmd(c, "order")
list!(c)    = send_cmd(c, "list")
pick(c, q)  = send_cmd(c, "=" * String(q))

close!(conn::RadioConn) = (conn.open = false; HTTP.WebSockets.close(conn.ws); conn)

function _dispatch(conn::RadioConn, event::Symbol, payload)
    for fn in conn.handlers[event]
        try
            fn(payload)
        catch err
            @warn "Shaber.Radio handler for :$event threw" exception=(err, catch_backtrace())
        end
    end
end

"""
    run([fn,] client::Client = Client()) -> RadioConn

Open a WebSocket to `/api/radio`. If `fn` is given, it runs with the
connection object before the receive loop starts (that's where you register
handlers). Blocks until the peer closes or `close!(conn)` is called.
"""
function run(fn::Union{Function,Nothing}, client::Client = Client())
    wsScheme = startswith(client.baseUrl, "https") ? "wss" : "ws"
    host     = replace(client.baseUrl, r"^https?://" => "")
    url      = "$wsScheme://$host/api/radio"
    conn     = RadioConn()
    HTTP.WebSockets.open(url) do ws
        conn.ws = ws
        if fn !== nothing
            fn(conn)
        end
        for raw in ws
            conn.open || break
            if raw isa AbstractString
                msg = try JSON3.read(raw) catch _; nothing end
                if msg !== nothing && haskey(msg, :type)
                    ev = Symbol(msg.type)
                    if ev in EVENTS
                        _dispatch(conn, ev, msg)
                    end
                end
            else
                _dispatch(conn, :binary, raw)
            end
        end
    end
    return conn
end

run(client::Client = Client()) = run(nothing, client)

end # module Radio
