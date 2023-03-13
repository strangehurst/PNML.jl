const PIDR = PnmlIDRegistry

"""
$(TYPEDSIGNATURES)

Call any method matching xml node's tag` in [`tagmap`](@ref),
otherwise parse as [`unclaimed_label`](@ref) wrapped in a [`PnmlLabel`](@ref).
All uses are expected to be pnml labels attached to pnml graph nodes, arcs, nets, pages,
that are excluded from this parsing pathway.
"""
function parse_node end

parse_node(node::XMLNode, idregistry::PIDR) = parse_node(node, PnmlCoreNet(), idregistry)

function parse_node(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    #println("parse_node $(EzXML.nodename(node))") # Useful for debug.
    if haskey(tagmap, EzXML.nodename(node))
        parsefun = tagmap[EzXML.nodename(node)]
        #@show nameof(parsefun) typeof(parsefun) methods(parsefun) # Useful for debug.
        return parsefun(node, pntd, idregistry) # Various types returned here.
    else
        return PnmlLabel(unclaimed_label(node, pntd, idregistry), node)
    end
end

function parse_excluded(node::XMLNode, _, _)
    @warn "Attempt to parse excluded tag: $(EzXML.nodename(node))"
end

#TODO test pnml_namespace

"""
$(TYPEDSIGNATURES)

Return namespace of `node.
When `node` does not have a namespace return default value [`pnml_ns`](@ref)
and warn or throw an error.
"""
function pnml_namespace(node::XMLNode; missing_ns_fatal::Bool = false, default_ns = pnml_ns)
    if EzXML.hasnamespace(node)
        return EzXML.namespace(node)
    else
        emsg = "$(nodename(node)) missing namespace"
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
Return a [`PnmlModel`](@ref) holding one or more [`PnmlNets`](@ref).
"""
function parse_pnml(node::XMLNode, idregistry::PIDR)
    nn = check_nodename(node, "pnml")

    namespace = if EzXML.hasnamespace(node)
        EzXML.namespace(node)
    else
        if CONFIG.warn_on_namespace
            @warn("$nn missing namespace")
        end
        pnml_ns # Use default value
    end

    nets = allchildren("net", node)
    isempty(nets) && throw(MalformedException("$nn does not have any <net> elements", node))

    # Do not yet have a PNTD defined, so call parse_net directly.
    # Each net can be subtype/specialization of generic Net subtype.
    net_tup = tuple([parse_net(net, idregistry) for net in nets]...) #! Allocation?
    @assert length(net_tup) > 0
    if CONFIG.verbose
        println("PnmlModel nets")
        for n in net_tup
            let n=n
                print("  ", pid(n), " :: ", typeof(n))
                println()
            end
        end
    end
    PnmlModel(net_tup, namespace, idregistry, node)
end

"""
$(TYPEDSIGNATURES)
Return a dictonary of the pnml net with keys matching their XML tag names.
"""
function parse_net(node::XMLNode, idregistry::PIDR, pntd_override::Maybe{PnmlType} = nothing)
    nn = check_nodename(node, "net")
    haskey(node, "id") || throw(MissingIDException(nn, node))
    haskey(node, "type") || throw(MalformedException("$nn missing type", node))

    if CONFIG.verbose
        println()
        println("=====")
        println("""parse_net $(node["id"]) $(node["type"]) $(pntd_override)""")
    end

    isempty(allchildren("page", node)) &&
        throw(MalformedException("$nn $(node["id"]) does not have any pages", node))

    # Although the specification says the petri net type definition (pntd) must be attached
    # to the <net> element, it is allowed by this package to override that value.

    pn_typedef = pnmltype(node["type"])
    if isnothing(pntd_override)
        pntd = pn_typedef
    else
        pntd = pntd_override
        @info "net $(node["id"]) pntd set to $pntd, overrides $pn_typedef"
    end

    # Create a PnmlDict with keys for possible child tags.
    # Some keys have known/required values.
    # Optional key values are nothing for single object or empty vector when multiples.
    # Keys that have pural names usually have a vector value.
    # The 'graphics' key is one exception and has a single value.
    d = let pntd = pntd,
            PNTD = typeof(pntd),
            pgtype = page_type(pntd),
            #!pgdict = OrderedDict{Symbol, pgtype}(), #! moved to pnd::PnmlNetData
            pgset = OrderedSet{Symbol}(),
            # tup = namedtuple(:place, :transition, :arc, :refTransition, :refPlace)(
            #     OrderedDict{Symbol, place_type(PNTD)}(), #Place{PNTD,M,S}},
            #     OrderedDict{Symbol, transition_type(PNTD)}(), #Transition{PNTD,C}},
            #     OrderedDict{Symbol, arc_type(PNTD)}(), #Arc{PNTD,I}}
            #     OrderedDict{Symbol, refplace_type(PNTD)}(), # RefPlace{PNTD}},
            #     OrderedDict{Symbol, reftransition_type(PNTD)}(), #RefTransition{PNTD}},
            #     ),
            pnd = PnmlNetData{PNTD}(
                        OrderedDict{Symbol, page_type(PNTD)}(),
                        OrderedDict{Symbol, place_type(PNTD)}(),
                        OrderedDict{Symbol, transition_type(PNTD)}(),
                        OrderedDict{Symbol, arc_type(PNTD)}(),
                        OrderedDict{Symbol, refplace_type(PNTD)}(),
                        OrderedDict{Symbol, reftransition_type(PNTD)}())

        # println()
        # @show typeof(tup)
        # println()
        # @show tup.place tup.transition tup.arc tup.refPlace tup.refTransition
        println()
        println("--------------------------------------------")
        @show typeof(pnd) propertynames(pnd)
        for x in  propertynames(pnd)
            @show length(getproperty(pnd, x))
        end
        println("--------------------------------------------")


        dict = pnml_node_defaults(
            node,
            :tag => Symbol(nn),
            :id => register_id!(idregistry, node["id"]),
            :pageset => pgset, # Root of the page id tree (pageset is per-tree-node data).
            #:pagedict => pgdict, # All pages & net share
            :netdata => pnd,
            :declaration => Declaration(),
            )

        parse_net_2!(dict, node, pntd, idregistry)
        dict
    end

    if CONFIG.verbose
        println()
        println("Net ", d[:id], ", ", length(d[:netdata][:page]), " Pages: ",  keys(d[:netdata][:page]))
        print(" page ids:")
        for pgid in d[:pageset]
            print(" ", pgid)
            @assert pid(d[:pagedict][pgid]) == pgid
        end
    end

    net = let pntd=pntd, id=d[:id], pgset=d[:pageset]
        PnmlNet(pntd, id, d[:netdata], pgset, d[:declaration], d[:name], ObjectCommon(d), node)
    end

    if CONFIG.verbose
        println()
        PnmlCore.pagetree(net)
        println()
        AbstractTrees.print_tree(net)
        println()
    end
    return net
end

"""
    parse_net_2!(d, node, pntd, idregistry)

Specialize on `pntd`. Go through children of `node` looking for expected tags,
delegating common tags and labels.
"""
function parse_net_2! end

function parse_net_2!(d::PnmlDict, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    for childnode in elements(node)
        tag = EzXML.nodename(childnode)
        if tag == "page"
            parse_net_page!(d, childnode, pntd, idregistry)
        else
            parse_pnml_node_common!(d, childnode, pntd, idregistry)
        end
        # Leave the empty `Declaration` alone.
    end
    return nothing
end

function parse_net_2!(d::PnmlDict, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore}
    for childnode in elements(node)
        tag = EzXML.nodename(childnode)
        if tag == "page"
            parse_net_page!(d, childnode, pntd, idregistry)
        elseif tag == "declaration"
            # For nets and pages the <declaration> tag is optional.
            # <declaration> ia a High-Level Annotation with a <structure> holding
            # zero or more <declarations>. Is complicated. You have been warned!
            # Expect
             #  <declaration> <structure> <declarations> <namedsort id="weight" name="Weight"> ...
            d[:declaration] = parse_declaration(childnode, pntd, idregistry)
        else
            parse_pnml_node_common!(d, childnode, pntd, idregistry)
        end
    end
    return nothing
end

#See also parse_subpage!.
function parse_net_page!(d::PnmlDict, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    let pg = parse_page!(d, node, pntd, idregistry), pageid = pid(pg)
        d[:pagedict][pageid] = pg #! PAGE: add to dictonary and id set
        push!(d[:pageset], pageid)
        if CONFIG.verbose
            println("parse_net_page! $pntd $pageid")
        end
    end
    return nothing
end

# See also parse_net_page!
function parse_subpage!(d::PnmlDict, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    let pg = parse_page!(d, node, pntd, idregistry), pageid = pid(pg)
        d[:pagedict][pageid] = pg #! PAGE: add to dictonary and id set
        push!(d[:pageset], pageid)

        if CONFIG.verbose
            println("parse_subpage! $pntd $pageid")
        end
    end
    return nothing
 end

"""
    parse_page!(pagedict, node, pntd, idregistry) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function parse_page!(d::PnmlDict, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    nn = check_nodename(node, "page")
    haskey(node, "id") || throw(MissingIDException(nn, node))
    if CONFIG.verbose
        println("parse $nn $pntd $(node["id"])")
    end

    d2 = let pgset = OrderedSet{Symbol}()
        pnml_node_defaults(
            node,
            :tag => Symbol(nn),
            :id => register_id!(idregistry, node["id"]),
            :declaration => Declaration(), #! HL
            :pageset => pgset,
            :netdata
            :pagedict => d[:pagedict], #! PAGE: propagate dictionary
            :netdata => d[:netdata] #! propagate to nodes
        )
    end

    #! parse_page_2!(d2, node, pntd, idregistry)
    for child in elements(node)
        if CONFIG.verbose
            println("""parse $(nodename(child)) $(child["id"])""")
        end
        #@assert haskey(d, :netdata)
        @match nodename(child) begin
            "place"               => parse_place!(d2[:netdata].place, child, pntd, idregistry)
            "transition"          => parse_transition!(d2[:netdata].transition, child, pntd, idregistry)
            "arc"                 => parse_arc!(d2[:netdata].arc, child, pntd, idregistry)
            "referencePlace"      => parse_refPlace!(d2[:netdata].refPlace, child, pntd, idregistry)
            "referenceTransition" => parse_refTransition!(d2[:netdata].refTransition, child, pntd, idregistry)
            "page" => parse_subpage!(d2, child, pntd, idregistry)
            _ => parse_pnml_node_common!(d2, child, pntd, idregistry)
        end
    end

    if CONFIG.verbose
        println("Page ", d2[:id], " add to ",  keys(d[:pagedict]))
        print(" subpage ids:")
        for pgid in d2[:pageset]
            print(" ", pgid)
        end
        println()
    end

    let pntd=pntd, pgdict=d2[:pagedict], pgset=d2[:pageset]
        Page(
            pntd,
            d2[:id],
            d2[:declaration],
            d2[:name],
            ObjectCommon(d),
            pgdict, # Dictionary of pages shared by net and all pages.
            d2[:netdata], # NamedTuple
            pgset, # Set of page ids of subpages of this page.
        )
    end
end

# function parse_page_2!(d::PnmlDict, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
#     for child in elements(node)
#         if CONFIG.verbose
#             println("""parse $(nodename(child)) $(child["id"])""")
#         end
#         @assert haskey(d, :netdata)
#         @match nodename(child) begin
#             "place"               => parse_place!(d[:netdata].place, child, pntd, idregistry)
#             "transition"          => parse_transition!(d[:netdata].transition, child, pntd, idregistry)
#             "arc"                 => parse_arc!(d[:netdata].arc, child, pntd, idregistry)
#             "referencePlace"      => parse_refPlace!(d[:netdata].refPlace, child, pntd, idregistry)
#             "referenceTransition" => parse_refTransition!(d[:netdata].refTransition, child, pntd, idregistry)
#             "page" => parse_subpage!(d, child, pntd, idregistry)
#             _ => parse_pnml_node_common!(d, child, pntd, idregistry)
#         end
#     end
#     return d
# end

function parse_place!(placedict, child, pntd, idregistry)
    id, p = parse_place(child, pntd, idregistry)
    placedict[id] = p
    return nothing
end

function parse_transition!(transdict, child, pntd, idregistry)
    p = parse_transition(child, pntd, idregistry)
    transdict[pid(p)] = p
    return nothing
end

function parse_arc!(arcdict, child, pntd, idregistry)
    p = parse_arc(child, pntd, idregistry)
    arcdict[pid(p)] = p
    return nothing
end

function parse_refPlace!(refdict, child, pntd, idregistry)
    p = parse_refPlace(child, pntd, idregistry)
    refdict[pid(p)] = p
    return nothing
end

function parse_refTransition!(refdict, child, pntd, idregistry)
    p = parse_refTransition(child, pntd, idregistry)
    refdict[pid(p)] = p
    return nothing
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "place")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        #!:marking => default_marking(pntd),
        #!:type => default_sort(pntd), # Different from net's type (this is a sort).
    )
    parse_place_labels!(d, node, pntd, idregistry)

    d[:id] => Place(pntd, d[:id],
        get(d, :marking, default_marking(pntd)),
        get(d, :type, default_sort(pntd)),
        d[:name], ObjectCommon(d))
