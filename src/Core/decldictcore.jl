"""
    struct DeclDict

$(DocStringExtensions.TYPEDFIELDS)

Collection of dictionaries holding various kinds of PNML declarations.
Used to define the multisorted algebra of a high-level petri net graph.
"""
@kwdef struct DeclDict
    variabledecls::Dict{Symbol, Any} = Dict{Symbol, Any}()

    #TODO use namedsorts to wrap built-in and arbitrary sorts'
    namedsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    arbitrarysorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    partitionsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # useroperator refers to a OperatorDeclaration by name.
    # todo use flattened iterator over all OperatorDeclarations
    # OperatorDecls include: namedoperator, feconstant, partition element, et al.
    # namedoperators are used to access built-in operators
    namedoperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
    arbitraryoperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # PartitionElement is an operator, there are other built-in operators
    partitionops::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # FEConstants are 0-ary OperatorDeclarations.
    # The only explicit attributes are ID symbol and name string.
    # TODO record an optional partition id when used by a partition
    feconstants::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # Allows using an IDREF symbol as a network-level "global".
    # Useful for non-high-level networks that mimic HLNets to share implementation.
    # Long way of saying generic? (in what sense generic?)
    usersorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    useroperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

_decldict_fields = (:namedsorts, :arbitrarysorts,
                    :namedoperators, :arbitraryoperators,
                    :variabledecls,
                    :partitionsorts, :partitionops, :feconstants,
                    :usersorts, :useroperators)

# Explicit propeties allows ignoring metadata.
Base.isempty(dd::DeclDict) = all(isempty, Iterators.map(Fix1(getproperty,dd), _decldict_fields))
Base.length(dd::DeclDict)  = sum(length,  Iterators.map(Fix1(getproperty,dd), _decldict_fields))

usersorts(dd::DeclDict)      = dd.usersorts
useroperators(dd::DeclDict)  = dd.useroperators
variabledecls(dd::DeclDict)  = dd.variabledecls
namedsorts(dd::DeclDict)     = dd.namedsorts
arbitrarysorts(dd::DeclDict) = dd.arbitrarysorts
partitionsorts(dd::DeclDict) = dd.partitionsorts
namedoperators(dd::DeclDict) = dd.namedoperators
arbitraryops(dd::DeclDict)   = dd.arbitraryoperators
partitionops(dd::DeclDict)   = dd.partitionops
feconstants(dd::DeclDict)    = dd.feconstants

# Default to ScopedValue
usersorts()      = usersorts(PNML.DECLDICT[])
useroperators()  = useroperators(PNML.DECLDICT[])
variabledecls()  = variabledecls(PNML.DECLDICT[])
namedsorts()     = namedsorts(PNML.DECLDICT[])
arbitrarysorts() = arbitrarysorts(PNML.DECLDICT[])
partitionsorts() = partitionsorts(PNML.DECLDICT[])
namedoperators() = namedoperators(PNML.DECLDICT[])
arbitraryops()   = arbitraryops(PNML.DECLDICT[])
partitionops()   = partitionops(PNML.DECLDICT[])
feconstants()    = feconstants(PNML.DECLDICT[])


"""
    declarations(dd::DeclDict) -> Iterator

Return an iterator over all the declaration dictionaries' values.
Flattens iterators: variabledecls, namedsorts, arbitrarysorts, partitionsorts, partitionops,
namedoperators, arbitraryops, feconstants, usersorts, useroperators.
"""
function declarations(dd::DeclDict)
    Iterators.flatten([
        values(variabledecls(dd)),
        values(namedsorts(dd)),
        values(arbitrarysorts(dd)),
        values(partitionsorts(dd)),
        values(partitionops(dd)),
        values(namedoperators(dd)),
        values(arbitraryops(dd)),
        values(feconstants(dd)),
        values(usersorts(dd)),
        values(useroperators(dd)),
    ])
end

has_variable(dd::DeclDict, id::Symbol)       = haskey(variabledecls(dd), id)
has_namedsort(dd::DeclDict, id::Symbol)      = haskey(namedsorts(dd), id)
has_arbitrarysort(dd::DeclDict, id::Symbol)  = haskey(arbitrarysorts(dd), id)
has_partitionsort(dd::DeclDict, id::Symbol)  = haskey(partitionsorts(dd), id)
has_namedop(dd::DeclDict, id::Symbol)        = haskey(namedoperators(dd), id)
has_arbitraryop(dd::DeclDict, id::Symbol)    = haskey(arbitraryops(dd), id)
has_partitionop(dd::DeclDict, id::Symbol)    = haskey(partitionops(dd), id)
has_feconstant(dd::DeclDict, id::Symbol)     = haskey(feconstants(dd), id)
has_usersort(dd::DeclDict, id::Symbol)       = haskey(usersorts(dd), id)
has_useroperator(dd::DeclDict, id::Symbol)   = haskey(usersorts(dd), id)

has_variable(id::Symbol) = (PNML.DECLDICT[], id)
has_namedsort(id::Symbol) = has_namedsort(PNML.DECLDICT[], id)
has_arbitrarysort(id::Symbol) = has_arbitrarysort(PNML.DECLDICT[], id)
has_partitionsort(id::Symbol) = has_partitionsort(PNML.DECLDICT[], id)
has_namedop(id::Symbol) = has_namedop(PNML.DECLDICT[], id)
has_arbitraryop(id::Symbol) = has_arbitraryop(PNML.DECLDICT[], id)
has_partitionop(id::Symbol) = has_partitionop(PNML.DECLDICT[], id)
has_feconstant(id::Symbol) = has_feconstant(PNML.DECLDICT[], id)
has_usersort(id::Symbol) = has_usersort(PNML.DECLDICT[], id)
has_useroperator(id::Symbol) = has_useroperator(PNML.DECLDICT[], id)

