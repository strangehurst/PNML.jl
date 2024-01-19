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
    text::Maybe{String}
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Vector{ToolInfo}
end

Declaration() = Declaration(Any[], nothing, nothing, ToolInfo[])

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

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

"""
$(TYPEDEF)
Declarations define objects/names that are used for high-level terms in conditions, inscriptions, markings.
The definitions are attached to PNML nets and/or pages using a PNML Label defined in a <declarations> tag.
"""
abstract type AbstractDeclaration end #<: AbstractLabel end

pid(decl::AbstractDeclaration) = decl.id
name(decl::AbstractDeclaration) = isnothing(name) ? "" : decl.name

function Base.show(io::IO, declare::AbstractDeclaration)
    pprint(io, declare)
end

quoteof(i::AbstractDeclaration) = :(AbstractDeclaration($(quoteof(i.id)), $(quoteof(i.name))))


"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct UnknownDeclaration  <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString}
    nodename::Union{String,SubString}
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
    name::Union{String,SubString}
    sort::S
end
VariableDeclaration() = VariableDeclaration(:unknown, "Empty Variable Declaration", DotSort())

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedSort{S<:Union{AbstractSort,AnyElement}} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString}
    def::S # ArbitrarySort, MultisetSort, ProductSort, UserSort
end
NamedSort() = NamedSort(:namedsort, "Empty NamedSort", DotSort())
sort(namedsort::NamedSort) = namedsort.def

function Base.show(io::IO, nsort::NamedSort)
    pprint(IOContext(io, :displaysize => (24, 180)), nsort)
end

quoteof(n::NamedSort) = :(NamedSort($(quoteof(n.id)), $(quoteof(n.name)), $(quoteof(n.def))))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition sort.
"""
struct PartitionSort{S,PE} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString}
    def::S # Refers to a NamedSort
    element::PE # 1 or more PartitionElements.
    #
end
PartitionSort() = PartitionSort(:partitionsort, "Empty PartitionSort", DotSort(),  PartitionElement[])
sort(partition::PartitionSort) = partition.def
elements(partition::PartitionSort) = partition.element

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition Element is part of a Partition Sort.
"""
struct PartitionElement # <: SortDeclaration should be something for accessors
    id::Symbol
    name::Union{String,SubString}
    terms::Vector{UserOperator} # 1 or more Terms (UserOperator?)
end
PartitionElement() = PartitionElement(:partitionelement, "Empty Partition Element", UserOperator[])


"""
$(TYPEDEF)
$(TYPEDFIELDS)

Arbitrary sorts that can be used for constructing terms are
reserved for/supported by `HLPNG` in the pnml specification.
"""
struct ArbitrarySort <: SortDeclaration
    id::Symbol
    name::Union{String,SubString}
end

function ArbitrarySort()
    ArbitrarySort(:arbitrarysort, "ArbitrarySort")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

See [`UserOperator`](@ref)
"""
struct NamedOperator{V,T} <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString}
    parameter::Vector{V}
    def::T # operator or variable term (with associated sort)
end
NamedOperator() = NamedOperator(:namedoperator, "Empty Named Operator", [], nothing)
operator(no::NamedOperator) = no.def
parameters(no::NamedOperator) = no.parameter
