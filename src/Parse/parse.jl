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

    #---------------------------------------------------------------------
    # Initialize/populate global Vector{PnmlIDRegistry}. Also a field of `Model`.
    #---------------------------------------------------------------------
    empty!(IDRegistryVec) # Tests, use in scripts may leave a polluted global.
    for _ in xmlnets
        push!(IDRegistryVec, registry())
    end
    length(xmlnets) == length(IDRegistryVec) ||
        error("length(xmlnets) $(length(xmlnets)) != length(IDRegistryVec) $(length(IDRegistryVec))")
    @show IDRegistryVec

    #---------------------------------------------------------------------
    # Clear out TOPDECLDICT. This prevents more than one PnmlModel existing.
    #---------------------------------------------------------------------
    empty!(TOPDECLDICTIONARY)

    # Do not YET have a PNTD defined. Each net can be different net type.
    # Each net should think it has its own ID registry.
    net_tup = ()
    for (net, reg) in zip(xmlnets, IDRegistryVec)
        net_tup = (net_tup..., @with(idregistry => reg, parse_net(net)))
        #! Allocation? RUNTIME DISPATCH? This is a parser. What did you expect?
   end
    length(net_tup) > 0 || error("length(net_tup) is zero")

    if CONFIG[].verbose #TODO Send this to a log file.
        @warn "CONFIG[].verbose is true"
        println("PnmlModel $(length(net_tup)) xmlnets")
        for n in net_tup
            println("  ", pid(n), " :: ", typeof(n))
        end
    end
    PnmlModel(net_tup, namespace, IDRegistryVec)
end

"""
$(TYPEDSIGNATURES)
Return a [`PnmlNet`](@ref)`.
"""
function parse_net(node::XMLNode, pntd_override::Maybe{PnmlType} = nothing)
    nn = check_nodename(node, "net")
    netid = register_idof!(idregistry[], node)

    # Parse the required-by-specification petri net type input.
    pn_typedef = PnmlTypeDefs.pnmltype(attribute(node, "type", "$nn missing type"))
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

    return parse_net_1(node, pntd; ids=(netid,)) # RUNTIME DISPATCH
end

"""
Parse PNML <net> with a defined PnmlType used to set the expected behavior of labels
attached to the nodes of a petri net graph, including: marking, inscription, condition and sorttype.

The `ids` tuple contains PNML ID `Symbol`s. The first is for this PnmlNet.
It is used to allocate a [`DeclDict`](@ref), a per-net collection of all <declarations> content.
[`TOPDECLDICTIONARY`](@ref) is a dictionary keyed by the PnmlNet's ID that holds a `DeclDict`.
Page IDs are appended as the XML tree is descended, followed by node IDs.

Note the use of `decldict(netid(ids))` to access the per-net data structure
as  a global wherever the netid is known.
"""
function parse_net_1(node::XMLNode, pntd::PnmlType; ids::Tuple)
    netid = first(ids)
    pgtype = page_type(typeof(pntd))

    # Create empty data structures to be filled with the parsed pnml XML.
    # The type information is used by PnmlNet.
    #-------------------------------------------------------------------------
    pagedict = OrderedDict{Symbol, pgtype}() # Page dictionary not part of PnmlNetData.
    netdata = PnmlNetData(pntd)
    netsets = PnmlNetKeys()
    tunesize!(netdata)
    tunesize!(netsets)

    println("\nparse_net_1 $pntd $(repr(netid))")
    @show pgtype typeof(netdata)
    println()

    @assert isregistered(idregistry[], netid)
    @assert !haskey(TOPDECLDICTIONARY, netid) "net $netid already in TOPDECLDICTIONARY, keys: $(collect(keys(TOPDECLDICTIONARY)))"
    TOPDECLDICTIONARY[netid] = DeclDict() # Allocate empty per-net global dictionary.

    # Parse *ALL* Declarations first (assuming this the tree root),
    # this includes any Declarations attached to Pages.
    # Place any/all declarations in decldict(netid).
    # It is like we are flattening only the declarations.
    # We collect all the toolinfos.
    # Only the first <declaration> text and graphics will be preserved.
    # Though what use graphics could add escapes me (and the specification).
    decls = alldecendents(node, "declaration") # There may be none.
    declaration = parse_declaration(decls, pntd; ids)::Declaration

    fill_nonhl!(decldict(netid); ids) # All net types have these. Decl def takes precenence.

    if !isempty(decldict(netid))
        #@show(netid, decldict(netid)) #! debug
        validate_declarations(decldict(netid))
    end

    namelabel::Maybe{Name} = nothing
    nameelement = firstchild(node, "name")
    if !isnothing(nameelement)
        namelabel = parse_name(nameelement, pntd)
    end

    tools::Maybe{Vector{ToolInfo}} = nothing
    nettoolinfo = allchildren(node, "toolspecific")
    if !isempty(nettoolinfo)
        for ti in nettoolinfo
            tools = add_toolinfo(tools, ti, pntd)
        end
    end

    labels::Maybe{Vector{PnmlLabel}} = nothing

    # Create net then fill
    net = PnmlNet(; type=pntd, id=netid, pagedict, netdata, page_set=page_idset(netsets),
                   declaration,
                   namelabel, tools, labels)

    # Fill the pagedict, netsets, netdata by depth first traversal.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag in ["declaration", "name", "toolspecific"]
            #println("net already parsed ", tag) #! debug
        elseif tag == "page"
            # All graph node content resides in pages.
            # Threre is always at least one page. A forest of multiple pages is allowd.
            # Note that one can always flatten a multi-page PnmlNet to a single page
            # and have the same graph with all the non-graphics labels preserved.
            # Un-flattened is not well tested!
            parse_page!(pagedict, netdata, netsets, child, pntd; ids)
        elseif tag == "graphics"
            @warn "ignoring unexpected child of <net>: 'graphics'"
        else # Labels are everything-else here.
            CONFIG[].warn_on_unclaimed && @warn "found unexpected label of <net> id=$netid: $tag"
            net.labels = add_label(net.labels, child, pntd)
        end
    end
    return net
