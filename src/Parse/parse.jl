"""
$(TYPEDSIGNATURES)

Call the method matching `node.name` from [`tagmap`](@ref) if that mapping exists,
otherwise parse as [`unclaimed_label`](@ref) wrapped in a [`PnmlLabel`](@ref).
"""
function parse_node end
parse_node(node::XMLNode; kw...) = parse_node(node, PnmlCore(); kw...)
function parse_node(node::XMLNode, pntd::PnmlType; kw...)
    if haskey(tagmap, nodename(node))
        return tagmap[nodename(node)](node, pntd; kw...) # Various types returned here.
    else
        return PnmlLabel(unclaimed_label(node, pntd; kw...), node)
    end
end

#TODO test pnml_namespace

"""
$(TYPEDSIGNATURES)

Return namespace of `node.
When `node` does not have a namespace return default value [`pnml_ns`](@ref)
and warn or throw an error.
"""
function pnml_namespace(node::XMLNode; missing_ns_fatal=false, default_ns=pnml_ns)
    if EzXML.hasnamespace(node)
         return EzXML.namespace(node)
    else
        emsg = "$(nodename(node)) missing namespace"
        missing_ns_fatal===false ? @warn(emsg) : error(emsg)
        return default_ns
    end
end
"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a string containing XML.
See [`parse_file`](@ref) and [`parse_pnml`](@ref).
"""
function parse_str(str::AbstractString)
    isempty(str) && error("parse_str must have a non-empty string argument")
    reg = IDRegistry()
    # Good place for debugging.
    parse_pnml(root(EzXML.parsexml(str)); reg)
end

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a file containing XML.
See [`parse_str`](@ref) and [`parse_pnml`](@ref).
"""
function parse_file(fname::AbstractString)
    isempty(fname) && error("parse_file must have a non-empty file name argument")
    reg = IDRegistry()
    # Good place for debugging.
    parse_pnml(root(EzXML.readxml(fname)); reg)
end

"""
$(TYPEDSIGNATURES)
Start parse from the pnml root `node` of a well formed XML document.
Return a [`PnmlModel`](@ref)..
"""
function parse_pnml(node::XMLNode; kw...)
    nn = nodename(node)
    nn == "pnml" || error("element name wrong: $nn" )

    @assert haskey(kw, :reg)

    nets = allchildren("net", node)
    isempty(nets) && throw(MalformedException("$nn does not have any <net> elements", node))

    # Do not yet have a PNTD defined, so call parse_net directly.
    netvec = parse_net.(nets; kw...)

    namespace = if EzXML.hasnamespace(node)
            EzXML.namespace(node)
        else
            @warn("$nn missing namespace")
            pnml_ns # Use default value
        end

    PnmlModel(netvec,
              namespace,
              kw[:reg],
              node)
end

"""
$(TYPEDSIGNATURES)
Return a dictonary of the pnml net with keys matching their XML tag names.
"""
function parse_net(node, pntd=nothing; kw...)::PnmlNet
    nn = nodename(node)
    nn == "net" || error("element name wrong: $nn")
    EzXML.haskey(node, "id")   || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "type") || throw(MalformedException("$nn missing type", node))
    @assert haskey(kw, :reg)

    # Missing the page level in the pnml heirarchy causes nodes to be placed in :labels.
    # May result in undefined behavior and/or require ideosyncratic parsing.
    isempty(allchildren("page", node)) &&
         throw(MalformedException("$nn does not have any pages", node))

    # Although the petri net type definition (pntd) must be attached to the <net> element,
    # it is allowed by this package to override that value.
    pntypedef = pnmltype(node["type"])
    if isnothing(pntd)
        pntd = pntypedef
    else
        @info """
        parse_net pntd set to $pntd
                    should be $pntypedef
        """
    end

    # Create a PnmlDict with keys for possible child tags.
    # Some keys have known/required values.
    # Optional key values are nothing for single object or empty vector when multiples.
    # Keys that have pural names usually have a vector value.
    # The 'graphics' key is one exception and has a single value.
    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg], node["id"]),
                           :pages => Page[],
                           :declaration => Declaration()) #! declaration is High Level
    parse_net_2!(d, node, pntd; kw...)
    PnmlNet(pntd, d[:id], d[:pages], d[:declaration], d[:name], ObjectCommon(d), node)
