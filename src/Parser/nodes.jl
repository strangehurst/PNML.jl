#
"Fill place_set, place_dict."
function parse_place!(place_set, netdata, child, pntd)
    pl = parse_place(child, pntd)::valtype(netdata.place_dict)
    push!(place_set, pid(pl))
    netdata.place_dict[pid(pl)] = pl
    return place_set
end

"Fill transition_set, transition_dict."
function parse_transition!(transition_set, netdata, child, pntd)
    tr = parse_transition(child, pntd)::valtype(netdata.transition_dict)
    push!(transition_set, pid(tr))
    netdata.transition_dict[pid(tr)] = tr
    return transition_set
end

"Fill arc_set, arc_dict."
function parse_arc!(arc_set, netdata, child, pntd)
    a = parse_arc(child, pntd; netdata)
    a isa valtype(PNML.arcdict(netdata)) ||
        @error("$(typeof(a)) not a $(valtype(PNML.arcdict(netdata)))) $pntd $(repr(a))")
    push!(arc_set, pid(a))
    netdata.arc_dict[pid(a)] = a
    return arc_set
end

"Fill refplace_set, refplace_dict."
function parse_refPlace!(refplace_set, netdata, child, pntd)
    rp = parse_refPlace(child, pntd)::valtype(netdata.refplace_dict)
    push!(refplace_set, pid(rp))
    netdata.refplace_dict[pid(rp)] = rp
    return refplace_set
end

"Fill reftransition_set, reftransition_dict."
function parse_refTransition!(reftransition_set, netdata, child, pntd)
    rt = parse_refTransition(child, pntd)::valtype(netdata.reftransition_dict)
    push!(reftransition_set, pid(rt))
    netdata.reftransition_dict[pid(rt)] = rt
    return reftransition_set
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "place")
    id   = register_idof!(idregistry[], node)
    mark = nothing
    sorttype::Maybe{SortType} = nothing
    name::Maybe{Name}         = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}   = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing

    # Parse using known structure.
    # First get sorttype.
    typenode = firstchild(node, "type")
    if !isnothing(typenode)
        sorttype = parse_sorttype(typenode, pntd)
    else
        #@warn("default sorttype $pntd $(repr(id))", default_typeusersort(pntd))
        sorttype = SortType("default", Labels.default_typeusersort(pntd), nothing, nothing)
    end
    #@warn "parse_place $id" sorttype

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "initialMarking" || tag == "hlinitialMarking"
            #! Maybe sorttype is infered from marking?
            mark = _parse_marking(child, sorttype, pntd)
        elseif tag == "type"
            # we already handled this
        elseif tag == "name"
            name = parse_name(child, pntd)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd)
        else # labels (unclaimed) are everything-else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected label of <place>: $tag"
            labels = add_label(labels, child, pntd)
        end
    end

    if isnothing(mark)
        if ishighlevel(pntd)
            mark = Labels.default_hlmarking(pntd, sorttype) # additive identity of multiset
        else
            mark = Labels.default_marking(pntd) # additive identity of number
        end
    end

    if isnothing(sorttype) # Infer sortype of place from mark?
        #~ NB: must support pnmlcore, no high-level stuff unless it is backported to pnmlcore.
        @error("infer sorttype", PNML.value(mark), sortof(mark), basis(mark))
        sorttype = SortType("default", basis(mark)::UserSort, nothing, nothing)
    end

    #! These are TermInterface expressions. Test elsewhere, after eval.
    # The basis sort of mark label must be the same as the sort of sorttype label.
    # if !equal(sortof(basis(mark)), sortof(sorttype))
    #     error(string("place $(repr(id)) of $pntd: sort mismatch,",
    #                     "\n\t sortof(basis(mark)) = ", sortof(basis(mark)),
    #                     "\n\t sortof(sorttype) = ", sortof(sorttype)))
    # end

    Place(pntd, id, mark, sorttype, name, graphics, tools, labels)
end


# Calls marking parser specialized on the pntd.
_parse_marking(node::XMLNode, placetype, pntd::T) where {T<:PnmlType} =
    parse_initialMarking(node, placetype, pntd)

_parse_marking(node::XMLNode, placetype, pntd::T) where {T<:AbstractHLCore} =
    parse_hlinitialMarking(node, placetype, pntd)
