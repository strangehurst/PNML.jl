"Alias for EzXML.Node"
const XMLNode = EzXML.Node

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

"""
Return XML namespace.
"""
function namespace end
namespace(::T) where {T<:Any} = error("namespace(::$T) method not defined")

"""
Parse xml string into EzXML node.

$(TYPEDSIGNATURES)
"""
macro xml_str(s)
    EzXML.parsexml(s).root
end

"""
$(TYPEDSIGNATURES)

Return up to 1 immediate child of element `el` that is a `tag`.
"""
function firstchild(tag, el::XMLNode, ns=pnml_ns)
    EzXML.findfirst("./x:$tag | ./$tag", el, ["x"=>ns])
end

"""
$(TYPEDSIGNATURES)

Return first matchibg child or nothing. 
"""
function getfirst(tag, el::XMLNode, ns=pnml_ns) 
    x = firstchild(tag, el, ns)
    isnothing(x) ? nothing : x
end


"""
$(TYPEDSIGNATURES)

Return vector of `el` element's immediate children with `tag`.
"""
function allchildren(tag, el, ns=pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", el, ["x"=>ns])
end

#-------------------------------------------------------------------
# Bindings for viewing tree.
AbstractTrees.children(n::EzXML.Node) = EzXML.elements(n)
AbstractTrees.printnode(io::IO, node::EzXML.Node) = print(io, getproperty(node, :name))
AbstractTrees.nodetype(::EzXML.Node) = EzXML.Node
