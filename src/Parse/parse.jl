"""
Take an XML `node` and parse it by calling the method matching `node.name` from
[`tagmap`](@ref) if that mapping exists, otherwise call [`unclaimed_element`](@ref)
and return a [`PnmlLabel`](@ref) wrapping the PnmlDict..
`verbose` is a boolean controlling debug logging.

$(TYPEDSIGNATURES)
"""
function parse_node(node; verbose=true, kw...)
    node === nothing && return #TODO Make all nodes optional. Is this a good idea?
    if verbose
        parser = haskey(tagmap, node.name) ? "tagmap" : "unclaimed_element"
        @debug( "parse_node($(node.name)) ---> $(parser)" *
                " attributes $(nodename.(attributes(node)))" *
                " children $(nodename.(elements(node)))")
    end
    if haskey(tagmap, node.name)
        tagmap[node.name](node; kw...) # Various types returned here.
    else
        PnmlLabel(unclaimed_element(node; kw...))
    end
end

"""
Start parse from the pnml root node of the well formed XML document.
Return vector of pnml petri nets.

$(TYPEDSIGNATURES)
"""
function parse_pnml(node; kw...)
    nn = nodename(node)
    nn == "pnml" || error("element name wrong: $nn" )
    EzXML.hasnamespace(node) || @warn("$(nn) missing namespace: ", node)
    #TODO: Make @warn optional? Maybe can use default pnml namespace without notice.
    @assert haskey(kw, :reg)
    # Do not yet have a PNTD defined, so call parse_net directly.
    PnmlModel(parse_net.(allchildren("net", node); kw...), kw[:reg], includexml(node))
end

"""
Return a dictonary of the pnml net with keys matching their XML tag names.

$(TYPEDSIGNATURES)
"""
function parse_net(node; kw...)
    nn = nodename(node)
    nn == "net" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_type(node) || throw(MalformedException("$(nn) missing type", node))

    @assert haskey(kw, :reg)
    isempty(allchildren("page", node)) && @warn "net does not have any pages"

    # Missing the page level in the pnml heirarchy causes nodes to be placed in :labels.
    # May result in undefined behavior and/or require ideosyncratic parsing.

    # Create a PnmlDict with keys for possible child tags.
    # Some keys have known/required values.
    # Optional key values are nothing for single object or empty vector when multiples
    # are allowed. Keys that have pural names usually have a vector value.
    # The 'graphics' key is an exception and has a single value.
    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg], node["id"]),
                           :type => pnmltype(node["type"]),
                           :pages => Page[],
                           :declarations => Declaration[])

    pntd = d[:type] # We pass the PNTD down the parse tree.

    # Go through children looking for expected tags, delegating common tags and labels.
    foreach(elements(node)) do child
        @match nodename(child) begin
            "page"         => push!(d[:pages], parse_node(child; pntd, kw...))
            # NB: There is also a tag 'declarations' that is different from this.
            "declaration"  => push!(d[:declarations], parse_node(child; pntd, kw...))
            _ => parse_pnml_node_common!(d, child; pntd, kw...)
        end
    end
    PnmlNet(d) #IR
end

"""
PNML requires at least one page.

$(TYPEDSIGNATURES)
"""
function parse_page(node; kw...)
    nn = nodename(node)
    nn == "page" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)
    @assert haskey(kw, :pntd)

    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg],node["id"]),
                           :places => Place[],
                           :trans => Transition[],
                           :arcs => Arc[],
                           :refP => RefPlace[],
                           :refT => RefTransition[],
                           :declarations => Declaration[],
                           :pages => Page[])

    foreach(elements(node)) do child
        @match nodename(child) begin
            "place"       => push!(d[:places], parse_node(child; kw...))
            "transition"  => push!(d[:trans], parse_node(child; kw...))
            "arc"         => push!(d[:arcs], parse_node(child; kw...))
            "referencePlace" => push!(d[:refP], parse_node(child; kw...))
            "referenceTransition" => push!(d[:refT], parse_node(child; kw...))
            "declaration" => push!(d[:declarations], parse_node(child; kw...))
            "page"         => push!(d[:pages], parse_node(child; kw...))
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    Page(d, kw[:pntd]) #IR
end


