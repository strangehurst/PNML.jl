"""
    pnmlmultiset(basis::SortRef, x::T, multi::Int=1) -> PnmlMultiset{T}

Construct as a multiset with one element, `x`, with default multiplicity of 1.

PnmlMultiset wraps a Multisets.Multiset{T} where `T` is the sort element type.

Some [`Operators`](@ref)` and [`Variables`](@ref) create/use a multiset.
Thre are constants (and 0-arity operators) defined that must be multisets
since HL markings are multisets.

See `Bag` for expression that returns this data structure.

"multi`x" is text representation of the `<numberof>` operator that produces a multiset.
As does `<all>` operator.
"""
@auto_hash_equals fields=mset typearg=true struct PnmlMultiset{T} #! data type
    basis_ref::SortRef # REFID indirection
    mset::Multiset{T}
    declarationdicts::DeclDict

    function PnmlMultiset{T}(b::SortRef, m::Multiset{T}, dd) where {T}
        new{T}(b, m, dd) #todo assert basis_ref and T match.
    end
end

decldict(ms::PnmlMultiset) = ms.declarationdicts

"""
    multiset(ms::PnmlMultiset) -> Multiset
Access wrapped multiset.
"""
multiset(ms::PnmlMultiset) = ms.mset

"""
    multiplicity(ms::PnmlMultiset, x) -> Integer
    multiplicity(ms::Number, x) -> Number
"""
multiplicity(ms::PnmlMultiset, x) = multiset(ms)[x]

"""
    cardinality(ms::PnmlMultiset, x) -> Integer
"""
cardinality(ms::PnmlMultiset) = length(multiset(ms))
cardinality(ms::Number) = ms

Base.length(ms::PnmlMultiset) = length(multiset(ms))
Base.keys(ms::PnmlMultiset) = keys(multiset(ms))
Base.values(ms::PnmlMultiset) = values(multiset(ms))
Base.iterate(ms::PnmlMultiset, ss) = iterate(multiset(ms), ss)
Base.iterate(ms::PnmlMultiset) = iterate(multiset(ms))

issingletonmultiset(ms::PnmlMultiset) = cardinality(ms) == 1

"""
    basis(ms::PnmlMultiset) -> SortRef

Multiset basis sort is accessed through a SortRef that holds an `REFID` index into `decldict`,
can be used to find a NamedSort.
Which gives a name and id to a built-in Sorts, ProductSorts, or __other__ UserSorts.
MultisetSorts not allowed here. Nor loops in sort references.
"""
basis(ms::PnmlMultiset) = ms.basis_ref::SortRef

Base.eltype(::Type{PnmlMultiset{T}}) where {T} = T

# Return empty multiset with matching basis sort, element type.
Base.zero(::PnmlMultiset{T}) where {T} = PnmlMultiset{T}(Multiset{T}()) #^ empty multiset

# Choose an arbitrary value (probably 0) to have multiplicity of 1.
#!function Base.one(::Type{PnmlMultiset{T}}) where {T} #^ singleton multiset
function Base.one(m::PnmlMultiset{T}) where {T} #^ singleton multiset
    o = PnmlMultiset{T}(Multiset{T}(first(sortelements(basis(m)))))
    @assert issingletonmultiset(o)
    return o
end

sortref(ms::PnmlMultiset) = basis(ms)::SortRef
sortof(ms::PnmlMultiset)  = sortof(basis(ms)) # definition of basis sort
"""
    sortelements(ms::PnmlMultiset) -> iterator

Iterates over elements of the basis sort. __May not be finite sort!__
"""
sortelements(ms::PnmlMultiset) = sortelements(basis(ms)) # basis element iterator


# TODO! forward what ops to Multiset?

"""
`A+B` for PnmlMultisets is the disjoint union of enclosed multiset.
"""
function (+)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    @assert basis(a) == basis(b)
    PnmlMultiset{T}(basis(a), multiset(a) + multiset(b), decldict(a))
end

 """
`A-B` for PnmlMultisets is the disjoint union of enclosed multiset.
"""
function (-)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    @assert basis(a) == basis(b)
    PnmlMultiset{T}(basis(a), multiset(a) - multiset(b), decldict(a))
end

