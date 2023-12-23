#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------

function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd, reg)
    nn = EzXML.nodename(node)
    CONFIG.verbose && println("add label $nn")
    label = PnmlLabel(unparsed_tag(node, pntd))
    #! Extension point. user supplied parser of DictType -> Annotation. Could do conversion after/on demand.
    #! 2 collections, one for PnmlLabels other for other Annotations?
    push!(v, label)
    return label
end

#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add [`ToolInfo`](@ref) to `infos`, return nothing.

The UML from the _pnml primer_ (and schemas) use <toolspecific>
as the tag name for instances of the type ToolInfo.
"""
function add_toolinfo!(infos, node, pntd, reg)
    CONFIG.verbose && println("add toolinfo")
    push!(infos, parse_toolspecific(node, pntd, reg))
    return nothing
end


"""
    number_value(::Type{T}, s) -> T

Parse string as a type T <: Number.
"""
function number_value(::Type{T}, s::AbstractString)::T where {T <: Number}
    x = tryparse(T, s)
    isnothing(x) && throw(ArgumentError("cannot parse '$s' as $T"))
    return x
end
