
"Build pnml from a string."
function parse_str(str)
    doc = EzXML.parsexml(str)
    parse_doc(doc)
end

"Build pnml from a file."
function parse_file(fn)
    doc = EzXML.readxml(fn)
    parse_doc(doc)
end

""" 
Start descent from the root XML element node of `doc`.
A well formed PNML XML document has a single root node: 'pnml'.
"""
function parse_doc(doc)
    parse_pnml(root(doc))
end

"""
    parse_node(node;verbose=true)

Take a `node` and parse it by calling the method matching `node.name` from
[`tagmap`](@ref) if mapping exists, otherwise call [`attribute_elem`](@ref).
`verbose` is a boolean controlling debug logging.
"""
function parse_node(node; verbose=true)
    node === nothing && return # Make all nodes optional. #TODO: is this a good idea?
    if verbose
        parser = haskey(tagmap, node.name) ? "present" : "attribute_elem"
        @debug( "parse_node($(node.name)) -> $(parser)" *
                " attributes $(nodename.(attributes(node)))" *
                " children $(nodename.(elements(node)))")
    end
    if haskey(tagmap, node.name)
        tagmap[node.name](node)
    else
        attribute_elem(node)
    end
end 


"""
    parse_pnml(node)

Start parse from the pnml root node of the well formed XML document.
Return a a named tuple containing vector of pnml petri nets.
"""
function parse_pnml(node)
    nn = nodename(node)
    nn == "pnml" || error("parse_pnml element name wrong: $nn" )
    EzXML.hasnamespace(node) || @warn("$(nn) missing namespace: ", node)
    #TODO: Make @warn optional? Maybe can use default pnml namespace without notice.
    validate_node(node) #TODO
    nets = parse_node.(allchildren("net", node))
    (; :id=>Symbol(nn), :tag=>Symbol(nn), :nets=>nets,
     :xml=>(INCLUDEXML ? node : nothing))
end