end

"Specialize net parsing on pntd"
function parse_net_2! end

function parse_net_2!(d::PnmlDict, node::XMLNode, pntd::PnmlType; kw...) # Every pntd not a AbstractHLCore.
    # Go through children looking for expected tags, delegating common tags and labels.
    foreach(elements(node)) do child
        @match nodename(child) begin
            "page" => push!(d[:pages], parse_page(child, pntd; kw...))
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
end

function parse_net_2!(d::PnmlDict, node::XMLNode, pntd::AbstractHLCore; kw...)
    # Go through children looking for expected tags, delegating common tags and labels.
    foreach(elements(node)) do child
        @match nodename(child) begin
            "page" => push!(d[:pages], parse_page(child, pntd; kw...))

            # For nets and pages the <declaration> tag is optional
            # <declaration> ia a High-Level Annotation with a <structure> holding
            # zero or more <declarations>. Is complicated. You have been warned!
            # Expected XML structure:
            #  <declaration> <structure> <declarations> <namedsort id="weight" name="Weight"> ...
            "declaration"  => (d[:declaration] = parse_declaration(child, pntd; kw...))
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
end

"""
$(TYPEDSIGNATURES)
PNML requires at least one page.
"""
function parse_page(node, pntd; kw...)
    nn = nodename(node)
    nn == "page" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg], node["id"]),
                           :places => Place[],
                           :trans => Transition[],
                           :arcs => Arc[],
                           :refP => RefPlace[],
                           :refT => RefTransition[],
                           :declaration => Declaration(), #! HL
                           :pages => Page[])
    parse_page_2!(d, node, pntd; kw...)
    Page(pntd, d[:id],
        d[:places], d[:refP],
        d[:trans], d[:refT],
        d[:arcs],
        d[:declaration], d[:pages], d[:name], ObjectCommon(d))
end

""
function parse_page_2! end

function parse_page_2!(d::PnmlDict, node::XMLNode, pntd::PnmlType; kw...)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "place"       => push!(d[:places], parse_place(child, pntd; kw...))
            "transition"  => push!(d[:trans], parse_transition(child, pntd; kw...))
            "arc"         => push!(d[:arcs], parse_arc(child, pntd; kw...))
            "referencePlace"      => push!(d[:refP], parse_refPlace(child, pntd; kw...))
            "referenceTransition" => push!(d[:refT], parse_refTransition(child, pntd; kw...))
            "page"        => push!(d[:pages], parse_page(child, pntd; kw...))
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
end

function parse_page_2!(d::PnmlDict, node::XMLNode, pntd::AbstractHLCore; kw...)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "place"       => push!(d[:places], parse_place(child, pntd; kw...))
            "transition"  => push!(d[:trans], parse_transition(child, pntd; kw...))
            "arc"         => push!(d[:arcs], parse_arc(child, pntd; kw...))
            "referencePlace"      => push!(d[:refP], parse_refPlace(child, pntd; kw...))
            "referenceTransition" => push!(d[:refT], parse_refTransition(child, pntd; kw...))
            # See note above about declarations vs. declaration.
            "declaration" => (d[:declaration] = parse_declaration(child, pntd; kw...)) #! HL
            "page"        => push!(d[:pages], parse_page(child, pntd; kw...))
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(node, pntd; kw...)
    nn = nodename(node)
    nn == "place" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg], node["id"]),
                           :marking => default_marking(pntd),
                           :type => default_sort(pntd)) # Different from net's.
    parse_place_labels!(d, node, pntd; kw...)

    Place(pntd, d[:id], d[:marking], d[:type], d[:name], ObjectCommon(d))
end

"Specialize place label parsing."
function parse_place_labels! end
function parse_place_labels!(d::PnmlDict, node::XMLNode, pntd::PnmlType; kw...)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "initialMarking"   => (d[:marking] = parse_initialMarking(child, pntd; kw...))
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
end
function parse_place_labels!(d::PnmlDict, node::XMLNode, pntd::AbstractHLCore; kw...)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "hlinitialMarking" => (d[:marking] = parse_hlinitialMarking(child, pntd; kw...)) #!L
            # Here type means `sort`. Re: Many-sorted algebra.
            "type"             => (d[:type] = parse_type(child, pntd; kw...)) #! HL
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node, pntd; kw...)
    nn = nodename(node)
    nn == "transition" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :condition=>default_condition(pntd))
    parse_transition_2!(d, node, pntd; kw...)
    Transition(pntd, d[:id], d[:condition], d[:name], ObjectCommon(d))
