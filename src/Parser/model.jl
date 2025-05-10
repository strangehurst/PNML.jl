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

Build a [`PnmlModel`](@ref) holding one or more [`PnmlNet`](@ref)
from a file containing XML or a XMLNode.
"""
function pnmlmodel end

function pnmlmodel(ctx::Context, filename::AbstractString; tp_vec=Labels.ToolParser[], lp_vec=LabelParser[])
    isempty(filename) && throw(ArgumentError("must have a non-empty file name argument"))
    pnmlmodel(ctx, EzXML.root(EzXML.readxml(filename)); tp_vec, lp_vec)
end

function pnmlmodel(ctx::Context, node::XMLNode; tp_vec=Labels.ToolParser[], lp_vec=LabelParser[])
    check_nodename(node, "pnml")
    namespace = pnml_namespace(node)
    #@error "parser logger = $(current_logger())"
    #@show PNML.pnml_logger[]
    #@info "parser logger $(global_logger())"

    xmlnets = allchildren(node ,"net") #! allocate Vector{XMLNode}
    isempty(xmlnets) && throw(PNML.MalformedException("<pnml> does not have any <net> elements"))

    # Vector of ID registries of the same length as the number of nets. May alias.
    idregistryvec = PnmlIDRegistry[]
    # Per-net vector of declaration dictionaries.
    TOPDECLVEC = DeclDict[]

    #---------------------------------------------------------------------
    # Initialize/populate global Vector{PnmlIDRegistry}. Also a field of `Model`.
    # And the declaration dictionary structure,
    #---------------------------------------------------------------------
    empty!(TOPDECLVEC) #  This prevents more than one PnmlModel existing.
    # Need a netid to populate
    for _ in xmlnets
        push!(idregistryvec, PnmlIDRegistry())
        push!(TOPDECLVEC, DeclDict())
    end
    length(xmlnets) == length(idregistryvec) ||
        error("length(xmlnets) $(length(xmlnets)) != length(idregistryvec) $(length(idregistryvec))")
    length(xmlnets) == length(TOPDECLVEC) ||
        error("length(xmlnets) $(length(xmlnets)) != length(TOPDECLVEC) $(length(TOPDECLVEC))")


    # Do not YET have a PNTD defined. Each net can be different net type.
    # Each net should think it has its own ID registry and declaration dictionary.
    # We can torture the code by violating that belief.
    # Note the use of ScopedValues.
    net_tup = ()
    for (netnode, reg, ddict) in zip(xmlnets, idregistryvec, TOPDECLVEC)
        #! Allocation? Runtime Dispatch? This is a parser! What did you expect?

        @with PNML.idregistry => reg PNML.DECLDICT => ddict begin
            # Each net gets its own ScopedValues for some things.
            net = parse_net(netnode)
            #~ At this point the XML has been processed into PnmlExpr terms.

            #todo test 0-arity expressions here, some are used for marking vector's initial value.
            # 0-arity means empty variable substitution.

            #! PLUGIN ACCESS POINT BEGIN
            # Ground terms used to set initial markings rewritten and evaluated here.

            #~ Evaluate expressions to create a mutable vector of markings.
            #^ This is used in enabling and firing rules.
            # printstyled("\ninitial marking vector $(pid(net)) $(net.namelabel))\n"; color=:light_red)
            m₀ = PNML.PNet.initial_markings(net)

            # Substitutions using indices into the marking vector.
            # Rewrite inscription and condition terms with variable substitution.

            # Create "color functions" that process variables using TermInterface expressions.
            # Pre-caculate as much as is practical.
            # Enabling rule
            # Firing rule.

            #^
            PNML.enabledXXX(net, m₀)
            #! END PLUGIN

            net_tup = (net_tup..., net)
        end
    end
    length(net_tup) > 0 || error("length(net_tup) is zero")


    #======================================================================================
    Want as much compiling of PnmlExpr trees as possible.
    Enabling and firing will use variables to do operations on place markings for high-level nets.

    We should evaluate ground terms here: markings are ground terms (no variables)
    Variable values are ground terms: used to transfer values between markings.

    PnmlExprs used to build functions of variables.

    Variables on input arcs used to test/access input place marking values.
    These are multiset elements. The PnmlMultiset basis sort is also the variable's sort.
    Variables may unpack PnmlTuples which are elements of a ProductSort.
    So the variable's sort is one of the product's.
    ProductSorts of the input arcs can be mutated into other ProductSorts (tupls) for output arcs.
    Variables that appear more than once refer to the same entity.
    This can result in token splitting/combination/creation.

    ======================================================================================#

    PnmlModel(net_tup, namespace, idregistryvec) #TODO Also keep TOPDECLVEC
end

"""
    find_toolinfos!(tools, node, pntd) -> tools

