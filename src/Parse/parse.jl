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
        parsefun = tagmap[EzXML.nodename(node)]
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
function pnml_namespace(node::XMLNode; missing_ns_fatal::Bool=false, default_ns=pnml_ns)
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
    isempty(fname) &&
        throw(ArgumentError("parse_file must have a non-empty file name argument"))
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
    isempty(nets) && throw(MalformedException(lazy"$nn does not have any <net> elements", node))

    # Do not yet have a PNTD defined. Each net can be different Net speciaization.
    net_tup = tuple((parse_net(net, idregistry) for net in nets)...) #! Allocation?
    @assert length(net_tup) > 0
    if CONFIG.verbose
        @warn "CONFIG.verbose is true"
        println(lazy"PnmlModel $(length(net_tup)) nets")
        for n in net_tup
            println("  ", pid(n), " :: ", typeof(n))
        end
    end
    PnmlModel(net_tup, namespace, idregistry, node)
end

"""
$(TYPEDSIGNATURES)
Return a [`PnmlNet`](@ref)`.
"""
function parse_net(node::XMLNode, idregistry::PIDR, pntd_override::Maybe{PnmlType}=nothing)
    nn = check_nodename(node, "net")
    haskey(node, "id") || throw(MissingIDException(nn, node))
    haskey(node, "type") || throw(MalformedException(lazy"$nn missing type", node))
    id = node["id"]
    type = node["type"]
    if CONFIG.verbose
        println(lazy"""

        =========
        parse_net: $id $type $(pntd_override !== nothing && pntd_override)
        """)
    end

    isempty(allchildren("page", node)) &&
        throw(MalformedException(lazy"$nn $id does not have any pages", node))

    # Although the specification says the petri net type definition (pntd) must be attached
    # to the <net> element, it is allowed by this package to override that value.
    pn_typedef = pnmltype(type)
    if isnothing(pntd_override)
        pntd = pn_typedef
    else
        pntd = pntd_override
        @info lazy"net $id pntd set to $pntd, overrides $pn_typedef"
    end
    @infiltrate

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
            OrderedDict{Symbol,Place{PNTD,mtype,stype}}(),
            OrderedDict{Symbol,Transition{PNTD,ctype}}(),
            OrderedDict{Symbol,Arc{PNTD,itype}}(),
            OrderedDict{Symbol,RefPlace{PNTD}}(),
            OrderedDict{Symbol,RefTransition{PNTD}}())

        @infiltrate

        pnml_node_defaults(
            :tag => Symbol(nodename(node)),
            :id => register_id!(idregistry, node["id"]),
            :netsets => netsets, # Per-page-tree-node data.
            :pagedict => pgdict, # All pages & net share.
            :netdata => pnd,# All pages & net share.
            :declaration => Declaration(),)
    end
    @infiltrate

    # Fill the pagedict, netsets, netdata.
    tup = parse_net_2!(tup, node, pntd, idregistry)

    if CONFIG.verbose
        println(lazy"""
                Net  $(tup.id), $(length(tup.pagedict))  Pages:  $(keys(tup.pagedict))
                    page ids: $(collect(values(tup.netsets.page_set)))
                """)
    end
    return PnmlNet(pntd, tup.id, tup.pagedict, tup.netdata, page_idset(tup.netsets),
        tup.declaration, tup.name, ObjectCommon(tup), node)
end

"""
    parse_net_2!(d, node, pntd, idregistry)

Specialize on `pntd`. Go through children of `node` looking for expected tags,
delegating common tags and labels.
"""
function parse_net_2! end

# For nets and pages the <declaration> tag is optional.
# <declaration> ia a High-Level Annotation with a <structure> holding
# zero or more <declarations>. Is complicated. You have been warned!
# Expect
#  <declaration> <structure> <declarations> <namedsort id="weight" name="Weight"> ...

