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

"""
$(TYPEDSIGNATURES)

Return up to 1 immediate child of `el` that is a `tag`.  `ns` is the default namespace.
Invent a prefix to create an iterator of namespace prefix and URI pairs
"""
function firstchild(tag::AbstractString, node::XMLNode, ns::AbstractString = pnml_ns)
    EzXML.findfirst("./x:$tag | ./$tag", node, ("x" => ns,))
end

"""
$(TYPEDSIGNATURES)

Return vector of `el`'s immediate children with `tag`.
"""
function allchildren(tag::AbstractString, el::XMLNode, ns::AbstractString = pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", el, ("x" => ns,))
end

function check_nodename(n::XMLNode, s::AbstractString)
    if EzXML.nodename(n) != s
        throw(ArgumentError(string("element name wrong, expected ", s,
                                   ", got ", EzXML.nodename(n))::String))
    end
    return s
end
