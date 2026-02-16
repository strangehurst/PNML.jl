# parse nodes of graph
"Fill place_set, place_dict."
function parse_place!(netsets, netdata, child, pntd, net::AbstractPnmlNet)
    pl = parse_place(child, pntd, net)::valtype(PNML.placedict(netdata))
    #@show valtype(PNML.placedict(netdata)) typeof(PNML.placedict(netdata))
    push!(place_idset(netsets), pid(pl))
    PNML.placedict(netdata)[pid(pl)] = pl
    return place_idset(netsets) #place_set
end

"Fill transition_set, transition_dict."
function parse_transition!(netsets, netdata, child, pntd, net::AbstractPnmlNet)
    tr = parse_transition(child, pntd, net)::valtype(PNML.transitiondict(netdata))
    push!(transition_idset(netsets), pid(tr))
    PNML.transitiondict(netdata)[pid(tr)] = tr
    return transition_idset(netsets)
end

"Fill arc_set, arc_dict."
function parse_arc!(netsets, netdata, child, pntd, net::AbstractPnmlNet)
    a = parse_arc(child, pntd, net)
    a isa valtype(PNML.arcdict(netdata)) ||
        @error("$(typeof(a)) not a $(valtype(PNML.arcdict(netdata)))) $pntd $(repr(a))")
    push!(arc_idset(netsets), pid(a))
    PNML.arcdict(netdata)[pid(a)] = a
    return arc_idset(netsets)
end

"Fill refplace_set, refplace_dict."
function parse_refPlace!(netsets, netdata, child, pntd, net::AbstractPnmlNet)
    rp = parse_refPlace(child, pntd, net)::valtype(PNML.refplacedict(netdata))
    push!(refplace_idset(netsets), pid(rp))
    PNML.refplacedict(netdata)[pid(rp)] = rp
    return refplace_idset(netsets)
end

"Fill reftransition_set, reftransition_dict."
function parse_refTransition!(netsets, netdata, child, pntd, net::AbstractPnmlNet)
    rt = parse_refTransition(child, pntd, net)::valtype(PNML.reftransitiondict(netdata))
    push!(reftransition_idset(netsets), pid(rt))
    PNML.reftransitiondict(netdata)[pid(rt)] = rt
    return reftransition_idset(netsets)
end


"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, pntd::PnmlType, net::AbstractPnmlNet)
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
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        if tag == :initialMarking || tag == :hlinitialMarking tag == :fifoinitialMarking
            isnothing(sorttype) && @warn "$pntd parse_place $placeid sorttype is nothing"
            mark = net.labelparser[tag](child, sorttype, pntd; net, parentid=placeid)
        elseif tag == :type
            # we already handled this
        elseif tag == :name
            namelabel = net.labelparser[tag](child, pntd; net, parentid=placeid)
        elseif tag == :graphics
            graphics = net.labelparser[tag](child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, net) # place
        else
            unexpected_label!(extralabels, child, tag, pntd; net, parentid=placeid)
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
        #~ NB: must support pnmlcore, no high-level stuff unless it is backported to pnmlcore.
        D()&& @warn("$pntd parse_place $(repr(placeid)) infer sorttype ", mark)
        sorttype = SortType("default", basis(mark)::SortRef, net)
    end
    Place(placeid, mark, sorttype, namelabel, graphics, toolspecinfos, extralabels, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType, net::AbstractPnmlNet)
    check_nodename(node, "transition")
    transitionid = register_idof!(net.idregistry, node)
    D()&& println("## parse_transition ", repr(transitionid))

    cond::Maybe{PNML.Labels.Condition} = nothing

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        if tag == :condition
            cond = net.labelparser[tag](child, pntd; net, parentid=transitionid)
        elseif tag == :name
            namelabel = net.labelparser[tag](child, pntd; net, parentid=transitionid)
        elseif tag == :graphics
            graphics = net.labelparser[tag](child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, net)
        else
            unexpected_label!(extralabels, child, tag, pntd; net, parentid=transitionid)
        end
    end

    Transition(transitionid,
            something(cond, Labels.default(Labels.Condition, pntd, net)),
            namelabel, graphics, toolspecinfos, extralabels,
            Set{REFID}(),
            NamedTuple[], net)
end

