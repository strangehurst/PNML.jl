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
            tools = add_toolinfo(tools, child, pntd) # place
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

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "transition")
    id = register_idof!(idregistry[], node)
    name::Maybe{Name} = nothing
    cond::Maybe{PNML.Labels.Condition} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "condition"
            cond = parse_condition(child, pntd)
        elseif tag == "name"
            name = parse_name(child, pntd)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd) # transition
        else # Labels (unclaimed) are everything-else. We expect at least one here!
            #! Create extension point here? Add more tag names to list?
            any(==(tag), transition_xlabels) ||
                @warn "unexpected label of <transition> id=$id: $tag"
            labels = add_label(labels, child, pntd)
        end
    end

    Transition{typeof(pntd), PNML.condition_type(pntd)}(pntd, id,
                something(cond, Labels.default_condition(pntd)), name, graphics, tools, labels,
                Set{REFID}(), NamedTuple[])
end

"""
    parse_arc(node::XMLNode, pntd::PnmlType) -> Arc

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node::XMLNode, pntd::PnmlType; netdata)
    check_nodename(node, "arc")
    arcid = register_idof!(idregistry[], node)
    source = Symbol(attribute(node, "source"))
    target = Symbol(attribute(node, "target"))

    name::Maybe{Name} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing
    inscription::Maybe{Any} = nothing # 2 kinds of inscriptions
    graphics::Maybe{Graphics} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "inscription" || tag == "hlinscription"
            # Input arc inscription and source's marking/placesort must have equal Sorts.
            # Output arc inscription and target's marking/placesort must have equal Sorts.
            # Have IDREF to source & target place & transition.
            # They which must have been parsed and can be found in netdata.
            inscription = _parse_inscription(child, source, target, pntd; netdata)
        elseif tag == "name"
            name = parse_name(child, pntd)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd) # arc
        else # labels (unclaimed) are everything-else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected child of <arc>: $tag"
            labels = add_label(labels, child, pntd)
        end
    end
    if isnothing(inscription)
        inscription = if ishighlevel(pntd)
            Labels.default_hlinscription(pntd, SortType("default", UserSort(:dot)))
        else
            Labels.default_inscription(pntd)
        end
        #@info("missing inscription for arc $(repr(arcid)), replace with $(repr(inscription))")
    end
    Arc(arcid, Ref(source), Ref(target), inscription, name, graphics, tools, labels)
end

# By specializing arc inscription label parsing we hope to return stable type.
function _parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::PnmlType;
                    netdata)
    parse_inscription(node, source, target, pntd) #! , netdata)
end
function _parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::T;
                    netdata) where {T<:AbstractHLCore}
    parse_hlinscription(node, source, target, pntd; netdata)
    # `netdata` used to find adjacent place's sorttype.
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "referencePlace")
    id = register_idof!(idregistry[], node)
    ref = Symbol(attribute(node, "ref"))
    name::Maybe{Name} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing
    graphics::Maybe{Graphics} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            name => parse_name(child, pntd)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd) # refPlace
        else # labels (unclaimed) are everything-else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected child of <referencePlace>: $tag"
            labels = add_label(labels, child, pntd)
        end
    end

    RefPlace(id, ref, name, graphics, tools, labels)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "referenceTransition")
    id = register_idof!(idregistry[], node)
    ref = Symbol(attribute(node, "ref"))
    name::Maybe{Name} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    labels::Maybe{Vector{PnmlLabel}}= nothing
    graphics::Maybe{Graphics} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            name = parse_name(child, pntd)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd) # refTransition
        else # labels (unclaimed) are everything-else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected child of <referenceTransition>: $tag"
            labels = add_label(labels, child, pntd)
        end
    end

    RefTransition(id, ref, name, graphics, tools, labels)
end


# Calls marking parser specialized on the pntd.
_parse_marking(node::XMLNode, placetype, pntd::T) where {T<:PnmlType} =
    parse_initialMarking(node, placetype, pntd)

_parse_marking(node::XMLNode, placetype, pntd::T) where {T<:AbstractHLCore} =
    parse_hlinitialMarking(node, placetype, pntd)
