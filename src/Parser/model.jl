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

function pnmlmodel(filename::AbstractString; context...)
    isempty(filename) && throw(ArgumentError("must have a non-empty file name argument"))
    pnmlmodel(EzXML.root(EzXML.readxml(filename)); context...)
end

function pnmlmodel(node::XMLNode; context...)
    check_nodename(node, "pnml")
    namespace = pnml_namespace(node) # Model level XML value.

    net_tup = ()
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "net"

            parse_context = parser_context()::ParseContext
            #! parse_context LabelParser[] filled using context
            #! parse_context ToolParser[] filled using context

            # Each net can be different PTND.
            net = parse_net(child; parse_context)::PnmlNet # Fully formed

            #TODO Add verification plugin here. Make our verifiers the 1st plugin.
            net_tup = (net_tup..., net)
        else
            @error "`<model>` has umexpected child $(repr(tag))"
        end
    end
    length(net_tup) > 0 ||
        throw(PNML.MalformedException("<pnml> does not have any <net> elements"))


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

    PnmlModel(net_tup, namespace)
end

"""
    parse_net(node::XMLNode[; options...]) -> PnmlNet

[`PnmlNet`](@ref) created from an `<net>` `XMLNode`.

# Arguments
 - pntd_override::Maybe{PnmlType}
 - parse_context::ParseContext
"""
function parse_net(node::XMLNode;
                    pntd_override::Maybe{PnmlType} = nothing,
                    parse_context::ParseContext)

    netid = register_idof!(parse_context.idregistry, node)

    # Parse the pnml net type attribute. Not the place sort `<type>` label.
    pntd = let pn_typedef = pnmltype(attribute(node, "type"))
        if isnothing(pntd_override)
            pn_typedef
        else
            # Override of the Petri Net Type Definition (PNTD) value for fun & games.
            @info "net $id pntd set to $pntd_override, overrides $pn_typedef"
            pntd_override
        end
    end

    # Now we know the PNTD and can parse a net.
    net = parse_net_1!(node, pntd, netid; parse_context)
    #~ --------------------------------------------------------------
    #~ At this point the XML has been processed into PnmlExpr terms.
    #~ --------------------------------------------------------------

    # Ground terms used to set initial markings can be rewritten and evaluated here.
    # 0-arity operator means empty variable substitution, i.e. constant.

    #~ Evaluate expressions to create a mutable vector of markings.
    #todo API for using ToolInfo in expressions?
    #^ Marking vector is used in enabling and firing rules.
    #m₀ = PNML.PNet.initial_markings(net)

    # ?Rewrite inscription and condition terms with variable substitution.

    # Create "color functions" that process variables using TermInterface expressions.
    # Pre-caculate as much as is practical.

    #PNML.enabledXXX(net, m₀) # enabling rule? #todo what side effect?
    return net
end

"""
Parse PNML <net> with a defined PnmlType used to set the expected behavior of labels
attached to the nodes of a petri net graph, including: marking, inscription, condition and sorttype.

Page IDs are appended as the XML tree is descended, followed by node IDs.
"""
function parse_net_1!(node::XMLNode, pntd::PnmlType, netid::Symbol; parse_context::ParseContext)
    pgtype = PNML.page_type(typeof(pntd))

    # Create empty data structures to be filled with the parsed pnml XML.
    # The type information is used by PnmlNet.
    #-------------------------------------------------------------------------
    pagedict = OrderedDict{Symbol, pgtype}() # Page dictionary not part of PnmlNetData.
    netdata = PnmlNetData()
    netsets = PnmlNetKeys()
    PNML.tunesize!(netdata)
    PNML.tunesize!(netsets)

    @assert isregistered(parse_context.idregistry, netid)

    namelabel = let n = firstchild(node, "name")
        isnothing(n) ? nothing : parse_name(n, pntd; parse_context)::Name
    end

    # We use the declarations toolkit for non-high-level nets,
    # and assume a minimum function for high-level nets.
    # Declarations present in the input file will overwrite these.
    #! PNML.fill_nonhl!(dd) done in `decldict(idreg)`

    # Parse *ALL* Declarations here (assuming this the tree root),
    # this includes any Declarations attached to Pages.
    # Place any/all declarations in net-level DeclDict.
    # It is like we are flattening only the declarations.
    # Only the first <declaration> label's text and graphics will be preserved.
    # Though what use graphics could add escapes me (and the standard).
    decls = alldecendents(node, "declaration") # There may be none.

    # If there are multiple `<declaration>`s parsed the will share the DeclDict.
    declaration = parse_declaration!(parse_context, decls, pntd)::Declaration
    @assert PNML.decldict(declaration) === parse_context.ddict
    PNML.validate_declarations(PNML.decldict(declaration)) #

    # Collect all the toolinfos at this level (if any exist). Enables use in later parsing.
    tools = find_toolinfos!(nothing, node, pntd, parse_context)::Maybe{Vector{ToolInfo}}

    PNML.Labels.validate_toolinfos(tools)

    # Create empty net (with declarations, net-level toolinfos parsed).
    net = PnmlNet(; type=pntd, id=netid,
                    pagedict, netdata,
                    page_set=PNML.page_idset(netsets), #! Not sorted!
                    declaration, # Label, Wraps DeclDict.
                    namelabel, tools,
                    parse_context.idregistry
                    )

    #! TODO add Ref(net) to parse_context

    # Fill the pagedict, netsets, netdata by depth first traversal of pages.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag in ["declaration", "name", "toolspecific"]
            # println("net already parsed ", tag) #! debug
        elseif tag == "page"
            # All graph node content resides in page node trees.
            # Threre is always at least one page. A forest of multiple page trees is allowd.
            # Note that one can always flatten a multi-page PnmlNet to a single page
            # and have the same graph with all the non-graphics labels preserved.
            # Un-flattened is not well tested!
            parse_page!(pagedict, netdata, netsets, child, pntd; parse_context) #
        elseif tag == "graphics"
            @warn "ignoring unexpected child of <net>: 'graphics'"
        else
            CONFIG[].warn_on_unclaimed && @warn "found unexpected label of <net> id=$netid: $tag"
            net.labels = add_label(net.labels, child, pntd, parse_context) # Net unclaimed label.
            # The standard allows meta-models defined upon the core to define
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
function parse_page!(pagedict, netdata, netsets, node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "page")
    pageid = register_idof!(parse_context.idregistry, node)
    push!(PNML.page_idset(netsets), pageid) # Record id before decending.
    pg = _parse_page!(pagedict, netdata, node, pntd, pageid; parse_context)
    @assert pageid === pid(pg)
    pagedict[pageid] = pg
    return pagedict