end

"Call `parse_page!`, add page to dictionary and id set"
function parse_page!(pagedict, netdata, netsets, node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "page")
    pageid = register_idof!(idregistry[], node)
    push!(page_idset(netsets), pageid) # Doing depth-first traversal, record id before decending.
    pg = _parse_page!(pagedict, netdata, node, pntd; ids=tuple(ids..., pageid))
    @assert pageid === pid(pg)
    pagedict[pageid] = pg
    return nothing
end

"""
    parse_page!(pagedict, netdata, node, pntd; ids) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function _parse_page!(pagedict, netdata, node::XMLNode, pntd::T; ids::Tuple) where {T<:PnmlType}
    pageid = last(ids) # Just appended,
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
        parse_place!(place_set, netdata, p, pntd; ids)
    end
    for rp in allchildren(node, "referencePlace")
        parse_refPlace!(rp_set, netdata, rp, pntd; ids)
    end
    for t in allchildren(node, "transition")
        parse_transition!(transition_set, netdata, t, pntd; ids)
    end
    for rt in allchildren(node, "referenceTransition")
        parse_refTransition!(rt_set, netdata, rt, pntd; ids)
    end
    for a in allchildren(node, "arc")
        parse_arc!(arc_set, netdata, a, pntd; ids)
    end

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag in ["declaration", "place", "transition", "arc",
                    "referencePlace", "referenceTransition", "toolspecific"]
            # NOOP println("already parsed ", tag)
        elseif tag == "page" # Subpage
            parse_page!(pagedict, netdata, netsets, child, pntd; ids)
        elseif tag == "name"
            name = parse_name(child, pntd)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        else
            CONFIG[].warn_on_unclaimed && @warn("found unexpected label of <page>: $tag")
            labels = add_label(labels, child, pntd)
        end
    end

    return Page(pntd, pageid, Declaration(), name, graphics, tools, labels,
                pagedict, # shared by net and all pages.
                netdata,  # shared by net and all pages.
                netsets,  # Set of ids "owned" by this page.
                )
end

# Reminder: set is per-Page, dict is per-Net

"Fill place_set, place_dict."
function parse_place!(place_set, netdata, child, pntd; ids)
    pl = parse_place(child, pntd; ids)::valtype(netdata.place_dict)
    #@show "parse_place!" pl valtype(placedict(netdata))
    push!(place_set, pid(pl))
    netdata.place_dict[pid(pl)] = pl
    return nothing
end

"Fill transition_set, transition_dict."
function parse_transition!(transition_set, netdata, child, pntd; ids)
    tr = parse_transition(child, pntd; ids)::valtype(netdata.transition_dict)
    #@show "parse_transition!" tr valtype(transitiondict(netdata))
    push!(transition_set, pid(tr))
    netdata.transition_dict[pid(tr)] = tr
    return nothing
end

"Fill arc_set, arc_dict."
function parse_arc!(arc_set, netdata, child, pntd; ids)
    a = parse_arc(child, pntd; ids, netdata)
    # println("parse_arc!");
    # @show a valtype(arcdict(netdata))
    a isa valtype(arcdict(netdata)) ||
        @error("$(typeof(a)) not a $(valtype(arcdict(netdata)))) $pntd $(repr(a)) ids")
    push!(arc_set, pid(a))
    netdata.arc_dict[pid(a)] = a
    return nothing
end

"Fill refplace_set, refplace_dict."
function parse_refPlace!(refplace_set, netdata, child, pntd; ids)
    rp = parse_refPlace(child, pntd; ids)::valtype(netdata.refplace_dict)
    push!(refplace_set, pid(rp))
    netdata.refplace_dict[pid(rp)] = rp
    return nothing
end

"Fill reftransition_set, reftransition_dict."
function parse_refTransition!(reftransition_set, netdata, child, pntd; ids)
    rt = parse_refTransition(child, pntd; ids)::valtype(netdata.reftransition_dict)
    push!(reftransition_set, pid(rt))
    netdata.reftransition_dict[pid(rt)] = rt
    return nothing
end

"""
$(TYPEDSIGNATURES)

