const PIDR = PnmlIDRegistry

"""
$(TYPEDSIGNATURES)

Call the method matching `node.name` from [`tagmap`](@ref) if that mapping exists,
otherwise parse as [`unclaimed_label`](@ref) wrapped in a [`PnmlLabel`](@ref).
"""
function parse_node end

parse_node(node::XMLNode, reg::PIDR) = parse_node(node, PnmlCoreNet(), reg)

function parse_node(node::XMLNode, pntd::PnmlType, reg::PIDR)
    if haskey(tagmap, EzXML.nodename(node))
        parsefun = tagmap[EzXML.nodename(node)]
        #@show pntd, nameof(parsefun), typeof(parsefun), methods(parsefun)
        return parsefun(node, pntd, reg) # Various types returned here.
    else
        return PnmlLabel(unclaimed_label(node, pntd, reg), node)
    end
end

#TODO test pnml_namespace

"""
$(TYPEDSIGNATURES)

Return namespace of `node.
When `node` does not have a namespace return default value [`pnml_ns`](@ref)
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
    reg = PnmlIDRegistry()
    # Good place for debugging.
    parse_pnml(xmlroot(str), reg)
end

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a file containing XML.
See [`parse_str`](@ref) and [`parse_pnml`](@ref).
"""
function parse_file(fname::AbstractString)
    isempty(fname) &&
        throw(ArgumentError("parse_file must have a non-empty file name argument"))
    reg = PnmlIDRegistry()
    # Good place for debugging.
    parse_pnml(root(EzXML.readxml(fname)), reg)
end

"""
$(TYPEDSIGNATURES)
Start parse from the pnml root `node` of a well formed XML document.
Return a [`PnmlModel`](@ref)..
"""
function parse_pnml(node::XMLNode, reg::PIDR)
    nn = check_nodename(node, "pnml")

    namespace = if EzXML.hasnamespace(node)
        EzXML.namespace(node)
    else
        if @load_preference("warn_on_namespace", true)
            @warn("$nn missing namespace")
        end
        pnml_ns # Use default value
    end

    nets = allchildren("net", node)
    isempty(nets) && throw(MalformedException("$nn does not have any <net> elements", node))

    # Do not yet have a PNTD defined, so call parse_net directly.
    # When there are multiple net types
    #net_vec = parse_net.(nets, Ref(reg))
    net_vec = PnmlNet[parse_net(net, reg, nothing) for net in nets] #! abstract Vector
    net_tup = tuple(net_vec...)  #! abstract Tuple
    PnmlModel(net_tup, namespace, reg, node)
end

"""
$(TYPEDSIGNATURES)
Return a dictonary of the pnml net with keys matching their XML tag names.
"""
function parse_net(node::XMLNode, reg::PIDR, pntd_override::Maybe{PnmlType}=nothing)::PnmlNet
    nn = check_nodename(node, "net")
    haskey(node, "id") || throw(MissingIDException(nn, node))
    haskey(node, "type") || throw(MalformedException("$nn missing type", node))

    # Missing the page level in the pnml heirarchy causes nodes to be placed in :labels.
    # May result in undefined behavior and/or require ideosyncratic parsing.
    isempty(allchildren("page", node)) &&
        throw(MalformedException("$nn does not have any pages", node))

    # Although the specification says the petri net type definition (pntd) must be attached
    # to the <net> element, it is allowed by this package to override that value.
    pn_typedef = pnmltype(node["type"])
    if isnothing(pntd_override)
        pntd = pn_typedef
    else
        pntd = pntd_override
        @info "parse_net pntd set to $pntd, overrides $pn_typedef"
    end

    # Create a PnmlDict with keys for possible child tags.
    # Some keys have known/required values.
    # Optional key values are nothing for single object or empty vector when multiples.
    # Keys that have pural names usually have a vector value.
    # The 'graphics' key is one exception and has a single value.
    d = let pntd=pntd
        pgtyp = page_type(pntd)   #!not inferrable?
        @show pgtyp
        pt2 = Page{typeof(pntd),
                    marking_type(pntd),
                    inscription_type(pntd),
                    condition_type(pntd),
                    sort_type(pntd)}
        @show pt2
        empty_pages = pgtyp[] #! this is OK
        @show empty_pages
        pnml_node_defaults(
            node,
            :tag => Symbol(nn),
            :id => register_id!(reg, node["id"]),
            :pages => empty_pages,
            :declaration => Declaration(),
        ) #! declaration is High Level
    end
    # Go through children looking for expected tags, delegating common tags and labels.
    parse_net_2!(d, node, pntd, reg)
    PnmlNet(pntd, d[:id], d[:pages], d[:declaration], d[:name], ObjectCommon(d), node)
