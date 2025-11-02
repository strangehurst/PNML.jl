"Alias for EzXML.Node"
const XMLNode = EzXML.Node

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

"""
Parse string into EzXML node.

$(TYPEDSIGNATURES)

See [`xmlnode`](@ref).
"""
macro xml_str(s)
    :(xmlnode($s))
end

"""
$(TYPEDSIGNATURES)

Parse string `s` into EzXML node.
"""
xmlnode(s::AbstractString) = EzXML.root(EzXML.parsexml(s))

#~ How expensive are these XPath queries?

# https://scrapfly.io/blog/xpath-cheatsheet/
"""
$(TYPEDSIGNATURES)

Return up to 1 immediate child of `el` that is a `tag`.  `ns` is the default namespace.
Invent a prefix to create an iterator of namespace prefix and URI pairs
"""
function firstchild(node::XMLNode, tag::AbstractString, namespace::AbstractString = pnml_ns)
    EzXML.findfirst("./x:$tag | ./$tag", node, ("x" => namespace,))
end

"""
    allchildren(node::XMLNode, tag::AbstractString) -> Vector{XMLNode}

Return vector of `el`'s immediate children with `tag`.
"""
function allchildren(node::XMLNode, tag::AbstractString, namespace::AbstractString = pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", node, ("x" => namespace,))::Vector{XMLNode}
end

"""
    alldecendents(node::XMLNode, tag::AbstractString) -> Vector{XMLNode}

Return vector of node's immediate children and decendents with `tag`.
"""
function alldecendents(node::XMLNode, tag::AbstractString, namespace::AbstractString = pnml_ns)
    EzXML.findall(".//x:$tag | .//$tag", node, ("x" => namespace,))::Vector{XMLNode}
end

function check_nodename(node::XMLNode, str::AbstractString)
    if EzXML.nodename(node) != str
        throw(ArgumentError(string("element name wrong, expected ", str,
                                   ", got ", EzXML.nodename(node))::String))
    end
    return str
end

"""
$(TYPEDSIGNATURES)
Return registered symbol from id attribute of node. See [`PnmlIDRegistry`](@ref).
"""
function register_idof!(registry::PnmlIDRegistry, node::XMLNode)
    EzXML.haskey(node, "id") || throw(PNML.MissingIDException(EzXML.nodename(node)))
    return register_id!(registry, Symbol(@inbounds(node["id"])))
end

"""
$(TYPEDSIGNATURES)
Return XML attribute value.
"""
function attribute(node::XMLNode, key::AbstractString, msg::String="attribute $key missing")
    key == "id" && error("'id' attribute not handled here")
    EzXML.haskey(node, key) || throw(PNML.MalformedException(msg))
    return @inbounds node[key]
end


"""
    unwrap_subterm(st::XMLNode) -> XMLNode, Symbol

Unwrap a `<subterm>` by returning tuple of child node and child's tag.
"""
function unwrap_subterm(st::XMLNode)
    check_nodename(st, "subterm")
    child = EzXML.firstelement(st)
    return (child, Symbol(EzXML.nodename(child)))
end
