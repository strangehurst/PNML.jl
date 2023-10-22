# Core types and methods are documented in interfaces.jl.

"""
Alias for Union{`T`, `Nothing`}.
"""
const Maybe{T} = Union{T, Nothing}

#--------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type AbstractPnmlObject{PNTD<:PnmlType} end

function Base.getproperty(o::AbstractPnmlObject, prop_name::Symbol)
    prop_name === :id   && return getfield(o, :id)::Symbol
    prop_name === :pntd && return getfield(o, :pntd)::PnmlType #! abstract
    prop_name === :name && return getfield(o, :name)::Maybe{Name}

    return getfield(o, prop_name)
end

pid(o::AbstractPnmlObject)        = o.id

has_name(o::AbstractPnmlObject)   = o.name !== nothing
name(o::AbstractPnmlObject)       = has_name(o) ? o.name.text : ""

has_labels(o::AbstractPnmlObject) = true
labels(o::AbstractPnmlObject)     = o.labels

has_label(o::AbstractPnmlObject, tagvalue::Symbol) = has_label(labels(o), tagvalue)
get_label(o::AbstractPnmlObject, tagvalue::Symbol) = get_label(labels(o), tagvalue)

tools(o::AbstractPnmlObject)     = o.tools

has_graphics(o::AbstractPnmlObject) = !isnothing(o.graphics)
graphics(o::AbstractPnmlObject)     = o.graphics

#TODO has_tool, get_tool no plural


#--------------------------------------------
"""
$(TYPEDEF)
Petri Net Graph nodes are [`Place`](@ref), [`Transition`](@ref).
They are the source or target of an [`Arc`](@ref)
"""
abstract type AbstractPnmlNode{PNTD} <: AbstractPnmlObject{PNTD} end

"""
$(TYPEDEF)
For common behavior shared by [`RefPlace`](@ref), [`RefTransition`](@ref)
used to connect [`Page`](@ref) together.
"""
abstract type ReferenceNode{PNTD} <: AbstractPnmlNode{PNTD} end

function Base.getproperty(rn::ReferenceNode, name::Symbol)
    name === :ref && return getfield(rn, :ref)::Symbol
    return getfield(rn, name)
end

"Return the `id` of the referenced node."
refid(r::ReferenceNode) = r.ref

#------------------------------------------------------------------------------
# Abstract Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph objects. See [`AbstractPnmlObject`](@ref).
"""
abstract type AbstractLabel end

#--------------------------------------------
"""
$(TYPEDEF)
Tool specific objects can be attached to
[`AbstractPnmlObject`](@ref)s and [`AbstractLabel`](@ref)s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

"""
Node in a tree formed from XML. `tag`s are XML tags or attribute names.
Leaf `val` are strings.
NB: Assumes XML "content" nodes do not have child XML nodes.
"""
struct AnyXmlNode #! Needed by PnmlLabel, AnyElement
    tag::Symbol
    val::Union{Vector{AnyXmlNode}, String, SubString}
end

AnyXmlNode(x::Pair{Symbol, Vector{AnyXmlNode}}) = AnyXmlNode(x.first, x.second)

tag(axn::AnyXmlNode) = axn.tag

"""
    value(axn::AnyXmlNode) -> Union{Vector{AnyXmlNode}, String, Substring}

Return vector of children or content of the node.
"""
value(axn::AnyXmlNode) = axn.val

# AnyXmlNode Symbol, Union{Vector{AnyXmlNode}, String, SubString}
# vs.
# AnyElement Symbol, Vector{AnyXmlNode}
# also PnmlLabel, Term, Structure

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Hold well-formed XML in a Vector{[`AnyXmlNode`](@ref)}. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol # XML tag
    elements::Vector{AnyXmlNode} #TODO remove vector container
end

AnyElement(p::Pair{Symbol, Vector{AnyXmlNode}}) = AnyElement(p.first, p.second)

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements

#---------------------------------------------------------------------------
# Collect the Singleton to Type translations here.
# The part that needs to know Type details is defined elsewhere. :)
#---------------------------------------------------------------------------

pnmlnet_type(pntd::PnmlType)       = pnmlnet_type(typeof(pntd))
page_type(pntd::PnmlType)          = page_type(typeof(pntd))

place_type(pntd::PnmlType)         = place_type(typeof(pntd))
transition_type(pntd::PnmlType)    = transition_type(typeof(pntd))
arc_type(pntd::PnmlType)           = arc_type(typeof(pntd))
refplace_type(pntd::PnmlType)      = refplace_type(typeof(pntd))
reftransition_type(pntd::PnmlType) = reftransition_type(typeof(pntd))

marking_type(pntd::PnmlType)       = marking_type(typeof(pntd))
marking_value_type(pntd::PnmlType) = marking_value_type(typeof(pntd))

condition_type(pntd::PnmlType)       = condition_type(typeof(pntd))
condition_value_type(pntd::PnmlType) = condition_value_type(typeof(pntd))

inscription_type(pntd::PnmlType)       = inscription_type(typeof(pntd))
inscription_value_type(pntd::PnmlType) = inscription_value_type(typeof(pntd))

term_type(x::Any) = error("no term_type defined for $(typeof(x))")
term_type(pntd::PnmlType)       = term_type(typeof(pntd))
term_value_type(pntd::PnmlType) = term_value_type(typeof(pntd))

coordinate_type(pntd::PnmlType)       = coordinate_type(typeof(pntd))
coordinate_value_type(pntd::PnmlType) = coordinate_value_type(typeof(pntd))

rate_value_type(pntd::PnmlType) = rate_value_type(typeof(pntd))
rate_value_type(::Type{<:PnmlType}) = Float64
