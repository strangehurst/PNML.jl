# parse nodes of graph
"Fill place_set, place_dict."
function parse_place!(netsets, netdata, child, pntd; parse_context::ParseContext)
    pl = parse_place(child, pntd; parse_context)::valtype(PNML.placedict(netdata))
    push!(place_idset(netsets), pid(pl))
    PNML.placedict(netdata)[pid(pl)] = pl
    return place_idset(netsets) #place_set
end

"Fill transition_set, transition_dict."
function parse_transition!(netsets, netdata, child, pntd; parse_context::ParseContext)
    tr = parse_transition(child, pntd; parse_context)::valtype(PNML.transitiondict(netdata))
    push!(transition_idset(netsets), pid(tr))
    PNML.transitiondict(netdata)[pid(tr)] = tr
    return transition_idset(netsets)
end

"Fill arc_set, arc_dict."
function parse_arc!(netsets, netdata, child, pntd; parse_context::ParseContext)
    a = parse_arc(child, pntd; netdata, parse_context)
    a isa valtype(PNML.arcdict(netdata)) ||
        @error("$(typeof(a)) not a $(valtype(PNML.arcdict(netdata)))) $pntd $(repr(a))")
    push!(arc_idset(netsets), pid(a))
    PNML.arcdict(netdata)[pid(a)] = a
    return arc_idset(netsets)
end

"Fill refplace_set, refplace_dict."
function parse_refPlace!(netsets, netdata, child, pntd; parse_context::ParseContext)
    rp = parse_refPlace(child, pntd; parse_context)::valtype(PNML.refplacedict(netdata))
    push!(refplace_idset(netsets), pid(rp))
    PNML.refplacedict(netdata)[pid(rp)] = rp
    return refplace_idset(netsets)
end

"Fill reftransition_set, reftransition_dict."
function parse_refTransition!(netsets, netdata, child, pntd; parse_context::ParseContext)
    rt = parse_refTransition(child, pntd; parse_context)::valtype(PNML.reftransitiondict(netdata))
    push!(reftransition_idset(netsets), pid(rt))
    PNML.reftransitiondict(netdata)[pid(rt)] = rt
    return reftransition_idset(netsets)
end


"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "place")
    placeid = register_idof!(parse_context.idregistry, node)

    # Place Node Labels
    mark = nothing

    # Get sorttype to use in parsing marking.
    sorttype = let typenode = firstchild(node, "type")
        if !isnothing(typenode)
            parse_sorttype(typenode, pntd; parse_context)
        else
            SortType("default",
                        Labels.default_typeusersort(pntd)::SortRef,
                        nothing, nothing, parse_context.ddict)
        end
    end
    #TODO capacity label

    namelabel::Maybe{Name}           = nothing
    graphics::Maybe{Graphics}        = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}}   = nothing
    extralabels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "initialMarking" || tag == "hlinitialMarking"
            #! Maybe sorttype is infered from marking?
            mark = _parse_marking(child, sorttype, pntd; parse_context)
        elseif tag == "type"
            # we already handled this

        elseif tag == "name"
            namelabel = parse_name(child, pntd; parse_context)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context) # place
        else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected label of <place>: $tag"
            extralabels = add_label(extralabels, child, pntd, parse_context)
        end
    end

    if isnothing(mark) # Use  additive identity of proper sort.
         mark = if ishighlevel(pntd)
            default(Marking, pntd, sorttype; parse_context.ddict)
        else
            dummy = SortType("unused", UserSortRef(:integer), parse_context.ddict)
            default(Marking, pntd, dummy; parse_context.ddict)
        end
    end

    if isnothing(sorttype) # Infer sortype of place from mark?
        #~ NB: must support pnmlcore, no high-level stuff unless it is backported to pnmlcore.
        @error("infer sorttype", PNML.value(mark), sortof(mark), basis(mark))
        sorttype = SortType("default", basis(mark)::SortRef, nothing, nothing, decldict(mark))
    end
    Place(pntd, placeid, mark, sorttype, namelabel, graphics, toolspecinfos, extralabels, parse_context.ddict)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "transition")
    transitionid = register_idof!(parse_context.idregistry, node)

    cond::Maybe{PNML.Labels.Condition} = nothing

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "condition"
            cond = parse_condition(child, pntd; parse_context)
        elseif tag == "name"
            namelabel = parse_name(child, pntd; parse_context)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context)
        else
            #! Create extension point here!
            #! `parse_contex` will have a list of possible `LabelParser`s.
            #!
            # Lookup parser for tag
            #
            any(==(tag), ("rate", "delayx")) ||
                @warn "found unexpected label of <transition> id=$transitionid: $tag"
            extralabels = add_label(extralabels, child, pntd, parse_context)
            #!@show extralabels
        end
    end

    Transition{typeof(pntd), PNML.condition_type(pntd)}(pntd, transitionid,
            something(cond, Labels.default(Labels.Condition, pntd; parse_context.ddict)),
            namelabel, graphics, toolspecinfos, extralabels,
            Set{REFID}(),
            NamedTuple[], parse_context.ddict)
