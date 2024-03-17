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
struct Inscription{T<:Number}  <: Annotation
    value::T
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

Inscription(value::Number) = Inscription(value, nothing, nothing)

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

inscription_value_type(::Type{<: PnmlType}) = eltype(PositiveSort)
inscription_value_type(::Type{<:AbstractContinuousNet}) = eltype(RealSort)

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc. The <structure> element is a term in a many-sorted algebra.
The `term` field TBD.
See also [`Inscription`](@ref)

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLInscription, NumberConstant, NaturalSort)
julia> i2 = HLInscription(NumberConstant(3, NaturalSort()))
HLInscription("", NumberConstant{Int64, NaturalSort}(3, NaturalSort()))

julia> i2()
3

julia> i3 = HLInscription("text", NumberConstant(1, NaturalSort()))
HLInscription("text", NumberConstant{Int64, NaturalSort}(1, NaturalSort()))

julia> i3()
1

julia> i4 = HLInscription("text", NumberConstant(3, NaturalSort()))
HLInscription("text", NumberConstant{Int64, NaturalSort}(3, NaturalSort()))

julia> i4()
3
```
"""
struct HLInscription <: HLAnnotation
    text::Maybe{String}
    term::PnmlExpr # Content of <structure> content must be a many-sorted algebra term.
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

HLInscription(t::PnmlExpr) = HLInscription(nothing, t)
HLInscription(s::Maybe{AbstractString}, t::PnmlExpr) = HLInscription(s, t, nothing, nothing)

value(i::HLInscription) = i.term

sortof(::HLInscription) = DotSort() #! IMPLEMENT ME! Deduce sort of inscription

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLInscription`](@ref). Returns a value of the `eltype` of sort of inscription.
"""
(hlinscription::HLInscription)() = _evaluate(value(hlinscription)) #! ::eltype(sortof(hlinscription))
#TODO needs to be equalsSorts not same eltype

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

inscription_type(::Type{T}) where{T<:AbstractHLCore} = HLInscription
inscription_value_type(::Type{<:AbstractHLCore}) = eltype(DotSort) #! sortof

"""
$(TYPEDSIGNATURES)
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(x::Any) = throw(ArgumentError(string("no default inscription for ", typeof(x))))
default_inscription(::PnmlType)              = Inscription(one(Int))
default_inscription(::AbstractContinuousNet) = Inscription(one(Float64)) # Not ISO Standard.
default_inscription(pntd::AbstractHLCore)    = HLInscription(nothing, default_one_term(pntd))
