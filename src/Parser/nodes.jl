# parse nodes of graph
"Fill place_set, place_dict."
function parse_place!(netsets, netdata, child, pntd; parse_context::ParseContext)
    pl = parse_place(child, pntd; parse_context)::valtype(PNML.placedict(netdata))
    #@show valtype(PNML.placedict(netdata)) typeof(PNML.placedict(netdata))
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
    D()&& println("## parse_place ", repr(placeid))
    mark = nothing

    # Get sorttype to use in parsing marking.
    sorttype::Maybe{SortType} = let typenode = firstchild(node, "type")
        if isnothing(typenode) # Deduce sort type of place if possible.
            if isa(pntd, AbstractHLCore) && !isa(pntd, PT_HLPNG)
                nothing # Deduce from initial marking.
            else
                SortType("default", Labels.default_typesort(pntd), parse_context.ddict)
            end
        else
            parse_sorttype(typenode, pntd; parse_context)
        end
    end
    #TODO capacity label

    namelabel::Maybe{Name}           = nothing
    graphics::Maybe{Graphics}        = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "initialMarking" || tag == "hlinitialMarking"
            isnothing(sorttype) && @warn "$pntd parse_place $placeid sorttype is nothing"
            mark = _parse_marking(child, sorttype, pntd; parse_context, placeid)
        elseif tag == "type"
            # we already handled this
        elseif tag == "name"
            namelabel = parse_name(child, pntd; parse_context)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context) # place
        else
            CONFIG[].warn_on_unclaimed && @warn "$pntd parse_place $placeid found unexpected label of <place>: $tag"
            extralabels = add_label(extralabels, child, pntd, parse_context)
        end
    end

    if isnothing(mark) # Use additive identity of proper sort.
        default_sorttype = if ishighlevel(pntd)
            if isnothing(sorttype)
                #D()&&
                @error("$pntd place $placeid has neither a mark nor sorttype, use :dot even if it is WRONG")
                SortType("dummy", NamedSortRef(:dot), parse_context.ddict)
            else
                sorttype
            end
        else
            SortType("dummy", NamedSortRef(:natural), parse_context.ddict)
        end
        mark = default(Marking, pntd, default_sorttype; parse_context.ddict)
    end

    if isnothing(sorttype) # Infer sortype of place from mark
        #~ NB: must support pnmlcore, no high-level stuff unless it is backported to pnmlcore.
        D()&& @warn("$pntd parse_place $(repr(placeid)) infer sorttype", mark)
        sorttype = SortType("default", basis(mark)::AbstractSortRef, decldict(mark))
    end
    Place(placeid, mark, sorttype, namelabel, graphics, toolspecinfos, extralabels, parse_context.ddict)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "transition")
    transitionid = register_idof!(parse_context.idregistry, node)
    D()&& println("## parse_transition ", repr(transitionid))

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
            any(==(tag), ("rate", "delay")) ||
                @warn "found unexpected label of <transition> id=$transitionid: $tag"
            extralabels = add_label(extralabels, child, pntd, parse_context)
            #!@show extralabels
        end
    end

    Transition(transitionid,
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

    D()&& println("## parse_arc $(repr(arcid)) source $(repr(source)) target $(repr(target))")

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
        dummy_placetype = if ishighlevel(pntd)
            if pntd isa PT_HLPNG
                SortType("dummy PT_HLPNG", NamedSortRef(:dot),  parse_context.ddict)
            else
                #D()&&r),  par
                @error "$pntd inscription not provided for arc $arcid ($source -> $target), will use :dot."
                D()&& Base.show_backtrace(stdout, stacktrace())

                #TODO XXX Use the adjacent place's sorttype.
                # Note that the adjacent place may have not been parsed yet.
                # We are using REFIDs to access them in a store.
                # This (an inscription) is an expression for a ground term.
                # Default should be one of the adjacent place sorttype.
                #todo? Make expression that creates/caches default expresson when evaluated?
                SortType("dummy HIGHLEVEL", NamedSortRef(:dot),  parse_context.ddict)
           end
        elseif iscontinuous(pntd)
            SortType("dummy CONTINUOUS", NamedSortRef(:real),  parse_context.ddict)
        elseif isdiscrete(pntd)
            SortType("dummy DISCRETE", NamedSortRef(:positive),  parse_context.ddict)
        end
        inscription = default(Inscription, pntd, dummy_placetype; parse_context.ddict)
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
    D()&& println("## parse_refPlace ", repr(refp_id))

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
    D()&& println("## parse_refTransition ", repr(reft_id))

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
_parse_marking(node::XMLNode, placetype, pntd::PnmlType; parse_context, placeid) =
    parse_initialMarking(node, placetype, pntd; parse_context, placeid)

_parse_marking(node::XMLNode, placetype, pntd::AbstractHLCore; parse_context, placeid) =
    parse_hlinitialMarking(node, placetype, pntd; parse_context, placeid)
# _parse_marking(node::XMLNode, placetype, pntd::T; parse_context, placeid) where {T<:PnmlType} =
#     parse_initialMarking(node, placetype, pntd; parse_context, placeid)

# _parse_marking(node::XMLNode, placetype, pntd::T; parse_context, placeid) where {T<:AbstractHLCore} =
#     parse_hlinitialMarking(node, placetype, pntd; parse_context, placeid)
