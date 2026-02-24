# parse nodes of graph
"Fill place_set, place_dict."
function parse_place!(netsets, netdata, node, pntd, net::APN)
    pl = parse_place(node, pntd, net)::valtype(placedict(netdata))
    #@show valtype(placedict(netdata)) typeof(placedict(netdata))
    push!(place_idset(netsets), pid(pl))
    placedict(netdata)[pid(pl)] = pl
    return place_idset(netsets) #place_set
end

"Fill transition_set, transition_dict."
function parse_transition!(netsets, netdata, node, pntd, net::APN)
    tr = parse_transition(node, pntd, net)::valtype(transitiondict(netdata))
    push!(transition_idset(netsets), pid(tr))
    transitiondict(netdata)[pid(tr)] = tr
    return transition_idset(netsets)
end

"Fill arc_set, arc_dict."
function parse_arc!(netsets, netdata, node, pntd, net::APN)
    a = parse_arc(node, pntd, net)
    a isa valtype(arcdict(netdata)) ||
        @error("$(typeof(a)) not a $(valtype(arcdict(netdata)))) $pntd $(repr(a))")
    push!(arc_idset(netsets), pid(a))
    arcdict(netdata)[pid(a)] = a
    return arc_idset(netsets)
end

"Fill refplace_set, refplace_dict."
function parse_refPlace!(netsets, netdata, node, pntd, net::APN)
    rp = parse_refPlace(node, pntd, net)::valtype(refplacedict(netdata))
    push!(refplace_idset(netsets), pid(rp))
    refplacedict(netdata)[pid(rp)] = rp
    return refplace_idset(netsets)
end

"Fill reftransition_set, reftransition_dict."
function parse_refTransition!(netsets, netdata, node, pntd, net::APN)
    rt = parse_refTransition(node, pntd, net)::valtype(reftransitiondict(netdata))
    push!(reftransition_idset(netsets), pid(rt))
    reftransitiondict(netdata)[pid(rt)] = rt
    return reftransition_idset(netsets)
end


"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, pntd::APNTD, net::APN)
    check_nodename(node, "place")
    placeid = register_idof!(net.idregistry, node)
    D()&& println("## parse_place ", repr(placeid))
    mark = nothing

    # Get sorttype to use in parsing marking.
    sorttype::Maybe{SortType} = let typenode = firstchild(node, "type")
        if isnothing(typenode) # Deduce sort type of place if possible.
            if isa(pntd, AbstractHLCore) && !isa(pntd, PT_HLPNG)
                nothing # Deduce from initial marking.
            else
                SortType("default", Labels.default_typesort(pntd), net)
            end
        else
            parse_sorttype(typenode, pntd; net, parentid=placeid)
        end
    end

    namelabel::Maybe{Name}           = nothing
    graphics::Maybe{Graphics}        = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol, Any} = LittleDict{Symbol, Any}()

    for place_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(place_child))
        if tag == :initialMarking || tag == :hlinitialMarking tag == :fifoinitialMarking
            isnothing(sorttype) && @warn "$pntd parse_place $placeid sorttype is nothing"
            mark = net.labelparser[tag](place_child, sorttype, pntd; net, parentid=placeid)
        elseif tag == :type
            # we already handled this
        elseif tag == :name
            namelabel = net.labelparser[tag](place_child, pntd; net, parentid=placeid)
        elseif tag == :graphics
            graphics = net.labelparser[tag](place_child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, place_child, pntd, net) # place
        else
            unexpected_label!(extralabels, place_child, tag, pntd; net, parentid=placeid)
        end
    end

    if isnothing(mark) # Use additive identity of proper sort as default value.
        effective_sorttype = if ishighlevel(pntd) && isnothing(sorttype)
            #D()&&
            @error("$pntd parse_place $(repr(placeid)) has neither a mark nor sorttype, " *
                            "use :dot even if it is WRONG")
            SortType("dummy", NamedSortRef(:dot), net)
        else
            sorttype # Already parsed a <type> or default for non-HL.
        end
        mark = default(Marking, pntd, effective_sorttype, net)
    end

    if isnothing(sorttype) # Infer sortype of place from mark.
        D()&& @warn("$pntd parse_place $(repr(placeid)) infer sorttype ", mark)
        sorttype = SortType("default", basis(mark)::SortRef, net)
    end
    Place(placeid, mark, sorttype, namelabel, graphics, toolspecinfos, extralabels, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::APNTD, net::APN)
    check_nodename(node, "transition")
    transitionid = register_idof!(net.idregistry, node)
    D()&& println("## parse_transition ", repr(transitionid))

    cond::Maybe{PNML.Labels.Condition} = nothing

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for trans_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(trans_child))
        if tag == :condition
            cond = net.labelparser[tag](trans_child, pntd; net, parentid=transitionid)
        elseif tag == :name
            namelabel = net.labelparser[tag](trans_child, pntd; net, parentid=transitionid)
        elseif tag == :graphics
            graphics = net.labelparser[tag](trans_child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, trans_child, pntd, net)
        else
            unexpected_label!(extralabels,
                              trans_child, tag, pntd; net, parentid=transitionid)
        end
    end

    Transition(transitionid,
            something(cond, Labels.default(Labels.Condition, pntd, net)),
            namelabel, graphics, toolspecinfos, extralabels,
            Set{REFID}(),
            NamedTuple[], net)