end

"""
    parse_arc(node::XMLNode, pntd::PnmlType) -> Arc

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node::XMLNode, pntd::PnmlType; netdata, parse_context::ParseContext)
    check_nodename(node, "arc")
    arcid = register_idof!(parse_context.idregistry, node)

    source = Symbol(attribute(node, "source"))
    target = Symbol(attribute(node, "target"))
    inscription::Maybe{Any} = nothing # 2 kinds of inscriptions

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}}  = nothing
    extralabels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "inscription" || tag == "hlinscription"
            # Input arc inscription and source's marking/placesort must have equal Sorts.
            # Output arc inscription and target's marking/placesort must have equal Sorts.
            # Have IDREF to source & target place & transition.
            # They which must have been parsed and can be found in netdata.
            inscription = _parse_inscription(child, source, target, pntd; netdata, parse_context)
        elseif tag == "name"
            namelabel = parse_name(child, pntd; parse_context)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context) # arc
        else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected child of <arc>: $tag"
            extralabels = add_label(extralabels, child, pntd, parse_context)
        end
    end

    #TODO Does creating default values win over Maybe? for inscriptions?
    #TODO There will be net meta-models that assume all inscriptions are 1 and omit the label.
    if isnothing(inscription)
        inscription = if ishighlevel(pntd)
            default(HLInscription, pntd,
                    SortType("default", UserSortRef(:dot), parse_context.ddict);
                    parse_context.ddict)
        else
            default(Inscription, pntd; parse_context.ddict)
        end
    end

    Arc(arcid, Ref(source), Ref(target), inscription, namelabel, graphics, toolspecinfos, extralabels, parse_context.ddict)
end

# By specializing arc inscription label parsing we hope to return stable type.
function _parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::PnmlType;
                    netdata, parse_context::ParseContext)
    parse_inscription(node, source, target, pntd; parse_context) #! , netdata)
end
function _parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::T;
                    netdata, parse_context) where {T<:AbstractHLCore}
    parse_hlinscription(node, source, target, pntd; netdata, parse_context)
    # `netdata` used to find adjacent place's sorttype.
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "referencePlace")
    refp_id = register_idof!(parse_context.idregistry, node)

    ref = Symbol(attribute(node, "ref"))

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            namelabel = parse_name(child, pntd; parse_context)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context)
        else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected child of <referencePlace>: $tag"
            extralabels = add_label(extralabels, child, pntd, parse_context)
        end
    end

    RefPlace(refp_id, ref, namelabel, graphics, toolspecinfos, extralabels, parse_context.ddict)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "referenceTransition")
    reft_id = register_idof!(parse_context.idregistry, node)

    ref = Symbol(attribute(node, "ref"))

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::Maybe{Vector{PnmlLabel}}= nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            namelabel = parse_name(child, pntd; parse_context)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context)
        else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected child of <referenceTransition>: $tag"
            extralabels = add_label(extralabels, child, pntd, parse_context)
        end
    end

    RefTransition(reft_id, ref, namelabel, graphics, toolspecinfos, extralabels, parse_context.ddict)
end


# Call marking parser specialized on the pntd.
_parse_marking(node::XMLNode, placetype, pntd::T; parse_context) where {T<:PnmlType} =
    parse_initialMarking(node, placetype, pntd; parse_context)

_parse_marking(node::XMLNode, placetype, pntd::T; parse_context) where {T<:AbstractHLCore} =
    parse_hlinitialMarking(node, placetype, pntd; parse_context)
