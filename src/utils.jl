# PNML XML utilities.

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

const XMLNode = EzXML.Node

"""
$(TYPEDSIGNATURES)

Utility macro for parsing xml strings into node.
"""
macro xml_str(s)
    EzXML.parsexml(s).root
end

"Parse string as a number. First try integer then float."
function number_value(s::AbstractString)
    x = tryparse(Int,s) 
    x = isnothing(x) ?  tryparse(Float64,s) : x
end

"""
$(TYPEDSIGNATURES)

Return up to 1 immediate child of element `el` that is a `tag`.
"""
function firstchild(tag, el, ns=PNML.pnml_ns)
    EzXML.findfirst("./x:$tag | ./$tag", el, ["x"=>ns])
end

"""
$(TYPEDSIGNATURES)

Return vector of `el` element's immediate children with `tag`.
"""
function allchildren(tag, el, ns=PNML.pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", el, ["x"=>ns])
end

#-------------------------------------------------------------------
# XML attribute predicates.
has_align(element)       = EzXML.haskey(element, "align")
has_color(element)       = EzXML.haskey(element, "color")
has_declaration(element) = EzXML.haskey(element, "declaration") # UserSort
has_decoration(element)  = EzXML.haskey(element, "decoration")
has_family(element)      = EzXML.haskey(element, "family")
has_gradient_color(element)    = EzXML.haskey(element, "gradient-color")
has_gradient_rotation(element) = EzXML.haskey(element, "gradient-rotation")
has_id(element)          = EzXML.haskey(element, "id")
has_image(element)       = EzXML.haskey(element, "image")
has_name(element)        = EzXML.haskey(element, "name") # declaration tag has name attributes.
has_ref(element)         = EzXML.haskey(element, "ref")
has_rotation(element)    = EzXML.haskey(element, "rotation")
has_shape(element)       = EzXML.haskey(element, "shape")
has_size(element)        = EzXML.haskey(element, "size")
has_source(element)      = EzXML.haskey(element, "source")
has_style(element)       = EzXML.haskey(element, "style")
has_target(element)      = EzXML.haskey(element, "target")
has_tool(element)        = EzXML.haskey(element, "tool")
has_type(element)        = EzXML.haskey(element, "type")
has_value(element)       = EzXML.haskey(element, "value")
has_variabledecl(element) = EzXML.haskey(element, "variabledecl") # Variable
has_refvariable(element) = EzXML.haskey(element, "refvariable") # Variable
has_version(element)     = EzXML.haskey(element, "version")
has_weight(element)      = EzXML.haskey(element, "weight")
has_width(element)       = EzXML.haskey(element, "width")
has_x(element)           = EzXML.haskey(element, "x")
has_xmlns(element)       = EzXML.haskey(element, "xmlns")
has_y(element)           = EzXML.haskey(element, "y")

#-------------------------------------------------------------------
# Bindings for viewing tree.
AbstractTrees.children(n::EzXML.Node) = EzXML.elements(n)
AbstractTrees.printnode(io::IO, node::EzXML.Node) = print(io, getproperty(node, :name))
AbstractTrees.nodetype(::EzXML.Node) = EzXML.Node

#-------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Pretty print the first `n` lines of the XML node.
If `io` is not supplied, prints to the default output stream `stdout`.
`pp` can be any pretty print method that takes (io::IO, node).
"""
function node_summary end
node_summary(node; n=5, pp=EzXML.prettyprint) = node_summary(stdout, node; n, pp)
function node_summary(io::IO, node; n=5, pp=EzXML.prettyprint)
    iobuf = IOBuffer()
    pp(iobuf, node)
    s = split(String(take!(iobuf)), "\n")
    head = @view s[begin:min(end,n)]
    println.(Ref(io), head)
    println(io, "...")
end
