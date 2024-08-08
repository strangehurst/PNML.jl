
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Arbitrary sorts that can be used for constructing terms are
reserved for/supported by `HLPNG` in the pnml specification.
"""
struct ArbitrarySort{S} <: SortDeclaration
    id::Symbol # TODO NamedSort?
    name::Union{String,SubString{String}}
    body::S
end

function ArbitrarySort()
    ArbitrarySort(:arbitrarysort, "ArbitrarySort", nothing)
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

> ...arbitrary sorts and operators do not come with a definition of the sort or operation; they just introduce a new symbol without giving a definition for it.
"""
struct ArbitraryOperator{O} <: OperatorDeclaration #AbstractOperator
    declaration::Symbol
    input::Vector{UserSort} # Sorts
    output::UserSort # sort of operator
    body::O # implementation of opearator
end
