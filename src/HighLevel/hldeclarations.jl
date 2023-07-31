"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra.
"""
abstract type AbstractOperator <: AbstractTerm end

"""
$(TYPEDEF)
Declarations are the core of high-level Petri Net.
They define objects/names that are used for conditions, inscriptions, markings.
They are attached to PNML nets and pages.
"""
abstract type AbstractDeclaration <: AbstractLabel end

pid(decl::AbstractDeclaration) = decl.id
name(decl::AbstractDeclaration) = decl.name

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct UnknownDeclaration  <: AbstractDeclaration
    id::Symbol
    name::String
    nodename::String
    content::Vector{Any} #! Vector{AnyElement}
end

"""
$(TYPEDEF)

See [`NamedSort`](@ref) and [`ArbitrarySort`] as concrete subtypes.
"""
abstract type SortDeclaration <: AbstractDeclaration end
"""
$(TYPEDEF)
"""
abstract type OperatorDeclaration <: AbstractDeclaration end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct VariableDeclaration{S}  <: AbstractDeclaration
    id::Symbol
    name::String
    sort::S
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedSort{S<:Union{AbstractSort,AnyElement}} <: SortDeclaration
    id::Symbol
    name::String
    def::S # ArbitrarySort, MultisetSort, ProductSort, UserSort
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User-declared sort.
"""
struct Partition{S,PE} <: SortDeclaration
    id::Symbol
    name::String
    def::S # Refers to a NamedSort
    element::PE # 0 or more PartitionElements.
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Arbitrary sorts that can be used for constructing terms are
reserved for/supported by `HLPNG` in the pnml specification.
"""
struct ArbitrarySort <: SortDeclaration
    id::Symbol
    name::String
end

function ArbitrarySort()
    ArbitrarySort(:arbitrarysort, "ArbitrarySort")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedOperator{V,T} <: OperatorDeclaration
    id::Symbol
    name::String
    parameter::Vector{V}
    def::T # opearator or variable term (with associated sort)
end


"""
$(TYPEDEF)
$(TYPEDFIELDS)

Example input: <variable refvariable="varx"/>
"""
struct Variable <: AbstractTerm
    variableDecl::Symbol
end

#TODO Define something for these. They are not really traits.
struct BuiltInOperator <: AbstractOperator end
struct BuiltInConst <: AbstractOperator end
struct MultiSetOperator <: AbstractOperator end
struct PnmlTuple <: AbstractOperator end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct UserOperator <: AbstractOperator
    "Identity of operators's declaration."
    declaration::Symbol #
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct ArbitraryOperator{I<:AbstractSort} <: AbstractOperator
    "Identity of operators's declaration."
    declaration::Symbol
    input::I
    output::Vector{AbstractSort} # Sorts
end
