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
function parse_str(str::AbstractString)
    isempty(str) && throw(ArgumentError("parse_str must have a non-empty string argument"))
    idregistry = registry()
    # Good place for debugging.
    parse_pnml(xmlroot(str), idregistry)
end

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a file containing XML.
See [`parse_str`](@ref) and [`parse_pnml`](@ref).
"""
function parse_file(fname::AbstractString)
    isempty(fname) && throw(ArgumentError("parse_file must have a non-empty file name argument"))
    idregistry = registry()
    # Good place for debugging.
    parse_pnml(EzXML.root(EzXML.readxml(fname)), idregistry)
end

"""
    parse_pnml(xmlnode, idregistry) -> PnmlModel

Start parse from the root `node` of a well formed pnml XML document.
Return a [`PnmlModel`](@ref) holding one or more [`PnmlNet`](@ref).
"""
function parse_pnml(node::XMLNode, idregistry::PIDR)
    nn = check_nodename(node, "pnml")
    namespace = pnml_namespace(node)
    nets = allchildren("net", node) #! allocate Vector{XMLNode}
    isempty(nets) && throw(MalformedException("<pnml> does not have any <net> elements"))

    # Do not yet have a PNTD defined. Each net can be different Net speciaization.
    net_tup = tuple((parse_net(net, idregistry) for net in nets)...) #! Allocation?
    @assert length(net_tup) > 0
    if CONFIG.verbose
        @warn "CONFIG.verbose is true"
        println("PnmlModel $(length(net_tup)) nets")
        for n in net_tup
            println("  ", pid(n), " :: ", typeof(n))
        end
    end
    PnmlModel(net_tup, namespace, idregistry)
end

"""
$(TYPEDSIGNATURES)
Return a [`PnmlNet`](@ref)`.
"""
function parse_net(node::XMLNode, idregistry::PIDR, pntd_override::Maybe{PnmlType} = nothing)
    nn = check_nodename(node, "net")
    haskey(node, "id") || throw(MissingIDException(nn))
    haskey(node, "type") || throw(MalformedException(lazy"$nn missing type"))
    type = node["type"]
    if CONFIG.verbose
        println("""

        =========
        parse_net: $(node["id"]) $type $(pntd_override !== nothing && pntd_override)
        """)
    end

    isempty(allchildren("page", node)) &&
        throw(MalformedException("""<net> $(node["id"]) does not have any <page> child"""))

    # Although the specification says the petri net type definition (pntd) MUST BE attached
    # to the <net> element, it is allowed by this package to override that value.
    pn_typedef = pnmltype(type)
    if isnothing(pntd_override)
        pntd = pn_typedef
    else
        pntd = pntd_override
        @info lazy"net $id pntd set to $pntd, overrides $pn_typedef"
    end

    # Now we know the PNTD and can parse.
    net = parse_net_1(node, pntd, idregistry)
    return net
end

"""
Parse net with a defined PnmlType. The PNTD is used to set
the marking, inscription, condition and sort type parameters.
"""
function parse_net_1(node::XMLNode, pntd::PnmlType, idregistry::PIDR)# where {PNTD<:PnmlType}
    PNTD = typeof(pntd)
    pgtype = page_type(PNTD)

    # Create empty data structures to be filled with the parsed pnml XML.
    #-------------------------------------------------------------------------
    pagedict = OrderedDict{Symbol, pgtype}() # Page dictionary not part of PnmlNetData.
    netsets = PnmlNetKeys()
    netdata = PnmlNetData(pntd)

    id   = register_id!(idregistry, node["id"])
    name = nothing
    decl::Maybe{Declaration} = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]
    #println("pagedict"); dump(pagedict)
    #println("netsets"); dump(netsets)
    #println("netdata"); dump(netdata)
    # Fill the pagedict, netsets, netdata by depth first traversal.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "page"
            _parse_page!(pagedict, netdata, netsets, child, pntd, idregistry)
        elseif tag == "declaration" # Make non-high-level also have declaration of some kind.
            decl = parse_declaration(child, pntd, idregistry)
        elseif tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            @warn "<net> ignoring unexpected <graphics> element"
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            @warn "unexpected child of <net>: $tag"
            add_label!(labels, child, pntd, idregistry)
        end
    end

    if CONFIG.verbose
        println(lazy"""
                Net $id, $(length(pagedict))  Pages:  $(keys(pagedict))
                    page ids: $(collect(values(page_idset(netsets))))
                """)
    end
    return PnmlNet(; type = pntd, id, pagedict, netdata, page_set = page_idset(netsets),
                    declaration = something(decl, Declaration()),
                    name, tools, labels)
end

"Call `parse_page!`, add page to dictionary and id set"
function _parse_page!(pagedict, netdata, netsets, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    pg = parse_page!(pagedict, netdata, node, pntd, idregistry)
    # Add to dictonary and id set.
    pageid = pid(pg)
    pagedict[pageid] = pg
    push!(page_idset(netsets), pageid)
    return nothing
end

"""
    parse_page!(tup, node, pntd, idregistry) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function parse_page!(pagedict, netdata, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    nn = check_nodename(node, "page")
    haskey(node, "id") || throw(MissingIDException(nn))
    pageid = register_id!(idregistry, node["id"])
    CONFIG.verbose && println("""parse $nn $pntd $pageid""")
    netsets = PnmlNetKeys() # per-page data

    #a = @allocated begin
    decl::Maybe{Declaration} = nothing
    name = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]

    place_set      = place_idset(netsets)
    transition_set = transition_idset(netsets)
    arc_set        = arc_idset(netsets)
    rp_set         = refplace_idset(netsets)
    rt_set         = reftransition_idset(netsets)

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        #CONFIG.verbose && println(lazy"""parse $tag $(child["id"])""")
        @match tag begin
            "place"               => parse_place!(place_set, netdata.place_dict, child, pntd, idregistry)
            "transition"          => parse_transition!(transition_set, netdata.transition_dict, child, pntd, idregistry)
            "arc"                 => parse_arc!(arc_set, netdata.arc_dict, child, pntd, idregistry)
            "referencePlace"      => parse_refPlace!(rp_set, netdata.refplace_dict, child, pntd, idregistry)
            "referenceTransition" => parse_refTransition!(rt_set, netdata.reftransition_dict, child, pntd, idregistry)
            "page"                => _parse_page!(pagedict, netdata, netsets, child, pntd, idregistry)
            "declaration"         => (decl = parse_declaration(child, pntd, idregistry))
            "name"                => (name = parse_name(child, pntd, idregistry))
            "graphics"            => (graphics = parse_graphics(child, pntd, idregistry))
            "toolspecific"        => add_toolinfo!(tools, child, pntd, idregistry)
            _                     => (@warn("unexpected child of <page>: $tag"),
                                        add_label!(labels, child, pntd, idregistry))
        end
    end
    #end; println("parse_page! $pageid allocated: ", a)

    CONFIG.verbose && println("Page $pageid name '$name' add to ", keys(pagedict))

    return Page(pntd, pageid, something(decl, Declaration()), name, graphics, tools, labels,
                pagedict, # shared by net and all pages.
                netdata,  # shared by net and all pages.
                netsets,  # Set of ids "owned" by this page.
                )
end

# set is per-Page, dict is per-Net
function parse_place!(place_set, place_dict, child, pntd, idregistry)
    pl = parse_place(child, pntd, idregistry)::valtype(place_dict)
    push!(place_set, pid(pl))
    place_dict[pid(pl)] = pl
    return nothing
end

function parse_transition!(transition_set, transition_dict, child, pntd, idregistry)
    tr = parse_transition(child, pntd, idregistry)::valtype(transition_dict)
    push!(transition_set, pid(tr))
    transition_dict[pid(tr)] = tr
    return nothing
end

function parse_arc!(arc_set, arc_dict, child, pntd, idregistry)
    a = parse_arc(child, pntd, idregistry)::valtype(arc_dict)
    push!(arc_set, pid(a))
    arc_dict[pid(a)] = a
    return nothing
end

function parse_refPlace!(refplace_set, refplace_dict, child, pntd, idregistry)
    rp = parse_refPlace(child, pntd, idregistry)::valtype(refplace_dict)
    push!(refplace_set, pid(rp))
    refplace_dict[pid(rp)] = rp
    return nothing
end

function parse_refTransition!(reftransition_set, reftransition_dict, child, pntd, idregistry)
    rt = parse_refTransition(child, pntd, idregistry)::valtype(reftransition_dict)
    push!(reftransition_set, pid(rt))
    reftransition_dict[pid(rt)] = rt
    return nothing
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "place")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id       = register_id!(idregistry, node["id"])
    mark     = nothing
    sorttype = nothing
    name     = nothing
    graphics = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]

    #a = @allocated begin
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "initialMarking" || tag == "hlinitialMarking"
            mark = _parse_marking(child, pntd, idregistry)
        elseif tag == "type"
            sorttype = parse_type(child, pntd, idregistry)
            CONFIG.verbose && println("parse_place $id sorttype $sorttype")
        elseif tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            @warn "unexpected child of <place>: $tag"
            add_label!(labels, child, pntd, idregistry)
        end
    end
    #end; println("parse_place $id allocated: ", a)
    mark = something(mark, default_marking(pntd))::marking_type(pntd)
    sorttype = something(sorttype, default_sorttype(pntd))::SortType
    #println("parse_place $pntd "); dump(mark); dump(sorttype)

    Place(pntd, id, mark, sorttype, name, graphics, tools, labels)
end

# By generalizing place marking label parsing we hope to return stable type.
# Calls marking parser specialized on the pntd.
_parse_marking(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} = parse_initialMarking(node, pntd, idregistry)
_parse_marking(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore} = parse_hlinitialMarking(node, pntd, idregistry)

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "transition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id   = register_id!(idregistry, node["id"])
    name = nothing
    cond::Maybe{Condition} = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]

    #a = @allocated begin
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "condition"
            cond = parse_condition(child, pntd, idregistry)
        elseif tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            # We expecte at least one unclaimed label here!
            tag != "rate" && @warn "unexpected child of <transition>: $tag"
            add_label!(labels, child, pntd, idregistry)
        end
    end
    #end; println("parse_transition $id allocated: ", a)

    Transition{typeof(pntd), condition_type(pntd)}(pntd, id,
                something(cond, default_condition(pntd)), name, graphics, tools, labels)
end

"""
    parse_arc(node::XMLNode, pntd::PnmlType, idregistry) -> Arc{typeof(pntd), typeof(inscription)}

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node, pntd, idregistry::PIDR)
    nn = check_nodename(node, "arc")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    nodeid = register_id!(idregistry, node["id"])
    haskey(node, "source") || throw(ArgumentError("missing source for arc $nodeid"))
    haskey(node, "target") || throw(ArgumentError("missing target for arc $nodeid"))
    source = Symbol(node["source"])
    target = Symbol(node["target"])

    name = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]
    inscription::Maybe{Any} = nothing # 2 kinds of inscriptions
    graphics::Maybe{Graphics} = nothing

    CONFIG.verbose && println("parse arc $nodeid $source -> $target")

    #a = @allocated begin

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "inscription" || tag == "hlinscription"
            inscription = _parse_inscription(child, pntd, idregistry)
        elseif tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics => parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            @warn "unexpected child of <arc>: $tag"
            add_label!(labels, child, pntd, idregistry)
        end
    end
    #end; println("parse_arc $nodeid allocated ", a)

    Arc(pntd, nodeid, source, target, something(inscription, default_inscription(pntd)),
                name, graphics, tools, labels)
end

# By specializing arc inscription label parsing we hope to return stable type.
_parse_inscription(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} = parse_inscription(node, pntd, idregistry)
_parse_inscription(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore} = parse_hlinscription(node, pntd, idregistry)

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referencePlace")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "ref") || throw(MalformedException("$nn $id missing ref attribute"))
    ref = Symbol(node["ref"])
    name = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]
    graphics::Maybe{Graphics} = nothing

    #a = @allocated begin
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            name => parse_name(child, pntd, idregistry)
        elseif tag === "graphics"
            graphics => parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            @warn "unexpected child of <referencePlace>: $tag"
            add_label!(labels, child, pntd, idregistry)
        end
    end
    #end; println("parse_refPlace $id allocated ", a)

    RefPlace(pntd, id, ref, name, graphics, tools, labels)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referenceTransition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "ref") || throw(MalformedException("$nn $id missing ref attribute"))
    ref = Symbol(node["ref"])
    name = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]
    graphics::Maybe{Graphics} = nothing

    #a = @allocated begin
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            name = parse_name(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics => parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            @warn "unexpected child of <referenceTransition>: $tag"
            add_label!(labels, child, pntd, idregistry)
        end
    end
    #end; println("parse_refTransition $id allocated ", a)

    RefTransition(pntd, id, ref, name, graphics, tools, labels)
end

#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the stripped string of node's content.
"""
function parse_text(node::XMLNode, _::PnmlType, _::PIDR)
    check_nodename(node, "text")
    return string(strip(EzXML.nodecontent(node)))
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding text value and optional tool & GUI information.
"""
function parse_name(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    check_nodename(node, "name")
    text::Maybe{String} = nothing
    graphics::Maybe{Graphics} = nothing
    tools = ToolInfo[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = string(strip(EzXML.nodecontent(child)))
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # No labels here
            @warn "ignoring unexpected child of <name>: $tag"
        end
    end

    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if isnothing(text)
        emsg = "<name> missing <text> element"
        if CONFIG.text_element_optional
            @warn emsg # Remove when CONFIG default set to false.
            text = string(strip(EzXML.nodecontent(node)))
        else
            throw(ArgumentError(emsg))
        end
    end

    # Since names are for humans and do not need to be unique we will allow empty strings.
    # When the "lint" methods are implemented, they can complain.
    CONFIG.verbose && println("parsed name '$text'") #! debug
    return Name(text, graphics, tools)
end

#----------------------------------------------------------
#
# PNML annotation-label XML element parsers.
#
#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)
"""
function parse_initialMarking(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "initialMarking")
    value = nothing
    structure = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]

    if isempty(EzXML.nodecontent(node))
        # Treat missing value as if the <initialMarking> element was absent.
        @warn lazy"missing  <initialMarking> nodecontent, using default $(_evaluate(default_marking(pntd)))"
        value = _evaluate(default_marking(pntd))
    else
        #a = @allocated begin
        for child in EzXML.eachelement(node)
            tag = EzXML.nodename(child)
            # We extend to real numbers.
            if tag == "text"
                value = number_value(marking_value_type(pntd), (string ∘ strip ∘ EzXML.nodecontent)(child))
            elseif tag == "structure"
                # Allow <structure> for non-high-level labels.
                structure = parse_structure(child, pntd, idregistry)
                @warn "$nn <structure> element not used" structure
            elseif tag == "graphics" # Specification does not forbid PTNet for using this.
                graphics = parse_graphics(child, pntd, idregistry)
            elseif tag == "toolspecific" # tokengraphics can live here for PTNet (in specification)
                # Because it is in a `ToolInfo`, `<tokengraphics>`, could appear anywhere and be ignored.
                add_toolinfo!(tools, child, pntd, idregistry)
            else
                @warn "<initialMarking> ignoring unknown child '$tag'"
            end
        end
        #end; a > 0 && println("parse_initialMarking allocated ", a)
    end
    Marking(something(value, zero(marking_value_type(pntd))), graphics, tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "inscription")
    CONFIG.verbose && println("parse inscription ", nn)

    value = nothing
    graphics::Maybe{Graphics} = nothing
    tools = ToolInfo[]

    #a = @allocated begin
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            txt = (string ∘ strip ∘ EzXML.nodecontent)(child)
            value = number_value(inscription_value_type(pntd), txt)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            @warn("ignoring unexpected child of <inscription>: $tag")
            #add_label!(labels, child, pntd, idregistry)
        end
    end
    #end; a > 0 && println("parse_inscription allocated ", a)

    # Treat missing value as if the <inscription> element was absent.
    if isnothing(value) && CONFIG.warn_on_fixup
        @warn("missing or unparsable <inscription> value for $pntd replaced with default value $(default_inscription(pntd)())")
    end
    Inscription(something(value, default_inscription(pntd)()), graphics, tools)
end

"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a [`Term`](@ref) in the <structure>
child. We extend the pnml standard by allowing node content to be numeric:
parsed to `Int` and `Float64`.
"""
function parse_hlinitialMarking(node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    nn = check_nodename(node, "hlinitialMarking")
    text::Maybe{AbstractString} = nothing
    markterm::Maybe{AbstractTerm} = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]

    #a = @allocated begin
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = string(strip(EzXML.nodecontent(child)))
        elseif tag == "structure"
            markterm = parse_marking_term(child, pntd, idregistry)
            #! TODO match sort of place
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else
            @warn("ignoring unexpected child of <hlinitialMarking>: $tag")
        end
    end
    #end; a > 0 && println("parse_hlinitialMarking allocated ", a)

    HLMarking(text, something(markterm, default_zero_term(pntd)), graphics, tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_marking_term(marknode, pntd, idregistry)
    check_nodename(marknode, "structure")
    if EzXML.haselement(marknode)
        term = EzXML.firstelement(marknode)
        return parse_term(term, pntd, idregistry)
    else
        content_string = strip(EzXML.nodecontent(marknode))
        if !isempty(content_string)
            @warn("marking term <structure> content value: $content_string")
            return Term(:value, number_value(marking_value_type(pntd), content_string))
        end
    end
    error("missing marking term element in <structure>")
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    check_nodename(node, "hlinscription")

    text::Maybe{AbstractString} = nothing
    inscriptterm::Maybe{AbstractTerm} = nothing
    graphics::Maybe{Graphics} = nothing
    tools = ToolInfo[]

    #a = @allocated begin
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        @match tag begin
            "text"         => (text = parse_text(child, pntd, idregistry))
            "structure"    => (inscriptterm = parse_inscription_term(child, pntd, idregistry))
            "graphics"     => (graphics = parse_graphics(child, pntd, idregistry))
            "toolspecific" => add_toolinfo!(tools, child, pntd, idregistry)
            _              => @warn("ignoring unexpected child of <hlinscription>: $tag")
        end
    end
    #end; println("parse_hlinscription allocated ", a)

    HLInscription(text, something(inscriptterm, default_one_term(pntd)), graphics, tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription_term(inode, pntd, idregistry)::Term
    check_nodename(inode, "structure")
    if EzXML.haselement(inode)
        term = EzXML.firstelement(inode)
        return parse_term(term, pntd, idregistry)
    else
        content_string = strip(EzXML.nodecontent(inode))
        if !isempty(content_string)
            @warn("inscription term <structure> content value: $content_string")
            return Term(:value, number_value(inscription_value_type(pntd), content_string))
        end
    end
    error("missing inscription term element in <structure>")
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
function parse_condition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    check_nodename(node, "condition")
    text::Maybe{AbstractString} = nothing
    condterm::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]

    #a = @allocated begin
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        @match tag begin
            "text"         => (text = parse_text(child, pntd, idregistry))
            "structure"    => (condterm = parse_condition_term(child, pntd, idregistry))
            "graphics"     => (graphics = parse_graphics(child, pntd, idregistry))
            "toolspecific" => add_toolinfo!(tools, child, pntd, idregistry)
            _              =>  @warn("ignoring unexpected child of <condition>: $tag")
        end
    end
    #end; println("parse_condition allocated ", a)

    Condition(text, something(condterm, default_bool_term(pntd)), graphics, tools)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_condition_term(cnode, pntd::PnmlType, idregistry)
    check_nodename(cnode, "structure")
    if EzXML.haselement(cnode)
        term = EzXML.firstelement(cnode)
        return parse_term(term, pntd, idregistry)
    else
        content_string = strip(EzXML.nodecontent(cnode))
        if !isempty(content_string)
            @warn("condition term <structure> content value: $content_string")
            return Term(:value, number_value(condition_value_type(pntd), content_string))
        end
    end
    error("missing condition term element in <structure>")
end

#---------------------------------------------------------------------
#TODO Will unclaimed_node handle this?
"""
$(TYPEDSIGNATURES)

Should not often have a '<label>' tag, this will bark if one is found.
Return NamedTuple (tag,node), to defer parsing the xml.
"""
function parse_label(node::XMLNode, _::PnmlType, _::PIDR)
    @assert node !== nothing
    nn = check_nodename(node, "label")
    @warn "there is a label named 'label'"
    (; :tag => Symbol(nn), :xml => node) # Always add xml because this is unexpected.
end