end

"Specialize place label parsing."
function parse_place_labels! end
function parse_place_labels!(d::PnmlDict, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    for child in elements(node)
        @match nodename(child) begin
            "initialMarking" => (d[:marking] = parse_initialMarking(child, pntd, idregistry))
            _ => parse_pnml_node_common!(d, child, pntd, idregistry)
        end
    end
end

function parse_place_labels!(d::PnmlDict, node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    for child in elements(node)
        @match nodename(child) begin
            "hlinitialMarking" => (d[:marking] = parse_hlinitialMarking(child, pntd, idregistry))
            # Here type means `sort`. Re: Many-sorted algebra.
            "type" => (d[:type] = Sort(parse_type(child, pntd, idregistry))) #! HL sorttype
            _ => parse_pnml_node_common!(d, child, pntd, idregistry)
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "transition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :condition => nothing,
    )
    parse_transition_2!(d, pntd, node, idregistry)
    Transition(pntd, d[:id], d[:condition], d[:name], ObjectCommon(d))
end

"Specialize transition label parsing on Petri Net Type Definition."
function parse_transition_2! end
function parse_transition_2!(d::PnmlDict, pntd::PnmlType, node::XMLNode, idregistry::PIDR)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "condition" => (d[:condition] = parse_condition(child, pntd, idregistry))
            _ => parse_pnml_node_common!(d, child, pntd, idregistry)
        end
    end
end

# Implement other pntd dispatches if needed.

"""
    parse_arc(node::XMLNode, pntd::PnmlType, idregistry) -> Arc{typeof(pntd), typeof(inscription)}

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node, pntd, idregistry::PIDR)
    nn = check_nodename(node, "arc")

    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(node, "source")
    @assert haskey(node, "target")

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :source => Symbol(node["source"]),
        :target => Symbol(node["target"]),
    )
    foreach(elements(node)) do child
        parse_arc_labels!(d, child, pntd, idregistry) # Dispatch on pntd
    end

    Arc(pntd, d[:id], d[:source], d[:target],
        get(d, :inscription, default_inscription(pntd)),
        d[:name], ObjectCommon(d))
end

"""
Specialize arc label parsing.
"""
function parse_arc_labels! end

function parse_arc_labels!(d, node, pntd::PnmlType, idregistry::PIDR) # not HL
    @match nodename(node) begin
        "inscription" => (d[:inscription] = parse_inscription(node, pntd, idregistry))
        _ => parse_pnml_node_common!(d, node, pntd, idregistry)
    end
end

function parse_arc_labels!(d, node, pntd::AbstractHLCore, idregistry::PIDR)
    @match nodename(node) begin
        "hlinscription" => (d[:inscription] = parse_hlinscription(node, pntd, idregistry))
        _ => parse_pnml_node_common!(d, node, pntd, idregistry)
    end
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referencePlace")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") ||
        throw(MalformedException("$(nn) missing ref attribute", node))

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :ref => Symbol(node["ref"]),
    )

    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child, pntd, idregistry)
        end
    end
    RefPlace(pntd, d[:id], d[:ref], d[:name], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referenceTransition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") ||
        throw(MalformedException("$(nn) missing ref attribute", node))

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => idregistryister_id!(idregistry, node["id"]),
        :ref => Symbol(node["ref"]),
    )

    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child, pntd, idregistry)
        end
    end
    RefTransition(pntd, d[:id], d[:ref], d[:name], ObjectCommon(d))
end

#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the stripped string of nodecontent.
"""
function parse_text(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "text")
    string(strip(nodecontent(node)))
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding text value and optional tool & GUI information.
"""
function parse_name(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "name")

    # Assumes there are no other children with this tag (like the specification says).
    textnode = firstchild("text", node)
    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if !isnothing(textnode)
        text = string(strip(nodecontent(textnode)))
    elseif CONFIG.text_element_optional
        @warn "$nn missing <text> element"
        text = string(strip(nodecontent(node)))
    else
        throw(ArgumentError("$nn missing <text> element"))
    end

    graphicsnode = firstchild("graphics", node)
    graphics = isnothing(graphicsnode) ? nothing :
               parse_graphics(graphicsnode, pntd, idregistry)

    toolspecific = allchildren("toolspecific", node)
    tools = isempty(toolspecific) ? nothing :
            parse_toolspecific.(toolspecific, Ref(pntd), idregistry)

    Name(; text, graphics, tools)
end

#----------------------------------------------------------
#
#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return [`Structure`](@ref) wrapping a `PnmlDict` holding a <structure>.
Should be inside of an label.
A "claimed" label usually elids the <structure> level (does not call this method).
"""
function parse_structure(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "structure")
    Structure(unclaimed_label(node, pntd, idregistry), node)
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

    d = pnml_label_defaults(node, :tag => Symbol(nn), :value => val)

    foreach(elements(node)) do child
        @match nodename(child) begin
            # We extend to real numbers.
            "text" => (d[:value] = number_value(marking_value_type(pntd), (string∘strip∘nodecontent)(child))
            )
            _ => parse_pnml_label_common!(d, child, pntd, idregistry)
        end
    end
    # Treat missing value as if the <initialMarking> element was absent.
    if isnothing(d[:value])
        @warn "missing  <initialMarking> value"
        d[:value] = _evaluate(default_marking(pntd))
    end
    Marking(d[:value], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(node, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "inscription")
    d = pnml_label_defaults(node, :tag => Symbol(nn), :value => nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = number_value(inscription_value_type(pntd), (string∘strip∘nodecontent)(child)))
            # Should not have a structure.
            _ => parse_pnml_label_common!(d, child, pntd, idregistry)
        end
    end
    # Treat missing value as if the <inscription> element was absent.
    if isnothing(d[:value])
        if CONFIG.warn_on_fixup
            @warn("missing or unparsable <inscription> value")
        end
        d[:value] = default_inscription(pntd)()
    end
    Inscription(d[:value], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a [`Term`](@ref) in the <structure>
child. We extend the pnml standard by allowing node content to be numeric:
parsed to `Int` and `Float64`.
"""
function parse_hlinitialMarking(node, pntd::AbstractHLCore, idregistry::PIDR)
    nn = check_nodename(node, "hlinitialMarking")
    d = pnml_label_defaults(
        node,
        :tag => Symbol(nn),
        :text => nothing,
        :structure => nothing,
    )
    for child in elements(node)
        @match nodename(child) begin
            "structure" => (
                d[:structure] = if haselement(child)
                    parse_term(firstelement(child), pntd, idregistry)
                else
                    default_marking(pntd)
                end
            ) #! sort of place
            _ => parse_pnml_label_common!(d, child, pntd, idregistry)
        end
    end

    HLMarking(d[:text], d[:structure], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    nn = check_nodename(node, "hlinscription")
    @debug nn
    d = pnml_label_defaults(node, :tag => Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Expect <structure> to contain a single Term as a child tag.
            # Otherwise use the default inscription Term.
            "structure" => (
                d[:structure] =
                    haselement(child) ? parse_term(firstelement(child), pntd, idregistry) :
                    default_inscription(pntd)
            )
            _ => parse_pnml_label_common!(d, child, pntd, idregistry)
        end
    end
    HLInscription(d[:text], d[:structure], ObjectCommon(d))
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
    d = pnml_label_defaults(node, :tag => Symbol(nn))

    foreach(elements(node)) do child
        @match nodename(child) begin
            "structure" => (d[:structure] = parse_condition_structure(child, pntd, idregistry))
            _ => parse_pnml_label_common!(d, child, pntd, idregistry)
        end
    end

    #@show pntd, d[:structure]
    Condition(pntd, d[:text], d[:structure], ObjectCommon(d))
end

function parse_condition_structure(node, pntd::PnmlType, idregistry)
    nn = check_nodename(node, "structure")

    if haselement(node)
        term = firstelement(node)
        # Term is an abstract type even in the ISO specification.
        # Wraps an unclaimed label until more of high-level many-sorted algebra is done.
        #nodename(term) == "term"  ||
        #    error("$nn did not have <term> child: found $(nodename(term))")
        parse_term(term, pntd, idregistry)
    else
        default_condition(pntd)()
    end
end

#---------------------------------------------------------------------
#TODO Will unclaimed_node handle this?
"""
$(TYPEDSIGNATURES)

Should not often have a '<label>' tag, this will bark if one is found.
Return minimal PnmlDict holding (tag,node), to defer parsing the xml.
"""
function parse_label(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "label")
    @debug nn
    @warn "parse_label '$(node !== nothing && nn)'"
    PnmlDict(:tag => Symbol(nn), :xml => node) # Always add xml because this is unexpected.
end