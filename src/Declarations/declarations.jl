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

See [`Declarations.NamedSort`](@ref) and Declarations.ArbitrarySort`] as concrete subtypes.
"""
abstract type SortDeclaration <: AbstractDeclaration end

"""
$(TYPEDEF)

[`NamedOperator`](@ref). [`PNML.FEConstant`](@ref), [`PartitionElement`](@ref) and
[`ArbitraryOperator`](@ref) are all referenced by [`UserOperator`](@ref).

`UserOperator` wraps REFID used to access `DeclDict`.
"""
abstract type OperatorDeclaration <: AbstractDeclaration end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable declaration `<variabledecl>` adds a name string and sort to the `id`
shared with `<variable>` terms in non-ground terms.

EXAMPLE

[`PNML.DeclDict`](@ref) PNML.variabledecls[id] = VariableDeclaration(id, "human name", sort)
"""
struct VariableDeclaration <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    sort::UserSort # user sort -> named sort -> sort object

    # Implementation of variables use a reference to a marking paired with a variable declaration REFID
    #   (ref::Ref{sortof(vdecl)}(mark), REFID)
    # where the sort of the mark matches the VariableDeclaration sort.

    # If the place sorttype is a product sort
    #   variable's sort will be one of the product member sorts or same product sort
    #   If part of a product sort,
    #       other variables or multiples of this one must combine to form a multiset element.
    # else
    #   variable's sort will be sorttype

    # There will be a value of `sort`
    #   removed from input marking(s) and/or added to output marking(s)
    #   is possible that only one action happens for a variable

    # How to match marking element?
    # A place has one marking, a multiset, with sorttype(place) as basis sort.
    # if sorttype(place) isa productsort
    #   if sortof(variable) isa productsort
    #       add/remove tuple, with cost
    #   else
    #       need an index into the product to add/remove (Ref(mark,i))
    # else
    #   add/remove sort

    # Find index in tuple? The inscription will be tuple-valued as will the relevant marking.
    # When parsing a <variable>, identify its enclosing tuple & index #TODO

    # Will PnmlTuple ever have fields mutated? No, marking vectors are not mutated! They are preserved as part of reachability graph.
    # PnmlTuple fields will be read as part of enabling function (inscription,condition) and firing function.
end
sortref(vd::VariableDeclaration) = identity(vd.sort)::UserSort
sortof(vd::VariableDeclaration) = sortdefinition(namedsort(sortref(vd)))
refid(vd::VariableDeclaration) = refid(sortref(vd))::Symbol

function Base.show(io::IO, declare::VariableDeclaration)
    print(io, nameof(typeof(declare)), "(")
    show(io, pid(declare)); print(io, ", ")
    show(io, name(declare)); print(io, ", ")
    show(io, refid(declare))
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Declaration of a `NamedSort`. Wraps an instance of an `AbstractSort`.
See [`MultisetSort`](@ref), [`ProductSort`](@ref), [`UserSort`](@ref).
"""
struct NamedSort{S <: AbstractSort} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    def::S # An instance of: ArbitrarySort, MultisetSort, ProductSort, BUILT-IN sorts!
end

sortdefinition(namedsort::NamedSort) = namedsort.def

Base.eltype(::Type{NamedSort{S}}) where {S} = eltype(S)

function Base.show(io::IO, nsort::NamedSort)
    print(io, "NamedSort(")
    show(io, pid(nsort)); print(io, ", ")
    show(io, name(nsort)); print(io, ", ")
    io = PNML.inc_indent(io)
    show(io, sortdefinition(nsort));
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

See [`UserOperator`](@ref)

Vector of `VariableDeclaration` for parameters (ordered),
and duck-typed `AbstractTerm` for its body.
"""
struct NamedOperator{T} <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    parameter::Vector{VariableDeclaration} # constants,variables with inferred sorts #TODO ===
    def::T # operator or variable term (with inferred sort) #TODO how to infer ===
end
NamedOperator() = NamedOperator(:namedoperator, "Empty Named Operator")
# Empty parameter vector. Default to dots.
NamedOperator(id::Symbol, str) = NamedOperator(id, str, VariableDeclaration[], PNML.DotConstant())

operator(no::NamedOperator) = no.def
parameters(no::NamedOperator) = no.parameter
sortref(no::NamedOperator) = sortref(operator(no))::UserSort # of the wrapped operator
sortof(no::NamedOperator) = sortdefinition(namedsort(sortref(no)))
