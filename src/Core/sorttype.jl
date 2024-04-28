"""
$(TYPEDEF)
$(TYPEDFIELDS)

A places's <type> label's <structure> element wraps a concrete subtype of [`AbstractSort`](@ref).
Defines the sort of a place, hence use of `sorttype`.

For high-level nets there will be a rich language of sorts using [`UserSort`](@ref)
& [`NamedSort`](@ref).

For other PnmlNet's they are used internally to allow common implementations.
"""
struct SortType <: Annotation # Not limited to high-level dialects.
    text::Maybe{String} # Supposed to be for human consumption.
    #sort::T # Content of <structure>.
    # Wrap in a Ref because we do not know the type
    sort::Base.RefValue{AbstractSort} # Content of <structure>.
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

SortType(sort::AbstractSort) = SortType(nothing, sort)
SortType(s::Maybe{AbstractString}, t::AbstractSort) = SortType(s, Ref{AbstractSort}(t), nothing, nothing)

text(t::SortType)   = ifelse(isnothing(t.text), "", t.text)
value(t::SortType)  = sortof(t)
sortof(t::SortType) = t.sort[]

"""
    type(::SortType) -> AbstractSort

Return type of sort object of a `Place`.
"""
type(t::SortType) = typeof(value(t))


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
Return instance of default SortType label based on `PNTD`.
Useful for non-high-level nets that otherwise assume and hardcode `Int`.
"""
function default_sorttype end
default_sorttype(x::Any) = throw(ArgumentError("no default sorttype for $(typeof(x))"))
default_sorttype(pntd::PnmlType) =
    SortType("default", Ref{AbstractSort}(default_sort(typeof(T))()), nothing, nothing)
#SortType("default", default_sort(typeof(pntd))(), nothing, nothing)
