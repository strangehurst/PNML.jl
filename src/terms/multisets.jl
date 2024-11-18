"""
    pnmlmultiset(basis::UserSort, x::T, multi::Int=1) -> PnmlMultiset{T}

Construct as a multiset with one element, `x`, with default multiplicity of 1.

PnmlMultiset wraps a Multisets.Multiset{T} and basis NamedSort.

Some [`Operators`](@ref)` and [`Variables`](@ref) create/use a multiset.
Thre are constants defined that must be multisets since HL markings are multisets.

multi`x is text representation of the numberof operator that produces a multiset.
"""
struct PnmlMultiset{T} #! data type, not operator, see Bag, pnmlmultiset()
    basis::UserSort # REFID indirection to NamedSort or ArbitrarySort
    mset::Multiset{T} # @assert eltype(basis) isa T
end

"""
    multiplicity(ms::PnmlMultiset{<:Any}, x) -> Integer
"""
multiplicity(ms::PnmlMultiset{<:Any}, x) = ms.mset[x]
cardinality(ms::PnmlMultiset{<:Any}) = length(ms.mset)
issingletonmultiset(ms::PnmlMultiset{<:Any}) = cardinality(ms) == 1

Base.eltype(::Type{PnmlMultiset{T}}) where {T} = T
Base.zero(::Type{PnmlMultiset{<:Any}}) = zero(Int) #! what meaning/use?
Base.one(::Type{PnmlMultiset{<:Any}})  = one(Int) #! what meaning/use?

sortref(ms::PnmlMultiset{<:Any}) = basis(ms)::UserSort # definition of basis sort
sortof(ms::PnmlMultiset{<:Any}) = sortof(basis(ms)) # definition of basis sort

_evaluate(ms::PnmlMultiset{<:Any}) = begin println("_evaluate: PnmlMultiset see Bag for operator, this is a data structure "); cardinality(ms); end #! TODO rewrite rule

#! toexpr(ms::PnmlMultiset{<:Any}) see Bag for operator, this is a data structure

# TODO! forward what ops to Multiset?

"""
`A+B` for PnmlMultisets is the disjoint union of enclosed multiset.
"""
function (+)(A::PnmlMultiset{T}, B::PnmlMultiset{T}) where {T}
    @assert basis(A) == basis(B)
    PnmlMultiset(basis(A), A.mset + B.mset)
end

"""
    basis(ms::PnmlMultiset) -> UserSort
Multiset basis sort is a UserSort that references the declaration of a NamedSort.
Which gives a name and id to a built-in Sorts, ProductSorts, or __other__ UserSorts.
MultisetSorts not allowed. Nor loops in sort references.
"""
basis(ms::PnmlMultiset{<:Any}) = ms.basis

"""
    sortelements(ms::PnmlMultiset{<:Any}) -> iterator

Iterates over elements of the basis sort. __May not be finite sort!__
"""
sortelements(ms::PnmlMultiset{<:Any}) = sortelements(basis(ms))


function Base.show(io::IO, t::PnmlMultiset)
    print(io, nameof(typeof(t)), "(basis=", repr(basis(t)))
    print(io, ", mset=", repr(t.mset),")")
    # nameof(typeof(t.mset)), "(",)
    # io = inc_indent(io)
    # for (k,v) in pairs(t.mset) # Control formatting.
    #     println(io, repr(k), " => v, ",")
    # end
    # print(io, "))") # Close BOTH parens.
end


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
we always find a sort to use, And use dummy elements for their `typeof` for empty mutisets.

Expect to be called from a `@matchable` `Terminterface`, thusly:
  - `eval(toexpr(Bag(basis, x, multi)))`
  - `eval(toexpr(Bag(basis)))`

"""
function pnmlmultiset end

# Constructor call
function pnmlmultiset(basis::UserSort, ms::Multiset)
    PnmlMultiset(basis, ms)
end

# For empty or singleton multiset.
function pnmlmultiset(basis::UserSort, element, multi::Int=1)
    #println("pnmlmultiset: ", repr(basis), ", ", repr(element), ", ", repr(multi))
    #! Are transitioning to call pnmlmultiset() from an expression.
    #! Expect `element` and `muti` to have been eval'ed.  So no longer a Bag.

    # `element` will be an expression. Bag
    if isa(basis, MultisetSort) # not usersort or namedsort, but definition
        throw(ArgumentError("Cannot be a MultisetSort: found $basis for $(repr(element))"))
    end
    multi >= 0 || throw(ArgumentError("multiplicity cannot be negative: found $multi"))
    #^ Where/how is absence of sort loop checked?
    # if !(equalSorts(sortof(basis), sortof(element)) || (typeof(element) == eltype(basis)))
    #     @warn "!equalSorts" sortof(basis) sortof(element) typeof(element) eltype(basis)
    # end
    M = Multiset{typeof(element)}()
    M[element] = multi
    PnmlMultiset(basis, M)
end

# For <all> only the basis is needed.
function pnmlmultiset(basis::AbstractSort, ::Nothing, ::Nothing) #! 2024-10-05 add for <all>
    #println("pnmlmultiset: basis = ", repr(basis), ", ", repr(sortof(basis)), ", ", eltype(basis))
    if isa(basis, MultisetSort) # use EqualSorts?us::UserSort
        throw(ArgumentError("Cannot be a MultisetSort: basis = $(repr(basis))"))
    end
    #^ Where/how is absence of sort loop checked?
    M = Multiset{eltype(basis)}()
    # Only expect finite sorts here. #! assert isfinitesort(b)
    for e in sortelements(basis) # iterator over one instance of each element of the set/sort
        #@show M e; flush(stdout)
        push!(M, e)
    end
    PnmlMultiset(basis, M)
end
