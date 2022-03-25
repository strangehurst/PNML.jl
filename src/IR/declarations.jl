abstract type AbstractTerm end
abstract type AbstractOperator <: AbstractTerm end
abstract type AbstractSort end

"""
Declarations are the core of high-level Petri Net.
They define objects/names that are used for conditions, inscriptions, markings.
They are attached to PNML nets and pages.

$(TYPEDEF)

"""
abstract type AbstractDeclaration <: HLAnnotation end

pid(decl::AbstractDeclaration) = decl.id
name(decl::AbstractDeclaration) = decl.name


abstract type SortDeclaration <: AbstractDeclaration end
abstract type OperatorDeclaration <: AbstractDeclaration end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct VariableDeclaration{S<:AbstractSort}  <: AbstractDeclaration
    id::Symbol
    name::String
    sort::S
    com::ObjectCommon
    xml::XMLNode
end

VariableDeclaration(pdict::PnmlDict, xml::XMLNode) =
    VariableDeclaration(PnmlLabel(pdict, xml), ObjectCommon(pdict), xml)

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedSort{S<:AbstractSort} <: SortDeclaration
    id::Symbol
    name::String
    def::S #Union{BuiltInSort,MultisetSort,ProductSort,UserSort}
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedOperator <: OperatorDeclaration
    id::Symbol
    name::String
    parameter::Vector{VariableDeclaration}
    def::Term
    com::ObjectCommon
    xml::XMLNode
end

NamedOperator(pdict::PnmlDict, xml::XMLNode) =
    NamedOperator(PnmlLabel(pdict, xml), ObjectCommon(pdict), xml)

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Example input: <variable refvariable="varx"/>
"""
struct Variable <: AbstractTerm
    variableDecl::VariableDeclaration
end

struct BuiltInOperator <: AbstractOperator end
struct BuiltInConst <: AbstractOperator end
struct MultiSetOperator <: AbstractOperator end
struct PnmlTuple <: AbstractOperator end

"""
$(TYPEDSIGNATURES)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.

From the 'primer': built-in sorts of Symmetric Nets are the following:
  Booleans, range of integers, finite enumerations, cyclic enumerations and dots
"""
struct BuiltInSort <: AbstractSort
    dict::AnyElement
end

"""
$(TYPEDSIGNATURES)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
"""
struct MultisetSort <: AbstractSort
    dict::AnyElement
end

"""
$(TYPEDSIGNATURES)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
"""
struct ProductSort <: AbstractSort
    dict::AnyElement
end

"""
$(TYPEDSIGNATURES)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
"""
struct UserSort <: AbstractSort
    dict::AnyElement
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct UserOperator <: AbstractOperator
    declaration::Symbol # varialble, operator, or sort declaration id
end

"""
Label of a net or place that holds zero or more [`AbstractDeclaration`].

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Declaration <: HLAnnotation
    declarations::Vector{AbstractDeclaration}
    com::ObjectCommon
    #TODO attach XML node?
end

Declaration(pdict::PnmlDict) = Declaration(pdict[:structure], ObjectCommon(pdict))
Declaration() = Declaration(Vector{AbstractDeclaration}[], ObjectCommon())

convert(::Type{Declaration}, nothing::Nothing) = Declaration()

declarations(d::Declaration) = d.declarations
Base.length(d::Declaration) = length(declarations(d))

#TODO make for all annotation?
function Base.append!(l::Declaration, r::Declaration)
    append!(declarations(l), declarations(r))
    append!(l.com, r.com)
end

function Base.empty!(d::Declaration)
    empty!(declarations(d))
    empty!(d.com)
end
