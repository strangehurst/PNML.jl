"Alias for EzXML.Node"
const XMLNode = EzXML.Node

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

"""
Parse string `s` into EzXML node.

$(TYPEDSIGNATURES)

See [`xmlroot`](@ref).
"""
macro xml_str(s)
    #! isempty(s) && throw(ArgumentError("empty XML string in macro"))
    xmlroot(s)
end

"""
Parse string `s` into EzXML node.

$(TYPEDSIGNATURES)
 """
xmlroot(s::String) = root(EzXML.parsexml(s))

"""
$(TYPEDSIGNATURES)

Return up to 1 immediate child of `el` that is a `tag`.
"""
function firstchild(tag::AbstractString, el::XMLNode, ns::String = pnml_ns)
    EzXML.findfirst("./x:$tag | ./$tag", el, ["x" => ns])
end

"""
$(TYPEDSIGNATURES)

Return first child with `tag` or nothing.
"""
function getfirst(tag::AbstractString, el::XMLNode, ns::String = pnml_ns)
    x = firstchild(tag, el, ns)
    isnothing(x) ? nothing : x
end


"""
$(TYPEDSIGNATURES)

Return vector of `el`'s immediate children with `tag`.
"""
function allchildren(tag::AbstractString, el::XMLNode, ns::String = pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", el, ["x" => ns])
end


function check_nodename(n::XMLNode, s::String)
    if EzXML.nodename(n) != s
        throw(ArgumentError(string("element name wrong, expected ", s,
                                   ", got ", EzXML.nodename(n))))
    end
    return s
end

#-------------------------------------------------------------------
# Bindings for viewing tree.
AbstractTrees.children(n::EzXML.Node) = EzXML.elements(n)
AbstractTrees.printnode(io::IO, node::EzXML.Node) = print(io, getproperty(node, :name))
AbstractTrees.nodetype(::EzXML.Node) = EzXML.Node
