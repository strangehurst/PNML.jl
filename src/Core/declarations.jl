"""
$(TYPEDEF)
$(TYPEDFIELDS)
Label of a net or page that holds zero or more declarations. The declarations are used
to define parts of the many-sorted algebra used by High-Level Petri Nets.
Other PNTDs may introduce non-standard uses for declarations.

# Notes
`declarations` is implemented as a collection of `Any`
We can use infrastructure implemented for HL nets to provide nonstandard extensions.
"""
struct Declaration <: Annotation
    declarations::Vector{Any} #TODO dictionary? Type parameter?
    com::ObjectCommon
    xml::Maybe{XMLNode}
end

Declaration() = Declaration(Any[], ObjectCommon(), nothing)

declarations(d::Declaration) = d.declarations
common(d::Declaration) = d.com
xmlnode(d::Declaration) = d.xml

#TODO Document/implement/test collection interface of Declaration.
Base.length(d::Declaration) = (length ∘ declarations)(d)

# Flattening pages combines declarations into the first page.
function Base.append!(l::Declaration, r::Declaration)
    append!(declarations(l), declarations(r))
    append!(common(l), common(r)) # Only merges collections.
end

function Base.empty!(d::Declaration)
    empty!(declarations(d))
    empty!(common(d))
end
