"""
$(TYPEDEF)
$(TYPEDFIELDS)

A places's <type> label's <structure> element holds a concrete subtype of [`AbstractSort`](@ref).
Defines the sort of a place, hence use of `sorttype`.

For high-level nets there will be a rich language of sorts using [`UserSort`](@ref)
and [`NamedSort`](@ref). For other `PnmlNet`s they may still be used internally
"""
struct SortType <: Annotation # Not limited to high-level dialects.
    text::Maybe{String} # Supposed to be for human consumption.
    sort::Base.RefValue{AbstractSort} # Content of <structure>.
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
end

SortType(t::AbstractSort) = SortType(nothing, t)
SortType(s::Maybe{AbstractString}, t::AbstractSort) = SortType(s, Ref{AbstractSort}(t), nothing, ToolInfo[])

text(t::SortType)  = isnothing(t.text) ? "" : t.text
value(t::SortType) = t.sort[]

"""
    type(::SortType) -> AbstractSort

Return type of sort object of a `Place`.
"""
type(t::SortType) = typeof(value(t)) # Look a layer deeper at referenced sort object.


function Base.show(io::IO, st::SortType)
    print(io, indent(io), "SortType(")
    show(io, text(st)); print(io, ", ")
    show(io, value(st))
    if has_graphics(st)
        print(io, ", ")
        show(io, graphics(st))
    end
    if has_tools(st)
        print(io, ", ")
        show(io, tools(st));
    end
    print(io, ")")
end


"""
$(TYPEDSIGNATURES)
Return instance of default place sort type based on `PNTD`.
"""
function default_sorttype end
default_sorttype(x::Any) = (throw ∘ ArgumentError)("no default sorttype for $(typeof(x))")
default_sorttype(pntd::PnmlType) = default_sorttype(typeof(pntd))
default_sorttype(::Type{T}) where {T<:PnmlType} =
        SortType("default", Ref{AbstractSort}(default_sort(T)()), nothing, ToolInfo[] )
