const PIDR = PnmlIDRegistry

"""
$(TYPEDSIGNATURES)

Call any method matching xml node's tag` in [`tagmap`](@ref),
otherwise parse as [`unclaimed_label`](@ref) wrapped in a [`PnmlLabel`](@ref).
All uses are expected to be pnml labels attached to pnml graph nodes, arcs, nets, pages,
that are excluded from this parsing pathway.
"""
function parse_node(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    CONFIG.verbose && println(lazy"PARSE_NODE $(EzXML.nodename(node))") # Useful for debug.
    if haskey(tagmap, EzXML.nodename(node))
        parsefun = @inline tagmap[EzXML.nodename(node)]
        #@show nameof(parsefun) typeof(parsefun) methods(parsefun) # Useful for debug.
        return parsefun(node, pntd, idregistry) # Various types returned here.
    else
        return PnmlLabel(unclaimed_label(node, pntd, idregistry), node)
    end
end

function parse_excluded(node::XMLNode, _, _)
    @warn lazy"Attempt to parse excluded tag: $(EzXML.nodename(node))"
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
        emsg = lazy"$(nodename(node)) missing namespace"
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
    parse_pnml(root(EzXML.readxml(fname)), idregistry)
end

"""
    parse_pnml(xmlnode, idregistry) -> PnmlModel

Start parse from the root `node` of a well formed pnml XML document.
Return a [`PnmlModel`](@ref) holding one or more [`PnmlNet`](@ref).
"""
function parse_pnml(node::XMLNode, idregistry::PIDR)
    nn = check_nodename(node, "pnml")
    namespace = pnml_namespace(node)
    nets = allchildren("net", node)
    isempty(nets) && throw(MalformedException(lazy"$nn does not have any <net> elements"))

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
        println(lazy"""

        =========
        parse_net: $(node["id"]) $type $(pntd_override !== nothing && pntd_override)
        """)
    end

    isempty(allchildren("page", node)) &&
        throw(MalformedException(lazy"""$nn $(node["id"]) does not have any pages"""))

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
    # create tuple
    tup = let pntd = pntd, PNTD = typeof(pntd),
        mtype = marking_type(PNTD),
        itype = inscription_type(PNTD),
        ctype = condition_type(PNTD),
        stype = sort_type(PNTD),
        pgtype = Page{PNTD,mtype,itype,ctype,stype},
        pgdict = OrderedDict{Symbol,pgtype}(), # Page dictonary not part of PnmlNetData.
        netsets = PnmlNetKeys(),
        pnd = PnmlNetData(pntd,
            OrderedDict{Symbol, Any}(), # Place{PNTD,mtype,stype}}(),
            OrderedDict{Symbol, Any}(), # Transition{PNTD,ctype}}(),
            OrderedDict{Symbol, Any}(), # Arc{PNTD,itype}}(),
            OrderedDict{Symbol, Any}(), # RefPlace{PNTD}}(),
            OrderedDict{Symbol, Any}()) # RefTransition{PNTD}}())

        pnml_node_defaults(
            :tag         => Symbol(nodename(node)),
            :id          => register_id!(idregistry, node["id"]),
            :netsets     => netsets, # Per-page-tree-node data.
            :pagedict    => pgdict, # All pages & net share.
            :netdata     => pnd,# All pages & net share.
            :declaration => Declaration(),)
    end

    # Fill the pagedict, netsets, netdata.
    a = @allocated begin
    for child in EzXML.eachelement(node)
        tup = merge(tup, parse_net_2!(tup, child, pntd, idregistry))
    end
    end; println("parse_net_1 $(tup.id) allocated: ", a)

    if CONFIG.verbose
        println(lazy"""
                Net $(tup.id), $(length(tup.pagedict))  Pages:  $(keys(tup.pagedict))
                    page ids: $(collect(values(tup.netsets.page_set)))
                """)
    end
    return PnmlNet(pntd, tup.id, tup.pagedict, tup.netdata, page_idset(tup.netsets),
        tup.declaration, tup.name, ObjectCommon(tup), node)
end

"""
    parse_net_2!(d, node, pntd, idregistry)

Go through children of `node` looking for expected tags, delegating common tags and labels.
"""
function parse_net_2!(tup, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    (; pagedict, netdata, netsets) = tup
    tag = EzXML.nodename(node)
    if tag == "page"
        pagedict, netdata, netsets = _parse_page!(tup, node, pntd, idregistry)
    elseif tag == "declaration" # Make non-high-level also have declaration of some kind.
        tup = merge(tup, (; :declaration => parse_declaration(node, pntd, idregistry)))
    elseif tag == "name"
        tup = merge(tup, (; :name => parse_name(node, pntd, idregistry)))
    elseif tag == "graphics"
        @warn "<net> ignoring unexpected <graphics> element"
    else
        # toolspecific infos
        # labels
        tup = parse_pnml_object_common(tup, node, pntd, idregistry) # net #! ObjectCommon
    end

    return tup
end

function _parse_page!(tup, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    (; pagedict, netdata, netsets) = tup
    pagedict, netdata, pg = parse_page!(pagedict, netdata, node, pntd, idregistry)

    pageid = pid(pg)
    pagedict[pageid] = pg #! PAGE: add to dictonary and id set
    push!(page_idset(netsets), pageid)

    return pagedict, netdata, netsets
end

"""
    parse_page!(tup, node, pntd, idregistry) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function parse_page!(pagedict, netdata, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    nn = check_nodename(node, "page")
    haskey(node, "id") || throw(MissingIDException(nn))
    CONFIG.verbose && println(lazy"""parse $nn $pntd $(node["id"])""")
    netsets = PnmlNetKeys() # per page-tree-node data

    tup2 = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :netsets => netsets, # per page-tree-node data
        :pagedict => pagedict, # shared
        :netdata => netdata # shared
    )
    CONFIG.verbose && println("parse page ", tup2.id) #! debug

    a = @allocated begin

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        CONFIG.verbose && println(lazy"""parse $tag $(child["id"])""")

        @assert haskey(tup2, :netdata)
        @assert haskey(tup2, :netsets)

        @match tag begin
            # Can have multiples
            "place"               => parse_place!(netsets.place_set, netdata.place_dict, child, pntd, idregistry)
            "transition"          => parse_transition!(netsets.transition_set, netdata.transition_dict, child, pntd, idregistry)
            "arc"                 => parse_arc!(netsets.arc_set, netdata.arc_dict, child, pntd, idregistry)
            "referencePlace"      => parse_refPlace!(netsets.refplace_set, netdata.refplace_dict, child, pntd, idregistry)
            "referenceTransition" => parse_refTransition!(netsets.reftransition_set, netdata.reftransition_dict, child, pntd, idregistry)
            "page"                => _parse_page!(tup2, child, pntd, idregistry) # Recursive call for subpage.
            # Just one of these
            "declaration"         => (tup2 = merge(tup2, [:declaration => parse_declaration(child, pntd, idregistry)]))
            "name"                => (tup2 = merge(tup2, (; :name => parse_name(child, pntd, idregistry))))
            "graphics"            => (tup2 = merge(tup2, (; :graphics => parse_graphics(child, pntd, idregistry))))
            # These are also multiples
            # tool infos
            # labels (unclaimed)
             _ => (tup2 = parse_pnml_object_common(tup2, child, pntd, idregistry)) # page
        end
    end
    end; println("parse_page! $(tup2.id) allocated: ", a)

    name = hasproperty(tup2, :name) ? tup2.name : nothing
    decl = hasproperty(tup2, :declaration) ? tup2.declaration : Declaration()

    if CONFIG.verbose
        println("Page ", tup2.id, " name ", name, " add to ", keys(tup2.pagedict))
    end
    @assert pagedict === tup2.pagedict
    @assert netdata === tup2.netdata
    @assert netsets === tup2.netsets
    return pagedict, netdata, Page(pntd, tup2.id, decl, name, ObjectCommon(tup2),
                                    pagedict, # shared by net and all pages.
                                    netdata,  # shared by net and all pages.
                                    netsets,  # Set of ids "owned" by this page.
                                    )
end

# set is per-Page, dict is per-Net
function parse_place!(place_set, place_dict, child, pntd, idregistry)
    pl = parse_place(child, pntd, idregistry)
    push!(place_set, pid(pl))
    place_dict[pid(pl)] = pl
    return nothing
end

function parse_transition!(transition_set, transition_dict, child, pntd, idregistry)
    tr = parse_transition(child, pntd, idregistry)
    push!(transition_set, pid(tr))
    transition_dict[pid(tr)] = tr
    return nothing
end

function parse_arc!(arc_set, arc_dict, child, pntd, idregistry)
    a = parse_arc(child, pntd, idregistry)
    push!(arc_set, pid(a))
    arc_dict[pid(a)] = a
    return nothing
end

function parse_refPlace!(refplace_set, refplace_dict, child, pntd, idregistry)
    rp = parse_refPlace(child, pntd, idregistry)
    push!(refplace_set, pid(rp))
    refplace_dict[pid(rp)] = rp
    return nothing
end

function parse_refTransition!(reftransition_set, reftransition_dict, child, pntd, idregistry)
    rt = parse_refTransition(child, pntd, idregistry)
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
    mark     = default_marking(pntd)
    sorttype = default_sort(pntd)
    name     = nothing
    graphics = nothing
    tup = (tools=ToolInfo[], labels=PnmlLabel[])

    a = @allocated begin

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "initialMarking" || tag == "hlinitialMarking"
            a = @allocated begin
                mark = _parse_marking(child, pntd, idregistry)
            end; a > 0 && println("_parse_marking $id allocated ", a)
        elseif tag == "type"
            a = @allocated begin
                sorttype = parse_type(child, pntd, idregistry)
            end; a > 0 && println("parse_type $id allocated ", a)
        elseif tag == "name"
            a = @allocated begin
                name = parse_name(child, pntd, idregistry)
            end; a > 0 && println("place parse_name $id allocated ", a)
        elseif tag == "graphics"
            a = @allocated begin
                graphics = parse_graphics(child, pntd, idregistry)
            end; a > 0 && println("place parse_graphics $id allocayted ", a)
        else
            # tool infos
            # labels
            a = @allocated begin #! needs bang!
                tup = parse_pnml_object_common(tup, child, pntd, idregistry) # place
            end; a > 0 && println("parse object_common $id allocated ", a)
        end
    end
    end; println("parse_place $id allocated: ", a)

    Place(pntd, id, mark, sorttype, name, ObjectCommon(graphics, tup.tools, tup.labels))
end

#_parse_type(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} = begin
#    (; :type => parse_type(node, pntd, idregistry))
#end

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
    id = register_id!(idregistry, node["id"])
    tup = pnml_node_defaults(:tag => Symbol(nn))

    a = @allocated begin

    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "condition"
            tup = merge(tup, (; :condition => parse_condition(child, pntd, idregistry)))
        elseif tag == "name"
            tup = merge(tup, (; :name => parse_name(child, pntd, idregistry)))
        elseif tag == "graphics"
            tup = merge(tup, (; :graphics => parse_graphics(child, pntd, idregistry)))
        else
            # tool infos
            # labels
            tup = parse_pnml_object_common(tup, child, pntd, idregistry) # transition
        end
    end
    end; println("parse_transition $id allocated: ", a)
    name = hasproperty(tup, :name) ? tup.name : nothing
    condition = hasproperty(tup, :condition) ? tup.condition : default_condition(pntd)

    Transition(pntd, id, condition, name, ObjectCommon(tup))
end

"""
    parse_arc(node::XMLNode, pntd::PnmlType, idregistry) -> Arc{typeof(pntd), typeof(inscription)}

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node, pntd, idregistry::PIDR)
    nn = check_nodename(node, "arc")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    nodeid = node["id"]
    haskey(node, "source") || throw(ArgumentError(lazy"missing source for arc $nodeid"))
    haskey(node, "target") || throw(ArgumentError(lazy"missing target for arc $nodeid"))
    source = Symbol(node["source"])
    target = Symbol(node["target"])

    tup = pnml_node_defaults(:tag => Symbol(nn), :id => register_id!(idregistry, nodeid))

    CONFIG.verbose && println(lazy"parse arc $(tup.id) $source -> $target")

    a = @allocated begin

    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "inscription" || tag == "hlinscription"
            tup = merge(tup, (; :inscription => _parse_inscription(child, pntd, idregistry)))
        elseif tag == "name"
            tup = merge(tup, (; :name => parse_name(child, pntd, idregistry)))
        elseif tag == "graphics"
            tup = merge(tup, (; :graphics => parse_graphics(child, pntd, idregistry)))
        else
            # tool infos
            # labels
            tup = parse_pnml_object_common(tup, child, pntd, idregistry) # arc
        end
    end
    end; println("parse_arc $nodeid allocated ", a)

    name = hasproperty(tup, :name) ? tup.name : nothing
    inscription = hasproperty(tup, :inscription) ? tup.inscription : default_inscription(pntd)

    Arc(pntd, tup.id, source, target, inscription, name, ObjectCommon(tup))
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
    EzXML.haskey(node, "ref") ||
        throw(MalformedException(lazy"$nn missing ref attribute"))

    ref = Symbol(node["ref"])

    tup = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
    )

    a = @allocated begin
    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "name"
            tup = merge(tup, (; :name => parse_name(child, pntd, idregistry)))
        elseif tag === "graphics"
            tup = merge(tup, (; :graphics => parse_graphics(child, pntd, idregistry)))
        else
            # tool infos
            # labels
            tup = parse_pnml_object_common(tup, child, pntd, idregistry) # refplace
        end
    end
    end; println("parse_refPlace $(tup.id) allocated ", a)

    name = hasproperty(tup, :name) ? tup.name : nothing
    RefPlace(pntd, tup.id, ref, name, ObjectCommon(tup))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referenceTransition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    EzXML.haskey(node, "ref") ||
        throw(MalformedException(lazy"$nn missing ref attribute"))

    ref = Symbol(node["ref"])
    tup = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
    )

    a = @allocated begin

    for child in eachelement(node)

        tag = EzXML.nodename(child)
        if tag == "name"
            tag = merge(tup, (; :name => parse_name(child, pntd, idregistry)))
        elseif tag == "graphics"
            tup = merge(tup, (; :graphics => parse_graphics(child, pntd, idregistry)))
        else
            # tool infos
            # labels
            tup = parse_pnml_object_common(tup, child, pntd, idregistry) # reftransition
        end
    end
    end; println("parse_refTransition $(tup.id) allocated ", a)
    name = hasproperty(tup, :name) ? tup.name : nothing
    RefTransition(pntd, tup.id, ref, name, ObjectCommon(tup))
