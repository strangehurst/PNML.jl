"""
$(TYPEDSIGNATURES)

Take an XML `node` and parse it by calling the method matching `node.name` from
[`tagmap`](@ref) if that mapping exists, otherwise call [`attribute_elem`](@ref).
`verbose` is a boolean controlling debug logging.
"""
function parse_node(node; verbose=true, kwargs...)::Maybe{PnmlDict}
    node === nothing && return #TODO Make all nodes optional. Is this a good idea?
    if verbose
        parser = haskey(tagmap, node.name) ? "tagmap" : "attribute_elem"
        @debug( "parse_node($(node.name)) ---> $(parser)" *
                " attributes $(nodename.(attributes(node)))" *
                " children $(nodename.(elements(node)))")
    end
    if haskey(tagmap, node.name)
        tagmap[node.name](node; kwargs...)
    else
        attribute_elem(node; kwargs...)
    end
end 

"""
$(TYPEDSIGNATURES)

Start parse from the pnml root node of the well formed XML document.
Return a a named tuple containing vector of pnml petri nets.
"""
function parse_pnml(node; kwargs...)
    nn = nodename(node)
    nn == "pnml" || error("element name wrong: $nn" )
    EzXML.hasnamespace(node) || @warn("$(nn) missing namespace: ", node)
    #TODO: Make @warn optional? Maybe can use default pnml namespace without notice.
    @assert haskey(kwargs, :reg)
    # Give an id to match the rest of the IR. There can only be one pnml tag, use its name.
    PnmlDict(:id => register_id!(kwargs[:reg], nn),
             :tag => Symbol(nn),
             :nets => parse_node.(allchildren("net", node); kwargs...),
             :xml => includexml(node))
end

"""
$(TYPEDSIGNATURES)

Return a dictonary of the pnml net with keys matching their XML tag names.
"""
function parse_net(node; kwargs...)
    nn = nodename(node)
    nn == "net" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_type(node) || throw(MalformedException("$(nn) missing type", node))
    
    @assert haskey(kwargs, :reg)
    isempty(allchildren("page", node)) && @warn "net does not have any pages"
    # Missing the page level in the pnml heirarchy causes nodes to be placed in :labels.
    # May result in undefined behavior and/or require ideosyncratic parsing.
    
    # Create a PnmlDict with keys for possible child tags.
    # Some keys have known/required values.
    # Optional key values are nothing for single object or empty vector when multiples
    # are allowed. Keys that have pural names usually have a vector value.
    # The 'graphics' key is an exception and has a single value.
    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kwargs[:reg], node["id"]),
                           :type => pntd(node["type"]),
                           :pages => PnmlDict[],
                           :declarations => PnmlDict[])
    # Go through children looking for expected tags, delegating common tags and labels.
    foreach(elements(node)) do child
        @match nodename(child) begin
            "page"         => push!(d[:pages], parse_node(child; kwargs...))
            # NB: There is also a tag 'declarations' that is different from this symbol.
            "declaration"  => push!(d[:declarations], parse_node(child; kwargs...))
            _ => parse_pnml_node_common!(d, child; kwargs...)
        end
    end
    d 
end

"""
$(TYPEDSIGNATURES)

PNML requires at least one page.
"""
function parse_page(node; kwargs...)
    nn = nodename(node)
    nn == "page" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert haskey(kwargs, :reg)

    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kwargs[:reg],node["id"]),
                           :places => PnmlDict[], :trans => PnmlDict[], :arcs => PnmlDict[],
                           :refP => PnmlDict[], :refT=>PnmlDict[],
                           :declarations => PnmlDict[],
                           :pages => PnmlDict[])
    
    foreach(elements(node)) do child
        @match nodename(child) begin
            "place"       => push!(d[:places], parse_node(child; kwargs...))
            "transition"  => push!(d[:trans], parse_node(child; kwargs...))
            "arc"         => push!(d[:arcs], parse_node(child; kwargs...))
            "referencePlace" => push!(d[:refP], parse_node(child; kwargs...))
            "referenceTransition" => push!(d[:refT], parse_node(child; kwargs...))
            "declaration" => push!(d[:declarations], parse_node(child; kwargs...))
            "page"         => push!(d[:pages], parse_node(child; kwargs...))
            _ => parse_pnml_node_common!(d, child; kwargs...)
        end
    end
    d
end


