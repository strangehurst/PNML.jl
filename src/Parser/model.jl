#TODO test pnml_namespace

"""
$(TYPEDSIGNATURES)

Return namespace of `node` or default value [`pnml_ns`](@ref) with warning (or error).
"""
function pnml_namespace(node::XMLNode;
                        missing_ns_fatal::Bool=false,
                        default_ns::String=pnml_ns)
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

function pnmlmodel(filename::AbstractString; kwargs...)
    isempty(filename) && throw(ArgumentError("must have a non-empty file name argument"))
    pnmlmodel(EzXML.root(EzXML.readxml(filename)); kwargs...)
end

function pnmlmodel(node::XMLNode; kwargs...)
    check_nodename(node, "pnml")
    namespace = pnml_namespace(node) # Model level XML value.
    net_tup = ()
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "net"
            net = parse_net(child; kwargs...)::PnmlNet # Fully formed
            net_tup = (net_tup..., net)
        else
            @error "<model> has unexpected child $tag"
        end
    end
    length(net_tup) > 0 ||
        throw(PNML.MalformedException("<pnml> does not have any <net> elements"))

    PnmlModel(net_tup, namespace)
end

"""
    parse_net(node::XMLNode[; options...]) -> PnmlNet

[`PnmlNet`](@ref) created from an `<net>` `XMLNode`.

# Arguments
 - pntd_override::Maybe{PnmlType}
"""
function parse_net(node::XMLNode; pntd_override::Maybe{String} = nothing, kwargs...)
    idregistry = IDRegistry() # empty
    netid = register_idof!(idregistry, node)

    # Parse the pnml net type attribute. Not the place sort `<type>` label.
    typestr = attribute(node, "type")
    if !isnothing(pntd_override)
        # Override of the Petri Net Type Definition (PNTD) value for fun & games.
        @info "net $netid pntd set to $pntd_override, overrides $typestr"
        typestr = pntd_override
    end
    pntd = pnmltype(typestr)
    D()&& println("\n## parse_net ", netid, " of type ", pntd)

    #----------------------------------------------------------------
    # Create net with empty data containers to be filled during parsing.
    # We already used `idregistry` and `pagedict` needs to be type stable.
    #-------------------------------------------------------------------------------------
    net = PnmlNet(; type=pntd, id=netid, idregistry,
                    pagedict = OrderedDict{Symbol, Page{typeof(pntd)}}(),
                    )
    # First fill the built-in label parser plugins.
    fill_builtin_labelparsers!(net.labelparser)
    @assert !isempty(net.labelparser)

    if haskey(kwargs, :lp) && !isnothing(kwargs[:lp]) && !isempty(kwargs[:lp])
        @warn "add $(length(kwargs[:lp])) labelparser(s)"
        foreach(kwargs[:lp]) do lparser
            #! todo sanity check labelparser
            @show lparser #! bring-up
            net.labelparser[lparser.tag] = lparser.func
        end
        @show net.labelparser #! bring-up
    end

    fill_builtin_toolparsers!(net.toolparser) # built-in toolparsers

    # if haskey(kwargs, :tp) && !isnothing(kwargs[:tp]) && !isempty(kwargs[:tp])
    #     @warn "add $(length(kwargs[:tp])) toolparser(s)"
    #     foreach(kwargs[:tp]) do tparser
    #         #! todo sanity check toolparser
    #         @show tparser
    #         push!(net.toolparser, tparser) # NB: a vector #TODO?
    #     end
    #     @show net.toolparser
    # end

    fill_builtin_sorts!(net)

    # Parse *ALL* Declarations here. Including any Declarations attached to Pages.
    # Place any/all declarations in single net-level DeclDict.
    # It is like we are flattening only the declarations.
    # Only the first <declaration> label's text and graphics will be preserved.
    # Though what use graphics could add escapes me (and the standard).
    decls = alldecendents(node, "declaration") # There may be none.
    # If there are multiple `<declaration>`s parsed they will share the DeclDict.
    net.declaration = parse_declaration!(net, decls, pntd)::Declaration

    let n = firstchild(node, "name")
        if !isnothing(n)
            net.namelabel = net.labelparser[:name](n, pntd; net, parentid=netid)::Name
        end
    end

    # Collect all the toolspecinfos at net level for use in later parsing.
    find_toolinfos!(net.toolspecinfos, node, pntd, net)
    PNML.Labels.validate_toolinfos(net.toolspecinfos)

    #--------------------------------------------------------------------
    # Fill `net`
    #--------------------------------------------------------------------
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "page"
            # There is always at least one page. A forest of multiple page trees is allowd.
            parse_page!(net, net.page_idset, child, pntd)
        elseif tag in ["declaration", "name", "toolspecific"]
            # println("NOOP: already parsed ", tag)
        elseif tag == "graphics"
            @warn "ignoring unexpected child of <net>: <graphics>"
        else
            unexpected_label!(net.extralabels, child, Symbol(tag), pntd; net, parentid=netid)
        end
    end
    PNML.verify(net, CONFIG[].verbose)

    #~ --------------------------------------------------------------
    #~ At this point the XML has been processed into PnmlExpr terms.
    #~ --------------------------------------------------------------

    #^ Ground terms used to set initial markings can be rewritten and evaluated here.
    #? Rewrite inscription and condition terms with variable substitution.
    #? 0-arity operator means empty variable substitution, i.e. constant.
    #TODO create API for using ToolInfo in expressions

    # Create "color functions" that process variables using TermInterface expressions.
    # Pre-caculate as much as is practical.

    #~ Evaluate expressions to create a mutable vector of markings.
    #^ Marking vector is used in enabling and firing rules.
    #m₀ = PNML.PNet.initial_markings(net)
    #PNML.enabledXXX(net, m₀) # enabling rule?

    return net