end

#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the stripped string of node's content.
"""
function parse_text(node::XMLNode, _::PnmlType, _::PIDR)
    check_nodename(node, "text")
    return string(strip(nodecontent(node)))
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding text value and optional tool & GUI information.
"""
function parse_name(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "name")
    CONFIG.verbose && print("parse name ") #! debug

    text::Maybe{String} = nothing
    graphics::Maybe{Graphics} = nothing
    tools = ToolInfo[]
    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            #b = @allocated begin
                text = string(strip(nodecontent(child)))
            #end; b > 0 && println("name text ", b)
        elseif tag == "graphics"
            #b = @allocated begin
                graphics = parse_graphics(child, pntd, idregistry)
            #end; b > 0 && println("name graphics ", b)
        elseif tag == "toolspecific"
            #b = @allocated begin
                add_toolinfo!(tools, child, pntd, idregistry)
            #end; b > 0 && println("name tools ", b)
        else
            @warn "unexpected child of <name>: $tag"
        end
    end

    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if isnothing(text)
        if CONFIG.text_element_optional
            @warn lazy"$nn missing <text> element" # Remove when CONFIG default set to false.
            text = string(strip(nodecontent(node)))
        else
            throw(ArgumentError(lazy"$nn missing <text> element"))
        end
    end

    isempty(text) && @info "empty name"
    CONFIG.verbose && println(lazy"parsed name $text") #! debug
    return Name(; text, graphics, tools)
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
    tup = pnml_common_defaults()#:tag => Symbol(nn))


    if isempty(nodecontent(node))
        # Treat missing value as if the <initialMarking> element was absent.
        @warn lazy"missing  <initialMarking> nodecontent, using default $(_evaluate(default_marking(pntd)))"
        value = _evaluate(default_marking(pntd))
    else
        a = @allocated begin
        for child in EzXML.eachelement(node)
            tag = nodename(child)
            # We extend to real numbers.
            if tag == "text"
                tup = merge(tup, (; :value => number_value(marking_value_type(pntd), (string ∘ strip ∘ nodecontent)(child))))
            elseif tag == "structure"
                # Allow <structure> for non-high-level labels.
                s = parse_structure(child, pntd, idregistry)
                tup = merge(tup, (structure = s,))
            elseif tag == "graphics"
                g = parse_graphics(child, pntd, idregistry)
                tup = merge(tup, (graphics = g,))
            elseif tag == "toolspecific"
                add_toolinfo!(tup.tools, child, pntd, idregistry) #! Add tool to collections
            else
                @warn "initial marking ignoring unknown child '$tag'"
            end
        end
        end; a > 0 && println("parse_initialMarking allocated ", a)

        if !hasproperty(tup, :value)
            #@warn "initialMarking missing <text>, using nodecontent for value" nodecontent(node)
            value = number_value(marking_value_type(pntd), (strip ∘ strip ∘ nodecontent)(node))
        else
            value = tup.value
        end
    end

    Marking(value, ObjectCommon(tup))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "inscription")
    CONFIG.verbose && println("parse inscription ", nn)
    tup = pnml_label_defaults(:tag => Symbol(nn), :value => nothing)

    a = @allocated begin

    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            txt = (string ∘ strip ∘ EzXML.nodecontent)(child)
            val = number_value(inscription_value_type(pntd), txt)
            tup = merge(tup, (; :value => val))
        else
            # Should not have a structure. May have graphics, toolspecific.
            tup = merge(tup, parse_pnml_label_common(tup, child, pntd, idregistry))
        end
    end
    end; a > 0 && println("parse_inscription allocated ", a)
    # Treat missing value as if the <inscription> element was absent.
    if !hasproperty(tup, :value) || isnothing(tup.value)
        if CONFIG.warn_on_fixup
            @warn("missing or unparsable <inscription> value")
        end
        tup = merge(tup, (; :value => default_inscription(pntd)()))
    end
    Inscription(tup.value, ObjectCommon(tup))
