function parse_excluded(node::XMLNode, _, _)
    @warn "Attempt to parse excluded tag: $(EzXML.nodename(node))"
    return nothing
end

#TODO test pnml_namespace

"""
$(TYPEDSIGNATURES)

Return namespace. When `node` does not have a namespace return default value [`pnml_ns`](@ref)
and warn or throw an error.
"""
function pnml_namespace(node::XMLNode; missing_ns_fatal::Bool=false, default_ns::String=pnml_ns)
    if EzXML.hasnamespace(node)
        return EzXML.namespace(node)
    else
        emsg = "$(EzXML.nodename(node)) missing namespace"
        missing_ns_fatal ? throw(ArgumentError(emsg)) : @warn(emsg)
        return default_ns
    end
end

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a string containing XML.
See [`parse_file`](@ref) and [`parse_pnml`](@ref).
"""
function parse_str(str::AbstractString) #! We never provide a registry
    isempty(str) && throw(ArgumentError("parse_str must have a non-empty string argument"))
    parse_pnml(xmlroot(str))
end

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a file containing XML.
See [`parse_str`](@ref) and [`parse_pnml`](@ref).
"""
function parse_file(fname::AbstractString) #! We never provide a registry
    isempty(fname) && throw(ArgumentError("parse_file must have a non-empty file name argument"))
    parse_pnml(EzXML.root(EzXML.readxml(fname)))
end

"""
    parse_pnml(xmlnode) -> PnmlModel

Start parse from the root `node` of a well formed pnml XML document.
Return a [`PnmlModel`](@ref) holding one or more [`PnmlNet`](@ref).
And each net has an independent ID Registry.
"""
function parse_pnml(node::XMLNode)
    check_nodename(node, "pnml")
    namespace = pnml_namespace(node)

    xmlnets = allchildren(node ,"net") #! allocate Vector{XMLNode}
    isempty(xmlnets) && throw(MalformedException("<pnml> does not have any <net> elements"))

    # Vector of ID registries of the same length as the number of nets. May alias.
    IDRegistryVec = PnmlIDRegistry[]
    # Per-net vector of declaration dictionaries.
    TOPDECLVEC = DeclDict[]

    #---------------------------------------------------------------------
    # Initialize/populate global Vector{PnmlIDRegistry}. Also a field of `Model`.
    # And the declaration dictionary structure,
    #---------------------------------------------------------------------
    empty!(TOPDECLVEC) #  This prevents more than one PnmlModel existing.
    # Need a netid to populate
    for _ in xmlnets
        push!(IDRegistryVec, registry())
        push!(TOPDECLVEC, DeclDict())
    end
    length(xmlnets) == length(IDRegistryVec) ||
        error("length(xmlnets) $(length(xmlnets)) != length(IDRegistryVec) $(length(IDRegistryVec))")
    length(xmlnets) == length(TOPDECLVEC) ||
        error("length(xmlnets) $(length(xmlnets)) != length(TOPDECLVEC) $(length(TOPDECLVEC))")


    # Do not YET have a PNTD defined. Each net can be different net type.
    # Each net should think it has its own ID registry and declaration dictionary.
    net_tup = ()
    for (net, reg, ddict) in zip(xmlnets, IDRegistryVec, TOPDECLVEC)
        net_tup = (net_tup..., @with(PNML.idregistry => reg, PNML.DECLDICT => ddict, parse_net(net)))

        #! Allocation? RUNTIME DISPATCH? This is a parser. What did you expect?
    end
    length(net_tup) > 0 || error("length(net_tup) is zero")

    PnmlModel(net_tup, namespace, IDRegistryVec) #TODO Also keep TOPDECLVEC
end

"""
$(TYPEDSIGNATURES)
Return a [`PnmlNet`](@ref)`.
"""
function parse_net(node::XMLNode, pntd_override::Maybe{PnmlType} = nothing)
    nn = check_nodename(node, "net")
    netid = register_idof!(PNML.idregistry[], node)

    # Parse the required-by-specification petri net type input.
    pn_typedef = PnmlTypeDefs.pnmltype(attribute(node, "type"))
    # Override of the Petri Net Type Definition (PNTD) value for fun & games.
    if isnothing(pntd_override)
        pntd = pn_typedef
    else
        pntd = pntd_override
        @info "net $id pntd set to $pntd, overrides $pn_typedef"
    end
    # Now we know the PNTD and can parse a net.

    isempty(allchildren(node ,"page")) &&
        throw(MalformedException("""<net> $netid does not have any <page> child"""))

    return parse_net_1(node, pntd, netid) # RUNTIME DISPATCH
