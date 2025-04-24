"""
    pnmlmultiset(basis::UserSort, x::T, multi::Int=1) -> PnmlMultiset{basis,T}

Construct as a multiset with one element, `x`, with default multiplicity of 1.

PnmlMultiset wraps a Multisets.Multiset{T} and has type parameters
B, a tuple of NamedSort REFIDs (first is the sort), and a matching sort element of type `T`.

Some [`Operators`](@ref)` and [`Variables`](@ref) create/use a multiset.
Thre are constants (and 0-arity operators) defined that must be multisets
since HL markings are multisets.

See `Bag` for expression that returns this data structure.

"multi`x" is text representation of the `<numberof>` operator that produces a multiset.
As does `<all>` operator.
"""
@auto_hash_equals struct PnmlMultiset{B,T} #! data type, not operator, see Bag, pnmlmultiset()
    #basis::UserSort # REFID indirection #^ !!!! MOVED TO TYPE DOMAIN !!!!
    mset::Multiset{T}
    function PnmlMultiset{B,T}(m::Multiset{T}) where {B,T}
        new{B,T}(m) #todo assert B and T match.
    end
end

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
    basis(ms::PnmlMultiset) -> UserSort

Multiset basis (B type parameter) is a REFID to a UserSort that references a NamedSort.
Which gives a name and id to a built-in Sorts, ProductSorts, or __other__ UserSorts.
MultisetSorts not allowed here. Nor loops in sort references.
"""
basis(::PnmlMultiset{B,T}) where {B,T} = UserSort(first(B)) # tuple(REFID) in type domain

Base.eltype(::Type{PnmlMultiset{B,T}}) where {B,T} = T

# Return empty multiset with matching basis sort, element type.
Base.zero(::PnmlMultiset{B, T}) where {B,T} = PnmlMultiset{B,T}(Multiset{T}()) #^ empty multiset

# Choose an arbitrary value (probably 0) to have multiplicity of 1.
Base.one(::Type{PnmlMultiset{B,T}}) where {B,T} = begin
    o = PnmlMultiset{B,T}(Multiset{T}(first(sortelements(B[1]))))  #^ singleton multiset
    @assert issingletonmultiset(o)
    return o
end

sortref(ms::PnmlMultiset)      = basis(ms)::UserSort # definition of basis sort
sortof(ms::PnmlMultiset)       = sortof(basis(ms)::UserSort) # definition of basis sort
"""
    sortelements(ms::PnmlMultiset) -> iterator

Iterates over elements of the basis sort. __May not be finite sort!__
"""
sortelements(ms::PnmlMultiset) = sortelements(basis(ms)::UserSort) # basis element iterator


# TODO! forward what ops to Multiset?

"""
`A+B` for PnmlMultisets is the disjoint union of enclosed multiset.
"""
function (+)(a::PnmlMultiset{B,T}, b::PnmlMultiset{B,T}) where {B,T}
    @assert basis(a) == basis(b)
    PnmlMultiset{B,T}(multiset(a) + multiset(b))
end

 """
