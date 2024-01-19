#
try
    parse_pnml(xml"""<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml"></pnml>""", registry())
catch e
    showerror(stderr, e)
    println()
end

try
    parse_net(xml"<net type='test'></net>", registry())
catch e
    showerror(stderr,e)
    println()
end

Base.redirect_stdio(stdout=testshow, stderr=testshow) do;
    println("print simple petri net")
    for accessor in [places, transitions, arcs]
        map(println, places(snet))
        map(println, transitions(snet))
        map(println, arcs(snet))
        for (a,b) in zip(accessor(snet1), accessor(snet))
            @test pid(a) == pid(b)
        end
    end
end

Base.redirect_stdio(stdout=testshow, stderr=testshow) do;
    @show S T Δ
    #for t in PNML.transition_idset(snet)
    #    @show t
    #    @show collect(pairs(PNML.ins(snet, t)))
    #    @show collect(pairs(PNML.outs(snet, t)))
    #    @show collect(pairs(PNML.in_out(snet, t)))
    #end
    @show Δ.birth tfun.birth
end

Base.redirect_stdio(stdout=testshow, stderr=testshow) do;
    #show(anet)
    println("inscriptions"); map(println, PNML.inscriptions(anet))
    println("conditions"); map(println, PNML.conditions(anet))
    #@show PNML.name(anet)

    @show typeof(mg) mg
    @show Graphs.is_directed(mg)
    @show Graphs.is_connected(mg)
    @show Graphs.is_bipartite(mg)
    @show Graphs.ne(mg)
    @show Graphs.nv(mg)
    @show MetaGraphsNext.labels(mg) |> collect
    @show MetaGraphsNext.edge_labels(mg) |> collect
end

Base.redirect_stdio(stdout=testshow, stderr=testshow) do
    println("print net")
    map(println, arcs(net))
    map(println, places(net))
    map(println, transitions(net))
    map(println, refplaces(net))
    map(println, reftransitions(net))
    println("---------------")
    @show (collect ∘ values ∘ page_idset)(net)
    println("---------------")
end

# Base.redirect_stdio(stdout=testshow, stderr=testshow) do
#     @show pntd default_sort(pntd)
#     for sort in InteractiveUtils.subtypes(AbstractSort) # Only 1 layer of abstract!
#         @printf "%-20s %-20s %-20s\n" sort eltype(sort) sort()
#     end
# end