"""
    parse_arc(node::XMLNode, pntd::PnmlType) -> Arc

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node::XMLNode, pntd::PnmlType, net::AbstractPnmlNet)
    check_nodename(node, "arc")
    arcid = register_idof!(net.idregistry, node)

    source = Symbol(attribute(node, "source"))
    target = Symbol(attribute(node, "target"))
    inscription::Maybe{Any} = nothing # 2 kinds of inscriptions

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}}  = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()
    arc_type_label::Maybe{ArcType} = nothing

    D()&& println("## parse_arc $(repr(arcid)) source $(repr(source)) target $(repr(target))")

    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        if tag == :inscription || tag == :hlinscription
            # Input arc inscription and source's marking/placesort must have equal Sorts.
            # Output arc inscription and target's marking/placesort must have equal Sorts.
            # Have IDREF to source & target place & transition.
            # They which must have been parsed and can be found in netdata.
            inscription = net.labelparser[tag](child, source, target, pntd;
                            net, parentid=arcid)
        elseif tag == :name
            namelabel = net.labelparser[tag](child, pntd; net, parentid=arcid)
        elseif tag == :arctype
            arc_type_label = net.labelparser[tag](child, pntd; net, parentid=arcid)
        elseif tag == :graphics
            graphics = net.labelparser[tag](child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, net) # arc
        else
            unexpected_label!(extralabels, child, tag, pntd; net, parentid=arcid)
        end
    end

    #TODO Does creating default values win over Maybe? for inscriptions?
    #TODO There will be net meta-models that assume all inscriptions are 1 and omit the label.
    if isnothing(inscription)
        dummy_placetype = if ishighlevel(pntd)
            if pntd isa PT_HLPNG
                SortType("dummy PT_HLPNG", NamedSortRef(:dot), net)
            else
                #D()&&
                @error "$pntd inscription not provided for arc $(repr(arcid)) ($(repr(source)) -> $(repr(target))), will use :dot."

                #TODO XXX Use the adjacent place's sorttype.
                # Note that the adjacent place may have not been parsed yet.
                # We are using REFIDs to access them in a store.
                # This (an inscription) is an expression for a ground term.
                # Default should be one of the adjacent place sorttype.
                #todo? Make expression that creates/caches default expresson when evaluated?
                SortType("dummy HIGHLEVEL", NamedSortRef(:dot),  net)
           end
        elseif iscontinuous(pntd)
            SortType("dummy CONTINUOUS", NamedSortRef(:real), net)
        elseif isdiscrete(pntd)
            SortType("dummy DISCRETE", NamedSortRef(:positive), net)
        end
        inscription = default(Inscription, pntd, dummy_placetype, net)
    end

    if isnothing(arc_type_label)
        arc_type_label = ArcType(; arctype=Labels.ArcT.normal())
    end

    Arc(; id=arcid, source=Ref(source), target=Ref(target),
        inscription, arctypelabel=arc_type_label, namelabel, graphics,
        toolspecinfos, extralabels, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::PnmlType, net::AbstractPnmlNet)
    check_nodename(node, "referencePlace")
    refp_id = register_idof!(net.idregistry, node)
    D()&& println("## parse_refPlace ", repr(refp_id))

    ref = Symbol(attribute(node, "ref"))

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        if tag == :name
            namelabel = net.labelparser[tag](child, pntd; net, parentid=refp_id)
        elseif tag == :graphics
            graphics =  net.labelparser[tag](child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, net)
        else
            unexpected_label!(extralabels, child, tag, pntd; net, parentid=refp_id)
        end
    end

    RefPlace(refp_id, ref, namelabel, graphics, toolspecinfos, extralabels, net)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType, net::AbstractPnmlNet)
    check_nodename(node, "referenceTransition")
    reft_id = register_idof!(net.idregistry, node)
    D()&& println("## parse_refTransition ", repr(reft_id))

    ref = Symbol(attribute(node, "ref"))

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()

    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        if tag == :name
            namelabel = net.labelparser[tag](child, pntd; net, parentid=reft_id)
        elseif tag == :graphics
            graphics = net.labelparser[tag](child, pntd)
        elseif tag == :toolspecific
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, net)
        else
            unexpected_label!(extralabels, child, tag, pntd; net, parentid=reft_id)
        end
    end

    RefTransition(reft_id, ref, namelabel, graphics, toolspecinfos, extralabels, net)
end
