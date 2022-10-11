"""
Alias for union of type `T` or `nothing`.
$(TYPEDEF)
"""
const Maybe{T} = Union{T, Nothing}

"""
$(TYPEDEF)
Alias for Dict with Symbol as key.
"""
const PnmlDict = Dict{Symbol, Any}

"""
$(TYPEDEF)
Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type PnmlObject end

"""
$(TYPEDEF)
Petri Net Graph nodes are places, transitions.
"""
abstract type PnmlNode <: PnmlObject end

"""
$(TYPEDEF)
For common behavior shared by [`RefPlace`](@ref), [`RefTransition`](@ref).
"""
abstract type ReferenceNode <: PnmlNode end

"""
$(TYPEDEF)

Tool specific objects can be attached to `PnmlObject`s and `AbstractLabel`s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo


"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph object subtypes. See [`PnmlObject`](@ref).
"""
abstract type AbstractLabel end

"""
$(TYPEDEF)
Label that may be displayed.
Differs from an Attribute Label by possibly having a [`Graphics`](@ref) field.
"""
abstract type Annotation <: AbstractLabel end



"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a `PnmlDict` that is a pnml label. Use the XML tag as identifier.

Used for "unclaimed" labels that do not have, or we choose not to use, a dedicated parse method.
Claimed labels will have a type/parser defined to make use of the structure defined by the pntd 
schema. See [`Name`](@ref), the only label defined in [`PnmlCore`](@ref)
and [`HLLabel`](@ref) for similar treatment of "unclaimed" high-level labels.
"""
@auto_hash_equals struct PnmlLabel <: Annotation
    tag::Symbol
    dict::PnmlDict
    xml::XMLNode
end

PnmlLabel(node::XMLNode; kw...) = PnmlLabel(unclaimed_label(node; kw...), node)
PnmlLabel(p::Pair{Symbol,PnmlDict}, node::XMLNode; kw...) = PnmlLabel(p.first, p.second, node; kw...)