end

"""
Parse PNML <net> with a defined PnmlType used to set the expected behavior of labels
attached to the nodes of a petri net graph, including: marking, inscription, condition and sorttype.

Page IDs are appended as the XML tree is descended, followed by node IDs.

Note the use of scoped value `DECLDICT[]` to access the per-net data structure as a scoped global.
Some uses of this scoped value are embedded in accessor methods like `variabledecls()`.
"""
function parse_net_1(node::XMLNode, pntd::PnmlType, netid::Symbol)
    pgtype = page_type(typeof(pntd))

    # Create empty data structures to be filled with the parsed pnml XML.
    # The type information is used by PnmlNet.
    #-------------------------------------------------------------------------
    pagedict = OrderedDict{Symbol, pgtype}() # Page dictionary not part of PnmlNetData.
    netdata = PnmlNetData(pntd)
    netsets = PnmlNetKeys()
    tunesize!(netdata)
    tunesize!(netsets)

    @assert isregistered(PNML.idregistry[], netid)

    # Having the name is useful for error/log messages.
    namelabel::Maybe{Name} = nothing
    nameelement = firstchild(node, "name")
    if !isnothing(nameelement)
        namelabel = parse_name(nameelement, pntd)
    end

    # We use the declarations toolkit for non-high-level nets,
    # and assume a minimum function for high-level nets.
    # Declarations present in the input file will overwrite these.
    fill_nonhl!(DECLDICT[])

    # Parse *ALL* Declarations here (assuming this the tree root),
    # this includes any Declarations attached to Pages.
    # Place any/all declarations in scoped value PNML.DECLDICT[].
    # It is like we are flattening only the declarations.
    # Only the first <declaration> text and graphics will be preserved.
    # Though what use graphics could add escapes me (and the specification).
    decls = alldecendents(node, "declaration") # There may be none.
    declaration = parse_declaration(decls, pntd)::Declaration

    validate_declarations(DECLDICT[])

    # We collect all the toolinfos at this level.
    # This enables use in later parsing.
    tools::Maybe{Vector{ToolInfo}} = nothing
    nettoolinfo = allchildren(node, "toolspecific")
    if !isempty(nettoolinfo)
        for ti in nettoolinfo
            tools = add_toolinfo(tools, ti, pntd)
        end
    end

    # Create empty net.
    net = PnmlNet(; type=pntd, id=netid,
                    pagedict, netdata, page_set=page_idset(netsets),
                    declaration, # Wraps a DeclDict, the current scoped value of PNML.DECLDICT[].
                    namelabel, tools, labels=nothing,
                    idregistry=PNML.idregistry[]
                    )

    # Fill the pagedict, netsets, netdata by depth first traversal of pages.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag in ["declaration", "name", "toolspecific"]
            #println("net already parsed ", tag) #! debug
        elseif tag == "page"
            # All graph node content resides in page node trees.
            # Threre is always at least one page. A forest of multiple page trees is allowd.
            # Note that one can always flatten a multi-page PnmlNet to a single page
            # and have the same graph with all the non-graphics labels preserved.
            # Un-flattened is not well tested!
            parse_page!(pagedict, netdata, netsets, child, pntd)
        elseif tag == "graphics"
            @warn "ignoring unexpected child of <net>: 'graphics'"
        else # PnmlLabels are assumed to be every other child.
            CONFIG[].warn_on_unclaimed && @warn "found unexpected label of <net> id=$netid: $tag"
            net.labels = add_label(net.labels, child, pntd) # No accessor because it has no user.
            # The specification allows meta-models defined upon the core to define
            # additional labels that conform to the Schema.
            # We use XMLDict as the parser for unclaimed labels (and anynet).
            #TODO mechanism for allowing new meta-models to provide specialized parsers
            #TODO When method `parse_unclaimed_label(Val(tag), child, pntd)` is defined,
            #TODO still need to be able to find the label to use it.

        end
    end
    return net
end