end

"""
    parse_arc(node::XMLNode, pntd::APNTD) -> Arc

Construct an `Arc` with labels specialized for the APNTD.
"""
function parse_arc(node::XMLNode, pntd::APNTD, net::APN)
    check_nodename(node, "arc")
    arc_id = register_idof!(net.idregistry, node)

    source = Symbol(attribute(node, "source"))
    target = Symbol(attribute(node, "target"))
    inscription::Maybe{Any} = nothing # 2 kinds of inscriptions

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}}  = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()
    arc_type_label::Maybe{ArcType} = nothing

    D()&& println("## parse_arc $arc_id source $source -> target $target")

    for arc_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(arc_child))
        if tag == :inscription || tag == :hlinscription
            # Input arc inscription and source's marking/placesort must have equal Sorts.
            # Output arc inscription and target's marking/placesort must have equal Sorts.
            # Have IDREF to source & target place & transition.
            # They which must have been parsed and can be found in netdata.
            inscription = net.labelparser[tag](arc_child, source, target, pntd;
                            net, parentid=arc_id)
        elseif tag == :name
            namelabel = net.labelparser[tag](arc_child, pntd; net, parentid=arc_id)
        elseif tag == :arctype
            arc_type_label = net.labelparser[tag](arc_child, pntd; net, parentid=arc_id)
        elseif tag == :graphics
            graphics = net.labelparser[tag](arc_child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, arc_child, pntd, net)
        else
            unexpected_label!(extralabels, arc_child, tag, pntd; net, parentid=arc_id)
        end
    end

    # We are using REFIDs to access both the adjacent place in a dictionary.
    # This (an inscription) is an expression returning a ground term.
    # It may have non-ground terms as parameters.

    if isnothing(inscription)
        dummy_placetype = if ishighlevel(pntd)
            if pntd isa PT_HLPNG
                SortType("dummy PT_HLPNG", NamedSortRef(:dot), net)
            else
                # For other high-level nets, try to deduce using the adjacent place.
                # Note that the adjacent place may have not been parsed yet.
                sr = if has_place(net, source)
                    sortref(place(net, source))
                elseif has_place(net, target)
                    sortref(place(net, target))
                else
                    @error string("$pntd inscription not provided for ",
                                "arc $arc_id ($source -> $target), ",
                                "and we failed to deduce a sorttype, will use :dot.")
                    NamedSortRef(:dot)
                end
                SortType("dummy HIGHLEVEL", sr,  net)
           end
        elseif iscontinuous(pntd)
            SortType("dummy CONTINUOUS", NamedSortRef(:real), net)
        elseif isdiscrete(pntd)
            SortType("dummy DISCRETE", NamedSortRef(:positive), net)
        end
        inscription = default(Inscription, pntd, dummy_placetype, net)
    end

    if isnothing(arc_type_label)
        arc_type_label = ArcType()
        @assert isnormal(arc_type_label)
    end

    Arc(; id=arc_id, source=Ref(source), target=Ref(target),
        inscription, arctypelabel=arc_type_label, namelabel, graphics,
        toolspecinfos, extralabels, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::APNTD, net::APN)
    check_nodename(node, "referencePlace")
    refp_id = register_idof!(net.idregistry, node)
    D()&& println("## parse_refPlace ", repr(refp_id))

    ref = Symbol(attribute(node, "ref"))

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for refp_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(refp_child))
        if tag == :name
            namelabel = net.labelparser[tag](refp_child, pntd; net, parentid=refp_id)
        elseif tag == :graphics
            graphics =  net.labelparser[tag](refp_child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, refp_child, pntd, net)
        else
            unexpected_label!(extralabels, refp_child, tag, pntd; net, parentid=refp_id)
        end
    end

    RefPlace(refp_id, ref, namelabel, graphics, toolspecinfos, extralabels, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::APNTD, net::APN)
    check_nodename(node, "referenceTransition")
    reft_id = register_idof!(net.idregistry, node)
    D()&& println("## parse_refTransition ", repr(reft_id))

    ref = Symbol(attribute(node, "ref"))

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for reft_child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(reft_child))
        if tag == :name
            namelabel = net.labelparser[tag](reft_child, pntd; net, parentid=reft_id)
        elseif tag == :graphics
            graphics = net.labelparser[tag](reft_child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, reft_child, pntd, net)
        else
            unexpected_label!(extralabels, reft_child, tag, pntd; net, parentid=reft_id)
        end
    end

    RefTransition(reft_id, ref, namelabel, graphics, toolspecinfos, extralabels, net)
end
