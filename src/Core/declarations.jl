"""
$(TYPEDEF)
$(TYPEDFIELDS)
Label of a <net> or <page> that holds zero or more declarations. The declarations are used
to define parts of the many-sorted algebra used by High-Level Petri Nets.
Other PNTDs may introduce non-standard uses for declarations.

# Notes: `declarations` is implemented as a collection of `Any`.
We can use infrastructure implemented for HL nets to provide nonstandard extensions.
"""
struct Declaration <: Annotation
    declarations::Vector{Any} #TODO Type parameter? Seperate vector for each type?
    #SortDeclarations               xml:"structure>declarations>namedsort"`
	#PartitionSortDeclarations      xml:"structure>declarations>partition"
	#VariableDeclarations           xml:"structure>declarations>variabledecl"
	#OperatorDeclarations           xml:"structure>declarations>namedoperator"
	#PartitionOperatorsDeclarations xml:"structure>declarations>partitionelement"
	#FEConstantDeclarations         xml:"structure>declarations>feconstant"

    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Vector{ToolInfo}
end

Declaration() = Declaration(Any[], nothing, ToolInfo[])

declarations(d::Declaration) = d.declarations

#TODO Document/implement/test collection interface of Declaration.
Base.length(d::Declaration) = (length ∘ declarations)(d)

# Flattening pages combines declarations & toolinfos into the first page.
function Base.append!(l::Declaration, r::Declaration)
    append!(declarations(l), declarations(r))
end

function Base.empty!(d::Declaration)
    empty!(declarations(d))
end

"""
$(TYPEDEF)
Declarations define objects/names that are used for high-level terms in conditions, inscriptions, markings.
The definitions are attached to PNML nets and/or pages.
"""
abstract type AbstractDeclaration end #<: AbstractLabel end

pid(decl::AbstractDeclaration) = decl.id
name(decl::AbstractDeclaration) = isnothing(name) ? "" : decl.name

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
UnknownDeclaration() = UnknownDeclaration(:unknowndeclaration, "Empty Unknown", "empty", [])

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
VariableDeclaration() = VariableDeclaration(:unknown, "Empty Variable Declaration", DotSort())

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedSort{S<:Union{AbstractSort,AnyElement}} <: SortDeclaration
    id::Symbol
    name::String
    def::S # ArbitrarySort, MultisetSort, ProductSort, UserSort
end
NamedSort() = NamedSort(:namedsort, "Empty NamedSort", DotSort())

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
Partition() = Partition(:partition, "Empty Partition", DotSort(),  [])

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
NamedOperator() = NamedOperator(:namedoperator, "Empty Named Operator", [], nothing)

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