"Call `parse_page!`, add page to dictionary and id set"
function parse_page!(pagedict, netdata, netsets, node::XMLNode, pntd::PnmlType)
    check_nodename(node, "page")
    pageid = register_idof!(idregistry[], node)
    push!(page_idset(netsets), pageid) # Doing depth-first traversal, record id before decending.
    pg = _parse_page!(pagedict, netdata, node, pntd, pageid)
    @assert pageid === pid(pg)
    pagedict[pageid] = pg
    return nothing
end

"""
    parse_page!(pagedict, netdata, node, pntd) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function _parse_page!(pagedict, netdata, node::XMLNode, pntd::T, pageid::Symbol) where {T<:PnmlType}
    netsets = PnmlNetKeys() # Allocate per-page data.

    name::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    labels::Maybe{Vector{PnmlLabel}}= nothing

    place_set      = place_idset(netsets)
    transition_set = transition_idset(netsets)
    arc_set        = arc_idset(netsets)
    rp_set         = refplace_idset(netsets)
    rt_set         = reftransition_idset(netsets)

    tools::Maybe{Vector{ToolInfo}} = nothing
    nettoolinfo = allchildren(node, "toolspecific")
    if !isempty(nettoolinfo)
        for ti in nettoolinfo
            tools = add_toolinfo(tools, ti, pntd)
        end
    end

    for p in allchildren(node, "place")
        parse_place!(place_set, netdata, p, pntd)
    end
    for rp in allchildren(node, "referencePlace")
        parse_refPlace!(rp_set, netdata, rp, pntd)
    end
    for t in allchildren(node, "transition")
        parse_transition!(transition_set, netdata, t, pntd)
    end
    for rt in allchildren(node, "referenceTransition")
        parse_refTransition!(rt_set, netdata, rt, pntd)
    end
    for a in allchildren(node, "arc")
        parse_arc!(arc_set, netdata, a, pntd)
    end

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag in ["declaration", "place", "transition", "arc",
                    "referencePlace", "referenceTransition", "toolspecific"]
            # NOOP println("already parsed ", tag)
        elseif tag == "page" # Subpage
            parse_page!(pagedict, netdata, netsets, child, pntd)
        elseif tag == "name"
            name = parse_name(child, pntd)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        else
            CONFIG[].warn_on_unclaimed && @warn("found unexpected label of <page>: $tag")
            labels = add_label(labels, child, pntd)
        end
    end
    #! Attach empty DeclDict to page, all declarations are attached to PnmlNet!
    return Page(pntd, pageid, Declaration(), name, graphics, tools, labels,
                pagedict, # shared by net and all pages.
                netdata,  # shared by net and all pages.
                netsets,  # Set of ids "owned" by this page.
                )
end

# Reminder: set is per-Page, dict is per-Net

"Fill place_set, place_dict."
function parse_place!(place_set, netdata, child, pntd)
    pl = parse_place(child, pntd)::valtype(netdata.place_dict)
    push!(place_set, pid(pl))
    netdata.place_dict[pid(pl)] = pl
    return nothing
end

"Fill transition_set, transition_dict."
function parse_transition!(transition_set, netdata, child, pntd)
    tr = parse_transition(child, pntd)::valtype(netdata.transition_dict)
    push!(transition_set, pid(tr))
    netdata.transition_dict[pid(tr)] = tr
    return nothing
end

"Fill arc_set, arc_dict."
function parse_arc!(arc_set, netdata, child, pntd)
    a = parse_arc(child, pntd; netdata)
    a isa valtype(arcdict(netdata)) ||
        @error("$(typeof(a)) not a $(valtype(arcdict(netdata)))) $pntd $(repr(a))")
    push!(arc_set, pid(a))
    netdata.arc_dict[pid(a)] = a
    return nothing
end

"Fill refplace_set, refplace_dict."
function parse_refPlace!(refplace_set, netdata, child, pntd)
    rp = parse_refPlace(child, pntd)::valtype(netdata.refplace_dict)
    push!(refplace_set, pid(rp))
    netdata.refplace_dict[pid(rp)] = rp
    return nothing
end

"Fill reftransition_set, reftransition_dict."
function parse_refTransition!(reftransition_set, netdata, child, pntd)
    rt = parse_refTransition(child, pntd)::valtype(netdata.reftransition_dict)
    push!(reftransition_set, pid(rt))
    netdata.reftransition_dict[pid(rt)] = rt
    return nothing
end

"""
$(TYPEDSIGNATURES)

