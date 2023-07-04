#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------

function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd, reg)
    nn = EzXML.nodename(node)
    CONFIG.verbose && println("add label! $nn")
    if CONFIG.warn_on_unclaimed
        if haskey(tagmap, nn) && nn != "structure"
            @info "$nn is known tag being treated as unclaimed."
        end
    end
    label = PnmlLabel(unclaimed_label(node, pntd, reg), node)
    push!(v, label)
    return nothing
end

#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add [`ToolInfo`](@ref) to vector, return nothing.

The UML from the _pnml primer_ (and schemas) use <toolspecific>
as the tag name for instances of the type ToolInfo.
"""
function add_toolinfo!(v::Vector{ToolInfo}, node, pntd, reg)
    ti = parse_toolspecific(node, pntd, reg)
    push!(v,ti)
    return nothing
end

"""
$(TYPEDSIGNATURES)

Does any toolinfo attached to `d` have a matching `toolname`.
"""
function has_toolinfo end

# tools vector
function has_toolinfo(v::Vector{<:ToolInfo}, toolname)
    has_toolinfo(v, Regex(toolname))
end
function has_toolinfo(v::Vector{<:ToolInfo}, toolname, version)
    has_toolinfo(v, Regex(toolname), Regex(version))
end
function has_toolinfo(v::Vector{<:ToolInfo}, namerex::Regex, versionrex::Regex=r"^.*$")
    any(v) do tool
       !isnothing(match(namerex, tool.toolname)) &&
            !isnothing(match(versionrex, tool.version))
    end
end

"""
$(TYPEDSIGNATURES)

Parse string as a type T <: Number.
"""
function number_value(::Type{T}, s::AbstractString)::T where {T <: Number}
    x = tryparse(T, s)
    isnothing(x) && throw(ArgumentError("cannot parse '$s' as $T"))
    return x
end
