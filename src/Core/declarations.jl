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

[`DeclDict`](@ref) variabledecls[id] = tuple(VariableDeclaration(id, "human name", sort), instance_of_sort)
"""
struct VariableDeclaration{S <: AbstractSort} <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    sort::S
end
sortof(vd::VariableDeclaration) = vd.sort

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct NamedSort{S <: AbstractSort} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    def::S # # An instance of: ArbitrarySort, MultisetSort, ProductSort, UserSort
    ids::Tuple
end
NamedSort(id::Symbol, name::AbstractString, sort::AbstractSort; ids::Tuple) = NamedSort(id, name, sort, ids)
sortof(namedsort::NamedSort) = definition(namedsort)
definition(namedsort::NamedSort) = namedsort.def

function Base.show(io::IO, nsort::NamedSort)
    print(io, "NamedSort(")
    show(io, pid(nsort)); print(io, ", ")
    show(io, name(nsort)); print(io, ", ")
    io = inc_indent(io)
    show(io, definition(nsort));
    print(io, ")")
end


"""
$(TYPEDEF)
$(TYPEDFIELDS)

See [`UserOperator`](@ref)

Vector of `VariableDeclaration` for parameters (ordered), and `AbstractTerm` for its body definition.
"""
struct NamedOperator{T <: AbstractTerm} <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    parameter::Vector{VariableDeclaration} # variables with inferred sorts
    def::T # operator or variable term (with inferred sort)
    ids::Tuple
end
NamedOperator() = NamedOperator(:namedoperator, "Empty Named Operator"; ids=(:NONET,))
NamedOperator(id::Symbol, str; ids::Tuple) = NamedOperator(id, str, VariableDeclaration[], dotconstant, ids)
operator(no::NamedOperator) = no.def
parameters(no::NamedOperator) = no.parameter
sortof(no::NamedOperator) = sortof(operator(no))

#----------------------------------------------------------------------------------