see [`fill_nonhl!`](@ref)
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
        sorttype = parse_type(typenode, pntd)
    else
        #@warn("default sorttype $pntd $(repr(id))", default_typeusersort(pntd))
        sorttype = SortType("default", default_typeusersort(pntd), nothing, nothing)
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
            mark = default_hlmarking(pntd, sorttype) # additive identity of multiset
        else
            mark = default_marking(pntd) # additive identity of number
        end
    end

    if isnothing(sorttype) # Infer sortype of place from mark?
        #~ NB: must support pnmlcore, no high-level stuff unless it is backported to pnmlcore.
        @error("infer sorttype", value(mark), sortof(mark), basis(mark))
        sorttype = SortType("default", basis(mark)::UserSort, nothing, nothing)
    end
    #@show basis(mark) sortof(mark) sortof(sorttype)
    #@show mark sorttype

    # The basis sort of mark label must be the same as the sort of sorttype label.
    if !equalSorts(sortof(basis(mark)), sortof(sorttype))
        error(string("place $(repr(id)) of $pntd: sort mismatch,",
                        "\n\t sortof(basis(mark)) = ", sortof(basis(mark)),
                        "\n\t sortof(sorttype) = ", sortof(sorttype)))
    end

    Place(pntd, id, mark, sorttype, name, graphics, tools, labels)
end


# Calls marking parser specialized on the pntd.
_parse_marking(node::XMLNode, placetype, pntd::T) where {T<:PnmlType} =
    parse_initialMarking(node, placetype, pntd)

_parse_marking(node::XMLNode, placetype, pntd::T) where {T<:AbstractHLCore} =
    parse_hlinitialMarking(node, placetype, pntd)

"Transition enrichment labels."
const transition_xlabels = ("rate", "delay") #TODO

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
            tools = add_toolinfo(tools, child, pntd)
        else # Labels (unclaimed) are everything-else. We expect at least one here!
            #! Create extension point here? Add more tag names to list?
            any(==(tag), transition_xlabels) ||
                @warn "unexpected label of <transition> id=$id: $tag"
            labels = add_label(labels, child, pntd)
        end
    end

    Transition{typeof(pntd), condition_type(pntd)}(pntd, id,
                something(cond, default_condition(pntd)), name, graphics, tools, labels)
end

"""
    parse_arc(node::XMLNode, pntd::PnmlType) -> Arc

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node, pntd; netdata)
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
            # Input arc inscription and source's marking/placesort must have equalSorts.
            # Output arc inscription and target's marking/placesort must have equalSorts.
            # Have IDREF to source & target place & transition.
            # They which must have been parsed and can be found in netdata.
            inscription = _parse_inscription(child, source, target, pntd; netdata)
        elseif tag == "name"
            name = parse_name(child, pntd)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd)
        else # labels (unclaimed) are everything-else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected child of <arc>: $tag"
            labels = add_label(labels, child, pntd)
        end
    end
    if isnothing(inscription)
        inscription = if ishighlevel(pntd)
            default_hlinscription(pntd, SortType("default_condition", UserSort(:dot)))
        else
            default_inscription(pntd)
        end
        #@info("missing inscription for arc $(repr(arcid)), replace with $(repr(inscription))")
    end
    Arc(arcid, Ref(source), Ref(target), inscription, name, graphics, tools, labels)
end

# By specializing arc inscription label parsing we hope to return stable type.
_parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::PnmlType;
            netdata) = parse_inscription(node, source, target, pntd)
_parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::T;
                     netdata) where {T<:AbstractHLCore} =
    parse_hlinscription(node, source, target, netdata)

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
            tools = add_toolinfo(tools, child, pntd)
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
            tools = add_toolinfo(tools, child, pntd)
        else # labels (unclaimed) are everything-else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected child of <referenceTransition>: $tag"
            labels = add_label(labels, child, pntd)
        end
    end

    RefTransition(id, ref, name, graphics, tools, labels)
end

#----------------------------------------------------------

    """
$(TYPEDSIGNATURES)