"""
$(TYPEDSIGNATURES)
"""
function parse_place(node; kw...)
    nn = nodename(node)
    nn == "place" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg],node["id"]),
                           :marking => nothing,
                           :type => nothing) # place 'type' is different from the net 'type'.
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Tags initialMarking and hlinitialMarking are mutually exclusive.
            "initialMarking"   => (d[:marking] = parse_node(child; kw...))
            "hlinitialMarking" => (d[:marking] = parse_node(child; kw...))
            "type"             => (d[:type] = parse_node(child; kw...))
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    Place(d)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node; kw...)
    nn = nodename(node)
    nn == "transition" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :condition=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "condition"    => (d[:condition] = parse_node(child; kw...))
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    Transition(d)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arc(node; kw...)
    nn = nodename(node)
    nn == "arc" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert has_source(node)
    @assert has_target(node)
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :source=>Symbol(node["source"]),
                           :target=>Symbol(node["target"]),
                           :inscription=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Mutually exclusive tags: inscription, hlinscription
            "inscription"    => (d[:inscription] = parse_node(child; kw...))
            "hlinscription"  => (d[:inscription] = parse_node(child; kw...))
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    Arc(d) #IR
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node; kw...)
    nn = nodename(node)
    nn == "referencePlace" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_ref(node) || throw(MalformedException("$(nn) missing ref attribute", node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    RefPlace(d) #IR
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node; kw...)
    nn = nodename(node)
    nn == "referenceTransition" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_ref(node) || throw(MalformedException("$(nn) missing ref attribute", node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d,child; kw...)
        end
    end
    RefTransition(d) #IR
end

#----------------------------------------------------------

"""
Return the stripped string of nodecontent.

$(TYPEDSIGNATURES)
"""
function parse_text(node; kw...)
    nn = nodename(node)
    nn == "text" || error("element name wrong")
    string(strip(nodecontent(node)))
end

"""
Return [`Name`](@ref) holding text value and optional tool & GUI information.

$(TYPEDSIGNATURES)
"""
function parse_name(node; kw...)
    node === nothing && return # Pnml names are optional. #TODO: error check mode? redundant?
    nn = nodename(node)
    nn == "name" || error("element name wrong")

    # Using firstchild or allchildren can cause parse_node to be passed nothing
    # for optional or missing child nodes.

    tx = firstchild("text", node)
    if isnothing(tx)
        @warn "$(nn) missing <text> element"
        # There are pnml files that break the rules & do not have a text element here.
        # Ex: PetriNetPlans-PNP/parallel.jl
        # Attempt to harvest content of <name> element instead of the child <text> element.
        # Assumes there are no other children elements.
        value = string(strip(nodecontent(node)))
    else
        value = string(strip(nodecontent(tx)))
    end

    gx = firstchild("graphics", node)
    graphics = isnothing(gx) ? nothing : parse_node(gx; kw..., verbose=false)

    ts = allchildren("toolspecific", node)
    tools = isempty(ts) ? nothing : parse_node.(ts; kw..., verbose=false)

    Name(value; graphics, tools)
end

#----------------------------------------------------------
#
# structure is neither a pnml node nor a pnml annotation-label.
# Behaves like an attribute-label.
# Should be inside of an label.
#
#----------------------------------------------------------

"""
A pnml structure node can hold any well formed XML.
Structure semantics will vary based on parent element and petri net type definition.

$(TYPEDSIGNATURES)
"""
function parse_structure(node; kw...)
    nn = nodename(node)
    nn == "structure" || error("element name wrong: $nn")
    PnmlLabel(unclaimed_element(node; kw...)) # TODO make a structure type (tree?)
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
function parse_initialMarking(node; kw...)
    nn = nodename(node)
    nn == "initialMarking" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # We extend to real numbers.
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d,child; kw...)
        end
    end
    PTMarking(d)  #IR
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(node; kw...)
    nn = nodename(node)
    nn == "inscription" || error("element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d,child; kw...)
        end
    end
    PTInscription(d) #IR
end

# High-Level Nets, includeing PT-HLPNG, are expected to use the structure child node to
# define the semantics of marking and inscriptions.

"""
$(TYPEDSIGNATURES)
"""
function parse_hlinitialMarking(node; kw...)
    nn = nodename(node)
    nn == "hlinitialMarking" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_label_common!(d,child; kw...)
        end
    end
    HLMarking(d) #IR
end

"""
$(TYPEDSIGNATURES)
"""
function parse_hlinscription(node; kw...)
    @debug node
    nn = nodename(node)
    nn == "hlinscription" || error("element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
           _ => parse_pnml_label_common!(d,child; kw...)
        end
    end
    HLInscription(d) #IR
end

"""
$(TYPEDSIGNATURES)

Annotation label of transition nodes.
"""
function parse_condition(node; kw...)
    @debug node
    nn = nodename(node)
    nn == "condition" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    parse_pnml_label_common!.(Ref(d), elements(node); kw...)
    Condition(d) #IR
end

#---------------------------------------------------------------------
#TODO Will unclaimed_node handel this?
"""
Should not often have a '<label>' tag, this will bark if one is found.
Return minimal PnmlDict holding (tag,node), to defer parsing the xml.

$(TYPEDSIGNATURES)
"""
function parse_label(node; kw...)
    nn = nodename(node)
    nn == "label" || error("element name wrong: $nn")
    @warn "parse_label '$(node !== nothing && nn)'"
    PnmlDict(:tag=>Symbol(nn), :xml=>node) # Always add xml because this is unexpected.
end
