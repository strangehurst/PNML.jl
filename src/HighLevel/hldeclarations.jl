"""
$(TYPEDEF)
Terms are part of the multi-sorted algebra that is part of a High-Level Petri Net.

An abstract type in the pnml XML specification, concrete `Term`s are
found within the <structure> element of a [`HLAnnotation`](@ref) label.

Notably, a [`Term`](@ref) is not a PnmlLabel.

See also [`Declaration`](@ref), [`SortType`](@ref), [`AbstractDeclaration`](@ref).
"""
abstract type AbstractTerm end

"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra.
"""
abstract type AbstractOperator <: AbstractTerm end

"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See  [`SortType`](@ref).

NamedSort is an AbstractTerm that declares a definition using an AbstractSort.
The pnml specification sometimes uses overlapping language.
"""
abstract type AbstractSort end

_evaluate(x::AbstractTerm) = x() # functor
_evaluate(x::AbstractSort) = x() # functor

"""
$(TYPEDEF)
Declarations are the core of high-level Petri Net.
They define objects/names that are used for conditions, inscriptions, markings.
They are attached to PNML nets and pages.
"""
abstract type AbstractDeclaration <: HLAnnotation end

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

abstract type SortDeclaration <: AbstractDeclaration end
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
struct NamedSort{S} <: SortDeclaration
    id::Symbol
    name::String
    def::S # BuiltInSort, MultisetSort, ProductSort, UserSort
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
"""
struct NamedOperator{V,T} <: OperatorDeclaration
    id::Symbol
    name::String
    parameter::Vector{V}
    def::T # sort of term
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
