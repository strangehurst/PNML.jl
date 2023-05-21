# Core types and methods documented in interfaces.jl.

"Alias for union of type `T` or `Nothing`."
const Maybe{T} = Union{T, Nothing}

pid(tup::NamedTuple)::Symbol = tup.id
tag(tup::NamedTuple)::Symbol = tup.tag
labels(tup::NamedTuple) = tup.labels
xmlnode(tup::NamedTuple)::XMLNode = tup.xml

has_labels(tup::NamedTuple) = hasproperty(tup, :labels)
get_labels(tup::NamedTuple, tagvalue::Symbol) = get_labels(labels(tup), tagvalue)
has_label(tup::NamedTuple, tag::Symbol) = has_labels(tup) ? has_label(labels(tup), tag) : false
get_label(tup::NamedTuple, tagvalue::Symbol) = has_labels(tup) ? get_label(labels(tup), tagvalue) : nothing

#--------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type AbstractPnmlObject{PNTD<:PnmlType} end

function Base.getproperty(o::AbstractPnmlObject, prop_name::Symbol)
    if prop_name === :id
        return getfield(o, :id)::Symbol
    elseif prop_name === :pntd
        return getfield(o, :pntd)::PnmlType #! abstract
    elseif prop_name === :name
        return getfield(o, :name)::Maybe{Name}
    elseif prop_name === :com
        return getfield(o, :com)::ObjectCommon
    end
    return getfield(o, prop_name)
end
pid() = error("not defined")
pid(o::AbstractPnmlObject)        = o.id
has_name(o::AbstractPnmlObject)   = o.name !== nothing
name(o::AbstractPnmlObject)       = has_name(o) ? o.name.text : ""
xmlnode(o::AbstractPnmlObject)    = has_xml(o) ? o.xml : nothing

has_labels(o::AbstractPnmlObject) = has_labels(o.com)
labels(o::AbstractPnmlObject)     = labels(o.com) # Iteratable required

has_label(o::AbstractPnmlObject, tagvalue::Symbol) = has_labels(o) && has_label(labels(o), tagvalue)
get_label(o::AbstractPnmlObject, tagvalue::Symbol) = get_label(labels(o), tagvalue)

has_tools(o::AbstractPnmlObject) = has_tools(o.com)
tools(o::AbstractPnmlObject)     = tools(o.com)
#TODO has_tool, get_tool


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
used to connect [`Page`](@ref) together. Adds a `ref` field to a node.
"""
abstract type ReferenceNode{PNTD} <: AbstractPnmlNode{PNTD} end

function Base.getproperty(rn::ReferenceNode, name::Symbol)
    if name === :ref
        return getfield(rn, :ref)::Symbol
    end
    return getfield(rn, name)
end

"Return the `id` of the referenced node."
refid(r::ReferenceNode) = r.ref

#--------------------------------------------
"""
$(TYPEDEF)
Tool specific objects can be attached to
[`AbstractPnmlObject`](@ref)s and [`AbstractLabel`](@ref)s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

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

condition_type(pntd::PnmlType)       = condition_type(typeof(pntd))
condition_value_type(pntd::PnmlType) = condition_value_type(typeof(pntd))

inscription_type(pntd::PnmlType)       = inscription_type(typeof(pntd))
inscription_value_type(pntd::PnmlType) = inscription_value_type(typeof(pntd))

marking_type(pntd::PnmlType)       = marking_type(typeof(pntd))
marking_value_type(pntd::PnmlType) = marking_value_type(typeof(pntd))

sort_type(pntd::PnmlType) = sort_type(typeof(pntd))

term_value_type(pntd::PnmlType) =  term_value_type(typeof(pntd))

coordinate_type(pntd::PnmlType)       =  coordinate_type(typeof(pntd))
coordinate_value_type(pntd::PnmlType) =  coordinate_value_type(typeof(pntd))
