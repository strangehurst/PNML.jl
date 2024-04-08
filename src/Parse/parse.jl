const PIDR = PnmlIDRegistry

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
    parse_pnml(xmlnode, idregistry) -> PnmlModel

Start parse from the root `node` of a well formed pnml XML document.
Return a [`PnmlModel`](@ref) holding one or more [`PnmlNet`](@ref).

The optional idregistry argument leads to internal weeds and should only be used after reading the code closely.
One effect is to have all `PnmlNet`
"""
function parse_pnml(node::XMLNode, idregistry::Maybe{PIDR}=nothing)
    check_nodename(node, "pnml")
    namespace = pnml_namespace(node)

    xmlnets = allchildren("net", node) #! allocate Vector{XMLNode}
    isempty(xmlnets) && throw(MalformedException("<pnml> does not have any <net> elements"))
    # Construct vector of PIDR samw length as xmlnets
    if !isnothing(idregistry)
        idregs = fill(idregistry, length(xmlnets)) # All nets share same PnmlIDRegistry.
    else
        idregs = PIDR[registry() for _ in xmlnets] # Each net has an independent PnmlIDRegistry.
    end
    @assert length(xmlnets) == length(idregs)

    # Do not YET have a PNTD defined. Each net can be different Net speciaization.
    net_tup = tuple((parse_net(net, reg) for (net, reg) in zip(xmlnets, idregs))...) #! Allocation? RUNTIME DISPATCH

    length(net_tup) > 0 || error("length(net_tup) is zero")
    if CONFIG.verbose #TODO Send this to a log file.
        @warn "CONFIG.verbose is true"
        println("PnmlModel $(length(net_tup)) xmlnets")
        for n in net_tup
            println("  ", pid(n), " :: ", typeof(n))
        end
    end
    PnmlModel(net_tup, namespace, idregs) #TODO registry tuple
end

"""
$(TYPEDSIGNATURES)
Return a [`PnmlNet`](@ref)`.
"""
function parse_net(node::XMLNode, idregistry::PIDR, pntd_override::Maybe{PnmlType} = nothing)
    nn = check_nodename(node, "net")
    netid = register_idof!(idregistry, node)

    # Parse the required-by-specification petri net type input.
    pn_typedef = PnmlTypeDefs.pnmltype(attribute(node, "type", "$nn missing type"))
    # Override of the Petri Net Type Definition (PNTD) value for fun & games.
    if isnothing(pntd_override)
        pntd = pn_typedef
    else
        pntd = pntd_override
        @info lazy"net $id pntd set to $pntd, overrides $pn_typedef"
    end
    # Now we know the PNTD and can parse.
    isempty(allchildren("page", node)) &&
        throw(MalformedException("""<net> $netid does not have any <page> child"""))

    return parse_net_1((netid,), node, pntd, idregistry) # RUNTIME DISPATCH
end

"""
Parse PNML <net> with a defined PnmlType used to set the expected behavior
of labels attached to the nodes of a petri net graph, including:
marking, inscription, condition and sorttype.

The `ids` tuple contains PNML ID `Symbol`s. The first is for this PnmlNet.
It is used to allocate a [`DeclDict`](@ref), a per-net collection of all <declarations> content.
[`TOPDECLDICTIONARY`](@ref) is a dictionary keyed by the PnmlNet's ID that holds a `DeclDict`.
Page IDs are appended as the XML tree is descended, followed by node IDs.

Note the use of `decldict(first(ids))` to access the per-net data structure
as  a global is possible wherever the netid is known.
"""
function parse_net_1(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    netid = first(ids)
    PNTD = typeof(pntd)
    pgtype = page_type(PNTD)

    # Create empty data structures to be filled with the parsed pnml XML.
    #-------------------------------------------------------------------------
    pagedict = OrderedDict{Symbol, pgtype}() # Page dictionary not part of PnmlNetData.
    netsets = PnmlNetKeys()
    tunesize!(netsets)
    netdata = PnmlNetData(pntd)
    tunesize!(netdata)

    @assert isregistered(idregistry, netid)
    @assert !haskey(TOPDECLDICTIONARY, netid) "net $netid already in TOPDECLDICTIONARY keys: $(collect(keys(TOPDECLDICTIONARY)))"
    TOPDECLDICTIONARY[netid] = DeclDict() # Allocate empty per-net global dictionary.

    namelabel = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    decl::Maybe{Declaration} = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing

    # Parse *ALL* Declarations first, this includes any Declarations attached to Pages.
    decls = alltags("declaration", node) #todo reverse parameter order
    decl = parse_declaration(ids, decls, pntd, idregistry)
    # All declarations in the decldict(netid) which is also attached to the `Declaration` label.
    # Which, because it is a label, must also support text, graphics and tools.
    # We also collect all the toolinfos.  Only the first <declaration> text and graphics will be preserved.
    # Though what use graphics could add escapes me.
    if !isempty(decldict(netid))
        @show(netid, decldict(netid)) #! debug
        validate_declarations(decldict(netid))
    end

    # Fill the pagedict, netsets, netdata by depth first traversal.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "page"
            parse_page!(pagedict, netdata, netsets, ids, child, pntd, idregistry)
        elseif tag == "declaration"
            # NOOP println("already done decls")
        elseif tag == "name"
            namelabel = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            @warn "ignoring unexpected child of <net>: 'graphics'"
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else # Labels are everything-else here.
            CONFIG.warn_on_unclaimed && @warn "found unexpected label of <net> id=$netid: $tag"
            if isnothing(labels)
                labels = PnmlLabel[]
            end
            add_label!(labels, child, pntd, idregistry)
        end
    end

    return PnmlNet(; type = pntd, id=netid, pagedict, netdata, page_set=page_idset(netsets),
                        declaration=decl, namelabel, tools, labels, idregistry)
end

"Call `parse_page!`, add page to dictionary and id set"
function parse_page!(pagedict, netdata, netsets, ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    check_nodename(node, "page")
    pageid = register_idof!(idregistry, node)
    push!(page_idset(netsets), pageid) # Doing depth-first traversal, record id before decending.
    pg = _parse_page!(pagedict, netdata, tuple(ids..., pageid), node, pntd, idregistry)
    @assert pageid === pid(pg)
    pagedict[pageid] = pg
    return nothing
end

"""
    parse_page!(pagedict, netdata, ids, node, pntd, idregistry) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function _parse_page!(pagedict, netdata, ids::Tuple, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    pageid = last(ids) # Just appended,
    netsets = PnmlNetKeys() # Allocate per-page data.

    decl::Maybe{Declaration} = nothing
    name = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    labels::Maybe{Vector{PnmlLabel}}= nothing

    place_set      = place_idset(netsets)
    transition_set = transition_idset(netsets)
    arc_set        = arc_idset(netsets)
    rp_set         = refplace_idset(netsets)
    rt_set         = reftransition_idset(netsets)

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "place"
            parse_place!(place_set, netdata.place_dict, ids, child, pntd, idregistry)
        elseif tag == "transition"
            parse_transition!(transition_set, netdata.transition_dict, ids, child, pntd, idregistry)
        elseif tag == "arc"
            parse_arc!(arc_set, netdata.arc_dict, ids, child, pntd, idregistry)
        elseif tag == "referencePlace"
            parse_refPlace!(rp_set, netdata.refplace_dict, ids, child, pntd, idregistry)
        elseif tag == "referenceTransition"
            parse_refTransition!(rt_set, netdata.reftransition_dict, ids, child, pntd, idregistry)
        elseif tag == "page" # Subpage
            parse_page!(pagedict, netdata, netsets, ids, child, pntd, idregistry)
        elseif tag == "declaration"
            # NOOP println("already done decls")
        elseif tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else
            CONFIG.warn_on_unclaimed && @warn("found unexpected label of <page>: $tag")
            if isnothing(labels)
                labels = PnmlLabel[]
            end
           add_label!(labels, child, pntd, idregistry)
        end
    end

    return Page(pntd, pageid, something(decl, Declaration()), name, graphics, tools, labels,
                pagedict, # shared by net and all pages.
                netdata,  # shared by net and all pages.
                netsets,  # Set of ids "owned" by this page.
                )
end

# set is per-Page, dict is per-Net
function parse_place!(place_set, place_dict, ids, child, pntd, idregistry)
    pl = parse_place(ids, child, pntd, idregistry)::valtype(place_dict)
    push!(place_set, pid(pl))
    place_dict[pid(pl)] = pl
    return nothing
end

function parse_transition!(transition_set, transition_dict, ids, child, pntd, idregistry)
    tr = parse_transition(ids, child, pntd, idregistry)::valtype(transition_dict)
    push!(transition_set, pid(tr))
    transition_dict[pid(tr)] = tr
    return nothing
end

function parse_arc!(arc_set, arc_dict, ids, child, pntd, idregistry)
    a = parse_arc(ids, child, pntd, idregistry)::valtype(arc_dict)
    push!(arc_set, pid(a))
    arc_dict[pid(a)] = a
    return nothing
end

function parse_refPlace!(refplace_set, refplace_dict, ids, child, pntd, idregistry)
    rp = parse_refPlace(ids, child, pntd, idregistry)::valtype(refplace_dict)
    push!(refplace_set, pid(rp))
    refplace_dict[pid(rp)] = rp
    return nothing
end

function parse_refTransition!(reftransition_set, reftransition_dict, ids, child, pntd, idregistry)
    rt = parse_refTransition(ids, child, pntd, idregistry)::valtype(reftransition_dict)
    push!(reftransition_set, pid(rt))
    reftransition_dict[pid(rt)] = rt
    return nothing
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "place")
    id       = register_idof!(idregistry, node)
    ids      = tuple(ids..., id)
    mark     = nothing
    sorttype = nothing
    name     = nothing
    graphics = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "initialMarking" || tag == "hlinitialMarking"
            mark = _parse_marking(ids, child, pntd, idregistry)
        elseif tag == "type"
            sorttype = parse_type(ids, child, pntd, idregistry)
        elseif tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            CONFIG.warn_on_unclaimed && @warn "found unexpected label of <place>: $tag"
            if isnothing(labels)
                labels = PnmlLabel[]
            end
            add_label!(labels, child, pntd, idregistry)
        end
    end

    mark = something(mark, default_marking(pntd))::marking_type(pntd)
    if isnothing(sorttype) # Infer tsortype from mark
        #TODO de-duplicate sorts
        sorttype = SortType("default", Ref{AbstractSort}(sortof(mark)), nothing, nothing)
    end
    # The sort of mark label must be the same as the sort of sorttype label.
    if !equalSorts(sortof(mark), sortof(sorttype))
        @warn(string("place id ", id, ": sort mismatch, expected ", sortof(mark), ", found ", sortof(sorttype)))
        @show mark sorttype ids
        # throw(MalformedException(string(
    end

    Place(pntd, id, mark, sorttype, name, graphics, tools, labels)
end

# By generalizing place marking label parsing we hope to return stable type.
# Calls marking parser specialized on the pntd.
_parse_marking(ids::Tuple, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} = parse_initialMarking(ids, node, pntd, idregistry)
_parse_marking(ids::Tuple, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore} = parse_hlinitialMarking(ids, node, pntd, idregistry)

const transition_xlabels = ("rate", "delay")
"""
$(TYPEDSIGNATURES)
"""
function parse_transition(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "transition")
    id   = register_idof!(idregistry, node)
    ids  = tuple(ids..., id)
    name = nothing
    cond::Maybe{Condition} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "condition"
            cond = parse_condition(ids, child, pntd, idregistry)
        elseif tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else # Labels (unclaimed) are everything-else. We expect at least one here!
            #! Create extension point here? Add more tag names to list?
            any(==(tag), transition_xlabels) ||
                @warn "unexpected label of <transition> id=$id: $tag"
            if isnothing(labels)
                labels = PnmlLabel[]
            end
            add_label!(labels, child, pntd, idregistry)
        end
    end

    Transition{typeof(pntd), condition_type(pntd)}(pntd, id,
                something(cond, default_condition(pntd)), name, graphics, tools, labels)
end

"""
    parse_arc(node::XMLNode, pntd::PnmlType, idregistry) -> Arc{typeof(pntd), typeof(inscription)}

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(ids::Tuple, node, pntd, idregistry::PIDR)
    nn = check_nodename(node, "arc")
    arcid = register_idof!(idregistry, node)
    ids = tuple(ids..., arcid)
    source = Symbol(attribute(node, "source", "missing source for arc $arcid"))
    target = Symbol(attribute(node, "target", "missing target for arc $arcid"))

    name = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing
    inscription::Maybe{Any} = nothing # 2 kinds of inscriptions
    graphics::Maybe{Graphics} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "inscription" || tag == "hlinscription"
            inscription = _parse_inscription(ids, child, pntd, idregistry)
        elseif tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            CONFIG.warn_on_unclaimed && @warn "found unexpected child of <arc>: $tag"
            if isnothing(labels)
                labels = PnmlLabel[]
            end
            add_label!(labels, child, pntd, idregistry)
        end
    end
    inscription = something(inscription, default_inscription(pntd))
    Arc(arcid, Ref(source), Ref(target), inscription, name, graphics, tools, labels)
end

# By specializing arc inscription label parsing we hope to return stable type.
_parse_inscription(ids::Tuple, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} =
    parse_inscription(ids, node, pntd, idregistry)
_parse_inscription(ids::Tuple, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore} =
    parse_hlinscription(ids, node, pntd, idregistry)

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referencePlace")
    id = register_idof!(idregistry, node)
    ids = tuple(ids..., id)
    ref = Symbol(attribute(node, "ref", "$nn $id missing ref attribute. trail = $ids"))
    name = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    labels::Maybe{Vector{PnmlLabel}} = nothing
    graphics::Maybe{Graphics} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            name => parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            CONFIG.warn_on_unclaimed && @warn "found unexpected child of <referencePlace>: $tag"
            if isnothing(labels)
                labels = PnmlLabel[]
            end
            add_label!(labels, child, pntd, idregistry)
        end
    end

    RefPlace(id, ref, name, graphics, tools, labels)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referenceTransition")
    id = register_idof!(idregistry, node)
    ids = tuple(ids..., id)
    ref = Symbol(attribute(node, "ref", "$nn $id missing ref attribute. trail = $ids"))
    name = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    labels::Maybe{Vector{PnmlLabel}}= nothing
    graphics::Maybe{Graphics} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
             add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            CONFIG.warn_on_unclaimed && @warn "found unexpected child of <referenceTransition>: $tag"
            if isnothing(labels)
                labels = PnmlLabel[]
            end
           add_label!(labels, child, pntd, idregistry)
        end
    end

    RefTransition(id, ref, name, graphics, tools, labels)
end

#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the stripped string of node's content.
"""
function parse_text(node::XMLNode, _::PnmlType, _::PIDR)
    check_nodename(node, "text")
    return string(strip(EzXML.nodecontent(node)))::String
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding text value and optional tool & GUI information.
"""
function parse_name(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    check_nodename(node, "name")
    text::Maybe{String} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = string(strip(EzXML.nodecontent(child)))::String
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else # No labels here
            @warn "ignoring unexpected child of <name>: '$tag'"
        end
    end

    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if isnothing(text)
        emsg = "<name> missing <text> element"
        if CONFIG.text_element_optional
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

Non-high-level `PnmlType` initial marking parser.
"""
function parse_initialMarking(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "initialMarking")
    l = parse_label_content(ids, node, parse_structure, pntd, idregistry)
    t = l.text
    if !isnothing(l.term) # There was a <structure> tag.
        @warn "$nn <structure> element not used YET by non high-level: $(l.term)"
    end
    value = isnothing(t) ? zero(marking_value_type(pntd)) : number_value(marking_value_type(pntd), t)

    Marking(value, l.graphics, l.tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
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
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else
            @warn("ignoring unexpected child of <inscription>: '$tag'")
        end
    end

    # Treat missing value as if the <inscription> element was absent.
    if isnothing(value)
        value = default_inscription(pntd)()
        CONFIG.warn_on_fixup &&
            @warn("missing or unparsable <inscription> value '$txt' replaced with $value")
    end
    Inscription(value, graphics, tools)
end

"""Parse label using a termparser argument function for any <structure>."""
function parse_label_content(ids::Tuple, node::XMLNode, termparser::F, pntd::PnmlType, idregistry) where {F <: Function}
    text::Maybe{Union{String,SubString{String}}} = nothing #
    term::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = parse_text(child, pntd, idregistry)
        elseif tag == "structure"
            term, sort = termparser(ids, child, pntd, idregistry) # Apply function/functor
            #!@show sort == sortof(term) uses DeclDict
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else
            @warn("ignoring unexpected child of <$(EzXML.nodename(node))>: '$tag'")
        end
    end
    return (; text, term, sort, graphics, tools)
end

"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a [`Term`](@ref) in the <structure>
child. We extend the pnml standard by allowing node content to be numeric:
parsed to `Int` and `Float64`.
"""
function parse_hlinitialMarking(ids::Tuple, node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    check_nodename(node, "hlinitialMarking")
    l = parse_label_content(ids, node, parse_marking_term, pntd, idregistry)
    #! TODO marking AbstractTerm match sort of place
    HLMarking(l.text, something(l.term, default_zero_term(pntd)), l.graphics, l.tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_marking_term(ids::Tuple, marknode, pntd, idregistry)
    check_nodename(marknode, "structure")
    if EzXML.haselement(marknode)
        term = EzXML.firstelement(marknode) # ignore any others
        mark, sort = parse_term(term, pntd, idregistry; ids)
        #TODO sortof(mark) == sortof(place) not decidable here
        return (mark, sort)
    end
    throw(ArgumentError("missing marking term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(ids::Tuple, node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    check_nodename(node, "hlinscription")
    l = parse_label_content(ids, node, parse_inscription_term, pntd, idregistry)
    HLInscription(l.text, something(l.term, default_one_term(pntd)), l.graphics, l.tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription_term(ids::Tuple, inode, pntd, idregistry)
    check_nodename(inode, "structure")
    if EzXML.haselement(inode)
        term = EzXML.firstelement(inode)
        insc, sort = parse_term(term, pntd, idregistry; ids)
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

function parse_condition(ids::Tuple, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore}
    check_nodename(node, "condition")
    l = parse_label_content(ids, node, parse_condition_term, pntd, idregistry)
    Condition(l.text, something(l.term, default_bool_term(pntd)), l.graphics, l.tools)
end

function parse_condition(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    check_nodename(node, "condition")
    println("condition for $pntd")
    l = parse_label_content(ids, node, parse_condition_term, pntd, idregistry)
    Condition(l.text, something(l.term, default_bool_term(pntd)), l.graphics, l.tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_condition_term(ids::Tuple, cnode::XMLNode, pntd::PnmlType, idregistry)
    check_nodename(cnode, "structure")
    if EzXML.haselement(cnode)
        term = EzXML.firstelement(cnode)
        cond, sort = parse_term(term, pntd, idregistry; ids)
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
See [`default_sort`](@ref).
"""
function parse_type(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "type")
    l = parse_label_content(ids, node, parse_sorttype_term, pntd, idregistry)
    # Use Ref to avoid boxing the sort.
    SortType(l.text, Ref{AbstractSort}(something(l.term, default_sort(pntd)())), l.graphics, l.tools)
end
#=
#~ MOVE THIS
Built from many different elements that contain a Sort:
type, namedsort, variabledecl, multisetsort, productsort, numberconstant, partition...

Sort = BuiltInSort | MultisetSort | ProductSort | UserSort
=#
"""
$(TYPEDSIGNATURES)
The PNML "type" of a `Place` is a "sort" of the high-level many-sorted algebra.
"""
function parse_sorttype_term(ids::Tuple, typenode, pntd, idregistry)
    check_nodename(typenode, "structure")
    EzXML.haselement(typenode) || throw(ArgumentError("missing sort type element in <structure> trail = $ids"))
    termnode = EzXML.firstelement(typenode)::XMLNode # Expect only child element to be a sort.
    sorttype = parse_sort(termnode, pntd, idregistry; ids)::AbstractSort
    isa(sorttype, MultisetSort) && error("multiset sort not allowed for Place type. trail = $ids")
    return (sorttype, sortof(sorttype))
end

"""
$(TYPEDSIGNATURES)

Return [`Structure`](@ref) holding an XML <structure>.
Should be inside of an PNML label.
A "claimed" label usually elids the <structure> level (does not call this method).
"""
function parse_structure(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
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
function parse_label(node::XMLNode, _::PnmlType, _::PIDR)
    @assert node !== nothing
    nn = check_nodename(node, "label")
    @warn "there is a label named 'label'"
    (; :tag => Symbol(nn), :xml => node) # Always add xml because this is unexpected.
end