end

"Specialize net parsing on pntd"
function parse_net_2! end

function parse_net_2!(d::PnmlDict, node::XMLNode, pntd::PnmlType, reg::PIDR)
    for childnode in elements(node)
        tag = EzXML.nodename(childnode)
        if tag == "page"
            push!(d[:pages], parse_page(childnode, pntd, reg))
        else
            parse_pnml_node_common!(d, childnode, pntd, reg)
        end
        # Leave the empty `Declaration` alone.
end
end

function parse_net_2!(d::PnmlDict, node::XMLNode, pntd::AbstractHLCore, reg::PIDR)
    for childnode in elements(node)
        tag = EzXML.nodename(childnode)
        if tag == "page"
            push!(d[:pages], parse_page(childnode, pntd, reg))
        elseif tag == "declaration"
            # For nets and pages the <declaration> tag is optional.
            # <declaration> ia a High-Level Annotation with a <structure> holding
            # zero or more <declarations>. Is complicated. You have been warned!
            # Expected XML structure:
            #  <declaration> <structure> <declarations> <namedsort id="weight" name="Weight"> ...
            d[:declaration] = parse_declaration(childnode, pntd, reg)
        else
            parse_pnml_node_common!(d, childnode, pntd, reg)
        end
    end
end

"""
$(TYPEDSIGNATURES)
PNML requires at least one page.
"""
function parse_page(node, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "page")
    #@show "parse_page $nn $pntd"
    haskey(node, "id") || throw(MissingIDException(nn, node))

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(reg, node["id"]),

        # Rather than use an abstract type here, assume we have a consistent model where
        # all places, transitions and arcs are parsed into type-stable, compatible objects.
        # The PNTD is used to deduce the expected types.
        :places => place_type(pntd)[], #!Place{typeof(pntd), marking_type(pntd), sort_type(pntd)}[],
        :trans => transition_type(pntd)[], #!Transition{typeof(pntd), condition_type(pntd)}[],
        :arcs => arc_type(pntd)[], #!Arc{typeof(pntd), inscription_type(pntd)}[],
        :refP => refplace_type(pntd)[], #!RefPlace{typeof(pntd)}[],
        :refT => reftransition_type(pntd)[], #!RefTransition{typeof(pntd)}[],
        :declaration => Declaration(), #! HL
        :pages => page_type(pntd)[],
        #Page{typeof(pntd),
        #               marking_type(pntd),
        #               inscription_type(pntd),
        #               condition_type(pntd),
        #               sort_type(pntd)}[],
    )
    parse_page_2!(d, node, pntd, reg)

    Page(
        pntd,
        d[:id],
        d[:places],
        d[:refP],
        d[:trans],
        d[:refT],
        d[:arcs],
        d[:declaration],
        d[:pages],
        d[:name],
        ObjectCommon(d),
    )
end


function parse_page_2! end