# function parse_net_2!(tup, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
#     for childnode in EzXML.eachelement(node)
#         tag = EzXML.nodename(childnode)
#         if tag == "page"
#             tup = parse_net_page!(tup, childnode, pntd, idregistry)
#         else
#             tup = parse_pnml_object_common(tup, childnode, pntd, idregistry)
#         end
#         # Leave the empty `Declaration` alone.
#     end
#     return tup
# end

function parse_net_2!(tup, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} #AbstractHLCore}
    page_order = Symbol[] # use to validate order of netsets page_idset owned by net
    (; pagedict, netdata, netsets) = tup
    for childnode in EzXML.eachelement(node)
        tag = EzXML.nodename(childnode)
        if tag == "page"
            (; id, pagedict, netdata, netsets) = _parse_page!(tup.pagedict, tup.netdata, tup.netsets, childnode, pntd, idregistry)
            push!(page_order, id)
            @assert id ∈ page_idset(netsets)
            @assert id ∈ keys(pagedict)
            @assert pagedict === tup.pagedict
            @assert netdata === tup.netdata
            @assert netsets === tup.netsets
        elseif tag == "declaration" # Make non-high-level also have declaration of some kind.
            tup = merge(tup, (; :declaration => parse_declaration(childnode, pntd, idregistry)))
        else
            tup = parse_pnml_object_common(tup, childnode, pntd, idregistry)
        end
    end
    return tup
end

# "See also parse_subpage!."
# function parse_net_page!(tup::NamedTuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
#     _parse_page!(tup, node, pntd, idregistry)
# end

