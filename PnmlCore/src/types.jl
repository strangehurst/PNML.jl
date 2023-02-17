# Core types and methods documented in interfaces.jl.

"Alias for union of type `T` or `Nothing`."
const Maybe{T} = Union{T, Nothing}

#--------------------------------------------
"Alias for dictionary with `Symbol` as key."
const PnmlDict = IdDict{Symbol, Any}

pid(pdict::PnmlDict)::Symbol = pdict[:id]
tag(pdict::PnmlDict)::Symbol = pdict[:tag]
xmlnode(pdict::PnmlDict)::XMLNode = pdict[:xml]

has_labels(pdict::PnmlDict) = haskey(pdict, :labels)
has_label(d::PnmlDict, tag::Symbol) = has_labels(d) ? has_label(labels(d), tag) : false

labels(pdict::PnmlDict) = pdict[:labels]

get_label(d::PnmlDict, tagvalue::Symbol) = has_labels(d) ? get_label(labels(d), tagvalue) : nothing
get_labels(d::PnmlDict, tagvalue::Symbol) = get_labels(labels(d), tagvalue)


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

pid(o::AbstractPnmlObject)        = o.id
has_name(o::AbstractPnmlObject)   = o.name !== nothing
name(o::AbstractPnmlObject)       = has_name(o) ? o.name.text : ""
xmlnode(o::AbstractPnmlObject)    = has_xml(o) ? o.xml : nothing
has_labels(o::AbstractPnmlObject) = has_labels(o.com)
labels(o::AbstractPnmlObject)     = labels(o.com)

has_label(o::AbstractPnmlObject, tagvalue::Symbol) =
    if has_labels(o)
        l = labels(o)
        l !== nothing ? has_label(l, tagvalue) : false
    else
        false
    end
get_label(o::AbstractPnmlObject, tagvalue::Symbol) =
    if has_labels(o)
        l = labels(o)
        l !== nothing ? get_label(l, tagvalue) : nothing
    else
        nothing
    end

has_tools(o::AbstractPnmlObject) = has_tools(o.com) && !isnothing(tools(o.com))
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