end

"Specialize transition label parsing."
function parse_transition_2! end
function parse_transition_2!(d::PnmlDict, node::XMLNode, pntd::PnmlType; kw...)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "condition"    => (d[:condition] = parse_condition(child, pntd; kw...))
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
end

# Implements if specialization needed.
#function parse_transition_2!(d::PnmlNode, node::XMLNode, pntd::PNTD; kw...) where{PNTD<:AbstractHLCore} end

"""
    parse_arc(node::XMLNode, pntd::PnmlType; kw...) -> Arc{typeof(pntd), typeof(inscription)}

Construct an `Arc` with labels specialized for the PnmlType.
"""
function parse_arc(node, pntd; kw...)
    nn = nodename(node)
    nn == "arc" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(node, "source")
    @assert haskey(node, "target")
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :source=>Symbol(node["source"]),
                           :target=>Symbol(node["target"]),
                           :inscription=>default_inscription(pntd))
    foreach(elements(node)) do child
        parse_arc_labels!(d, child, pntd; kw...) # Dispatch on pntd
    end
    Arc(pntd, d[:id], d[:source], d[:target], d[:inscription], d[:name], ObjectCommon(d))
end

"""
Specialize arc label parsing.
"""
function parse_arc_labels! end

function parse_arc_labels!(d, node, pntd::PnmlType; kw...) # not HL
    @match nodename(node) begin
        "inscription" => (d[:inscription] = parse_inscription(node, pntd; kw...))
        _ => parse_pnml_node_common!(d, node, pntd; kw...)
    end
end

function parse_arc_labels!(d, node, pntd::AbstractHLCore; kw...)
    @match nodename(node) begin
        "hlinscription" => (d[:inscription] = parse_hlinscription(node, pntd; kw...))
        _ => parse_pnml_node_common!(d, node, pntd; kw...)
    end
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node, pntd; kw...)
    nn = nodename(node)
    nn == "referencePlace" || error("element name wrong: $nn")
    EzXML.haskey(node, "id")  || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") || throw(MalformedException("$(nn) missing ref attribute", node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :ref=>Symbol(node["ref"]))

    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
    RefPlace(pntd, d[:id], d[:ref], d[:name], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node, pntd; kw...)
    nn = nodename(node)
    nn == "referenceTransition" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") || throw(MalformedException("$(nn) missing ref attribute", node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :ref=>Symbol(node["ref"]))

    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child, pntd; kw...)
        end
    end
    RefTransition(pntd, d[:id], d[:ref], d[:name], ObjectCommon(d))
end

#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the stripped string of nodecontent.
"""
function parse_text(node, pntd; kw...)
    nn = nodename(node)
    nn == "text" || error("$nn nodename wrong")
    string(strip(nodecontent(node)))
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding text value and optional tool & GUI information.
"""
function parse_name(node, pntd; kw...)
    nn = nodename(node)
    nn == "name" || error("element nodename wrong")

    # Assumes there are no other children with this tag (like the specification says).
    textnode = firstchild("text", node)
    if isnothing(textnode)
        @warn "$(nn) missing <text> element" #TODO Make optional.
        # There are pnml files that break the rules & do not have a text element here.
        # Ex: PetriNetPlans-PNP/parallel.jl
        # Attempt to harvest content of <name> element instead of the child <text> element.
        text = string(strip(nodecontent(node)))
    else
        text = string(strip(nodecontent(textnode)))
    end

    graphicsnode = firstchild("graphics", node)
    graphics = isnothing(graphicsnode) ? nothing : parse_graphics(graphicsnode, pntd; kw..., verbose=false)

    toolspecific = allchildren("toolspecific", node)
    tools = isempty(toolspecific) ? nothing : parse_toolspecific.(toolspecific, Ref(pntd); kw..., verbose=false)

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
function parse_structure(node, pntd; kw...)
    nn = nodename(node)
    nn == "structure" || error("element name wrong: $nn")
    Structure(unclaimed_label(node, pntd; kw...), node)