"See also parse_net_page!"
function parse_subpage!(tup::NamedTuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    (; pagedict, netdata, netsets) = tup
    (; id, pagedict, netdata, netsets) = _parse_page!(tup.pagedict, tup.netdata, tup.netsets, node, pntd, idregistry)
    @assert id ∈ page_idset(netsets)
    @assert id ∈ keys(pagedict)
    @assert pagedict === tup.pagedict
    @assert netdata === tup.netdata
    @assert netsets === tup.netsets
    return tup
end

function _parse_page!(pagedict, netdata, netsets, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    @infiltrate
    pagedict, netdata, pg = parse_page!(pagedict, netdata, node, pntd, idregistry)
    #    tup = _add_page(pagedict, netsets, pg)
    pageid = pid(pg)
    @assert !haskey(pagedict, pageid)
    @assert pageid ∉ keys(pagedict)
    @assert pageid ∉ page_idset(netsets)

    pagedict[pageid] = pg #! PAGE: add to dictonary and id set
    push!(page_idset(netsets), pageid)

    @assert haskey(pagedict, pageid)
    @assert pageid ∈ page_idset(netsets)
    return (; :id => pageid, :pagedict => pagedict, :netdata => netdata, :netsets => netsets)
end

#_add_page(pagedict, netsets, pg) = begin
#    @nospecialize
#    pageid = pid(pg)
#    @assert !haskey(pagedict, pageid)
#    @assert pageid ∉ keys(pagedict)
#    @assert pageid ∉ page_idset(netsets)
#    pagedict[pageid] = pg #! PAGE: add to dictonary and id set
#    push!(page_idset(netsets), pageid)
#    return tup
#end

"""
    parse_page!(tup, node, pntd, idregistry) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function parse_page!(pagedict, netdata, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    nn = check_nodename(node, "page")
    haskey(node, "id") || throw(MissingIDException(nn, node))
    CONFIG.verbose && println(lazy"""parse $nn $pntd $(node["id"])""")
    netsets = PnmlNetKeys() # per page-tree-node data
    #!pagedict = tup1.pagedict
    #!netdata =  tup1.netdata

    tup2 = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :netsets => netsets, # per page-tree-node data
        :pagedict => pagedict, # shared
        :netdata => netdata # shared
    )
    CONFIG.verbose && println("parse page ", tup2.id) #! debug
    @infiltrate

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        #!id = child["id"]
        CONFIG.verbose && println(lazy"""parse $tag $(child["id"])""")

        @assert haskey(tup2, :netdata)
        @assert haskey(tup2, :netsets)

        @match tag begin
            "place" => parse_place!(netsets.place_set, netdata.place_dict, child, pntd, idregistry)
            "transition" => parse_transition!(netsets.transition_set, netdata.transition_dict, child, pntd, idregistry)
            "arc" => parse_arc!(netsets.arc_set, netdata.arc_dict, child, pntd, idregistry)
            "referencePlace" => parse_refPlace!(netsets.refplace_set, netdata.refplace_dict, child, pntd, idregistry)
            "referenceTransition" => parse_refTransition!(netsets.reftransition_set, netdata.reftransition_dict, child, pntd, idregistry)
            "declaration" => (tup2 = merge(tup2, [:declaration => parse_declaration(child, pntd, idregistry)]))
            "page" => parse_subpage!(tup2, child, pntd, idregistry) # Recursive call
            _ => (tup2 = parse_pnml_object_common(tup2, child, pntd, idregistry))
        end
    end

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
    @assert pl isa valtype(place_dict)
    push!(place_set, pid(pl))
    setindex!(place_dict, pl, pid(pl))
    return nothing
end

function parse_transition!(transition_set, transition_dict, child, pntd, idregistry)
    tr = parse_transition(child, pntd, idregistry)
    @assert tr isa valtype(transition_dict)
    push!(transition_set, pid(tr))
    transition_dict[pid(tr)] = tr
    return nothing
end

function parse_arc!(arc_set, arc_dict, child, pntd, idregistry)
    a = parse_arc(child, pntd, idregistry)
    @assert a isa valtype(arc_dict)
    push!(arc_set, pid(a))
    arc_dict[pid(a)] = a
    return nothing
end

function parse_refPlace!(refplace_set, refplace_dict, child, pntd, idregistry)
    rp = parse_refPlace(child, pntd, idregistry)
    @assert rp isa valtype(refplace_dict)
    push!(refplace_set, pid(rp))
    refplace_dict[pid(rp)] = rp
    return nothing
end

function parse_refTransition!(reftransition_set, reftransition_dict, child, pntd, idregistry)
    rt = parse_refTransition(child, pntd, idregistry)
    @assert rt isa valtype(reftransition_dict)
    push!(reftransition_set, pid(rt))
    reftransition_dict[pid(rt)] = rt
    return nothing
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "place")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    tup = pnml_node_defaults(
        :tag => Symbol(nn), # XML tag
        :id => register_id!(idregistry, node["id"]),
    )

    plabels = parse_place_labels!(node, pntd, idregistry)
    mark = hasproperty(plabels, :marking) ? plabels.marking : default_marking(pntd)
    sorttype = hasproperty(plabels, :type) ? plabels.type : default_sort(pntd)
    name = hasproperty(plabels, :name) ? plabels.name : nothing
    objcom = ObjectCommon(plabels)

    Place(pntd, tup.id, mark, sorttype, name, objcom)
end

_parse_marking(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} = parse_initialMarking(node, pntd, idregistry)
_parse_marking(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore} = parse_hlinitialMarking(node, pntd, idregistry)

_parse_type(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} = begin
    (; :type => parse_type(node, pntd, idregistry))
end

"place label parsing updates tuple."
function parse_place_labels!(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    #print("parse_place_labels! ") #! debug
    if CONFIG.verbose
        let labels = EzXML.elements(node)
            isempty(labels) || println(EzXML.nodename(node), " labels ", EzXML.nodename.(labels))
        end
    end
    tup = NamedTuple()
    @infiltrate
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "initialMarking" || tag == "hlinitialMarking"
            tup = merge(tup, [:marking => _parse_marking(child, pntd, idregistry)])
        elseif tag == "type"
            # Here type means `sort`. Re: Many-sorted algebra from High-Level nets.
            # But we extend to all nets using a type parameter (meaning TBD).
            tup = merge(tup, (; :type => parse_type(child, pntd, idregistry)))
        else
            tup = parse_pnml_object_common(tup, child, pntd, idregistry)
        end
    end
    #println("on return from  parse_place_labels! tup = ", tup)
    return tup
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "transition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))

    tup = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
    )

    @infiltrate
    #!parse_transition_2!(tup, pntd, node, idregistry)
    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "condition"
            tup = merge(tup, (; :condition => parse_condition(child, pntd, idregistry)))
        else
            tup = parse_pnml_object_common(tup, child, pntd, idregistry)
        end
    end

    name = hasproperty(tup, :name) ? tup.name : nothing
    condition = hasproperty(tup, :condition) ? tup.condition : default_condition(pntd)

    Transition(pntd, tup.id, condition, name, ObjectCommon(tup))
end

"""
    parse_arc(node::XMLNode, pntd::PnmlType, idregistry) -> Arc{typeof(pntd), typeof(inscription)}

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node, pntd, idregistry::PIDR)
    nn = check_nodename(node, "arc")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    nodeid = node["id"]
    haskey(node, "source") || throw(ArgumentError(lazy"missing source for arc $nodeid"))
    haskey(node, "target") || throw(ArgumentError(lazy"missing target for arc $nodeid"))
    source = Symbol(node["source"])
    target = Symbol(node["target"])

    tup = pnml_node_defaults(:tag => Symbol(nn), :id => register_id!(idregistry, nodeid))

    @infiltrate
    CONFIG.verbose && println(lazy"parse arc $(tup.id) $source -> $target")
    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "inscription"
            tup = merge(tup, (; :inscription => _parse_inscription(child, pntd, idregistry)))
        else
            tup = parse_pnml_object_common(tup, child, pntd, idregistry)
        end
    end
    name = hasproperty(tup, :name) ? tup.name : nothing
    inscription = hasproperty(tup, :inscription) ? tup.inscription : default_inscription(pntd)

    Arc(pntd, tup.id, source, target, inscription, name, ObjectCommon(tup))
end

"""
Specialize arc inscription label parsing.
"""
_parse_inscription(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType} = begin
    i = parse_inscription(node, pntd, idregistry)
    return i
end
_parse_inscription(node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore} = begin
    i = parse_hlinscription(node, pntd, idregistry)
    return i
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referencePlace")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") ||
        throw(MalformedException(lazy"$nn missing ref attribute", node))

    ref = Symbol(node["ref"])

    tup = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
    )

    for child in eachelement(node)
        tup = parse_pnml_object_common(tup, child, pntd, idregistry)
    end

    name = hasproperty(tup, :name) ? tup.name : nothing
    RefPlace(pntd, tup.id, ref, name, ObjectCommon(tup))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referenceTransition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") ||
        throw(MalformedException(lazy"$nn missing ref attribute", node))

    ref = Symbol(node["ref"])
    tup = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
    )

    for child in eachelement(node)
        tup = parse_pnml_object_common(tup, child, pntd, idregistry)
    end

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
    string(strip(nodecontent(node)))
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding text value and optional tool & GUI information.
"""
function parse_name(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "name")
    CONFIG.verbose && print("parse name ") #! debug
    # Assumes there are no other children with this tag (like the specification says).
    textnode = firstchild("text", node)
    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if !isnothing(textnode)
        text = string(strip(nodecontent(textnode)))
    elseif CONFIG.text_element_optional
        @warn lazy"$nn missing <text> element" # Remove when CONFIG default set to false.
        text = string(strip(nodecontent(node)))
    else
        throw(ArgumentError(lazy"$nn missing <text> element"))
    end
    CONFIG.verbose && println(lazy"'$text'") #! debug
    graphicsnode = firstchild("graphics", node) # single
    graphics = isnothing(graphicsnode) ? nothing :
               parse_graphics(graphicsnode, pntd, idregistry)

    toolspecific = allchildren("toolspecific", node) # multiple
    tools = isempty(toolspecific) ? nothing : parse_toolspecific.(toolspecific, Ref(pntd), idregistry)
    @assert isnothing(tools) || tools isa Vector{ToolInfo}
    Name(; text, graphics, tools)
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

    val = if isempty(nodecontent(node))
        @warn "missing  <initialMarking> content"
        nothing
    else
        number_value(marking_value_type(pntd), (strip ∘ nodecontent)(node))
    end
    tup = pnml_label_defaults(:tag => Symbol(nn), :value => val)

    for child in EzXML.eachelement(node)
        tag = nodename(child)
        # We extend to real numbers.
        if tag == "text"
            tup = merge(tup, (; :value => number_value(marking_value_type(pntd),
                (string ∘ strip ∘ nodecontent)(child))))
        else
            tup = parse_pnml_label_common(tup, child, pntd, idregistry)
        end
    end

    # Treat missing value as if the <initialMarking> element was absent.
    if isnothing(tup.value)
        @warn "missing <initialMarking> value"
        tup.value = _evaluate(default_marking(pntd))
    end

    Marking(tup.value, ObjectCommon(tup))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "inscription")
    CONFIG.verbose && println("parse inscription ", nn)
    tup = pnml_label_defaults(:tag => Symbol(nn), :value => nothing)

    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            txt = (string ∘ strip ∘ EzXML.nodecontent)(child)
            val = number_value(inscription_value_type(pntd), txt)
            tup = merge(tup, (; :value => val))
        else
            # Should not have a structure.
            tup = parse_pnml_label_common(tup, child, pntd, idregistry)
        end
    end
    # Treat missing value as if the <inscription> element was absent.
    if !hasproperty(tup, :value) || isnothing(tup.value)
        if CONFIG.warn_on_fixup
            @warn("missing or unparsable <inscription> value")
        end
        tup = merge(tup, (; :value => default_inscription(pntd)()))
    end
    #! WHY? name = hasproperty(tup, :name) ? tup.name : nothing
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

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "structure"
            tup = merge(tup, (; :term => parse_marking_term(child, pntd, idregistry)))
            #! TODO match sort of place
        else
            tup = parse_pnml_label_common(tup, child, pntd, idregistry)
        end
    end

    term = hasproperty(tup, :term) ? tup.term : default_marking(pntd)
    HLMarking(tup.text, term, ObjectCommon(tup))
end

parse_marking_term(node, pntd, idregistry)::Term = begin
    check_nodename(node, "structure")
    if EzXML.haselement(node)
        parse_term(EzXML.firstelement(node), pntd, idregistry)
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

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "structure"
            tup = merge(tup, (; :term => parse_inscription_term(child, pntd, idregistry)))
        else
            tup = parse_pnml_label_common(tup, child, pntd, idregistry)
        end
    end

    term = hasproperty(tup, :term) ? tup.term : default_inscription(pntd)
    HLInscription(tup.text, term, ObjectCommon(tup))
end

parse_inscription_term(node, pntd, idregistry)::Term = begin
    check_nodename(node, "structure")
    if EzXML.haselement(node)
        parse_term(EzXML.firstelement(node), pntd, idregistry)
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

    for child in EzXML.eachelement(node)
        @match nodename(child) begin
            "structure" => (tup = merge(tup, (; :term => parse_condition_term(child, pntd, idregistry))))
            _ => (tup = parse_pnml_label_common(tup, child, pntd, idregistry))
        end
    end

    term = hasproperty(tup, :term) ? tup.term : default_condition(pntd)
    Condition(pntd, tup.text, term, ObjectCommon(tup))
end

function parse_condition_term(node, pntd::PnmlType, idregistry)
    check_nodename(node, "structure")
    if EzXML.haselement(node)
        term = EzXML.firstelement(node)
        parse_term(term, pntd, idregistry)
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
