# Core types and methods documented in interfaces.jl.

"""
Alias for union of type `T` or `nothing`.
$(TYPEDEF)
"""
const Maybe{T} = Union{T, Nothing}

#--------------------------------------------
"""
$(TYPEDEF)
Alias for Dict with Symbol as key.
"""
const PnmlDict = Dict{Symbol, Any}

pid(pdict::PnmlDict)::Symbol = pdict[:id]
tag(pdict::PnmlDict)::Symbol = pdict[:tag]
xmlnode(pdict::PnmlDict) = pdict[:xml]

has_labels(pdict::PnmlDict) = haskey(pdict, :labels)
has_label(d::PnmlDict, tag::Symbol) = has_labels(d) ? has_label(labels(d), tag) : false

labels(pdict::PnmlDict) = pdict[:labels]

get_label(d::PnmlDict, tagvalue::Symbol) = has_labels(d) ? get_label(labels(d), tagvalue) : nothing
get_labels(d::PnmlDict, tagvalue::Symbol) = get_labels(labels(d), tagvalue)

#--------------------------------------------
"""
$(TYPEDEF)

Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type PnmlObject{PNTD<:PnmlType} end

pid(o::PnmlObject)        = o.id
tag(o::PnmlObject)        = o.tag
has_name(o::PnmlObject)   = o.name !== nothing
name(o::PnmlObject)       = has_name(o) ? o.name.text : ""
xmlnode(o::PnmlObject)    = has_xml(o) ? o.xml : nothing
has_labels(o::PnmlObject) = has_labels(o.com)
labels(o::PnmlObject)     = labels(o.com)

has_label(o::PnmlObject, tagvalue::Symbol) =
    if has_labels(o)
        l = labels(o)
        l !== nothing ? has_label(l, tagvalue) : false
    else
        false
    end
get_label(o::PnmlObject, tagvalue::Symbol) =
    if has_labels(o)
        l = labels(o)
        l !== nothing ? get_label(l, tagvalue) : nothing
    else
        nothing
    end

has_tools(o::PnmlObject) = has_tools(o.com) && !isnothing(tools(o.com))
tools(o::PnmlObject)     = tools(o.com)
#TODO has_tool, get_tool


#--------------------------------------------
"""
$(TYPEDEF)
Petri Net Graph nodes are [`Place`](@ref), [`Transition`](@ref).
They are the source or target of an [`Arc`](@ref)
"""
abstract type PnmlNode{PNTD} <: PnmlObject{PNTD} end

"""
$(TYPEDEF)
For common behavior shared by [`RefPlace`](@ref), [`RefTransition`](@ref)
used to connect [`Page`](@ref) together.
"""
abstract type ReferenceNode{PNTD} <: PnmlNode{PNTD} end

"Return the `id` of the referenced node."
refid(r::ReferenceNode) = r.ref

#--------------------------------------------
"""
$(TYPEDEF)

Tool specific objects can be attached to
[`PnmlObject`](@ref)s and [`AbstractLabel`](@ref)s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

#--------------------------------------------