"""
$(TYPEDSIGNATURES)
"""
function parse_place(node; kwargs...)
    nn = nodename(node)
    nn == "place" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert haskey(kwargs, :reg)

    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kwargs[:reg],node["id"]),
                           :marking => nothing,
                           :type => nothing) # place 'type' is different from the net 'type'.
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Tags initialMarking and hlinitialMarking are mutually exclusive.
            "initialMarking"   => (d[:marking] = parse_node(child; kwargs...))
            "hlinitialMarking" => (d[:marking] = parse_node(child; kwargs...))
            "type"             => (d[:type] = parse_node(child; kwargs...))
            _ => parse_pnml_node_common!(d, child; kwargs...)
        end
    end
    d
end

"""
$(TYPEDSIGNATURES)
"""     
function parse_transition(node; kwargs...)
    nn = nodename(node)
    nn == "transition" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert haskey(kwargs, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kwargs[:reg], node["id"]),
                           :condition=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "condition"    => (d[:condition] = parse_node(child; kwargs...))
            _ => parse_pnml_node_common!(d, child; kwargs...)
        end
    end
    d
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arc(node; kwargs...)
    nn = nodename(node)
    nn == "arc" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert has_source(node)
    @assert has_target(node)
    @assert haskey(kwargs, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kwargs[:reg], node["id"]),
                           :source=>Symbol(node["source"]),
                           :target=>Symbol(node["target"]),
                           :inscription=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Mutually exclusive tags: inscription, hlinscription
            "inscription"    => (d[:inscription] = parse_node(child; kwargs...))
            "hlinscription"  => (d[:inscription] = parse_node(child; kwargs...))
            _ => parse_pnml_node_common!(d, child; kwargs...)
        end
    end
    d
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node; kwargs...)
    nn = nodename(node)
    nn == "referencePlace" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_ref(node) || throw(MalformedException("$(nn) missing ref attribute", node))
    @assert haskey(kwargs, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kwargs[:reg], node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child; kwargs...)
        end
    end
    d
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node; kwargs...)
    nn = nodename(node)
    nn == "referenceTransition" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_ref(node) || throw(MalformedException("$(nn) missing ref attribute", node))
    @assert haskey(kwargs, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kwargs[:reg], node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d,child; kwargs...)
        end
    end
    d
end

#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

"Return the stripped string of text child's nodecontent as :content key of PnmlDict.
"""
function parse_text(node; kwargs...)
    nn = nodename(node)
    nn == "text" || error("element name wrong")
    PnmlDict(:tag=>Symbol(nn), :content=>string(strip(nodecontent(node))),)
end

"""
$(TYPEDSIGNATURES)

Return name text value and optional tool & GUI information.
"""
function parse_name(node; kwargs...)
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
    graphics = isnothing(gx) ? nothing : parse_node(gx; kwargs..., kwargs..., verbose=false)
    
    ts = allchildren("toolspecific", node)
    tools = isempty(ts) ? nothing : parse_node.(ts; kwargs..., verbose=false)
    
    PnmlDict(:tag => Symbol(nn),
             :value => value,
             :graphics => graphics,
             :tools => tools)
end

#----------------------------------------------------------
#
# structure is neither a pnml node nor a pnml annotation-label.
# Behaves like an attribute-label.
# Should be inside of an label. 
#
#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

A pnml structure node can hold any well formed XML.
Structure semantics will vary based on parent element and petri net type definition of the net.
#TODO: Specialized structure parsers are needed. 2nd pass parser?
"""
function parse_structure(node; kwargs...)
    nn = nodename(node)
    nn == "structure" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
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
function parse_initialMarking(node; kwargs...)
    nn = nodename(node)
    nn == "initialMarking" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # We extend to real numbers.
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d,child; kwargs...)
        end
    end
    d  
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(node; kwargs...)
    nn = nodename(node)
    nn == "inscription" || error("element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d,child; kwargs...)
        end
    end
    d
end

# High-Level Nets, includeing PT-HLPNG, are expected to use the structure child node to
# define the semantics of marking and inscriptions.

"""
$(TYPEDSIGNATURES)
"""
function parse_hlinitialMarking(node; kwargs...)
    nn = nodename(node)
    nn == "hlinitialMarking" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_label_common!(d,child; kwargs...)          
        end
    end
    d
end

"""
$(TYPEDSIGNATURES)
"""
function parse_hlinscription(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "hlinscription" || error("element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
           _ => parse_pnml_label_common!(d,child; kwargs...)
        end
    end
    d
end

"""
$(TYPEDSIGNATURES)

Annotation label of transition nodes. Meaning it can have text, graphics, et al.
"""
function parse_condition(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "condition" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    parse_pnml_label_common!.(Ref(d), elements(node); kwargs...)
    d
end