"""
`A*B` for PnmlMultisets is forwarded to `Multiset`.
"""
function Base.:*(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    @assert basis(a) == basis(b)
    PnmlMultiset{T}(basis(a), multiset(a) * multiset(b), decldict(a))
end

"""
`n*B` for PnmlMultisets is the scalar multiset product.
"""
function Base.:*(n::Number, a::PnmlMultiset{T}) where {T}
    PnmlMultiset{T}(basis(a), convert(Int, n) * multiset(a), decldict(a))
end

function Base.:*(a::PnmlMultiset{T}, n::Number) where {T}
    PnmlMultiset{T}(basis(a), convert(Int, n) * multiset(a), decldict(a))
end

"""
`A<B` for PnmlMultisets is forwarded `Multiset`.
"""
function (<)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    @assert basis(a) == basis(b)
    multiset(a) < multiset(b)
end

"""
`A>B` for PnmlMultisets is forwarded `Multiset`.
"""
function (>)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    @assert basis(a) == basis(b)
    multiset(a) > multiset(b)
end
"""
`A<=B` for PnmlMultisets is forwarded `Multiset`.
"""
function (<=)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    @assert basis(a) == basis(b)
    multiset(a) <= multiset(b)
end

"""
`A>=B` for PnmlMultisets is forwarded `Multiset`.
"""
function (>=)(a::PnmlMultiset{T}, b::PnmlMultiset{T}) where {T}
    @assert basis(a) == basis(b)
    multiset(a) >= multiset(b)
end

# function Base.show(io::IO, t::PnmlMultiset)
#     print(io, nameof(typeof(t)), "(", multiset(t), ")")
# end


"""
    pnmlmultiset(basis::SortRef, x, multi::Int=1; ddict) -> PnmlMultiset
    pnmlmultiset(basis::SortRef, x::Multisets.Multiset; ddict) -> PnmlMultiset
    pnmlmultiset(basis::SortRef; ddict) -> PnmlMultiset

Constructs a [`PnmlMultiset`](@ref) containing a multiset and a sort from either
  - a sortref, one element and a multiplicity, default = 1, denoted "1'x",
  - a sortref and `Multiset`
  - or just a sortref (not a multisetsort), uses all sortelements, each with multiplicity 1.

Are mapping to Multisets.jl implementation:
Create empty Multiset{T}() then fill.
  If we have an element we can use `typeof(x)` to deduce T.
  If we have a basis sort definition we use `eltype(basis)` to deduce T.

Usages
  - ⟨all⟩ wants all sortelements
  - default marking, inscription want one element or zero elements (elements can be PnmlTuples)
we always find a sort to use, And use dummy elements for their `typeof` for empty multisets.

Expect to be called from a `@matchable` `Terminterface`, thusly:
  - `eval(toexpr(Bag(basis, x, multi, ddict), variable_substitutions))`
  - `eval(toexpr(Bag(basis), ddict), variable_substitutions))`

"""
function pnmlmultiset end

# Constructor call
function pnmlmultiset(basis::SortRef, ms::Multiset; ddict::DeclDict)
    PnmlMultiset{eltype(ms)}(basis, ms, ddict)
end

# Expect `element` and `muti` subterms to have already been eval'ed to perform variable substitution.
function pnmlmultiset(basis::SortRef, element, multi::Int=1; ddict::DeclDict)
    # NOTE: This is legal and used.
    # Seem to recall something about singleton-multisets serving as "numbers".
    # Should we test `issingletonmultiset` here?

    if isa(basis, MultisetSort) # not usersort or namedsort, but definition
        #^ Where/how is absence of sort loop checked?
        throw(ArgumentError("Cannot be a MultisetSort: found $basis for $(repr(element))"))
    end
    multi >= 0 || throw(ArgumentError("multiplicity cannot be negative: found $multi"))
    # if !(equal(sortof(basis), sortof(element)) || (typeof(element) == eltype(basis)))
    #     @warn "!equal" sortof(basis) sortof(element) typeof(element) eltype(basis)
    # end
    M = Multiset{typeof(element)}()
    M[element] = multi
    PnmlMultiset{eltype(M)}(basis, M, ddict)
end

# For <all> only the basis is needed.
function pnmlmultiset(basis::SortRef, ::Nothing, ::Nothing; ddict::DeclDict)
    if isa(basis, MultisetSortRef)
        throw(ArgumentError("Cannot have MultisetSort basis of $(repr(basis))"))
    end
    #^ Where/how is absence of sort loop checked?
    #@show basis eltype(basis) #! debug
    M = Multiset{eltype(basis, ddict)}()
    # Only expect finite sorts here. #! assert isfinitesort(b)
    sort = PNML.Parser.to_sort(basis; ddict)
    for e in sortelements(sort) # iterator over elements
        #@show M e; flush(stdout) #! debug
        push!(M, e)
    end
    PnmlMultiset{eltype(M)}(basis, M, ddict)
end
