"Alias for EzXML.Node"
const XMLNode = EzXML.Node

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

"""
Parse string into EzXML node.

$(TYPEDSIGNATURES)

See [`xmlroot`](@ref).
"""
macro xml_str(s)
    xmlroot(s)
end

"""
$(TYPEDSIGNATURES)

Parse string `s` into EzXML node.
"""
xmlroot(s::AbstractString) = EzXML.root(EzXML.parsexml(s))

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
$(TYPEDSIGNATURES)

Return vector of `el`'s immediate children with `tag`.
"""
function allchildren(node::XMLNode, tag::AbstractString; namespace::AbstractString = pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", node, ("x" => namespace,))
end

"""
$(TYPEDSIGNATURES)

Return vector of node's immediate children and decendents with `tag`.
"""
function alldecendents(node::XMLNode, tag::AbstractString; namespace::AbstractString = pnml_ns)
    EzXML.findall(".//x:$tag | .//$tag", node, ("x" => namespace,))::Vector{XMLNode}
end

function check_nodename(n::XMLNode, s::AbstractString)
    if EzXML.nodename(n) != s
        throw(ArgumentError(string("element name wrong, expected ", s,
                                   ", got ", EzXML.nodename(n))::String))
    end
    return s
end

"""
$(TYPEDSIGNATURES)
Return registered symbol from id attribute of node. See [`PnmlIDRegistry`](@ref).
"""
function register_idof!(registry::PnmlIDRegistry, node::XMLNode)
    EzXML.haskey(node, "id") || throw(PNML.MissingIDException(EzXML.nodename(node)))
    id = Symbol(@inbounds(node["id"]))
    if isregistered(idregistry[], id)
        @warn "trying to register existing id $id in registry $(objectid(idregistry[]))" idregistry[]
    end
    return register_id!(registry, id)
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
