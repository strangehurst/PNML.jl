
"Alias for EzXML.Node"
const XMLNode = EzXML.Node

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

"""
Parse xml string into ExXML node.

$(TYPEDSIGNATURES)
"""
macro xml_str(s)
    EzXML.parsexml(s).root
end

"""
Return up to 1 immediate child of element `el` that is a `tag`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function firstchild(tag, el, ns=pnml_ns)
    EzXML.findfirst("./x:$tag | ./$tag", el, ["x"=>ns])
end

"""
Return vector of `el` element's immediate children with `tag`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function allchildren(tag, el, ns=pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", el, ["x"=>ns])
end

#-------------------------------------------------------------------
# Bindings for viewing tree.
AbstractTrees.children(n::EzXML.Node) = EzXML.elements(n)
AbstractTrees.printnode(io::IO, node::EzXML.Node) = print(io, getproperty(node, :name))
AbstractTrees.nodetype(::EzXML.Node) = EzXML.Node

#export XMLNode, @xml_str, pnml_ns, firstchild, allchildren


