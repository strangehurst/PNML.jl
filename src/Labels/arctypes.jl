"""
$(TYPEDEF)
$(TYPEDFIELDS)

Arc type label.
"""
@kwdef struct ArcType{T<:AbstractArcEnum} <: Annotation
    text::String = ""
    arctype::T
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
end

# ArcType(t::AbstractString, ae::AbstractArcEnum) = ArcType(t, ae, nothing, nothing)

# function ArcType(t::AbstractString, ae::AbstractArcEnum, g::Maybe{Graphics}, i::Maybe{Vector{ToolInfo}})
#     ArcType(t, ae, g, i)
# end

arctype(at::ArcType) = at.arctype