"""
    parse_net(node)

Return a dictonary of the pnml net with keys matching their XML tag names.
"""
function parse_net(node)
    nn = nodename(node)
    nn == "net" || error("parse_net element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_type(node) || throw(MalformedException("$(nn) missing type", node))
    
    isempty(allchildren("page", node)) && @warn "net does not have any pages"
    # Missing the page level in the pnml heirarchy causes nodes to be placed in :labels.
    # May result in undefined behavior and/or require ideosyncratic parsing.

    # Create a Dict with keys for possible child tags.
    # Some keys have known/required values.
    # Optional key values are nothing for single object or empty vector when multiples
    # are allowed. Keys that have pural names usually have a vector value.
    # The 'graphics' key is an exception and has a single value.
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :type=>default_pntd_map[node["type"]],
                           :pages => [],
                           :declarations => [])
    # Go through children looking for expected tags, delegating common tags and labels..
    foreach(elements(node)) do child
        @match nodename(child) begin
            "page"         => push!(d[:pages], parse_node(child))
            # NB: There is also a tag declarations that is different for this symbol.
            "declaration"  => push!(d[:declarations], parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d 
end

"""
    parse_page(node)

PNML requires at least on page.
"""
function parse_page(node)
    nn = nodename(node)
    nn == "page" || error("parse_page element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))

    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :places=>[], :trans=>[], :arcs=>[],
                           :refP=>[], :refT=>[],
                           :declarations=>[])

    # Can XML element order be predicted?
    foreach(elements(node)) do child
        @match nodename(child) begin
            "place"       => push!(d[:places], parse_node(child))
            "transition"  => push!(d[:trans], parse_node(child))
            "arc"         => push!(d[:arcs], parse_node(child))
            "referencePlace" => push!(d[:refP], parse_node(child))
            "referenceTransition" => push!(d[:refT], parse_node(child))
            "declaration" => push!(d[:declarations], parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_place(node)
    nn = nodename(node)
    nn == "place" || error("parse_place element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id => Symbol(node["id"]),
                           :marking => nothing,
                           :type=>nothing) # This 'type' is different from the net 'type'.
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Tags initialMarking and hlinitialMarking are mutually exclusive.
            "initialMarking"   => (d[:marking] = parse_node(child))
            "hlinitialMarking" => (d[:marking] = parse_node(child))
            "type"             => (d[:type] = parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_transition(node)
    nn = nodename(node)
    nn == "transition" || error("parse_transition element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id => Symbol(node["id"]),
                           :condition=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "condition"    => (d[:condition] = parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_arc(node)
    nn = nodename(node)
    nn == "arc" || error("parse_arc element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert has_source(node)
    @assert has_target(node)
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :source=>Symbol(node["source"]),
                           :target=>Symbol(node["target"]),
                           :inscription=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Mutually exclusive tags: inscription, hlinscription
            "inscription"    => (d[:inscription] = parse_node(child))
            "hlinscription"  => (d[:inscription] = parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_refPlace(node)
    nn = nodename(node)
    nn == "referencePlace" || error("parse_refPlace element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_ref(node) || throw(MalformedException("$(nn) missing ref attribute", node))
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_refTransition(node)
    nn = nodename(node)
    nn == "referenceTransition" || error("parse_refTransition element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_ref(node) || throw(MalformedException("$(nn) missing ref attribute", node))
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

#----------------------------------------------------------

"Return the striped string of text child's nodecontent in a named tuple."
function parse_text(node)
    nn = nodename(node)
    nn == "text" || error("parse_text element name wrong")
    (; :tag=>Symbol(nn), :content=>string(strip(nodecontent(node))),)
end

"Return named tuple with pnml name text and optional tool & GUI information."
function parse_name(node)
    node === nothing && return # Pnml names are optional. #TODO: error check mode? redundant?
    nn = nodename(node)
    nn == "name" || error("parse_name element name wrong")
    # These can cause parse_node to be passed nothing.
    text     = parse_node(firstchild("text", node); verbose=false)
    graphics = parse_node(firstchild("graphics", node); verbose=false)
    ts = allchildren("toolspecific", node)
    tools = !isempty(ts) ? parse_node.(ts; verbose=false) : nothing
    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    isnothing(text) && @warn "$(nn) missing <text> element"
    
    #TODO: rename :value to :content?
    (; :tag=>Symbol(nn), :value=>isnothing(text) ? nothing : text[:content],
     :graphics=>graphics, :tools=>tools)
end

#----------------------------------------------------------
#
# structure is neither a pnml node nor a pnml annotation-label.
# Behaves like an attribute-label.
# Should be inside of an label. 
#
#----------------------------------------------------------
"""
Return dictonary including a vector of child content elements.
A pnml structure can possibly hold any well formed XML.
Structure will vary based on parent element and petri net type definition of the net.
#TODO: Specialized structure parsers are needed. 2nd pass parser?
"""
function parse_structure(node)
    nn = nodename(node)
    nn == "structure" || error("parse_structure element name wrong: $nn")
    attribute_elem(node)
end



#----------------------------------------------------------
#
# PNML label-like XML element parsers.
#
#----------------------------------------------------------

function parse_initialMarking(node)
    nn = nodename(node)
    nn == "initialMarking" || error("parse_initialMarking element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # We extend to allowing meaknings to be real numbers.
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d,child)
        end
    end
    d  
end

function parse_inscription(node)
    nn = nodename(node)
    nn == "inscription" || error("parse_inscription element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d,child)
        end
    end
    d
end

function parse_hlinitialMarking(node)
    nn = nodename(node)
    nn == "hlinitialMarking" || error("parse_initialMarking element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_label_common!(d,child)          
        end
    end
    d
end

function parse_hlinscription(node)
    @debug node
    nn = nodename(node)
    nn == "hlinscription" || error("parse_hlinscription element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
           _ => parse_pnml_label_common!(d,child)
        end
    end
    d
end