function parse_page_2!(d::PnmlDict, node::XMLNode, pntd::PnmlType, reg::PIDR)
    for child in elements(node)
        #!@show "parse_page_2! $pntd $(nodename(child))"
        @match nodename(child) begin
            "place" => push!(d[:places], parse_place(child, pntd, reg))
            "transition" => push!(d[:trans], parse_transition(child, pntd, reg))
            "arc" => push!(d[:arcs], parse_arc(child, pntd, reg))
            "referencePlace" => push!(d[:refP], parse_refPlace(child, pntd, reg))
            "referenceTransition" =>
                push!(d[:refT], parse_refTransition(child, pntd, reg))
            "page" => push!(d[:pages], parse_page(child, pntd, reg))
            _ => parse_pnml_node_common!(d, child, pntd, reg)
        end
    end
    return d
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "place")
    @debug nn
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(reg, node["id"]),
        #!:marking => default_marking(pntd),
        #!:type => default_sort(pntd), # Different from net's type (this is a sort).
    )
    parse_place_labels!(d, node, pntd, reg)

    Place(pntd, d[:id],
        get(d, :marking, default_marking(pntd)),
        get(d, :type, default_sort(pntd)),
        d[:name], ObjectCommon(d))
end

"Specialize place label parsing."
function parse_place_labels! end
function parse_place_labels!(d::PnmlDict, node::XMLNode, pntd::PnmlType, reg::PIDR)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "initialMarking" => (d[:marking] = parse_initialMarking(child, pntd, reg))
            _ => parse_pnml_node_common!(d, child, pntd, reg)
        end
    end
end
function parse_place_labels!(d::PnmlDict, node::XMLNode, pntd::AbstractHLCore, reg::PIDR)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "hlinitialMarking" => (d[:marking] = parse_hlinitialMarking(child, pntd, reg))
            # Here type means `sort`. Re: Many-sorted algebra.
            "type" => (d[:type] = Sort(parse_type(child, pntd, reg))) #! HL sorttype
            _ => parse_pnml_node_common!(d, child, pntd, reg)
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "transition")
    @debug nn
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(reg, node["id"]),
        :condition => nothing, #default_condition(pntd),
    )
    parse_transition_2!(pntd, d, node, reg)
    #! Allow condition to be nothing here.
    Transition(pntd, d[:id], d[:condition], d[:name], ObjectCommon(d))
end

"Specialize transition label parsing on Petri Net Type Definition."
function parse_transition_2! end
function parse_transition_2!(pntd::PnmlType, d::PnmlDict, node::XMLNode, reg::PIDR)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "condition" => (d[:condition] = parse_condition(child, pntd, reg))
            _ => parse_pnml_node_common!(d, child, pntd, reg)
        end
    end
end

# Implement other pntd dispatches if needed.

