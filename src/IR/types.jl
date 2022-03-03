#types and interface methods.
"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph object subtypes. See [`PnmlObject`](@ref).
"""
abstract type AbstractLabel end

has_xml(::AbstractLabel) = false
xmlnode(::AbstractLabel) = nothing

has_text(::AbstractLabel) = false
text(::AbstractLabel) = nothing

has_structure(::AbstractLabel) = false
structure(::AbstractLabel) = nothing

"""
$(TYPEDEF)
Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type PnmlObject end

"PnmlObjects are exected to have unique pnml ids."
pid(object::PnmlObject) = object.id

"""
$(TYPEDEF)
Petri Net Graph nodes are places, transitions.
"""
abstract type PnmlNode <: PnmlObject end

has_xml(node::PnmlNode) = true
xmlnode(node::PnmlNode) = node.xml

"""
$(TYPEDEF)

Tool specific objects can be attached to `PnmlObject`s and `AbstractLabel`s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

has_xml(tool::AbstractPnmlTool) = true
xmlnode(tool::AbstractPnmlTool) = tool.xml