see [`fill_nonhl!`](@ref)
"""
function parse_place(node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "place")
    id   = register_idof!(idregistry[], node)
    ids  = tuple(ids..., id)
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
        sorttype = parse_type(typenode, pntd; ids)
    else
        #@warn("default sorttype $pntd $(repr(id))", default_typeusersort(pntd; ids))
        sorttype = SortType("default", default_typeusersort(pntd; ids), nothing, nothing)
    end
    #@warn "parse_place $id" sorttype

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "initialMarking" || tag == "hlinitialMarking"
            #! Maybe sorttype is infered from marking?
            mark = _parse_marking(child, sorttype, pntd; ids)
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
            mark = default_hlmarking(pntd, sorttype; ids) # additive identity of multiset
        else
            mark = default_marking(pntd; ids) # additive identity of number
        end
    end

    if isnothing(sorttype) # Infer sortype of place from mark?
        #~ NB: must support pnmlcore, no high-level stuff unless it is backported to pnmlcore.
        @error("infer sorttype", value(mark), sortof(mark), basis(mark))
        sorttype = SortType("default", basis(mark)::UserSort, nothing, nothing)
    end
    #@show basis(mark) sortof(mark) sortof(sorttype)
    #@show mark sorttype ids

    # The basis sort of mark label must be the same as the sort of sorttype label.
    if !equalSorts(sortof(basis(mark)), sortof(sorttype))
        # throw(MalformedException(string(
        error(string("place id $(repr(id)) of $pntd: sort mismatch,",
                        "\n\n sortof(basis(mark)) = ", sortof(basis(mark)),
                        "\n\t sortof(sorttype) = ", sortof(sorttype), ", trail $ids"))
    end

    Place(pntd, id, mark, sorttype, name, graphics, tools, labels)
end


# Calls marking parser specialized on the pntd.
_parse_marking(node::XMLNode, placetype, pntd::T; ids::Tuple) where {T<:PnmlType} =
    parse_initialMarking(node, placetype, pntd; ids)

_parse_marking(node::XMLNode, placetype, pntd::T; ids::Tuple) where {T<:AbstractHLCore} =
    parse_hlinitialMarking(node, placetype, pntd; ids)

const transition_xlabels = ("rate", "delay") #TODO

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "transition")
    id   = register_idof!(idregistry[], node)
    ids  = tuple(ids..., id)
    name::Maybe{Name} = nothing
    cond::Maybe{Condition} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "condition"
            cond = parse_condition(child, pntd; ids)
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
    parse_arc(node::XMLNode, pntd::PnmlType) -> Arc{typeof(pntd), typeof(inscription)}

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node, pntd; ids::Tuple, netdata)
    check_nodename(node, "arc")
    arcid = register_idof!(idregistry[], node)
    ids = tuple(ids..., arcid)
    source = Symbol(attribute(node, "source", "missing source for arc $arcid"))
    target = Symbol(attribute(node, "target", "missing target for arc $arcid"))

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
            inscription = _parse_inscription(child, source, target, pntd; ids, netdata)
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
            default_hlinscription(pntd, SortType("default_condition", UserSort(:dot; ids)))
        else
            default_inscription(pntd)
        end
        #@info("missing inscription for arc $(repr(arcid)), replace with $(repr(inscription))")
    end
    Arc(arcid, Ref(source), Ref(target), inscription, name, graphics, tools, labels)
end

# By specializing arc inscription label parsing we hope to return stable type.
_parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::PnmlType;
            ids::Tuple, netdata) = parse_inscription(node, source, target, pntd; ids)
_parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::T;
                     ids::Tuple, netdata) where {T<:AbstractHLCore} =
    parse_hlinscription(node, source, target, pntd; ids, netdata)

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::PnmlType; ids::Tuple)
    nn = check_nodename(node, "referencePlace")
    id = register_idof!(idregistry[], node)
    ids = tuple(ids..., id)
    ref = Symbol(attribute(node, "ref", "$nn $id missing ref attribute. trail = $ids"))
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
function parse_refTransition(node::XMLNode, pntd::PnmlType; ids::Tuple)
    nn = check_nodename(node, "referenceTransition")
    id = register_idof!(idregistry[], node)
    ids = tuple(ids..., id)
    ref = Symbol(attribute(node, "ref", "$nn $id missing ref attribute. trail = $ids"))
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
$(TYPEDSIGNATURES)

Non-high-level `PnmlType` initial marking parser. Most things are assumed to be Numbers.
"""
function parse_initialMarking(node::XMLNode, placetype::SortType, pntd::PnmlType; ids::Tuple)
    nn = check_nodename(node, "initialMarking")
    # See if there is a <structure> attached to the label. This is non-standard.
    # But allows use of same mechanism used for high-level nets.
    l = parse_label_content(node, parse_structure, pntd; ids)::NamedTuple
    if !isnothing(l.term) # There was a <structure> tag. Used in the high-level meta-models.
        @warn "$nn <structure> element not used YET by non high-level net $pntd; found $(l.term)"
    end

    # Parse <text> as a `Number` of appropriate type or use apropriate default.
    mvt = eltype(sortof(placetype))
    mvt == marking_value_type(pntd) ||
        throw(ArgumentError("marking value type must be $(marking_value_type(pntd)), found: $mvt"))

    value = if isnothing(l.text)
        zero(mvt)
    else
        number_value(mvt, l.text)
    end

    #@show placetype value eltype(sortof(placetype))
    value isa mvt || throw(ArgumentError(string("eltype of marking placetype, $mvt",
            ", does not match type of `value`, $(typeof(value))",
            ", for a $pntd. trail = $ids")))

    Marking(value, l.graphics, l.tools; ids)
