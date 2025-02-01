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

See [`PNML.Declarations.NamedSort`](@ref) and [`PNML.Declarations.ArbitrarySort`] as concrete subtypes.
"""
abstract type SortDeclaration <: AbstractDeclaration end

"""
$(TYPEDEF)

[`NamedOperator`](@ref). [`FEConstant`](@ref), [`PartitionElement`](@ref) and
[`ArbitraryOperator`](@ref) are all referenced by [`UserOperator`](@ref).
"""
abstract type OperatorDeclaration <: AbstractDeclaration end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

[`PNML.DeclDict`](@ref) variabledecls[id] = tuple(VariableDeclaration(id, "human name", sort), instance_of_sort)
"""
struct VariableDeclaration <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    sort::UserSort # user -> named -> sort object

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

    # Will PnmlTuple ever have fields mutated? Or will mark updated be done by replacement?
    # PnmlTuple fields will be read as part of enabling function (condition)
end
sortref(vd::VariableDeclaration) = identity(vd.sort)::UserSort
sortof(vd::VariableDeclaration) = sortdefinition(namedsort(sortref(vd))) #? partitionsort

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

 # NamedSort cannot contain a UserSort (for Symmetric and lower only?

function Base.show(io::IO, nsort::NamedSort)
    print(io, "NamedSort(")
    show(io, pid(nsort)); print(io, ", ")
    show(io, name(nsort)); print(io, ", ")
    io = inc_indent(io)
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
NamedOperator(id::Symbol, str) = NamedOperator(id, str, VariableDeclaration[], DotConstant())

operator(no::NamedOperator) = no.def
parameters(no::NamedOperator) = no.parameter
sortref(no::NamedOperator) = sortref(operator(no))::UserSort # of the wrapped operator
sortof(no::NamedOperator) = sortdefinition(namedsort(sortref(no)))

#? id & name should map to the function whose body is `def` and inputs are `parameters`
