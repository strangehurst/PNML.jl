"""
    pnmlmultiset(x::T, basis::NamedSort, multi::Integer=1) -> PnmlMultiset{T}

Construct as a multiset with one element, `x`, with default multiplicity of 1.

PnmlMultiset wraps a Multisets.Multiset{T} and basis NamedSort.

Some [`Operators`](@ref)` and [`Variables`](@ref) create/use a multiset.
Thre are constants defined that must be multisets since HL markings are multisets.

multi`x
"""
struct PnmlMultiset{T} #! <: AbstractOperator  XXX is data type not operator XXX
    basis::UserSort # indirection to NamedSort or ArbitrarySort
    mset::Multiset{T}
end

Base.eltype(::Type{PnmlMultiset{T}}) where {T} = T
Base.zero(::Type{PnmlMultiset{<:Any}}) = zero(Int) #! what meaning/use?
Base.one(::Type{PnmlMultiset{<:Any}})  = one(Int) #! what meaning/use?

sortof(ms::PnmlMultiset{<:Any}) = sortof(basis(ms)) # Dereferences the UserSort

function Base.show(io::IO, t::PnmlMultiset)
    print(io, nameof(typeof(t)), "(basis=", repr(basis(t)))
    print(io, ", mset=", nameof(typeof(t.mset)), "(",)
    io = inc_indent(io)
    for (k,v) in pairs(t.mset)
        println(io, repr(k), " => ", repr(v), ",")
    end
    print(io, "))") # Close BOTH parens.
end


"""
    pnmlmultiset(x, basis::NamedSort, multi::Integer=1)

Constructs a [`PnmlMultiset`](@ref)` containing multiset "1'x" and a sort.

Any `x` that supports `sortof(x)`
"""
function pnmlmultiset(x, basis::UserSort, multi::Integer=1)
    if isa(sortof(x), MultisetSort)
        throw(ArgumentError("sortof(x) cannot be a MultisetSort: found $(sortof(x))"))
    end
    multi >= 0 || throw(ArgumentError("multiplicity cannot be negative: found $multi"))
    #^ Where/how is absence of sort loop checked?

    println("pnmlmultiset: "); @show x basis multi
    # @show typeof(x)
    # @show sortof(x)
    # @show typeof(sortof(x))
    # @show typeof(basis)
    # @show sortof(basis)
    M = Multiset{typeof(x)}()
    #@show typeof(M) eltype(M)
    @show M[x] = multi #
    #@warn typeof(M) #repr(M)
    #@warn typeof(basis) repr(basis)
    #@warn collect(elements(basis))
    PnmlMultiset(basis, M)
end

multiplicity(ms::PnmlMultiset{<:Any}, x) = ms.mset[x]
issingletonmultiset(ms::PnmlMultiset{<:Any}) = length(ms.mset) == 1
cardinality(ms::PnmlMultiset{<:Any}) = length(ms.mset)

# TODO forward what ops to Multiset?
# TODO alter Multiset: union, add element, erase element, change multiplicity?

"""
    basis(ms::PnmlMultiset) -> UserSort
Multiset basis sort is a UserSort that references the declaration of a NamedSort.
Which gives a name and id to a built-in Sorts, ProductSorts, or __other__ UserSorts.
MultisetSorts not allowed. Nor loops in sort references.
"""
basis(ms::PnmlMultiset{<:Any}) = ms.basis

sortelements(ms::PnmlMultiset{<:Any}) = sortelements(basis(ms)) #! iterator

_evaluate(ms::PnmlMultiset{<:Any}) = cardinality(ms)
