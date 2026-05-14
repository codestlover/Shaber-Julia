using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using Shaber

c = Client()

println("--- health ---")
h = health(c)
println("ok=$(h.ok)  uptime=$(h.uptimeSeconds)s")

println("\n--- stats ---")
s = stats(c)
println("totalUploads=$(s.totalUploads)  totalUsers=$(s.totalUsers)  dayUsers=$(s.dayUsers)")

println("\n--- wiki: random (en) ---")
r = wikiRandom(c, "en")
println("#$(r.pageid)  $(r.title)")

println("\n--- wiki: Creature page (html len) ---")
p = wikiPage(c, "en", "Creature"; format="html")
println("html bytes: ", length(something(p.html, "")))

println("\n--- manifest endpoint count ---")
m = manifest(c)
println("endpoints: ", length(m.endpoints))
