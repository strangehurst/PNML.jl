"""
$(TYPEDEF)
Declarations define objects/names that are used for high-level terms in conditions, inscriptions, markings.
The definitions are attached to PNML nets and/or pages using a PNML Label defined in a <declarations> tag.

- id
- name
"""
abstract type AbstractDeclaration end

pid(decl::AbstractDeclaration) = decl.id
name(decl::AbstractDeclaration) = decl.name
decldict(decl::AbstractDeclaration) = decl.declarationdicts

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
    content::AnyElement
    declarationdicts::DeclDict
end

function Base.show(io::IO, x::UnknownDeclaration)
    print(io, nameof(typeof(x)), "(", repr(id), ", ", repr(name), ", ",
            repr(nodename), content, ")")
end

"""
$(TYPEDEF)

See [`Declarations.NamedSort`](@ref), [`Declarations.PartitionSort`](@ref) and
[`Declarations.ArbitrarySort`] as concrete subtypes.
"""
abstract type SortDeclaration <: AbstractSort end #!<: AbstractDeclaration end

"""
$(TYPEDEF)

[`NamedOperator`](@ref). [`PNML.FEConstant`](@ref), [`PartitionElement`](@ref) and
[`ArbitraryOperator`](@ref) are all referenced by `UserOperator`.

`UserOperator` wraps REFID used to access `DeclDict`.
"""
abstract type OperatorDeclaration <: AbstractSort end #!<: AbstractDeclaration end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable declaration `<variabledecl>` adds a name string and sort to the `id`
shared with `<variable>` terms in non-ground terms.

EXAMPLE

[`PNML.DeclDict`](@ref)

PNML.variabledecls[id] = VariableDeclaration(id, "human name", sort)
"""
struct VariableDeclaration{S <: AbstractSortRef} <: AbstractDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    sort::S
    declarationdicts::DeclDict

    #! Inline Sorts allowed, also <usersort> indirection.
    # Example:
    # <variabledecl id="id12" name="x">
    #     <productsort>
    #       <integer/>
    #       <integer/>
    #     </productsort>
    # </variabledecl>

    #! Sorts serve a similar role as Juia Types.
    #! Sorts are static, Distinct variabledecls may have the same product sort inlined.
    #todo use hashes (dictionary?) to deduplicate.
end

    # Implementation of variables use a reference to a marking paired with a variable declaration REFID
    #   (ref::Ref{sortof(vdecl)}(mark), REFID)
    # or ref::Ref{sortof(vdecl)}(mark) => REFID
    # where the sort of the mark matches the VariableDeclaration sort.

    #! If the place sorttype is a product sort
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

    # Find index in tuple? The inscription will be pnml-tuple-valued as will the relevant marking.
    # When parsing a <variable>, identify its enclosing tuple & index #TODO

    # Will PnmlTuple ever have fields mutated? No, marking vectors are not mutated!
    # They evolve and are possibly preserved as part of reachability graph.
    # PnmlTuple fields will be read as part of enabling function (inscription,condition) and firing function.

decldict(vd::VariableDeclaration) = vd.declarationsdicts

sortref(vd::VariableDeclaration) = vd.sort::AbstractSortRef
sortof(vd::VariableDeclaration) = sortdefinition(namedsort(decldict(vd), refid(vd)))::AbstractSort
#TODO also do `partitionsort`, `arbitrarysort` that function like `namedsort` to add `id` and `name` to something.

function Base.show(io::IO, declare::VariableDeclaration)
    print(io, nameof(typeof(declare)), "(")
    show(io, pid(declare)); print(io, ", ")
    show(io, name(declare)); print(io, ", ")
    show(io, sortref(declare))
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Declaration of a `NamedSort`. Wraps a concrete instance of a built-in `AbstractSort`.
See [`MultisetSort`](@ref), [`ProductSort`](@ref).
"""
@auto_hash_equals fields=id,name,def struct NamedSort{S <: AbstractSort} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    def::S  #! This remains where the concrete sort lives.
    # An instance of: ArbitrarySort, MultisetSort, ProductSort, or BUILT-IN sort!
    declarationdicts::DeclDict

    function NamedSort(id_::Symbol, name_, def_::AbstractSort, dd::DeclDict)
        if isa(def_, NamedSort)
            error("NamedSort wraps NamedSort: $(repr(id_)) $(repr(name_)) $(repr(def_))") #|> throw
            yield()
        end
        new{typeof(def_)}(id_, name_, def_, dd)
    end
end

function sortdefinition(namedsort::NamedSort)
    namedsort.def # Instance of concrete sort.
end

sortelements(namedsort::NamedSort) = sortelements(sortdefinition(namedsort))

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

See `UserOperator`.

Vector of `VariableDeclaration` for parameters (ordered),
and duck-typed `AbstractTerm` for its body.
"""
struct NamedOperator{T} <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    parameter::Vector{VariableDeclaration} # constants,variables with inferred sorts #TODO XXX
    def::T # expression  terms (with inferred output sort) #TODO! XXX how to infer from expression ===
    declarationdicts::DeclDict
end

# Empty parameter vector. Default to return sort of dots.
NamedOperator(id::Symbol, str; ddict) = NamedOperator(id, str, VariableDeclaration[], PNML.DotConstant(ddict), ddict)

decldict(no::NamedOperator) = no.declarationdicts
operator(ddict, no::NamedOperator) = operator(ddict, no.def)
parameters(no::NamedOperator) = no.parameter

function Base.show(io::IO, op::NamedOperator)
    print(io, nameof(typeof(op)), "(", repr(id), ", ", repr(name), ", ",
            parameter, ", ", def,  ")")
end
