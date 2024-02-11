"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc. See also [`HLInscription`](@ref).

# Examples

```jldoctest; setup=:(using PNML: Inscription)
julia> i = Inscription(3)
Inscription(3)

julia> i()
3
```
"""
struct Inscription{T<:Union{Int,Float64}}  <: Annotation
    value::T
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

Inscription(value::Union{Int,Float64}) = Inscription(value, nothing, nothing)

value(i::Inscription) = i.value
sortof(i::Inscription) = isa(i.value, Integer) ? IntegerSort() : RealSort() #TODO cleanup

function Base.show(io::IO, inscription::Inscription)
    print(io, "Inscription(")
    show(io, value(inscription))
    if has_graphics(inscription)
        print(io, ", ")
        show(io, graphics(inscription))
    end
    if has_tools(inscription)
        print(io, ", ")
        show(io, tools(inscription))
    end
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)
Evaluate an [`Inscription`](@ref)'s `value`.
"""
(inscription::Inscription)() = _evaluate(value(inscription))

inscription_type(::Type{T}) where {T <: PnmlType} = Inscription{inscription_value_type(T)}

inscription_value_type(::Type{<: PnmlType}) = Int
inscription_value_type(::Type{<:AbstractContinuousNet}) = Float64

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc. The <structure> element is a term in a many-sorted algebra.
The `term` field TBD.
See also [`Inscription`](@ref)

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLInscription, Term)
julia> i2 = HLInscription(Term(:value, 3))
HLInscription("", Term(:value, 3))

julia> i2()
3

julia> i3 = HLInscription("text", Term(:empty, 1))
HLInscription("text", Term(:empty, 1))

julia> i3()
1

julia> i4 = HLInscription("text", Term(:value, 3))
HLInscription("text", Term(:value, 3))

julia> i4()
3
```
"""
struct HLInscription{T<:Term} <: HLAnnotation
    text::Maybe{String}
    term::T # Content of <structure> content must be a many-sorted algebra term.
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

HLInscription(t::Term) = HLInscription(nothing, t)
HLInscription(s::Maybe{AbstractString}, t) = HLInscription(s, t, nothing, nothing)

value(i::HLInscription) = i.term

sortof(i::HLInscription) = DotSort() #! IMPLEMENT ME!

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLInscription`](@ref). Returns a value of the same sort as _TBD_.
"""
(hli::HLInscription)() = _evaluate(value(hli))

function Base.show(io::IO, inscription::HLInscription)
    print(io, "HLInscription(")
    show(io, text(inscription)); print(io, ", "),
    show(io, value(inscription))
    if has_graphics(inscription)
        print(io, ", ")
        show(io, graphics(inscription))
    end
    if has_tools(inscription)
        print(io, ", ")
        show(io, tools(inscription));
    end
    print(io, ")")
end

inscription_type(::Type{T}) where{T<:AbstractHLCore} = HLInscription{Term}
inscription_value_type(::Type{<:AbstractHLCore}) = eltype(DotSort())

"""
$(TYPEDSIGNATURES)
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(x::Any) = (throw ∘ ArgumentError)("no default inscription for $(typeof(x))")
default_inscription(::PnmlType)              = Inscription(one(Int))
default_inscription(::AbstractContinuousNet) = Inscription(one(Float64))
default_inscription(pntd::AbstractHLCore)    = HLInscription("default", default_one_term(pntd))
