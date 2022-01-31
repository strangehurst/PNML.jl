# PNML XML utilities.

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

const XMLNode = EzXML.Node

"""
Parse xml string into ExXML node.

$(TYPEDSIGNATURES)
"""
macro xml_str(s)
    EzXML.parsexml(s).root
end

"""
Parse string as a number. First try integer then float.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function number_value(s::AbstractString)
    x = tryparse(Int, s)
    x = isnothing(x) ?  tryparse(Float64, s) : x
end

"""
Return up to 1 immediate child of element `el` that is a `tag`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function firstchild(tag, el, ns=PNML.pnml_ns)
    EzXML.findfirst("./x:$tag | ./$tag", el, ["x"=>ns])
end

"""
Return vector of `el` element's immediate children with `tag`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function allchildren(tag, el, ns=PNML.pnml_ns)
    EzXML.findall("./x:$tag | ./$tag", el, ["x"=>ns])
end

#-------------------------------------------------------------------
# Predicates return a boolean.
"""
Does object have XML? Defaults to `false`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function has_xml end
has_xml(::Any) = false

# TODO Create docstring for block of predicates?
#-------------------------------------------------------------------
# XML attribute predicates (traits with a boolean value).
# There is no defined interface here. Allows changing (maybe) the implementation.
# And shorter, self documenting code.
has_align(el::EzXML.Node)       = EzXML.haskey(el, "align")
has_color(el::EzXML.Node)       = EzXML.haskey(el, "color")
has_declaration(el::EzXML.Node) = EzXML.haskey(el, "declaration") # UserSort
has_decoration(el::EzXML.Node)  = EzXML.haskey(el, "decoration")
has_family(el::EzXML.Node)      = EzXML.haskey(el, "family")
has_gradient_color(el::EzXML.Node)    = EzXML.haskey(el, "gradient-color")
has_gradient_rotation(el::EzXML.Node) = EzXML.haskey(el, "gradient-rotation")
has_id(el::EzXML.Node)          = EzXML.haskey(el, "id")
has_image(el::EzXML.Node)       = EzXML.haskey(el, "image")
has_name(el::EzXML.Node)        = EzXML.haskey(el, "name") # declaration tag has name attributes.
has_ref(el::EzXML.Node)         = EzXML.haskey(el, "ref")
has_rotation(el::EzXML.Node)    = EzXML.haskey(el, "rotation")
has_shape(el::EzXML.Node)       = EzXML.haskey(el, "shape")
has_size(el::EzXML.Node)        = EzXML.haskey(el, "size")
has_source(el::EzXML.Node)      = EzXML.haskey(el, "source")
has_style(el::EzXML.Node)       = EzXML.haskey(el, "style")
has_target(el::EzXML.Node)      = EzXML.haskey(el, "target")
has_tool(el::EzXML.Node)        = EzXML.haskey(el, "tool")
has_type(el::EzXML.Node)        = EzXML.haskey(el, "type")
has_value(el::EzXML.Node)       = EzXML.haskey(el, "value")
has_variabledecl(el::EzXML.Node) = EzXML.haskey(el, "variabledecl") # Variable
has_refvariable(el::EzXML.Node) = EzXML.haskey(el, "refvariable") # Variable
has_version(el::EzXML.Node)     = EzXML.haskey(el, "version")
has_weight(el::EzXML.Node)      = EzXML.haskey(el, "weight")
has_width(el::EzXML.Node)       = EzXML.haskey(el, "width")
has_x(el::EzXML.Node)           = EzXML.haskey(el, "x")
has_xmlns(el::EzXML.Node)       = EzXML.haskey(el, "xmlns")
has_y(el::EzXML.Node)           = EzXML.haskey(el, "y")

#-------------------------------------------------------------------
# Bindings for viewing tree.
AbstractTrees.children(n::EzXML.Node) = EzXML.elements(n)
AbstractTrees.printnode(io::IO, node::EzXML.Node) = print(io, getproperty(node, :name))
AbstractTrees.nodetype(::EzXML.Node) = EzXML.Node