Return the stripped string of node's content.
"""
function parse_text(node::XMLNode, _::PnmlType)
    check_nodename(node, "text")
    return string(strip(EzXML.nodecontent(node)))::String
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding text value and optional tool & GUI information.
"""
function parse_name(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "name")
    text::Maybe{String} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = string(strip(EzXML.nodecontent(child)))::String
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd)
        else
            @warn "ignoring unexpected child of <name>: '$tag'"
        end
    end

    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if isnothing(text)
        emsg = "<name> missing <text> element"
        if CONFIG[].text_element_optional
            text = string(strip(EzXML.nodecontent(node)))::String
            @warn string(emsg, " Using name content = '", text, "'")::String
        else
            throw(ArgumentError(emsg))
        end
    end

    # Since names are for humans and do not need to be unique we will allow empty strings.
    # When the "lint" methods are implemented, they can complain.
    return Name(text, graphics, tools)
end

#----------------------------------------------------------
#
# PNML annotation-label XML element parsers.
#
#----------------------------------------------------------
"""
    parse_label_content(node::XMLNode, termparser, pntd) -> NamedTuple

Parse label using a `termparser` callable applied to any structure element.
Also parses text, toolinfo, graphics, term and sort of term.
"""
function parse_label_content(node::XMLNode, termparser::F, pntd::PnmlType) where {F}
    text::Maybe{Union{String,SubString{String}}} = nothing
    term::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    tsort ::Maybe{AbstractSort}= nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = parse_text(child, pntd)
        elseif tag == "structure"
            term, tsort = termparser(child, pntd) # Apply function/functor
            #@show term tsort
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd)
        else
            @warn("ignoring unexpected child of <$(EzXML.nodename(node))>: '$tag'")
        end
    end
    return (; text, term, sort=tsort, graphics, tools)
end

"""
$(TYPEDSIGNATURES)

Non-high-level `PnmlType` initial marking parser. Most things are assumed to be Numbers.
"""
function parse_initialMarking(node::XMLNode, placetype::SortType, pntd::PnmlType)
    nn = check_nodename(node, "initialMarking")
    # See if there is a <structure> attached to the label. This is non-standard.
    # But allows use of same mechanism used for high-level nets.
    l = parse_label_content(node, parse_structure, pntd)::NamedTuple
    if !isnothing(l.term) # There was a <structure> tag. Used in the high-level meta-models.
        @warn "$nn <structure> element not used YET by non high-level net $pntd; found $(l.term)"
    end

    # Sorts are sets in Part 1 of the ISO specification that defines the semantics.
    # Very much mathy, so thinking of sorts as collections is natural.
    # Some of the sets are finite: boolean, enumerations, ranges.
    # Others include integers, natural, and positive numbers (we extend with floats/reals).
    # Some High-levl Petri nets, in particular Symmetric nets, are restricted to finite sets.
    # We support the possibility of full-fat High-level nets with
    # arbitrary sort and arbitrary operation definitions.

    # Part2 of the ISO specification that defines the syntax of the xml markup language
    # maps these sets to sorts (similar to Type). And adds things.
    # A MathML replacement for HL nets. (They abandoned MathML.)
    # Partitions, Lists,

    # Part 3 of the ISO specification is a math and semantics extension covering
    # modules, extensions, more net types. Not reflected in Part 2 as on August 2024.
    # The 2nd edition of Part 1 is contemperoranous with Part 3.
    # Part 2 add some of these features through the www.pnml.org Schema repository.

    # sortelements is needed to support the <all> operator that forms a multiset out of
    # one of each of the finite sorts elements. This leads to iteration. Thus eltype.

    # If there is no appropriate eltype method defined expect eltype(x) @ Base abstractarray.jl:241
    # to return Int64.
    # Base.eltype is for collections: what would an iterator return.

    # Parse <text> as a `Number` of appropriate type or use apropriate default.
    #@show placetype sortof(placetype) typeof(sortof(placetype))
    mvt = eltype(sortof(placetype))
    #@show mvt,

    mvt == marking_value_type(pntd) || #! could be DotSort, PnmlTuple, numbera
        throw(ArgumentError("initial marking value type of $pntd must be $(marking_value_type(pntd)), found: $mvt"))

    value = if isnothing(l.text)
        zero(mvt)
    else
        number_value(mvt, l.text)
    end

    #@show placetype value eltype(sortof(placetype))
    value isa mvt || throw(ArgumentError(string("eltype of marking placetype = $mvt",
            ", does not match type of `value` = $(typeof(value))",
            ", for a $pntd")))

    Marking(value, l.graphics, l.tools)
