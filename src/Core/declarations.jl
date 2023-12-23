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
Other PNTDs may introduce non-standard uses for declarations.

We can use infrastructure implemented for HL nets to provide nonstandard extensions.
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
    tools::Vector{ToolInfo}
end

Declaration() = Declaration(nothing, AbstractDeclaration[], nothing, ToolInfo[])

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
    content::Vector{Any} #! Vector{AnyElement}
end
UnknownDeclaration() = UnknownDeclaration(:unknowndeclaration, "Empty Unknown", "empty", [OrderedDict()])

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
    name::Union{String,SubString{String}}
    sort::S
end
VariableDeclaration() = VariableDeclaration(:unknown, "Empty Variable Declaration", DotSort())

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedSort{S<:Union{AbstractSort,AnyElement}} <: SortDeclaration
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

Partition sort.
"""
struct PartitionSort{S,PE} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
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
    name::Union{String,SubString{String}}
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