end

"""
    unexpected_label!(extralabels, child, tag, pntd; net, parentid)

Apply a labelparser to `child` if one matches `tag`, otherwise call [`xmldict`](@ref).
Add to `extralabels`.
"""
function unexpected_label!(extralabels::AbstractDict, child::XMLNode, tag::Symbol, pntd; net, parentid::Symbol)
    #println("unexpected_label! $tag")
    if haskey(net.labelparser, tag)
        #@error "labelparser[$(repr(tag))] " net.labelparser[tag] #! bring-up
        extralabels[tag] = net.labelparser[tag](child, pntd; net, parentid)
    else
        xd = xmldict(child)
        xd isa AbstractString &&
            error("PNML Labels must have XML structure, not just text content, found $xd")
        l = PnmlLabel(tag, xd, net)
        #CONFIG[].warn_on_unclaimed &&
        @info "add PnmlLabel $(repr(tag)) to $(repr(parentid))" l #! bring-up? todo logginng
        extralabels[tag] = l
    end
    return nothing
end

"""
    parse_page!(net, page_idset, node, pntd) -> Nothing

Call `_parse_page!` to create a page with its own `netsets`.
Add created page to parent's `page_idset` and `pagedict(net)`.
"""
function parse_page!(net::PnmlNet, page_idset, node::XMLNode, pntd::PnmlType)
    check_nodename(node, "page")
    pageid = register_idof!(PNML.registry_of(net), node)
    push!(page_idset, pageid) # Record id before decending.
    pg = __parse_page!(net, node, pntd, pageid)
    @assert pageid === pid(pg)
    pagedict(net)[pageid] = pg
    return nothing
end

"""
    __parse_page!(net, node, pntd, pageid) -> Page

Return `Page`. `pageid` already parsed from `node`.
"""
function __parse_page!(net::AbstractPnmlNet, node::XMLNode, pntd::T, pageid::Symbol) where {T<:PnmlType}
    D()&& println("## parse_page ", pageid)
    #---------------------------------------------------------
    # Create "empty" page. Will have `toolinfos` parsed.
    #---------------------------------------------------------
    page = Page{T,typeof(net)}(; net, pntd, id = pageid, netsets = PnmlNetKeys(),
        toolspecinfos = find_toolinfos!(nothing, node, pntd, net)::Maybe{Vector{ToolInfo}})

    PNML.Labels.validate_toolinfos(toolinfos(page))

    #---------------------------------------------------------
    # Fill page with graph nodes & arcs.
    #---------------------------------------------------------
    for child in EzXML.eachelement(node)
        nname = Symbol(EzXML.nodename(child))
        if nname == :place
            parse_place!(netsets(page), netdata(net), child, pntd, net)
        elseif nname == :referencePlace
            parse_refPlace!(netsets(page), netdata(net), child, pntd, net)
        elseif nname == :transition
            parse_transition!(netsets(page), netdata(net), child, pntd, net)
        elseif nname == :referenceTransition
            parse_refTransition!(netsets(page), netdata(net), child, pntd, net)
        elseif nname == :arc
            parse_arc!(netsets(page), netdata(net), child, pntd, net)
        elseif nname in [:declaration, :toolspecific]
             # NOOP already parsed
        elseif nname == :page
            # Subpage stored at net-level with key in page's id set.
            parse_page!(net, page_idset(page), child, pntd)
        elseif nname == :name
            page.namelabel = net.labelparser[nname](child, pntd; net, parentid=pageid)
        elseif nname == :graphics
            page.graphics = net.labelparser[nname](child, pntd)
        else
            unexpected_label!(page.extralabels, child, nname, pntd; net, parentid=pageid)
        end
    end

    return page
end

"""
    find_toolinfos!(toolspecinfos, node, pntd, net) -> toolinfos

Calls `add_toolinfo(toolspecinfos, info, pntd, net)` for each info found.
See [`Labels.get_toolinfos`](@ref) for accessing `ToolInfo`s.
"""
function find_toolinfos!(toolspecinfos::Maybe{Vector{ToolInfo}}, node, pntd, net)
    for info in allchildren(node, "toolspecific")
        toolspecinfos = add_toolinfo(toolspecinfos, info, pntd, net) # nets and pages
    end
    return toolspecinfos
end