end

"""
    _parse_page!(pagedict, netdata, node, pntd; ddict) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function _parse_page!(pagedict, netdata, node::XMLNode, pntd::T, pageid::Symbol;
            parse_context::ParseContext) where {T<:PnmlType}
    # Allocate per-page data structures.
    netsets = PnmlNetKeys()
    # Track which objects belong to this page.
    place_set      = PNML.place_idset(netsets)
    transition_set = PNML.transition_idset(netsets)
    arc_set        = PNML.arc_idset(netsets)
    rp_set         = PNML.refplace_idset(netsets)
    rt_set         = PNML.reftransition_idset(netsets)

    namelabel::Maybe{Name} = nothing
    graphics::Maybe{Graphics} = nothing
    labels::Maybe{Vector{PnmlLabel}}= nothing
    tools = find_toolinfos!(nothing, node, pntd, parse_context)::Maybe{Vector{ToolInfo}}

    PNML.Labels.validate_toolinfos(tools)

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "place"
            parse_place!(place_set, netdata, child, pntd; parse_context)
        elseif tag == "referencePlace"
            parse_refPlace!(rp_set, netdata, child, pntd; parse_context)
        elseif tag == "transition"
            parse_transition!(transition_set, netdata, child, pntd; parse_context)
        elseif tag == "referenceTransition"
            parse_refTransition!(rt_set, netdata, child, pntd; parse_context)
        elseif tag == "arc"
            parse_arc!(arc_set, netdata, child, pntd; parse_context)
        # if tag in ["declaration", "place", "transition", "arc",
        #             "referencePlace", "referenceTransition", "toolspecific"]
        #     # NOOP println("already parsed ", tag)
        elseif tag == "page" # Subpage
            parse_page!(pagedict, netdata, netsets, child, pntd; parse_context)
        elseif tag == "name"
            namelabel = parse_name(child, pntd; parse_context)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        else
            CONFIG[].warn_on_unclaimed && @warn("found unexpected label of <page>: $tag")
            labels = add_label(labels, child, pntd, parse_context)
        end
    end

    return Page(pntd, pageid, namelabel, graphics, tools, labels,
                pagedict, # shared by net and all pages.
                netdata,  # shared by net and all pages.
                netsets,  # OrderedSet of ids "owned" by this page.
                )
end


"""
    find_toolinfos!(tools, node, pntd, parse_context::ParseContext) -> tools

Calls `add_toolinfo(tools, info, pntd, parse_context)` for each info found.
See [`Labels.get_toolinfos`](@ref) for accessing `ToolInfo`s.
"""
function find_toolinfos!(tools, node, pntd, parse_context::ParseContext)
    for info in allchildren(node, "toolspecific")
        tools = add_toolinfo(tools, info, pntd, parse_context) # nets and pages
    end
    return tools
end

# Reminder: set is per-Page, dict is per-Net
