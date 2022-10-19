# pnml label
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a `PnmlDict` for an `XMLNode` that is treated as a pnml label. Use the XML tag as identifier.

Used for "unclaimed" labels that do not have, or we choose not to use, a dedicated parse method.
Claimed labels will have a type/parser defined to make use of the structure defined by the pntd 
schema. See [`Name`](@ref), the only label defined in [`PnmlCore`](@ref)
and [`HLLabel`](@ref) for similar treatment of "unclaimed" High-Level labels.
"""
@auto_hash_equals struct PnmlLabel <: Annotation
    tag::Symbol
    dict::PnmlDict
    xml::XMLNode
end

PnmlLabel(node::XMLNode; kw...) = PnmlLabel(unclaimed_label(node; kw...), node)
PnmlLabel(p::Pair{Symbol,PnmlDict}, node::XMLNode; kw...) = PnmlLabel(p.first, p.second, node; kw...)
