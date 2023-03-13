"""
$(TYPEDEF)
Terms are part of the multi-sorted algebra that is part of High-Level Petri Net
markings, inscriptions and conditions.

See also [`AbstractDeclaration`](@ref).
"""
abstract type AbstractTerm end
abstract type AbstractOperator <: AbstractTerm end
abstract type AbstractSort end

_evaluate(x::AbstractTerm) = x() # functor
_evaluate(x::AbstractSort) = x() # functor

#!
#! move to PnmlCore
#!
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
#!
#!
#!

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
    #com::ObjectCommon
    #xml::XMLNode
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