end

"""
$(TYPEDSIGNATURES)
Ignore the source & target IDREF symbols.
"""
function parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::PnmlType; ids::Tuple)
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
            @warn("ignoring unexpected child of <inscription>: '$tag'. trail = $ids")
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
Parse label using a `termparser` callable applied to any <structure>.
"""
function parse_label_content(node::XMLNode, termparser::F, pntd::PnmlType; ids::Tuple) where {F}
    text::Maybe{Union{String,SubString{String}}} = nothing
    term::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = parse_text(child, pntd)
        elseif tag == "structure"
            term, sort = termparser(child, pntd; ids) # Apply function/functor
            #! @show term sort
            @assert sort == sortof(term)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd)
        else
            @warn("ignoring unexpected child of <$(EzXML.nodename(node))>: '$tag'", ids)
        end
    end
    return (; text, term, sort, graphics, tools)
end

"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a <structure> child containing a ground term.
Sort of marking term must be the same as `placetype`, a `UserSort` that holds the ID of a sort declaration.

NB: Used by PTNets that assume placetype is DotSort().
"""
function parse_hlinitialMarking(node::XMLNode, placetype::SortType, pntd::AbstractHLCore; ids::Tuple)
    check_nodename(node, "hlinitialMarking")
    l = parse_label_content(node, ParseMarkingTerm(value(placetype)), pntd; ids)::NamedTuple
    #@warn pntd l.text l.term ids

    mark = if isnothing(l.term) # Default to an empty multiset whose basis is placetype
        els = elements(placetype) # Finite sets return non-empty iteratable.
        @assert !isnothing(els) # High-level requires finite sets. #^ HLPNG?
        el = first(els) # Default to first of finite sort's elements (how often is this best?)
        pnmlmultiset(el, # used to deduce the type for Multiset.Multiset
                     sortof(placetype), # basis sort
                     0) # empty multiset, multiplicity of every element = zero.
    else
        l.term
    end
    equalSorts(sortof(basis(mark)), sortof(placetype)) ||
        error(string("HL marking sort mismatch,",
            "\n\t sortof(basis(mark)) = ", sortof(basis(mark)),
            "\n\t sortof(placetype) = ", sortof(placetype), ", trail $ids"))
    HLMarking(l.text, mark, l.graphics, l.tools; ids)