end

#----------------------------------------------------------
#
# PNML annotation-label XML element parsers.
#
#----------------------------------------------------------

# Place Transition nets (PT-Nets) use only the text tag of a label for
# the meaning of marking and inscriptions.

"""
$(TYPEDSIGNATURES)
"""
function parse_initialMarking(node, pntd; kw...)
    nn = nodename(node)
    nn == "initialMarking" || error("element name wrong: $nn")

    val = if isempty(nodecontent(node))
        @warn "missing  <initialMarking> content"
        nothing
    else
       number_value(strip(nodecontent(node)))
    end

    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>val)

    foreach(elements(node)) do child
        @match nodename(child) begin
            # We extend to real numbers.
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d, child, pntd; kw...)
        end
    end
    # Treat missing value as if the <initialMarking> element was absent.
    if isnothing(d[:value])
        @warn "missing  <initialMarking> value"
        d[:value] = _evaluate(default_marking(pntd))
    end
    PTMarking(d[:value], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(node, pntd::PnmlType; kw...)
    nn = nodename(node)
    nn == "inscription" || error("element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            # Should not have a structure.
            _ => parse_pnml_label_common!(d, child, pntd; kw...)
        end
    end
    # Treat missing value as if the <inscription> element was absent.
    if isnothing(d[:value])
        @warn "missing or unparsable <inscription> value"
        d[:value] = _evaluate(default_inscription(pntd))
    end
   PTInscription(d[:value], ObjectCommon(d))
end

# High-Level Nets, includeing PT-HLPNG, are expected to use the structure child node to
# define the semantics of marking and inscriptions.
#
"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a [`Term`](@ref) in the <structure>
child. We extend the pnml standard by allowing node content to be numeric:
parsed to `Int` and `Float64`.
"""
function parse_hlinitialMarking(node, pntd::AbstractHLCore; kw...)
    nn = nodename(node)
    nn == "hlinitialMarking" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn),
                            :text=>nothing,
                            :structure=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "structure" => (d[:structure] =
                haselement(child) ? parse_term(firstelement(child), pntd; kw...) :
                default_marking(pntd)) #! sort of place
            _ => parse_pnml_label_common!(d, child, pntd; kw...)
        end
    end

    # Missing value as if the <inscription> element was absent.

    HLMarking(d[:text], d[:structure], ObjectCommon(d))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node, pntd::AbstractHLCore; kw...)
    @debug node
    nn = nodename(node)
    nn == "hlinscription" || error("element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
        # Expect <structure> to contain a single Term as a child tag.
        # Otherwise use the default inscription Term.
        "structure" => (d[:structure] =
                haselement(child) ? parse_term(firstelement(child), pntd; kw...) :
                default_inscription(pntd))
        _ => parse_pnml_label_common!(d, child, pntd; kw...)
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
that the <structure> holds.

We extend Condition by allowing <structure> to have _context_ instead of of a child element.
This content is treated as either an Integer or Float64.

A Condition should evaluate to a boolean. We defer that evaluation to a higher level.
See [`AbstractTerm`](@ref).
"""
function parse_condition(node, pntd; kw...)
    @debug node
    nn = nodename(node)
    nn == "condition" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))

    foreach(elements(node)) do child
        @match nodename(child) begin
            "structure" => (d[:structure] =
                    haselement(child) ? parse_term(firstelement(child), pntd; kw...) :
                    !isempty(nodecontent(child)) ? number_value(strip(nodecontent(child))) :
                    default_condition(pntd)())
            _ => parse_pnml_label_common!(d, child, pntd; kw...)
        end
    end
    Condition(d[:text], d[:structure], ObjectCommon(d))
end


#---------------------------------------------------------------------
#TODO Will unclaimed_node handle this?
"""
$(TYPEDSIGNATURES)

Should not often have a '<label>' tag, this will bark if one is found.
Return minimal PnmlDict holding (tag,node), to defer parsing the xml.
"""
function parse_label(node, pntd; kw...)
    nn = nodename(node)
    nn == "label" || error("element name wrong: $nn")
    @warn "parse_label '$(node !== nothing && nn)'"
    PnmlDict(:tag=>Symbol(nn), :xml=>node) # Always add xml because this is unexpected.
end
