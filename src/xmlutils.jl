
"Alias for EzXML.Node"
const XMLNode = EzXML.Node

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

"""
Return XML namespace.
"""
function namespace end
namespace(::Any) = error("namespace method not defined")

"""
Parse xml string into ExXML node.

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
function getfirst(tag, el::XMLNode, ns=pnml_ns) 
    i = findchild(tag, el, ns)
    isnothing(i) ? nothing : i
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
