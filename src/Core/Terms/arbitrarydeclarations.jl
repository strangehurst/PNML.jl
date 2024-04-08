
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Arbitrary sorts that can be used for constructing terms are
reserved for/supported by `HLPNG` in the pnml specification.
"""
struct ArbitrarySort <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
end

function ArbitrarySort()
    ArbitrarySort(:arbitrarysort, "ArbitrarySort")
end


"""
$(TYPEDEF)
$(TYPEDFIELDS)

> ...arbitrary sorts and operators do not come with a definition of the sort or operation; they just introduce a new symbol without giving a definition for it.
"""
struct ArbitraryOperator{I<:AbstractSort} <: OperatorDeclaration #AbstractOperator
    declaration::Symbol
    input::Vector{AbstractSort} # Sorts
    output::I # sort of operator
end
