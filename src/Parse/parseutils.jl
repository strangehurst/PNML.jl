#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------

function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd, reg)
    nn = EzXML.nodename(node)
    CONFIG.verbose && println("add label $nn")
    if CONFIG.warn_on_unclaimed
        if haskey(tagmap, nn) && nn != "structure"
            @info "$nn is known tag being treated as unclaimed."
        end
    end
    label = PnmlLabel(unparsed_tag(node, pntd))
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
    has_toolinfo(infos, toolname[, version]) -> Bool

Does any toolinfo in iteratable `infos` have a matching `toolname`, and a matching `version` (if it is provided).
`toolname` and `version` will be turned into `Regex`s to match against each `ToolInfo` in the `infos` collection.
"""
function has_toolinfo end

function has_toolinfo(infos, toolname)
    has_toolinfo(infos, Regex(toolname))
end

function has_toolinfo(infos, toolname, version)
    has_toolinfo(infos, Regex(toolname), Regex(version))
end

function has_toolinfo(infos, namerex::Regex, versionrex::Regex=r"^.*$")
    any(infos) do tool
       !isnothing(match(namerex, name(tool))) &&
        !isnothing(match(versionrex, version(tool)))
    end
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
