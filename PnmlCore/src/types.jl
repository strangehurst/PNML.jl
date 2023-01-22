# Core types and methods documented in interfaces.jl.

"Alias for union of type `T` or `Nothing`."
const Maybe{T} = Union{T, Nothing}

#--------------------------------------------
"Alias for `Dict` with `Symbol` as key."
const PnmlDict = IdDict{Symbol, Any}

pid(pdict::PnmlDict)::Symbol = pdict[:id]
tag(pdict::PnmlDict)::Symbol = pdict[:tag]
xmlnode(pdict::PnmlDict) = pdict[:xml]

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
#!tag(o::AbstractPnmlObject)        = o.tag not an Object field
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
used to connect [`Page`](@ref) together.
"""
abstract type ReferenceNode{PNTD} <: AbstractPnmlNode{PNTD} end

"Return the `id` of the referenced node."
refid(r::ReferenceNode) = r.ref

#--------------------------------------------
"""
$(TYPEDEF)
Tool specific objects can be attached to
[`AbstractPnmlObject`](@ref)s and [`AbstractLabel`](@ref)s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

#--------------------------------------------