end

"""
$(TYPEDSIGNATURES)
Ignore the source & target IDREF symbols.
"""
function parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::PnmlType)
    check_nodename(node, "inscription")
    txt = nothing
    value = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            txt = string(strip(EzXML.nodecontent(child)))
            value = number_value(inscription_value_type(pntd), txt)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd)
        else
            @warn("ignoring unexpected child of <inscription>: '$tag'")
        end
    end

    # Treat missing value as if the <inscription> element was absent.
    if isnothing(value)
        value = one(inscription_value_type(pntd))
        CONFIG[].warn_on_fixup &&
            @warn("missing or unparsable <inscription> value '$txt' replaced with $value")
    end
    Inscription(value, graphics, tools)
end

"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a <structure> child containing a ground term.
Sort of marking term must be the same as `placetype`, a `UserSort` that holds the ID of a sort declaration.

NB: Used by PTNets that assume placetype is DotSort().
"""
function parse_hlinitialMarking(node::XMLNode, placetype::SortType, pntd::AbstractHLCore)
    check_nodename(node, "hlinitialMarking")
    l = parse_label_content(node, ParseMarkingTerm(sortref(placetype)), pntd)::NamedTuple
    # @warn pntd l.text l.term l.sort
    # Marking label content is expected to be a TermInterface expression.
    # All declarations are expected to have been processed before the
    # first place is encountered.

    markterm = if isnothing(l.term)
        # Default is an empty multiset whose basis matches placetype.
        pnmlmultiset(sortref(placetype), def_sort_element(placetype), 0) #! TermInterface expression
    else
        #!
        #! Evaluate the expression. Expect a pnmlmultiset expression result (from an operator).
        #!
        @show l.term typeof(l.term)
        l.term
    end
    equalSorts(sortof(basis(markterm)), sortof(placetype)) ||
        error(string("HL marking sort mismatch,",
            "\n\t sortof(basis(markterm)) = ", sortof(basis(markterm)),
            "\n\t sortof(placetype) = ", sortof(placetype)))
    HLMarking(l.text, markterm, l.graphics, l.tools)
end

""
function eval_initialmarking_term()
end
"""
    ParseMarkingTerm(placetype) -> Functor

Holds parameters for parsing when called as (f::T)(::XMLNode, ::PnmlType)
"""
struct ParseMarkingTerm
    placetype::UserSort
end

placetype(pmt::ParseMarkingTerm) = pmt.placetype

function (pmt::ParseMarkingTerm)(marknode::XMLNode, pntd::PnmlType)
    check_nodename(marknode, "structure")
    if EzXML.haselement(marknode)
        println("\n(pmt::ParseMarkingTerm) "); @show placetype(pmt)
        term = EzXML.firstelement(marknode) # ignore any others

        mark, sort = parse_term(term, pntd)

        @show mark
        println()
        @show ex = toexpr(mark) #~ recursive `toexpr`.
        #dump(ex)
        mark = eval(ex)

        @show mark typeof(mark) #sortof(mark)
        @show sort typeof(sort)
        @show typeof(placetype(pmt))

        #! MARK will be a TERM, a symbolic expression using TermInterface
        #! that, when evaluated, produces a PnmlMultiset object.

        #@assert sort == sortof(mark) # sortof multiset is the basis sort
        #@assert sortof(mark) != basis(mark)
        #@assert basis(mark) == sortof(basis(mark))

        # PnmlMultiset (datastructure) vs UserOperator/NamedOperator (term/expression)
        # Here we are parsing a term from XML to a ground term, which must be an operator.
        # Like with sorts, we have useroperator -> namedoperator -> operator.
        # NamedOperators will be joined by ArbitraryOperators for HLPNGs.
        # Operators include built-in operators, multiset operators, tuples
        # Multiset operators must be evaluated to become PnmlMultiset objects.
        # Markings are multisets (a.k.a. bags).
        #!isa(mark, PnmlMultiset) ||
        #!ismultisetoperator(tag(mark)) || error("mark is not a multiset operator: $mark))")

        # isa(sortof(mark), UserSort) ||
        #     error("sortof(mark) is a $(sortof(mark)), expected UserSort")
        # isa(mark, Union{PnmlMultiset,Operator}) ||
        #     error("mark is a $(nameof(typeof(mark))), expected PnmlMultiset or Operator")

        isa(placetype(pmt), UserSort) ||
            error("placetype is a $(nameof(typeof(placetype(pmt)))), expected UserSort")

        @show basis(mark)
        if !equalSorts(sortof(basis(mark)), sortof(placetype(pmt)))
            @show basis(mark) placetype(pmt) sortof(basis(mark)) sortof(placetype(pmt))
            throw(ArgumentError(string("parse marking term sort mismatch:",
                "\n\t sortof(basis(mark)) = ", sortof(basis(mark)),
                "\n\t sortof(sorttype) = ", sortof(placetype(pmt)))))
        end
        return (mark, sort)
    end
    throw(ArgumentError("missing marking term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, source::Symbol, target::Symbol,
                             pntd::AbstractHLCore; netdata::PnmlNetData)
    check_nodename(node, "hlinscription")
    l = parse_label_content(node, ParseInscriptionTerm(source, target, netdata), pntd)
    HLInscription(l.text, l.term, l.graphics, l.tools)
end

"""
    ParseInscriptionTerm(placetype) -> Functor