variable(dd::DeclDict, id::Symbol)       = variabledecls(dd)[id]
namedsort(dd::DeclDict, id::Symbol)      = namedsorts(dd)[id]
arbitrarysort(dd::DeclDict, id::Symbol)  = arbitrarysorts(dd)[id]
partitionsort(dd::DeclDict, id::Symbol)  = partitionsorts(dd)[id]
namedop(dd::DeclDict, id::Symbol)        = namedoperators(dd)[id]
arbitrary_op(dd::DeclDict, id::Symbol)   = arbitraryoperators(dd)[id]
partitionop(dd::DeclDict, id::Symbol)    = partitionops(dd)[id]
feconstant(dd::DeclDict, id::Symbol)     = feconstants(dd)[id]
usersort(dd::DeclDict, id::Symbol)       = usersorts(dd)[id]
useroperator(dd::DeclDict, id::Symbol)   = useroperators(dd)[id]

variable(id::Symbol)       = variabledecls(PNML.DECLDICT[])[id]
namedsort(id::Symbol)      = namedsorts(PNML.DECLDICT[])[id]
arbitrarysort(id::Symbol)  = arbitrarysorts(PNML.DECLDICT[])[id]
partitionsort(id::Symbol)  = partitionsorts(PNML.DECLDICT[])[id]
namedop(id::Symbol)        = namedoperators(PNML.DECLDICT[])[id]
arbitrary_op(id::Symbol)   = arbitraryoperators(PNML.DECLDICT[])[id]
partitionop(id::Symbol)    = partitionops(PNML.DECLDICT[])[id]
feconstant(id::Symbol)     = feconstants(PNML.DECLDICT[])[id]
usersort(id::Symbol)       = usersorts(PNML.DECLDICT[])[id]
useroperator(id::Symbol)   = useroperators(PNML.DECLDICT[])[id]

#TODO :useroperators
_op_dictionaries() = (:namedoperators, :feconstants, :partitionops, :arbitraryoperators)
_ops(dd) = Iterators.map(op -> getfield(dd, op), _op_dictionaries())

"""
    operators(dd::DeclDict)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(dd::DeclDict) = Iterators.flatten(Iterators.map(values, _ops(dd)))
operators() = operators(dd::DeclDict)

"Does any operator dictionary contain `id`?"
has_operator(dd::DeclDict, id::Symbol) = any(opdict -> haskey(opdict, id), _ops(dd))
has_operator(id::Symbol) = has_operator(PNML.DECLDICT[], id)

#! Change first to only when de-duplication implementd? as test?
"Return operator dictionary containing key `id`."
_get_op_dict(dd::DeclDict, id::Symbol) = first(Iterators.filter(Fix2(haskey, id), _ops(dd)))

"""
Return operator with `id`. Operators include: `NamedOperator`, `FEConstant`, `PartitionElement`.
"""
function operator(dd::DeclDict, id::Symbol)
    dict = _get_op_dict(dd, id)
    op = dict[id]
    return op
end
operator(id::Symbol) = operator(PNML.DECLDICT[], id)

"""
    validate_declarations(dd::DeclDict) -> Bool
"""
function validate_declarations(dd::DeclDict)
    #! println("validate declarations")
    return true
end

"""
    fill_nonhl!() -> nothing
    fill_nonhl!(dd::DeclDict) -> nothing

Fill a DeclDict with defaults and values needed by non-high-level networks.
Defaults to filling the scoped value PNML.DECLDICT[].

    NamedSort(:integer, "Integer", IntegerSort())
    NamedSort(:natural, "Natural", NaturalSort())
    NamedSort(:positive, "Positive", PositiveSort())
    NamedSort(:real, "Real", RealSort())
    NamedSort(:dot, "Dot", DotSort())
    NamedSort(:bool, "Bool", BoolSort())

    UserSort(:integer)
    UserSort(:natural)
    UserSort(:positive)
    UserSort(:real)
    UserSort(:dot)
    UserSort(:bool)
"""
function fill_nonhl! end

fill_nonhl!() = fill_nonhl!(PNML.:DECLDICT[]) # ScopedValue
function fill_nonhl!(dd::DeclDict)
    for (tag, name, sort) in ((:integer, "Integer", IntegerSort()),
                              (:natural, "Natural", NaturalSort()),
                              (:positive, "Positive", PositiveSort()),
                              (:real, "Real", RealSort()),
                              (:dot, "Dot", DotSort()),
                              (:bool, "Bool", BoolSort()),
                              (:null, "Null", NullSort()),
                              )
        #TODO list, strings, arbitrarysorts other built-ins
        fill_sort_tag!(dd, tag, name, sort)
    end
end

"""
    fill_sort_tag!(dd::DeclDict, tag::Symbol, name, sort)

If not already in the declarations dictionary, create and add a namedsort, usersort for `tag`.
"""
function fill_sort_tag! end

function fill_sort_tag!(dd::DeclDict, tag::Symbol, name, sort)
    if !has_namedsort(dd, tag) # Do not overwrite existing content.
        !isregistered(PNML.idregistry[], tag) && register_id!(PNML.idregistry[], tag)
        namedsorts(dd)[tag] = NamedSort(tag, name, sort)
    end
    if !has_usersort(dd, tag) # Do not overwrite existing content.
        !isregistered(PNML.idregistry[], tag) && register_id!(PNML.idregistry[], tag)
        usersorts(dd)[tag] = UserSort(tag)
    end
end

fill_sort_tag!(tag::Symbol, name, sort) = fill_sort_tag!(PNML.:DECLDICT[], tag::Symbol, name, sort)
