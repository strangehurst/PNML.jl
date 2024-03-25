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
"""
struct VariableDeclaration{S <: AbstractSort} <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    sort::S
end
VariableDeclaration() = VariableDeclaration(:unknown, "Empty Variable Declaration", DotSort())
sortof(vd::VariableDeclaration) = vd.sort

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
sort(namedsort::NamedSort) = namedsort.def #! sortof?

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

#----------------------------------------------------------------------------------
@kwdef struct DeclDict
    namedsorts::Dict{Symbol,NamedSort} = Dict{Symbol, NamedSort}()       # namedsort
    partitionsorts::Dict{Symbol, PartitionSort} = Dict{Symbol, PartitionSort}() # partition
    variabledecls::Dict{Symbol,VariableDeclaration} = Dict{Symbol, VariableDeclaration}() # variabledecl
    namedoperators::Dict{Symbol,NamedOperator} = Dict{Symbol, NamedOperator}()          # namedoperator

    #! partitionops::Dict{Symbol,PartitionOp} = Dict{Symbol,PartitionOp}() # partitionelement
    feconstants::Dict{Symbol,FEConstant} = Dict{Symbol, FEConstant}()    # feconstant
end

named_op(dd::DeclDict, id::Symbol)      = dd.namedoperators[id]
named_sort(dd::DeclDict, id::Symbol)    = dd.namedsorts[id]
variable(dd::DeclDict, id::Symbol)      = dd.variabledecls[id]
partitionsort(dd::DeclDict, id::Symbol) = dd.partitionsorts[id]
#partitionop(dd::DeclDict, id::Symbol)  = dd.partitionops[id]
feconstant(dd::DeclDict, id::Symbol)    = dd.feconstants[id]

has_named_op(dd::DeclDict, id::Symbol)      = haskey(dd.namedoperators, id)
has_named_sort(dd::DeclDict, id::Symbol)    = haskey(dd.namedsorts, id)
has_variable(dd::DeclDict, id::Symbol)      = haskey(dd.variabledecls, id)
has_partitionsort(dd::DeclDict, id::Symbol) = haskey(dd.partitionsorts, id)
#has_partitionop(dd::DeclDict, id::Symbol)  = haskey(dd.partitionops, id)
has_feconstant(dd::DeclDict, id::Symbol)    = haskey(dd.feconstants, id)

function declarations(dd::DeclDict)
    # AbstractDeclaration[d for d in Iterators.flatten([values(dd.namedsorts)...,
    #         values(dd.partitionsorts)...,
    #         values(dd.variables)...,
    #         values(dd.operators)...])]
    collect(Iterators.flatten([values(dd.namedsorts),
                               values(dd.partitionsorts),
                               values(dd.variabledecls),
                               values(dd.namedoperators)]))
end


function Base.show(io::IO, dd::DeclDict)
    println(io, nameof(typeof(dd)), "(")

    io = inc_indent(io)
    iio = inc_indent(io)
    print(io, "Namedsort[")
    for (k,v) in pairs(dd.namedsorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "PartitionSort[")
    for (k,v) in pairs(dd.partitionsorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "VariableDeclaration[")
    for (k,v) in pairs(dd.variabledecls)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "NamedOperator[")
    for (k,v) in pairs(dd.namedoperators)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    #! partitionops:
    print(io, "FEConstant[")
    for (k,v) in pairs(dd.feconstants)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, ")")
end
