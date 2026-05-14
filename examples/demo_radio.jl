using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using Shaber, Shaber.Radio

c = Client()
bytes_received = Ref(0)
tracks_played  = Ref(0)
target         = 2  # stop after this many tracks

io = open("/tmp/shaber-julia-radio.bin", "w")

Radio.run(c) do conn
    onevent!(conn, :hello)  do m
        println("catalog: $(m.count) tracks")
    end
    onevent!(conn, :state)  do m
        println("mode: $(m.mode)")
    end
    onevent!(conn, :track)  do m
        println("▶ #", lpad(m.index, 3, '0'), " ", m.name)
        bytes_received[] = 0
    end
    onevent!(conn, :binary) do d
        write(io, d)
        bytes_received[] += length(d)
    end
    onevent!(conn, :end)    do _
        tracks_played[] += 1
        println("  end of track ($(bytes_received[]) bytes)")
        if tracks_played[] >= target
            println("done — closing")
            Radio.close!(conn)
        else
            Radio.next!(conn)
        end
    end
    onevent!(conn, :error)  do m
        println("! ", m.message)
    end
end

close(io)
println("wrote /tmp/shaber-julia-radio.bin")