"""
    parse_arc(node::XMLNode, pntd::PnmlType, reg) -> Arc{typeof(pntd), typeof(inscription)}

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node, pntd, reg::PIDR)
    nn = check_nodename(node, "arc")
    @debug nn
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(node, "source")
    @assert haskey(node, "target")

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(reg, node["id"]),
        :source => Symbol(node["source"]),
        :target => Symbol(node["target"]),
    )
    foreach(elements(node)) do child
        parse_arc_labels!(d, child, pntd, reg) # Dispatch on pntd
    end

    Arc(pntd, d[:id], d[:source], d[:target],
        get(d, :inscription, default_inscription(pntd)),
        d[:name], ObjectCommon(d))
end

"""
Specialize arc label parsing.
"""
function parse_arc_labels! end

function parse_arc_labels!(d, node, pntd::PnmlType, reg::PIDR) # not HL
    @match nodename(node) begin
        "inscription" => (d[:inscription] = parse_inscription(node, pntd, reg))
        _ => parse_pnml_node_common!(d, node, pntd, reg)
    end
end

function parse_arc_labels!(d, node, pntd::AbstractHLCore, reg::PIDR)
    @match nodename(node) begin
        "hlinscription" => (d[:inscription] = parse_hlinscription(node, pntd, reg))
        _ => parse_pnml_node_common!(d, node, pntd, reg)
    end
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "referencePlace")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") ||
        throw(MalformedException("$(nn) missing ref attribute", node))

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(reg, node["id"]),
        :ref => Symbol(node["ref"]),
    )

    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child, pntd, reg)
        end
    end
    RefPlace(pntd, d[:id], d[:ref], d[:name], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "referenceTransition")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") ||
        throw(MalformedException("$(nn) missing ref attribute", node))

    d = pnml_node_defaults(
        node,
        :tag => Symbol(nn),
        :id => register_id!(reg, node["id"]),
        :ref => Symbol(node["ref"]),
    )

    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child, pntd, reg)
        end
    end
    RefTransition(pntd, d[:id], d[:ref], d[:name], ObjectCommon(d))
end

#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the stripped string of nodecontent.
"""
function parse_text(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "text")
    string(strip(nodecontent(node)))
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding text value and optional tool & GUI information.
"""
function parse_name(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "name")

    # Assumes there are no other children with this tag (like the specification says).
    textnode = firstchild("text", node)
    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if !isnothing(textnode)
        text = string(strip(nodecontent(textnode)))
    elseif @load_preference("text_element_optional", true)
        @warn "$nn missing <text> element"
        text = string(strip(nodecontent(node)))
    else
        throw(ArgumentError("$nn missing <text> element"))
    end

    graphicsnode = firstchild("graphics", node)
    graphics = isnothing(graphicsnode) ? nothing :
               parse_graphics(graphicsnode, pntd, reg)

    toolspecific = allchildren("toolspecific", node)
    tools = isempty(toolspecific) ? nothing :
            parse_toolspecific.(toolspecific, Ref(pntd), reg)

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
function parse_structure(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "structure")
    Structure(unclaimed_label(node, pntd, reg), node)
end

#----------------------------------------------------------
#
# PNML annotation-label XML element parsers.
#
#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)
"""
function parse_initialMarking(node::XMLNode, pntd::PnmlType, reg::PIDR)
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
            _ => parse_pnml_label_common!(d, child, pntd, reg)
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
function parse_inscription(node, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "inscription")
    d = pnml_label_defaults(node, :tag => Symbol(nn), :value => nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = number_value(inscription_value_type(pntd), (string∘strip∘nodecontent)(child)))
            # Should not have a structure.
            _ => parse_pnml_label_common!(d, child, pntd, reg)
        end
    end
    # Treat missing value as if the <inscription> element was absent.
    if isnothing(d[:value])
        if @load_preference("warn_on_fixup", false)
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
function parse_hlinitialMarking(node, pntd::AbstractHLCore, reg::PIDR)
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
                    parse_term(firstelement(child), pntd, reg)
                else
                    default_marking(pntd)
                end
            ) #! sort of place
            _ => parse_pnml_label_common!(d, child, pntd, reg)
        end
    end

    HLMarking(d[:text], d[:structure], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, pntd::AbstractHLCore, reg::PIDR)
    nn = check_nodename(node, "hlinscription")
    @debug nn
    d = pnml_label_defaults(node, :tag => Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Expect <structure> to contain a single Term as a child tag.
            # Otherwise use the default inscription Term.
            "structure" => (
                d[:structure] =
                    haselement(child) ? parse_term(firstelement(child), pntd, reg) :
                    default_inscription(pntd)
            )
            _ => parse_pnml_label_common!(d, child, pntd, reg)
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
function parse_condition(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "condition")
    d = pnml_label_defaults(node, :tag => Symbol(nn))

    foreach(elements(node)) do child
        @match nodename(child) begin
            "structure" => (d[:structure] = parse_condition_structure(child, pntd, reg))
            _ => parse_pnml_label_common!(d, child, pntd, reg)
        end
    end

    #@show pntd, d[:structure]
    Condition(pntd, d[:text], d[:structure], ObjectCommon(d))
end

function parse_condition_structure(node, pntd::PnmlType, reg)
    nn = check_nodename(node, "structure")

    if haselement(node)
        term = firstelement(node)
        # Term is an abstract type even in the ISO specification.
        # Wraps an unclaimed label until more of high-level many-sorted algebra is done.
        #nodename(term) == "term"  ||
        #    error("$nn did not have <term> child: found $(nodename(term))")
        parse_term(term, pntd, reg)
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
function parse_label(node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "label")
    @debug nn
    @warn "parse_label '$(node !== nothing && nn)'"
    PnmlDict(:tag => Symbol(nn), :xml => node) # Always add xml because this is unexpected.
end
