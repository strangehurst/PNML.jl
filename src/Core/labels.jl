"""
$(TYPEDEF)
$(TYPEDFIELDS)

Name is for display, possibly in a tool specific way.
"""
struct Name <: AbstractLabel
    text::String
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

Name(; text::AbstractString = "", graphics=nothing, tools=nothing) =
    Name(text, graphics, tools)


xmlnode(::AbstractLabel) = nothing

"Return `true` if label has `text` field."
has_text(l::L) where {L <: AbstractLabel} = hasproperty(l, :text) && !isnothing(l.text)
"Return `text` field"
text(l::L) where {L <: AbstractLabel} = l.text
    
"Return `true` if label has a `structure` field."
has_structure(l::L) where {L <: AbstractLabel} = hasproperty(l, :structure) && !isnothing(l.structure)
"Return `structure` field."
structure(l::L) where {L <: AbstractLabel} = has_structure(l) ? l.structure : nothing
    
has_graphics(l::L) where {L <: AbstractLabel} =
        hasproperty(l, :graphics) && !isnothing(l.graphics)
graphics(l::L) where {L <: AbstractLabel} =
        has_graphics(l) ? l.graphics : nothing
    
has_tools(l::L) where {L <: AbstractLabel} = has_tools(l.com)
tools(l::L) where {L <: AbstractLabel} = tools(l.com)
    
has_labels(l::L) where {L <: AbstractLabel} = has_labels(l.com)
labels(l::L) where {L <: AbstractLabel} = labels(l.com)
    
has_label(l::L, tagvalue::Symbol)  where {L <: AbstractLabel} = 
    if has_labels(l)
        has_label(labels(l), tagvalue)
    else
        false
    end
    
tag(label::PnmlLabel) = label.tag
dict(label::PnmlLabel) = label.dict
xmlnode(label::PnmlLabel) = label.xml
    
function has_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    any(label->tag(label) === tagvalue, v)
end
    
function get_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    getfirst(l->tag(l) === tagvalue, v)
end
    
function get_labels(v::Vector{PnmlLabel}, tagvalue::Symbol)
    filter(l -> tag(l) === tagvalue, v)
end
