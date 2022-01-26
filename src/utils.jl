# PNML XML utilities.

"Namespace expected for pnml XML."
const pnml_ns = "http://www.pnml.org/version-2009/grammar/pnml"

const XMLNode = EzXML.Node

"""
Utility macro for parsing xml strings into node.

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
Does object have XML, defaults to `false`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function has_xml end
has_xml(::Any) = false

# TODO Create docstring for block of predicates?
# XML predicates
function has_align             end
function has_color             end
function has_declaration       end
function has_decoration        end
function has_family            end
function has_gradient_color    end
function has_gradient_rotation end
function has_id                end
function has_image             end
function has_name              end
function has_ref               end
function has_rotation          end
function has_shape             end
function has_size              end
function has_source            end
function has_style             end
function has_target            end
function has_tool              end
function has_type              end
function has_value             end
function has_variabledecl      end
function has_refvariable       end
function has_version           end
function has_weight            end
function has_width             end
function has_x                 end
function has_xmlns             end
function has_y                 end

#-------------------------------------------------------------------
has_align(::Any)             = false
has_color(::Any)             = false
has_declaration(::Any)       = false
has_decoration(::Any)        = false
has_family(::Any)            = false
has_gradient_color(::Any)    = false
has_gradient_rotation(::Any) = false
has_id(::Any)                = false
has_image(::Any)             = false
has_name(::Any)              = false
has_ref(::Any)               = false
has_rotation(::Any)          = false
has_shape(::Any)             = false
has_size(::Any)              = false
has_source(::Any)            = false
has_style(::Any)             = false
has_target(::Any)            = false
has_tool(::Any)              = false
has_type(::Any)              = false
has_value(::Any)             = false
has_variabledecl(::Any)      = false
has_refvariable(::Any)       = false
has_version(::Any)           = false
has_weight(::Any)            = false
has_width(::Any)             = false
has_x(::Any)                 = false
has_xmlns(::Any)             = false
has_y(::Any)                 = false


#-------------------------------------------------------------------
# XML attribute predicates (traits with a boolean value).
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

#-------------------------------------------------------------------
"""
Pretty print the first `n` lines of the XML node.
If `io` is not supplied, prints to the default output stream `stdout`.
`pp` can be any pretty print method that takes (io::IO, node).

---
$(TYPEDSIGNATURES)

$(METHODLIST)
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
