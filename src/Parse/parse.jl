const PIDR = PnmlIDRegistry

"""
$(TYPEDSIGNATURES)

Call any method matching xml node's tag` in [`tagmap`](@ref),
otherwise parse as [`unclaimed_label`](@ref) wrapped in a [`PnmlLabel`](@ref).
All uses are expected to be pnml labels attached to pnml graph nodes, arcs, nets, pages,
that are excluded from this parsing pathway.
"""
function parse_node(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    println("PARSE_NODE $(EzXML.nodename(node))") # Useful for debug.
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

Return namespace. When `node` does not have a namespace return default value [`pnml_ns`](@ref)
and warn or throw an error.
"""
function pnml_namespace(node::XMLNode; missing_ns_fatal::Bool=false, default_ns=pnml_ns)
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
Return a [`PnmlModel`](@ref) holding one or more [`PnmlNet`](@ref).
"""
function parse_pnml(node::XMLNode, idregistry::PIDR)
    nn = check_nodename(node, "pnml")
    namespace = pnml_namespace(node)
    nets = allchildren("net", node)
    isempty(nets) && throw(MalformedException("$nn does not have any <net> elements", node))

    # Do not yet have a PNTD defined. Each net can be different Net speciaization.
    net_tup = tuple((parse_net(net, idregistry) for net in nets)...) #! Allocation?
    @assert length(net_tup) > 0
    if CONFIG.verbose
        println("PnmlModel $(length(net_tup)) nets")
        for n in net_tup
            print("  ", pid(n), " :: ", typeof(n))
            println()
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
    haskey(node, "type") || throw(MalformedException("$nn missing type", node))
    id = node["id"]
    type = node["type"]
    if CONFIG.verbose
        println("""

        =========
        parse_net: $id $type $(pntd_override !== nothing && pntd_override)
        """)
    end

    isempty(allchildren("page", node)) &&
        throw(MalformedException("$nn $id does not have any pages", node))

    # Although the specification says the petri net type definition (pntd) must be attached
    # to the <net> element, it is allowed by this package to override that value.
    pn_typedef = pnmltype(type)
    if isnothing(pntd_override)
        pntd = pn_typedef
    else
        pntd = pntd_override
        @info "net $id pntd set to $pntd, overrides $pn_typedef"
    end

    # Now we know the PNTD and can parse.
    net = parse_net_1(node, pntd, idregistry)
    if CONFIG.verbose
        println()
        PNML.pagetree(net)
        println()
        AbstractTrees.print_tree(net)
        println()
    end
    return net
end

"""
Parse net with a defined PnmlType. The PNTD is used to set
the marking, inscription, condition and sort type parameters.
"""
function parse_net_1(node::XMLNode, pntd::PNTD, idregistry::PIDR) where {PNTD<:PnmlType}
    # create tuple
    tup = let pntd = pntd, PNTD = typeof(pntd),
        mtype = marking_type(PNTD),
        itype = inscription_type(PNTD),
        ctype = condition_type(PNTD),
        stype = sort_type(PNTD),
        pgtype = Page{PNTD, mtype, itype, ctype, stype},
        pgdict = OrderedDict{Symbol,pgtype}(),
        netsets = PnmlNetSets(),
        pnd = PnmlNetData(pntd,
            OrderedDict{Symbol,Place{PNTD,<:mtype,<:stype}}(),
            OrderedDict{Symbol,Transition{PNTD,ctype}}(),
            OrderedDict{Symbol,Arc{PNTD,itype}}(),
            OrderedDict{Symbol,RefPlace{PNTD}}(),
            OrderedDict{Symbol,RefTransition{PNTD}}())

        # Create a PnmlDict with keys for possible child tags. #! tuplize
        pnml_node_defaults(
            :tag => Symbol(nodename(node)),
            :id => register_id!(idregistry, node["id"]),
            :netsets => netsets, # Per-page-tree-node data.
            :pagedict => pgdict, # All pages & net share.
            :netdata => pnd,# All pages & net share.
            :declaration => Declaration(),)
    end

    # Fill the pagedict, netsets, netdata.
    parse_net_2!(tup, node, pntd, idregistry)
    @show typeof(tup)
    if CONFIG.verbose
        println("""
                Net  $(tup.id), $(length(tup.pagedict))  Pages:  $(keys(tup.pagedict))
                    page ids: $(collect(values(tup.netsets.page_set)))
                """)
    end
    return PnmlNet(pntd, tup.id, tup.pagedict, tup.netdata, tup.netsets,
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

function parse_net_2!(tup, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    for childnode in elements(node)
        tag = EzXML.nodename(childnode)
        if tag == "page"
            parse_net_page!(tup, childnode, pntd, idregistry)
        else
            parse_pnml_object_common!(tup, childnode, pntd, idregistry)
        end
        # Leave the empty `Declaration` alone.
    end
    return nothing
end

function parse_net_2!(tup, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:AbstractHLCore}
    for childnode in elements(node)
        tag = EzXML.nodename(childnode)
        if tag == "page"
            parse_net_page!(tup, childnode, pntd, idregistry)
        elseif tag == "declaration"
            tup = merge(tup, (; :declaration => parse_declaration(childnode, pntd, idregistry))) #! tuplize
        else
            parse_pnml_object_common!(tup, childnode, pntd, idregistry)
        end
    end
    return nothing
end

#See also parse_subpage!.
function parse_net_page!(tup::NamedTuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    pg = parse_page!(tup, node, pntd, idregistry)
    pageid = pid(pg)
    CONFIG.verbose && println("parse_net_page! $pntd $pageid")
    tup.pagedict[pageid] = pg #! PAGE: add to dictonary and id set
    push!(tup.netsets.page_set, pageid)
    return nothing
end

# See also parse_net_page!
function parse_subpage!(tup::NamedTuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    pg = parse_page!(tup, node, pntd, idregistry)
    pageid = pid(pg)
    CONFIG.verbose && println("parse_subpage! $pntd $pageid")
    tup.pagedict[pageid] = pg #! PAGE: add to dictonary and id set
    push!(tup.netsets.page_set, pageid)
    return nothing
end

"""
    parse_page!(tup, node, pntd, idregistry) -> Page

Place `Page` in `pagedict` using id as the key.
"""
function parse_page!(tup1::NamedTuple, node::XMLNode, pntd::T, idregistry::PIDR) where {T<:PnmlType}
    nn = check_nodename(node, "page")
    haskey(node, "id") || throw(MissingIDException(nn, node))
    CONFIG.verbose && println("parse $nn $pntd $(node["id"])")
    tup2 = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :declaration => Declaration(), #! HL
        :netsets => PnmlNetSets(), # per page-tree-node data
        :pagedict => tup1.pagedict, #! propagate from tup1 to tup2
        :netdata => tup1.netdata #! propagate from tup1 to tup2
    )
    println("parse_page tup2 = ", tup2) #! debug

    for child in elements(node)
        tag = nodename(child)
        id = child["id"]
        CONFIG.verbose && println("parse $tag $id")

        @assert hasproperty(tup1, :netdata)
        @assert hasproperty(tup1, :netsets)
        @assert haskey(tup2, :netdata)
        @assert haskey(tup2, :netsets)

        @match tag begin
            "place"                => parse_place!(tup2.netsets.place_set, tup2.netdata.place_dict, child, pntd, idregistry)
            "transition"           => parse_transition!(tup2.netsets.transition_set, tup2.netdata.transition_dict, child, pntd, idregistry)
            "arc"                  => parse_arc!(tup2.netsets.arc_set, tup2.netdata.arc_dict, child, pntd, idregistry)
            "referencePlace"       => parse_refPlace!(tup2.netsets.refplace_set, tup2.netdata.refplace_dict, child, pntd, idregistry)
            "referenceTransition"  => parse_refTransition!(tup2.netsets.reftransition_set, tup2.netdata.reftransition_dict, child, pntd, idregistry)
            "page"                 => parse_subpage!(tup2, child, pntd, idregistry)
            _                      => parse_pnml_object_common!(tup2, child, pntd, idregistry)
        end
    end

    if CONFIG.verbose
        @show typeof(tup2)
        println("Page ", tup2.id, " add to ", keys(tup2.pagedict))
        print(" subpage ids:")
        for pgid in tup2.netsets.page_set
            print(" ", pgid)
        end
        println()
    end

    Page(pntd,
        tup2.id,
        tup2.declaration,
        tup2.name,
        ObjectCommon(tup2),
        tup2.pagedict, #! shared by net and all pages.
        tup2.netdata, #! shared by net and all pages.
        tup2.netsets, # Set of ids "owned" by this page.
    )
end

# set is per-Page, dict is per-Net
function parse_place!(place_set, place_dict, child, pntd, idregistry)
    pl = parse_place(child, pntd, idregistry)
    id = pid(pl)
    println(id, "  ", typeof(pl))
    push!(place_set, id)
    setindex!(place_dict, pl, id) # place_dict[id] = pl
    return nothing
end

function parse_transition!(transition_set, transition_dict, child, pntd, idregistry)
    tr = parse_transition(child, pntd, idregistry)
    push!(transition_set, pid(tr))
    transition_dict[pid(tr)] = tr
    return nothing
end

function parse_arc!(arc_set, @nospecialize(arc_dict), child, pntd, idregistry)
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
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    tup = pnml_node_defaults(
        :tag => Symbol(nn), # XML tag
        :id => register_id!(idregistry, node["id"]),
        #!:marking => default_marking(pntd),
        #!:type => default_sort(pntd), # Different from net's type (this is a sort).
    )

    println("before parse_place_labels! tup = ", tup)
    parse_place_labels!(@nospecialize(RefValue(tup)), node, pntd, idregistry)
    println("after parse_place_labels! tup  = ", tup)

    mark = hasproperty(tup, :marking) ? tup.marking : default_marking(pntd)
    sorttype = hasproperty(tup, :type) ? tup.type : default_sort(pntd)
    #@show typeof(mark) typeof(sorttype)
    Place(pntd,
        tup.id,
        mark, #!get(d, :marking, default_marking(pntd)),
        sorttype, #!get(d, :type, default_sort(pntd)),
        tup.name,
        ObjectCommon(tup))
end

"place label parsing updates tuple."
function parse_place_labels!(@nospecialize(tup::RefValue{NamedTuple}), node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    print("parse_place_labels! ") #! debug
    let
        labels = EzXML.elements(node)
        isempty(labels) || print(EzXML.nodename.(labels))
    end
    println()

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        println("    $tag")
        if tag == "initialMarking"
            tup[] = merge(tup[], (; :marking => parse_initialMarking(child, pntd, idregistry)))
        elseif tag == "hlinitialMarking"
            tup[] = merge(tup[], (; :marking => parse_hlinitialMarking(child, pntd, idregistry)))
        elseif tag == "type"
            # Here type means `sort`. Re: Many-sorted algebra from High-Level nets.
            # But we extend to all nets using a type parameter (meaning TBD).
            if pntd isa AbstractHLCore #! HL, move parse_type from declarations to TBD
                tup[] = merge(tup[], (; :type => parse_type(child, pntd, idregistry))) # Sort
                @assert tup[].type isa Sort
            else
                tup[] = merge(tup[], (; :type => parse_type(child, pntd, idregistry)))
                @assert tup[].type isa Number # sort_type(pntd)
            end
        else
            parse_pnml_object_common!(tup[], child, pntd, idregistry)
        end
    end
    println("on return from  parse_place_labels! tup = ", tup[])
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
        :condition => nothing,
    )
    parse_transition_2!(tup, pntd, node, idregistry)
    Transition(pntd, tup.id, tup.condition, tup.name, ObjectCommon(tup))
end

"Specialize transition label parsing on Petri Net Type Definition."
function parse_transition_2! end
function parse_transition_2!(tup::NamedTuple, pntd::PnmlType, node::XMLNode, idregistry::PIDR)
    for child in eachelement(node)
        tag = EzXML.nodename(child)
        @match nodename(child) begin
            "condition" => (tup = merge(tup, (; :condition => parse_condition(child, pntd, idregistry))))
            _ => parse_pnml_object_common!(tup, child, pntd, idregistry)
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

    tup = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :source => Symbol(node["source"]),
        :target => Symbol(node["target"]),
    )

    println("arc $(tup.id) $(tup.source) -> $(tup.target) has ")
    for child in eachelement(node)
        println("    $(nodename(child))") # Show any labels
        parse_arc_labels!(tup, child, pntd, idregistry) # Dispatch on pntd
    end

    Arc(pntd, tup.id, tup.source, tup.target,
        get(tup, :inscription, default_inscription(pntd)),
        tup.name, ObjectCommon(tup))
end

"""
Specialize arc label parsing.
"""
function parse_arc_labels! end

function parse_arc_labels!(tup, node, pntd::PnmlType, idregistry::PIDR) # not HL
    @match nodename(node) begin
        "inscription" => (tup = merge(tup, (; :inscription => parse_inscription(node, pntd, idregistry))))
        _ => parse_pnml_object_common!(tup, node, pntd, idregistry)
    end
end

function parse_arc_labels!(tup, node, pntd::AbstractHLCore, idregistry::PIDR)
    @match nodename(node) begin
        "hlinscription" => (tup = merge(tup, (; :inscription => parse_hlinscription(node, pntd, idregistry))))
        _ => parse_pnml_object_common!(tup, node, pntd, idregistry)
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

    tup = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :ref => Symbol(node["ref"]),
    )

    for child in eachelement(node)
        @match nodename(child) begin
            _ => parse_pnml_object_common!(tup, child, pntd, idregistry)
        end
    end
    RefPlace(pntd, tup.id, tup.ref, tup.name, ObjectCommon(tup))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "referenceTransition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") ||
        throw(MalformedException("$(nn) missing ref attribute", node))

    tup = pnml_node_defaults(
        :tag => Symbol(nn),
        :id => register_id!(idregistry, node["id"]),
        :ref => Symbol(node["ref"]),
    )

    for child in eachelement(node)
        @match nodename(child) begin
            _ => parse_pnml_object_common!(tup, child, pntd, idregistry)
        end
    end
    RefTransition(pntd, tup.id, tup.ref, tup.name, ObjectCommon(tup))
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
    print("parse_name ") #! debug
    # Assumes there are no other children with this tag (like the specification says).
    textnode = firstchild("text", node)
    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if !isnothing(textnode)
        text = string(strip(nodecontent(textnode)))
    elseif CONFIG.text_element_optional
        @warn "$nn missing <text> element" # Remove when CONFIG default set to false.
        text = string(strip(nodecontent(node)))
    else
        throw(ArgumentError("$nn missing <text> element"))
    end
    println("'$text'") #! debug
    graphicsnode = firstchild("graphics", node) # single
    graphics = isnothing(graphicsnode) ? nothing :
               parse_graphics(graphicsnode, pntd, idregistry)

    toolspecific = allchildren("toolspecific", node) # multiple
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
    check_nodename(node, "structure")
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
    tup = pnml_label_defaults(:tag => Symbol(nn), :value => val)

    for child in elements(node)
        tag = nodename(child)
            # We extend to real numbers.
        if tag == "text"
            tup = merge(tup, (; :value => number_value(marking_value_type(pntd),
                                                       (string ∘ strip ∘ nodecontent)(child))))
        else
            parse_pnml_label_common!(tup, child, pntd, idregistry)
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
    tup = pnml_label_defaults(:tag => Symbol(nn), :value => nothing)

    for child in elements(node)
        tag = nodename(child)
        if tup == "text"
            txt = (string ∘ strip ∘ nodecontent)(child)
            val = number_value(inscription_value_type(pntd), txt)
            tup = merge(tup, (; :value => val))
            println(txt, " ", val)
        else
            # Should not have a structure.
            parse_pnml_label_common!(tup, child, pntd, idregistry)
        end
    end
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

    for child in elements(node)
        @match nodename(child) begin
            "structure" => (
                tup = merge(tup, (; :structure => if haselement(child)
                    parse_term(firstelement(child), pntd, idregistry)
                else
                    default_marking(pntd)
                end
            ))) #! sort of place
            _ => parse_pnml_label_common!(tup, child, pntd, idregistry)
        end
    end

    HLMarking(tup.text, tup.structure, ObjectCommon(tup))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, pntd::AbstractHLCore, idregistry::PIDR)
    nn = check_nodename(node, "hlinscription")
    @debug nn
    tup = pnml_label_defaults(:tag => Symbol(nn))

    for child in elements(node)
        @match nodename(child) begin
            # Expect <structure> to contain a single Term as a child tag.
            # Otherwise use the default inscription Term.
            "structure" => (
                tup = merge(tup, (; :structure =>
                    haselement(child) ? parse_term(firstelement(child), pntd, idregistry) :
                    default_inscription(pntd)
            )))
            _ => parse_pnml_label_common!(tup, child, pntd, idregistry)
        end
    end
    HLInscription(tup.text, tup.structure, ObjectCommon(tup))
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

    for child in elements(node)
        @match nodename(child) begin
            "structure" => (tup = merge(tup, (; :structure => parse_condition_structure(child, pntd, idregistry))))
            _ => parse_pnml_label_common!(tup, child, pntd, idregistry)
        end
    end

    #@show pntd, d[:structure]
    Condition(pntd, tup.text, tup.structure, ObjectCommon(tup))
end

function parse_condition_structure(node, pntd::PnmlType, idregistry)
    nn = check_nodename(node, "structure")

    if haselement(node)
        term = firstelement(node)
        # Term is an abstract type even in the ISO specification.
        # Wraps an unclaimed label until more of high-level many-sorted algebra is done.
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
    @assert node !== nothing
    nn = check_nodename(node, "label")
    @warn "parse_label '$(nn)'"
    (; :tag => Symbol(nn), :xml => node) # Always add xml because this is unexpected.
end