end

"""
    ParseMarkingTerm(placetype) -> Functor

Holds parameters for parsing when called as (f::T)(::XMLNode, ::PnmlType; ids::Tuple)
"""
struct ParseMarkingTerm
    placetype::Union{TupleSort,UserSort}
end

placetype(pmt::ParseMarkingTerm) = pmt.placetype

function (pmt::ParseMarkingTerm)(marknode::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(marknode, "structure")
    println("\n(pmt::ParseMarkingTerm) ")
    # @show placetype(pmt)
    #@show sortof(placetype(pmt))
    if EzXML.haselement(marknode)
        term = EzXML.firstelement(marknode) # ignore any others
        mark, sort = parse_term(term, pntd; ids)

        # @show mark sort
        # @show typeof(mark) sortof(mark) basis(mark)
        # @show sortof(basis(mark))
        @assert sort == sortof(mark) # sortof multiset is the basis sort
        #@assert sortof(mark) != basis(mark)
        #@assert basis(mark) == sortof(basis(mark))

        isa(mark, AbstractTerm) ||
            error("mark is a $(nameof(typeof(mark))), expected AbstractTerm")
        isa(sortof(mark), AbstractSort) ||
            error("sortof(mark) is a $(sortof(mark)), expected AbstractSort")
        #isa(mark, Union{PnmlMultiset,Operator}) ||
        #    error("mark is a $(nameof(typeof(mark))), expected PnmlMultiset or Operator")
        isa(placetype(pmt), AbstractSort) ||
            error("placetype is a $(nameof(typeof(placetype(pmt)))), expected AbstractSort")

        equalSorts(sortof(basis(mark)), sortof(placetype(pmt))) ||
            throw(ArgumentError(string("parse marking term sort mismatch:",
                "\n\t sortof(basis(mark)) = ", sortof(basis(mark)),
                "\n\t sortof(sorttype) = ", sortof(placetype(pmt)))))
        return (mark, sort)
    end
    throw(ArgumentError("missing marking term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, source::Symbol, target::Symbol,
                             pntd::AbstractHLCore; ids::Tuple, netdata::PnmlNetData)
    check_nodename(node, "hlinscription")
    l = parse_label_content(node, ParseInscriptionTerm(source, target, netdata), pntd; ids)
    HLInscription(l.text, l.term, l.graphics, l.tools)
end

"""
    ParseInscriptionTerm(placetype) -> Functor

Holds parameters for parsing inscription.
The sort of the inscription must match the place sorttype.
Input arcs (source is a transition) and output arcs (source is a place)
called as (pit::ParseInscriptionTerm)(::XMLNode, ::PnmlType; ids::Tuple)
"""
struct ParseInscriptionTerm
    source::Symbol
    target::Symbol
    netdata::PnmlNetData
end

source(pit::ParseInscriptionTerm) = pit.source
target(pit::ParseInscriptionTerm) = pit.target
netdata(pit::ParseInscriptionTerm) = pit.netdata

function (pit::ParseInscriptionTerm)(inscnode::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(inscnode, "structure")
    println("\n(pmt::ParseInscriptionTerm) ", source(pit), ", ", target(pit))

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

    placesort = sortof(place)
    # @show placesort

    if EzXML.haselement(inscnode)
        term = EzXML.firstelement(inscnode) # ignore any others
        inscript, sort = parse_term(term, pntd; ids)
    else
        # Default to an  multiset whose basis is placetype
        inscript = def_insc(netdata(pit), source(pit), target(pit))
        @warn("missing inscription term in <structure>, returning ", inscript)
    end
    #@show inscript sort typeof(inscript) sortof(inscript) basis(inscript)
    isa(inscript, AbstractTerm) ||
        error("inscription is a $(nameof(typeof(inscript))), expected AbstractTerm")
    isa(sortof(inscript), AbstractSort) ||
        error("sortof(inscript) is a $(nameof(sortof(inscript))), expected AbstractSort")
    #@assert sort == sortof(inscript) "error $sort != $(sortof(inscript))"

    equalSorts(sortof(basis(inscript)), placesort) ||
    throw(ArgumentError(string("sort mismatch:",
        "\n\t sortof(basis(inscription)) ", sortof(basis(inscript)),
        "\n\t placesort ", placesort)))
    return (inscript, sortof(inscript))
end

# default inscription with sort of adjacent place
def_insc(netdata, source, target) = begin
    # Core PNML specification allows arcs from place to place & transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).
    place = if haskey(placedict(netdata), source)
        @assert haskey(transitiondict(netdata), target)
        placedict(netdata)[source]
    elseif haskey(placedict(netdata),target)
        @assert haskey(transitiondict(netdata), source)
        placedict(netdata)[target]
    else
        error("inscription place not found, source = $source, target = $target")
    end
    placesort = sortof(place)
    #@show place placesort

    # Default to an  multiset whose basis is placetype
    els = elements(placesort) # Finite sets return non-empty iteratable.
    @assert !isnothing(els) # Symmetric Net requires finite sets. #^ HLPNG?
    el = first(els) # Default to first of finite sort's elements (how often is this best?)
    inscr = pnmlmultiset(el, # used to deduce the type for Multiset.Multiset
                placesort, # basis sort
                1)
    #@show inscr
    return inscr
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription_term(inode, pntd; ids::Tuple)
    check_nodename(inode, "structure")
    if EzXML.haselement(inode)
        term = EzXML.firstelement(inode)
        insc, sort = parse_term(term, pntd; ids)
        return (insc, sort)
    end
    throw(ArgumentError("missing inscription term element in <structure>"))
end

"""
$(TYPEDSIGNATURES)

Label of transition nodes.

# Details

Condition is defined by the ISO Specification as a High-level Annotation,
meaning it has <text> and <structure> elements. With all meaning in the element
that the <structure> holds evaluating to a boolean value.
We extend this to anything that evaluates to a boolean value when
treated as a functor.

A Condition should evaluate to a boolean.
See [`AbstractTerm`](@ref).
"""
function parse_condition end

function parse_condition(node::XMLNode, pntd::T; ids::Tuple) where {T<:AbstractHLCore}
    check_nodename(node, "condition")
    l = parse_label_content(node, parse_condition_term, pntd; ids)
    Condition(l.text, something(l.term, BooleanConstant(true)), l.graphics, l.tools)
end

function parse_condition(node::XMLNode, pntd::PnmlType; ids::Tuple) # Non-HL
    check_nodename(node, "condition")
    l = parse_label_content(node, parse_condition_term, pntd; ids)
    #@warn("condition for $pntd = $(repr(l)) l.term = $(l.term)")
    Condition(l.text, something(l.term, BooleanConstant(true)), l.graphics, l.tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_condition_term(cnode::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(cnode, "structure")
    if EzXML.haselement(cnode)
        term = EzXML.firstelement(cnode)
        cond, sort = parse_term(term, pntd; ids)
        return (cond, sort)
    end
    throw(ArgumentError("missing condition term element in <structure>"))
end

"""
$(TYPEDSIGNATURES)

Label that defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place from _many-sorted algebra_ is different from
the Petri Net "type" of a net or "pntd". Neither is directly a julia type.

Allow all pntd's places to have a <type> label.  Non high-level are expecting a numeric sort: eltype(sort) <: Number.
"""
function parse_type(node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "type")
    l = parse_label_content(node, parse_sorttype_term, pntd; ids)
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
function parse_sorttype_term(typenode, pntd; ids::Tuple)
    check_nodename(typenode, "structure")
    EzXML.haselement(typenode) || throw(ArgumentError("missing sort type element in <structure> trail = $ids"))
    sortnode = EzXML.firstelement(typenode)::XMLNode # Expect only child element to be a sort.
    sorttype = parse_sort(sortnode, pntd; ids)::AbstractSort
    isa(sorttype, MultisetSort) && error("multiset sort not allowed for Place type. trail = $ids")
    return (sorttype, sortof(sorttype))
end

"""
$(TYPEDSIGNATURES)

Return [`Structure`](@ref) holding an XML <structure>.
Should be inside of an PNML label.
A "claimed" label usually elids the <structure> level (does not call this method).
"""
function parse_structure(node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "structure")
    @warn "parse_structure is not a well defined thing, $pntd. trail = $ids"
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
