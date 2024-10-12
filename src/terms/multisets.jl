"""
    pnmlmultiset(basis::UserSort, x::T, multi::Int=1) -> PnmlMultiset{T}

Construct as a multiset with one element, `x`, with default multiplicity of 1.

PnmlMultiset wraps a Multisets.Multiset{T} and basis NamedSort.

Some [`Operators`](@ref)` and [`Variables`](@ref) create/use a multiset.
Thre are constants defined that must be multisets since HL markings are multisets.

multi`x is text representation of the numberof operator that produces a multiset.
"""
struct PnmlMultiset{T} #! XXX is data type not operator XXX, see Bag, pnmlmultiset()
    basis::UserSort # REFID indirection to NamedSort or ArbitrarySort
    mset::Multiset{T}
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

sortref(ms::PnmlMultiset{<:Any}) = basis(ms) # definition of basis sort
sortof(ms::PnmlMultiset{<:Any}) = sortof(basis(ms)) # definition of basis sort

_evaluate(ms::PnmlMultiset{<:Any}) = begin println("_evaluate: PnmlMultiset see Bag for operator, this is a data structure "); cardinality(ms); end #! TODO rewrite rule

#! toexpr(ms::PnmlMultiset{<:Any}) see Bag for operator, this is a data structure

# TODO forward what ops to Multiset?

"""
    basis(ms::PnmlMultiset) -> UserSort
Multiset basis sort is a UserSort that references the declaration of a NamedSort.
Which gives a name and id to a built-in Sorts, ProductSorts, or __other__ UserSorts.
MultisetSorts not allowed. Nor loops in sort references.
"""
basis(ms::PnmlMultiset{<:Any}) = ms.basis

"""
    sortelements(ms::PnmlMultiset{<:Any}) -> iterator

Iterates over elements of the basis sort. __May not be finite.__
"""
sortelements(ms::PnmlMultiset{<:Any}) = sortelements(basis(ms))


function Base.show(io::IO, t::PnmlMultiset)
    print(io, nameof(typeof(t)), "(basis=", repr(basis(t)))
    print(io, ", mset=", nameof(typeof(t.mset)), "(",)
    io = inc_indent(io)
    for (k,v) in pairs(t.mset) # Control formatting.
        println(io, repr(k), " => ", repr(v), ",")
    end
    print(io, "))") # Close BOTH parens.
end


"""
    pnmlmultiset(basis::UserSort, x, multi::Int=1 metadata=nothing)
    pnmlmultiset(basis::UserSort; metadata=nothing)

Constructs a [`PnmlMultiset`](@ref) containing a multiset and a sort from either
  - a usersort, one element and a multiplicity, default = 1, denoted "1'x",
  - or just a sort (not usersort or multisetsort), uses all sortelements(sort), each with multiplicity = 1.

Are mapping to Multisets.jl implementation:
Create empty Multiset{T}() then fill.
  If we have an element we can use `typeof(x)` to deduce T.
  If we have a basis sort definition we use `eltype(basis)` to deduce T.

Usages
  - ⟨all⟩ wants all sortelements
  - default marking, inscription want one element or zero elements (elements can be PnmlTuples)
we always find a sort to use, And use dummy elements for their `typeof`.
"""
function pnmlmultiset end

# For singletons of any multiplicity.
function pnmlmultiset(basis::UserSort, x, multi::Int=1; metadata=nothing)
    println("pnmlmultiset: ", " basis = ", repr(basis), ", x = ", repr(x), ", multi = ", repr(multi),
            (isnothing(metadata) ? "" : ", metadata = "*repr(metadata)))
    if isa(sortof(x), MultisetSort) # not usersort or namedsort, but definition
        throw(ArgumentError("Cannot be a MultisetSort: found $(sortof(x)) for $(repr(x))"))
    end
    multi >= 0 || throw(ArgumentError("multiplicity cannot be negative: found $multi"))
    #^ Where/how is absence of sort loop checked?
    #& Assert equalSorts(basis, sortof(x), eltype(basis) == typeof(x)
    M = Multiset{typeof(x)}()
    M[x] = multi
    PnmlMultiset(basis, M) #! TODO TermInterface expression LIKE Bag
end
#~ maketerm(::Type{Bag}, basis, x, multi, metadata)
# Will construct a Bag(basis, x, multi, metadata)
# basis is a literal usersort wrapping a REFID
# x and multi are expressions (will have toexpr methods). See <numberof> multiset operator.
# metadata is nothing or a TBD

# For <all> only the basis is needed.
function pnmlmultiset(basis::AbstractSort, ::Nothing, ::Nothing; metadata=nothing) #! 2024-10-05 add for <all>
    println("pnmlmultiset: basis = ", repr(basis),
            (isnothing(metadata) ? "" : ", metadata = "*repr(metadata)))
    if isa(basis, MultisetSort) # use EqualSorts?
        throw(ArgumentError("Cannot be a MultisetSort: basis = $(repr(basis))"))
    end
    #^ Where/how is absence of sort loop checked?
    M = Multiset{eltype(basis)}()
    # Only expect finite sorts here. #! assert isfinitesort(b)
    for e in sortelements(basis) # iterator over one instance of each element of the set/sort
        push!(M, e)
    end
    PnmlMultiset(basis, M)  # return object when toexpr is eval'ed (a :call) #! TermInterface
end
#~ maketerm(::Type{Bag}, basis, nothing, nothing, metadata)
# basis is a literal usersort wrapping a REFID
# x and multi are nothing
# metadata is nothing or a TBD

"""
    Bag

TermInterface expression calling pnmlmultiset(basis, x, multi) to construct
a [`PnmlMultiset`](@ref).

See [`Operator`](@ref) for another TermInterface operator.
"""
struct Bag
    basis::UserSort # Wraps a sort REFID.
    x::Any # An element of the basis sort. #! must have toexpr() method unless nothing
    multi::Any # multiplicity of x #! must have toexpr() method unless nothing
    metadata
end

# TermInterface operators are s-expressions: first is function, rest are arguments
TermInterface.maketerm(::Type{Bag}, b, x, m, metadata) = Bag(b, toexpr(x), toexpr(m), metadata)
toexpr(b::Bag) = Expr(:call, :pnmlmultiset, [ b.basis, toexpr(b.x), toexpr(b.multi), b.metadata])

# from SymUtils.toexpr: Expr(:call, toexpr(op, st), map(x->toexpr(x, st), args)...)