`A-B` for PnmlMultisets is the disjoint union of enclosed multiset.
"""
function (-)(a::PnmlMultiset{B,T}, b::PnmlMultiset{B,T}) where {B,T}
    @assert basis(a) == basis(b)
    PnmlMultiset{B,T}(multiset(a) - multiset(b))
end

"""
`A*B` for PnmlMultisets is forwarded to `Multiset`.
"""
function Base.:*(a::PnmlMultiset{B,T}, b::PnmlMultiset{B,T}) where {B,T}
    @assert basis(a) == basis(b)
    PnmlMultiset{B,T}(multiset(a) * multiset(b))
end

"""
`n*B` for PnmlMultisets is the scalar multiset product.
"""
function Base.:*(n::Number, b::PnmlMultiset{B,T}) where {B,T}
    PnmlMultiset{B,T}(convert(Int, n) * multiset(b))
end

function Base.:*(b::PnmlMultiset{B,T}, n::Number) where {B,T}
    PnmlMultiset{B,T}(convert(Int, n) * multiset(b))
end

"""
`A<B` for PnmlMultisets is forwarded `Multiset`.
"""
function (<)(a::PnmlMultiset{B,T}, b::PnmlMultiset{B,T}) where {B,T}
    @assert basis(a) == basis(b)
    multiset(a) < multiset(b)
end
"""
`A>B` for PnmlMultisets is forwarded `Multiset`.
"""
function (>)(a::PnmlMultiset{B,T}, b::PnmlMultiset{B,T}) where {B,T}
    @assert basis(a) == basis(b)
    multiset(a) > multiset(b)
end
"""
`A<=B` for PnmlMultisets is forwarded `Multiset`.
"""
function (<=)(a::PnmlMultiset{B,T}, b::PnmlMultiset{B,T}) where {B,T}
    @assert basis(a) == basis(b)
    multiset(a) <= multiset(b)
end
"""
`A>=B` for PnmlMultisets is forwarded `Multiset`.
"""
function (>=)(a::PnmlMultiset{B,T}, b::PnmlMultiset{B,T}) where {B,T}
    @assert basis(a) == basis(b)
    multiset(a) >= multiset(b)
end

# function Base.show(io::IO, t::PnmlMultiset)
#     print(io, nameof(typeof(t)), "(", multiset(t), ")")
# end


"""
    pnmlmultiset(basis::UserSort, x, multi::Int=1) -> PnmlMultiset
    pnmlmultiset(basis::UserSort, x::Multisets.Multiset) -> PnmlMultiset
    pnmlmultiset(basis::UserSort) -> PnmlMultiset

Constructs a [`PnmlMultiset`](@ref) containing a multiset and a sort from either
  - a usersort, one element and a multiplicity, default = 1, denoted "1'x",
  - a usersort and `Multiset`
  - or just a sort (not usersort or multisetsort), uses all sortelements(sort), each with multiplicity = 1.

Are mapping to Multisets.jl implementation:
Create empty Multiset{T}() then fill.
  If we have an element we can use `typeof(x)` to deduce T.
  If we have a basis sort definition we use `eltype(basis)` to deduce T.

Usages
  - ⟨all⟩ wants all sortelements
  - default marking, inscription want one element or zero elements (elements can be PnmlTuples)
we always find a sort to use, And use dummy elements for their `typeof` for empty multisets.

Expect to be called from a `@matchable` `Terminterface`, thusly:
  - `eval(toexpr(Bag(basis, x, multi), variable_substitutions))`
  - `eval(toexpr(Bag(basis)), variable_substitutions))`

"""
function pnmlmultiset end

# Constructor call
function pnmlmultiset(basis::UserSort, ms::Multiset)
    PnmlMultiset{(refid(basis),), eltype(ms)}(ms)
end

# Expect `element` and `muti` subterms to have already been eval'ed to perform variable substitution.
function pnmlmultiset(basis::UserSort, element, multi::Int=1)
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
    PnmlMultiset{(refid(basis),), eltype(M)}(M)
end

# For <all> only the basis is needed.
function pnmlmultiset(basis::AbstractSort, ::Nothing, ::Nothing) #! 2024-10-05 add for <all>
    #println("pnmlmultiset: basis = ", repr(basis), ", ", repr(sortof(basis)), ", ", eltype(basis))
    if isa(basis, MultisetSort) # use EqualSorts? us::UserSort
        throw(ArgumentError("Cannot be a MultisetSort: basis = $(repr(basis))"))
    end
    #^ Where/how is absence of sort loop checked?
    #@show basis eltype(basis) #! debug
    M = Multiset{eltype(basis)}()
    # Only expect finite sorts here. #! assert isfinitesort(b)
    for e in sortelements(basis) # iterator over one instance of each element of the set/sort
        #@show M e; flush(stdout) #! debug
        push!(M, e)
    end
    PnmlMultiset{(refid(basis),), eltype(M)}(M)
end
