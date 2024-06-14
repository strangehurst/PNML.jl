#=
using PNML, EzXML, JET, AbstractTrees, PrettyTables
using PNML:
    Maybe, tag, labels, firstpage, first_net, nettype,
    PnmlNet, Page, pages, pid,
    arc, arcs, place, places, transition, transitions,
    refplace, refplaces, reftransition, reftransitions,
    place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset,
    flatten_pages!, nets,
    place_type, transition_type, arc_type, refplace_type, reftransition_type,
    initial_markings,
    arc_type, place_type, transition_type,
    condition_type, condition_value_type,
    sort_type,
    inscription_type, inscription_value_type,
    marking_type, marking_value_type, page_type, refplace_type, reftransition_type,
    rate_value_type,
    default_inscription,
    default_marking,
    default_condition,
=#
using Printf

function showme(net) #TODO iterate on nets

    type_funs = (
        arc_type,
        place_type,
        transition_type,
        condition_type,
        condition_value_type,
        sort_type,
        inscription_type,
        inscription_value_type,
        marking_type,
        marking_value_type,
        net_type,
        page_type,
        refplace_type,
        reftransition_type,
        rate_value_type,
        )

    def_funs = (
        default_inscription,
        default_marking,
        default_condition,
        )

    PNTD = PNML.all_nettypes()
    println()
    println("#----------")
    println("# types: $type_funs")
    println()
    println("### lookup types by net")
    println()
    r1 = Any[]
    for fun in type_funs
        push!(r1, (nameof(fun), typeof(net), "$fun($(typeof(net)))", fun(net)))
        @printf "%-45s %s\n" "$fun(net)"  fun(net)
    end
    println()
    println()
    println("### lookup types by singleton")
    println()
    r2 = Any[]
    for fun in type_funs
        for pntd in PNTD
            push!(r2, (nameof(fun), pntd, "$fun($pntd)", fun(pntd)))
            @printf "%-45s %s\n" "$fun($pntd)"  fun(pntd)
        end
        println()
    end


    println()
    println("### lookup types by type")
    println()
    r3 = Any[]
    for fun in type_funs
        for T in typeof.(PNTD)
            push!(r3, (nameof(fun), T, "$fun($T)", fun(T)))
            #println("$fun($T) \t", fun(T))
            @printf "%-45s %s\n" "$fun($T)"  fun(T)
        end
        println()
    end
    println()
    println("#----------")
    println("# defaults: $def_funs")
    println()
    r4 = Any[]
    for def in def_funs
        for pntd in PNTD
            push!(r4, (nameof(def), pntd, "$def($pntd)", def(pntd)))
            #println("$def($pntd) \t", def(pntd))
            @printf "%-45s %s\n" "$def($pntd)"  def(pntd)
        end
        println()
    end
    println()
end