Holds parameters for parsing inscription.
The sort of the inscription must match the place sorttype.
Input arcs (source is a transition) and output arcs (source is a place)
called as (pit::ParseInscriptionTerm)(::XMLNode, ::PnmlType)
"""
struct ParseInscriptionTerm
    source::Symbol
    target::Symbol
    netdata::PnmlNetData
end

source(pit::ParseInscriptionTerm) = pit.source
target(pit::ParseInscriptionTerm) = pit.target
netdata(pit::ParseInscriptionTerm) = pit.netdata

function (pit::ParseInscriptionTerm)(inscnode::XMLNode, pntd::PnmlType)
    check_nodename(inscnode, "structure")
    #println("\n(pmt::ParseInscriptionTerm) ", source(pit), ", ", target(pit))

    isa(target(pit), Symbol) ||
        error("target is a $(nameof(typeof(target(pit)))), expected Symbol")
    isa(source(pit), Symbol) ||
        error("source is a $(nameof(typeof(target(pit)))), expected Symbol")

    # The core PNML specification allows arcs from place to place, and transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).
    place = if haskey(placedict(netdata(pit)), source(pit))
        @assert haskey(transitiondict(netdata(pit)), target(pit))
        placedict(netdata(pit))[source(pit)]
    elseif haskey(placedict(netdata(pit)),target(pit))
        @assert haskey(transitiondict(netdata(pit)), source(pit))
        placedict(netdata(pit))[target(pit)]
    else
        error("inscription place not found, source = $(source(pit)), target = $(target(pit))")
    end

    if EzXML.haselement(inscnode)
        term = EzXML.firstelement(inscnode) # ignore any others
        inscript, _ = parse_term(term, pntd) #! TermInterface expression with a toexpr method.
    else
        # Default to an  multiset whose basis is placetype
        inscript = def_insc(netdata(pit), source(pit), target(pit))
        @warn("missing inscription term in <structure>, returning ", inscript)
    end
    # @show inscript sort typeof(inscript) sortof(inscript) basis(inscript)
    isa(inscript, AbstractTerm) ||
        error("inscription is a $(nameof(typeof(inscript))), expected AbstractTerm")
    isa(sortof(inscript), AbstractSort) ||
        error("sortof(inscript) is a $(nameof(sortof(inscript))), expected AbstractSort")
    # @assert sort == sortof(inscript) "error $sort != $(sortof(inscript))"

    placesort = sortof(place)
    # @show placesort

    equalSorts(sortof(basis(inscript)), placesort) ||
        throw(ArgumentError(string("sort mismatch:",
            "\n\t sortof(basis(inscription)) ", sortof(basis(inscript)),
            "\n\t placesort ", placesort)))
    return (inscript, sortof(inscript))
end

"adjacent place of an arc is either the `source` or `target`"
function adjacent_place(netdata, source, target)
    if haskey(placedict(netdata), source)
        @assert haskey(transitiondict(netdata), target)
        placedict(netdata)[source]
    elseif haskey(placedict(netdata),target)
        @assert haskey(transitiondict(netdata), source)
        placedict(netdata)[target]
    else
        error("inscription place not found, source = $source, target = $target")
    end
end

# default inscription with sort of adjacent place
function def_insc(netdata, source, target)
    # Core PNML specification allows arcs from place to place & transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).
    place = adjacent_place(netdata, source, target)
    placetype = place.sorttype
    el = def_sort_element(placetype)
    inscr = pnmlmultiset(sortref(placetype), el, 1)
    #@show inscr
    return inscr
end

"""
$(TYPEDSIGNATURES)

