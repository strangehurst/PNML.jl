"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a `PnmlDict` that can be the root of an XML-tree.

Used for labels that do not have, or we choose not to use, a dedicated parse method.
Claimed labels will have a type defined to make use of the structure 
defined by the pntd schema. See [`Name`](@ref), the only label defined in pnmlcore.
"""
struct PnmlLabel <: AbstractLabel
    dict::PnmlDict
    xml::XMLNode
end

PnmlLabel(node::XMLNode; kw...) = PnmlLabel(unclaimed_label(node; kw...), node)

tag(label::PnmlLabel) = tag(label.dict)

has_xml(label::PnmlLabel) = true
xmlnode(label::PnmlLabel) = label.xml
    
    
    
struct HLLabel
    text::Maybe{String}
    #structure::Maybe{Structure}
    xml::XMLNode
end

"""
Return `true` if the label has a `text`` element.
"""
function has_text(label::HLLabel)
    haskey(label.dict, :text) 
end

"Return `text` element."
function text(label::HLLabel)
    label.dict[:text]
end

"""
Return `true` if the label has a `structure`` element.
"""
function has_structure(label::HLLabel)
    haskey(label.dict, :structure)
end

"Return `structure` element."
function structure(label::HLLabel)
    label.dict[:structure]
end

#------------------------------------------------------------------------
# Collection of generic labels
#------------------------------------------------------------------------

has_labels(x::T) where {T<: PnmlObject} = has_labels(x.com)

has_label(x, tagvalue::Symbol) = has_labels(x) ? has_Label(x.com.labels, tagvalue) : false
get_label(x, tagvalue::Symbol) = has_labels(x) ? get_label(x.com.labels, tagvalue) : nothing


"""
$(TYPEDEF)
$(TYPEDFIELDS)

Name is for display, possibly in a tool specific way.
"""
struct Name <: AbstractLabel
    text::String
    graphics::Maybe{Graphics} #TODO
    tools::Maybe{Vector{ToolInfo}}
end

Name(name::AbstractString = ""; graphics=nothing, tools=nothing) =
    Name(name, graphics, tools)