Calls `add_toolinfo(tools, info, pntd)` for each info found.
See [`Labels.get_toolinfos`](@ref) for accessing `ToolInfo`s.
"""
function find_toolinfos!(tools, node, pntd)
    toolinfos = allchildren(node, "toolspecific")
    if !isempty(toolinfos)
        for info in toolinfos
            tools = add_toolinfo(tools, info, pntd) # nets and pages
        end
    end
    return tools
end

"""
$(TYPEDSIGNATURES)
Return a [`PnmlNet`](@ref)`.
"""
function parse_net(node::XMLNode, pntd_override::Maybe{PnmlType} = nothing)
    nn = check_nodename(node, "net")
    netid = register_idof!(PNML.idregistry[], node)

    # Parse the required-by-specification petri net type input.
    pn_typedef = pnmltype(attribute(node, "type"))
    # Override of the Petri Net Type Definition (PNTD) value for fun & games.
    if isnothing(pntd_override)
        pntd = pn_typedef
    else
        pntd = pntd_override
        @info "net $id pntd set to $pntd, overrides $pn_typedef"
    end
    # Now we know the PNTD and can parse a net.

    isempty(allchildren(node ,"page")) &&
        throw(PNML.MalformedException("""<net> $netid does not have any <page> child"""))

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
    pgtype = PNML.page_type(typeof(pntd))

    # Create empty data structures to be filled with the parsed pnml XML.
    # The type information is used by PnmlNet.
    #-------------------------------------------------------------------------
    pagedict = OrderedDict{Symbol, pgtype}() # Page dictionary not part of PnmlNetData.
    netdata = PnmlNetData()
    netsets = PnmlNetKeys()
    PNML.tunesize!(netdata)
    PNML.tunesize!(netsets)

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
    PNML.fill_nonhl!(DECLDICT[])

    # Parse *ALL* Declarations here (assuming this the tree root),
    # this includes any Declarations attached to Pages.
    # Place any/all declarations in scoped value PNML.DECLDICT[]. #TODO can Context hold collections
    # It is like we are flattening only the declarations.
    # Only the first <declaration> label's text and graphics will be preserved.
    # Though what use graphics could add escapes me (and the specification).
    decls = alldecendents(node, "declaration") # There may be none.
    declaration = parse_declaration(decls, pntd)::Declaration

    PNML.validate_declarations(DECLDICT[]) # Pass ScopedValue

    # Collect all the toolinfos at this level (if any exist). Enables use in later parsing.
    tools = find_toolinfos!(nothing, node, pntd)::Maybe{Vector{ToolInfo}}

    PNML.Labels.validate_toolinfos(tools)

    # Create empty net.
    net = PnmlNet(; type=pntd, id=netid,
                    pagedict, netdata,
                    page_set=PNML.page_idset(netsets), #! XXX   NOT SORTED!   XXX
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
        else # Unclaimed labels are assumed to be every other child.
            CONFIG[].warn_on_unclaimed && @warn "found unexpected label of <net> id=$netid: $tag"
            net.labels = add_label(net.labels, child, pntd) # Net unclaimed label.
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
    push!(PNML.page_idset(netsets), pageid) # Record id before decending.
    pg = _parse_page!(pagedict, netdata, node, pntd, pageid)
    @assert pageid === pid(pg)
    pagedict[pageid] = pg
    return pagedict
end

"""
    _parse_page!(pagedict, netdata, node, pntd) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function _parse_page!(pagedict, netdata, node::XMLNode, pntd::T, pageid::Symbol) where {T<:PnmlType}
    netsets = PnmlNetKeys() # Allocate per-page data.

    name::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    labels::Maybe{Vector{PnmlLabel}}= nothing

    # Track which objects belong to this page.
    place_set      = PNML.place_idset(netsets)
    transition_set = PNML.transition_idset(netsets)
    arc_set        = PNML.arc_idset(netsets)
    rp_set         = PNML.refplace_idset(netsets)
    rt_set         = PNML.reftransition_idset(netsets)

    tools = find_toolinfos!(nothing, node, pntd)::Maybe{Vector{ToolInfo}}
    PNML.Labels.validate_toolinfos(tools)

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
            labels = add_label(labels, child, pntd) # page unclaimed label
        end
    end

    return Page(pntd, pageid, name, graphics, tools, labels,
                pagedict, # shared by net and all pages.
                netdata,  # shared by net and all pages.
                netsets,  # OrderedSet of ids "owned" by this page.
                )
end

# Reminder: set is per-Page, dict is per-Net