Label of transition nodes.

# Details

Condition has <text> and <structure> elements. With all meaning in the <structure> that
holds (an expression) evaluating to a boolean value.

See [`BoolExpr`](@ref).
"""
function parse_condition end

function parse_condition(node::XMLNode, pntd::T) where {T<:AbstractHLCore}
    l = parse_label_content(node, parse_condition_term, pntd) #! term is expession
    @show l
    PNML.Labels.Condition(l.text, l.term, l.graphics, l.tools)
end

function parse_condition(node::XMLNode, pntd::PnmlType) # Non-HL
    l = parse_label_content(node, parse_condition_term, pntd) #! term is expession
    @show l
    #term = toexpr(l.term) # All non-HL net conditions are literal expressions.
    #@show term
    #@warn("condition for $pntd = $(repr(l)) l.term = $(l.term)")
    PNML.Labels.Condition(l.text, l.term, l.graphics, l.tools)
end

"""
$(TYPEDSIGNATURES)

`Condition` label of a `Transition` will have a structure element containing a term.
PTNets are extended to have conditions and use a `BooleanConstant` to set the initial value.
"""
function parse_condition_term(cnode::XMLNode, pntd::PnmlType)
    check_nodename(cnode, "structure")
    if EzXML.haselement(cnode)
        return parse_term(EzXML.firstelement(cnode), pntd) # expression
    end
    throw(ArgumentError("missing condition term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

Label that defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place from _many-sorted algebra_ is different from
the Petri Net "type" of a net or "pntd". Neither is directly a julia type.

Allow all pntd's places to have a <type> label.  Non high-level are expecting a numeric sort: eltype(sort) <: Number.
"""
function parse_type(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "type")
    l = parse_label_content(node, parse_sorttype_term, pntd)
    # High-level nets are expected to have a sorttype term defined.
    # Others will use a default

    SortType(l.text, l.term, l.graphics, l.tools)
end
#=
#~ MOVE THIS
Built from many different elements that contain a Sort:
type, namedsort, variabledecl, multisetsort, productsort, numberconstant, partition...
parse_type(
Sort = BuiltInSort | MultisetSort | ProductSort | UserSort
=#
"""
$(TYPEDSIGNATURES)
The PNML "type" of a `Place` is a "sort" of the high-level many-sorted algebra.
"""
function parse_sorttype_term(typenode, pntd)
    check_nodename(typenode, "structure")
    EzXML.haselement(typenode) || throw(ArgumentError("missing sort type element in <structure>"))
    sortnode = EzXML.firstelement(typenode)::XMLNode # Expect only child element to be a sort.
    sorttype = parse_sort(sortnode, pntd)::UserSort
    isa(sorttype, MultisetSort) && error("multiset sort not allowed for Place type")
    return (sorttype, sortof(sorttype))
end

"""
$(TYPEDSIGNATURES)

Return [`PNML.Labels.Structure`](@ref) holding an XML <structure>.
Should be inside of an PNML label.
A "claimed" label usually elids the <structure> level (does not call this method).
"""
function parse_structure(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "structure")
    @warn "parse_structure is not a well defined thing, $pntd"
    Structure(unparsed_tag(node)...) #TODO anyelement
end


#---------------------------------------------------------------------
#TODO Will unclaimed_node handle this?
"""
$(TYPEDSIGNATURES)

Should not often have a <label> tag, this will bark if one is found and return NamedTuple (tag,xml) to defer parsing the xml.
"""
function parse_label(node::XMLNode, _::PnmlType)
    @assert node !== nothing
    nn = check_nodename(node, "label")
    @warn "there is a label named 'label'"
    (; :tag => Symbol(nn), :xml => node) # Always add xml because this is unexpected.
end