end

"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a [`Term`](@ref) in the <structure>
child. We extend the pnml standard by allowing node content to be numeric:
parsed to `Int` and `Float64`.
"""
function parse_hlinitialMarking(node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    nn = check_nodename(node, "hlinitialMarking")
    tup = pnml_label_defaults(
        :tag => Symbol(nn),
        :text => nothing,
        :structure => nothing,
    )

    a = @allocated begin

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "structure"
            tup = merge(tup, (; :term => parse_marking_term(child, pntd, idregistry)))
            #! TODO match sort of place
        else
            tup = parse_pnml_label_common(tup, child, pntd, idregistry)
        end
    end
    end; a > 0 && println("parse_hlinitialMarking allocated ", a)
    term = hasproperty(tup, :term) ? tup.term : default_marking(pntd)
    HLMarking(tup.text, term, ObjectCommon(tup))
end

parse_marking_term(marknode, pntd, idregistry)::Term = begin
    check_nodename(marknode, "structure")
    if EzXML.haselement(marknode)
        parse_term(EzXML.firstelement(marknode), pntd, idregistry)
    else
        # Handle an empty <structure>.
        default_marking(pntd)
    end
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    nn = check_nodename(node, "hlinscription")
    tup = pnml_label_defaults(:tag => Symbol(nn))

    a = @allocated begin

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "structure"
            tup = merge(tup, (; :term => parse_inscription_term(child, pntd, idregistry)))
        else
            tup = parse_pnml_label_common(tup, child, pntd, idregistry)
        end
    end
    end; println("parse_hlinscription allocated ", a)

    term = hasproperty(tup, :term) ? tup.term : default_inscription(pntd)
    HLInscription(tup.text, term, ObjectCommon(tup))
end

parse_inscription_term(inscriptionnode, pntd, idregistry)::Term = begin
    check_nodename(inscriptionnode, "structure")
    if EzXML.haselement(inscriptionnode)
        parse_term(EzXML.firstelement(inscriptionnode), pntd, idregistry)
    else
        # Handle an empty <structure>.
        default_inscription(pntd)
    end
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
    nn = check_nodename(node, "condition")
    tup = pnml_label_defaults(:tag => Symbol(nn))

    a = @allocated begin

    for child in EzXML.eachelement(node)
        @match nodename(child) begin
            "structure" => (tup = merge(tup, (; :term => parse_condition_term(child, pntd, idregistry))))
            _ => (tup = parse_pnml_label_common(tup, child, pntd, idregistry))
        end
    end
    end; println("parse_condition allocated ", a)

    term = hasproperty(tup, :term) ? tup.term : default_condition(pntd)
    Condition(pntd, tup.text, term, ObjectCommon(tup))
end

function parse_condition_term(conditionnode, pntd::PnmlType, idregistry)
    check_nodename(conditionnode, "structure")

    if EzXML.haselement(conditionnode)
        parse_term(EzXML.firstelement(conditionnode), pntd, idregistry)
    else
        # Handle an empty <structure>.
        default_condition(pntd)()
    end
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
    @warn lazy"parse_label '$nn'"
    (; :tag => Symbol(nn), :xml => node) # Always add xml because this is unexpected.
end
