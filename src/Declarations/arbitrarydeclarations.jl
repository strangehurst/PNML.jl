
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Arbitrary sorts that can be used for constructing terms are reserved for/supported by `HLPNG` in the pnml standard.

> ...arbitrary sorts and operators do not come with a definition of the sort or operation; they just introduce a new symbol.

Like `ArbitraryOperator`, does not have an associated algebra, not usable by `SymmetricNet.`
"""
struct ArbitrarySort <: SortDeclaration
    id::Symbol # TODO NamedSort?
    name::Union{String,SubString{String}}
    body::Symbol #! Are id and declaration redundent?
    declarationdicts::DeclDict
end

function ArbitrarySort()
    ArbitrarySort(:arbitrarysort, "ArbitrarySort", nothing)
end

function Base.show(io::IO, s::ArbitrarySort)
    print(io, nameof(typeof(s)), "(", repr(id), ", ", repr(name), ", ", repr(body), ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

> ...arbitrary sorts and operators do not come with a definition of the sort or operation; they just introduce a new symbol.

Like `ArbitrarySort`, does not have an associated algebra, not usable by `SymmetricNet.`
"""
struct ArbitraryOperator <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    declaration::Symbol #! Are id and declaration redundent?
    declarationdicts::DeclDict
end

function Base.show(io::IO, op::ArbitraryOperator)
    print(io, nameof(typeof(op)), "(", repr(id), ", ", repr(name), ", ", repr(declaration), ")")
end
