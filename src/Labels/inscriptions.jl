"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc with a expression term .

`Inscription(t::PnmlExpr)()` is a functor evaluating the expression and
returns a value of the `eltype` of sort of inscription.
"""
struct Inscription{T <: PnmlExpr, N <: AbstractPnmlNet} <: HLAnnotation
    text::Maybe{String}
    term::T # expression whose output sort is the same as adjacent place's sorttype.
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    vars::Vector{Symbol}
    net::N
end

term(i::Inscription) = i.term
sortref(i::Inscription) = expr_sortref(term(i), i.net)::SortRef
sortof(i::Inscription) = sortdefinition(namedsort(i.net, sortref(i)))::PnmlMultiset #TODO other sorts

function (inscription::Inscription)(varsub::NamedTuple)
    eval(toexpr(term(inscription), varsub, inscription.net))
end

variables(inscription::Inscription) = inscription.vars

function Base.show(io::IO, inscription::Inscription)
    print(io, "Inscription(")
    show(io, text(inscription)); print(io, ", "),
    show(io, term(inscription))
    if has_graphics(inscription)
        print(io, ", ")
        show(io, graphics(inscription))
    end
    if has_tools(inscription)
        print(io, ", ")
        show(io, toolinfos(inscription));
    end
    print(io, ")")
end

# Non-high-level have a fixed, single value type for inscriptions, marks that is a Number.
# High-level use a multiset or bag over a basis or support set.
# Sometimes the basis is an infinite set. That is possible with HLPNG.
# Symmetric nets are restrictd to finite sets: enumerations, integer ranges.
# The desire to support marking & inscriptions that use Real value type introduces complications.
#
# Approaches
# - Only use Real for non-HL. The multiset implementation uses integer multiplicity.
#   Restrict the basis to ?
# - PnmlMultiset wraps a multiset and a sort. The sort and the contents of the multiset
#   must have the same type.
#
# The combination of basis and sortof is complicated.
# Terms sort and type are related. Type is very much a Julia mechanism. Like sort it is found
# in mathmatical texts that also use type.

# Julia Type is the "fixed" part.

#!============================================================================
#! inscription value_type must match adjacent place marking value_type
#! with inscription being PositiveSort and marking being NaturalSort.
#!============================================================================

value_type(::Type{Inscription}, ::PnmlType) = eltype(PositiveSort) #::Int
value_type(::Type{Inscription}, ::AbstractContinuousNet) = eltype(RealSort) #::Float64
value_type(::Type{Inscription}, ::PT_HLPNG) = eltype(DotSort)

function value_type(::Type{Inscription}, pntd::AbstractHLCore)
    @error("value_type(::Type{Inscription}, $pntd) undefined. Using DotSort.") #! XXX TODO XXX
    eltype(DotSort) #! XXX TODO XXX
end

function default(::Type{<:Inscription}, pntd::PnmlType, placetype::SortType, net::AbstractPnmlNet)
    #@info "$pntd default Inscription $placetype = NamedSortRef(:positive)"
    if refid(placetype) !== :positive
        @error("$pntd default Inscription $placetype mismatch $(repr(refid(placetype))) != :positive")
    end
    #D()&& @info "$pntd default Inscription of adjacent $placetype = NumberEx(NamedSortRef(:positive), one(Int))"
    Inscription(nothing, NumberEx(NamedSortRef(:positive), one(Int)), nothing, nothing, REFID[], net)
end

function default(::Type{<:Inscription}, pntd::AbstractContinuousNet, placetype::SortType, net::AbstractPnmlNet)
    if refid(placetype) !== :real
        @error "$pntd default Inscription $placetype mismatch $(refid(placetype)) != :real"
    end
    #D()&& @info "$pntd default Inscription of adjacent $placetype = NumberEx(NamedSortRef(:real), one(Float64))"
    Inscription(nothing, NumberEx(NamedSortRef(:real), one(Float64)), nothing, nothing, REFID[], net)
end

# See def_insc
function default(::Type{<:Inscription}, pntd::AbstractHLCore, placetype::SortType, net::AbstractPnmlNet)
    basis = sortref(placetype)::SortRef
    el = def_sort_element(placetype, net)
    #D()&& @info "$pntd default Inscription of adjacent $placetype = Bag($basis, $el, 1)"
    Inscription(nothing, Bag(basis, el, 1), nothing, nothing, REFID[], net) # non-empty singleton multiset.
end
