"""
$(TYPEDEF)
Declarations define objects/names that are used for high-level terms in conditions, inscriptions, markings.
The definitions are attached to PNML nets and/or pages using a PNML Label defined in a <declarations> tag.

- id
- name
"""
abstract type AbstractDeclaration end

pid(decl::AbstractDeclaration) = decl.id
has_name(decl::AbstractDeclaration) = hasproperty(decl, :name)
name(decl::AbstractDeclaration) = decl.name

function Base.show(io::IO, declare::AbstractDeclaration)
    print(io, nameof(typeof(declare)), "(")
    show(io, pid(declare)); print(io, ", ")
    show(io, name(declare)); print(io, ", ")

    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
Label of a <net> or <page> that holds zero or more declarations. The declarations are used
to define parts of the many-sorted algebra used by High-Level Petri Nets.

We can use infrastructure implemented for HL nets to provide nonstandard extensions for other PNTDs.
"""
struct Declaration <: Annotation
    text::Maybe{String}
    declarations::Vector{AbstractDeclaration} #TODO Type parameter? Seperate vector for each type?
    #!declarations::Vector{Any} #TODO Type parameter? Seperate vector for each type?
    #SortDeclarations               xml:"structure>declarations>namedsort"`
	#PartitionSortDeclarations      xml:"structure>declarations>partition"
	#VariableDeclarations           xml:"structure>declarations>variabledecl"
	#OperatorDeclarations           xml:"structure>declarations>namedoperator"
	#PartitionOperatorsDeclarations xml:"structure>declarations>partitionelement"
	#FEConstantDeclarations         xml:"structure>declarations>feconstant"
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Maybe{Vector{ToolInfo}}
end

Declaration() = Declaration(nothing, AbstractDeclaration[], nothing, nothing)

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
$(TYPEDFIELDS)
"""
struct UnknownDeclaration  <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    nodename::Union{String,SubString{String}}
    content::Vector{AnyElement}
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
struct VariableDeclaration{S <: AbstractSort} <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    sort::S
end
VariableDeclaration() = VariableDeclaration(:unknown, "Empty Variable Declaration", DotSort())

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedSort{S <: AbstractSort} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    def::S # ArbitrarySort, MultisetSort, ProductSort, UserSort
end
NamedSort() = NamedSort(:namedsort, "Empty NamedSort", DotSort())
sort(namedsort::NamedSort) = namedsort.def

function Base.show(io::IO, nsort::NamedSort)
    print(io, "NamedSort(")
    show(io, pid(nsort)); print(io, ", ")
    show(io, name(nsort)); print(io, ", ")
    show(inc_indent(io), sort(nsort))
    print(io, ")")
end


"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of a [`PartitionSort`](@ref)'s emumeration. See also [`FiniteEnumerationSort`](@ref).
"""
struct PartitionElement
    id::Symbol
    name::Union{String,SubString{String}}
    terms::Vector{UserOperator} # 1 or more Terms of PatrtitionSort's (UserOperator?) as constants
end
PartitionElement() = PartitionElement(:partitionelement, "Empty Partition Element", UserOperator[])

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition is a finite enumeration that is partitioned into sub-ranges of enumerations.
Is the sort at the partition or the element level (1 sort ot many sorts?)
"""
struct PartitionSort{S <: AbstractSort, PE <: PartitionElement} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    def::S # Refers to a NamedSort
    element::Vector{PE} # 1 or more PartitionElements. Each is
    #
end
PartitionSort() = PartitionSort(:partitionsort, "Empty PartitionSort", DotSort(),  PartitionElement[])
sort(partition::PartitionSort) = partition.def
elements(partition::PartitionSort) = partition.element

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

See [`UserOperator`](@ref)
"""
struct NamedOperator{V,T} <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    parameter::Vector{V}
    def::T # operator or variable term (with associated sort)
end
NamedOperator() = NamedOperator(:namedoperator, "Empty Named Operator", [], nothing)
operator(no::NamedOperator) = no.def
parameters(no::NamedOperator) = no.parameter
