"""
    struct DeclDict
Collection of dictionaries holdind various kinds of PNML declarations.
Used to define the multisorted algebra of a high-level petri net graph.
"""
@kwdef struct DeclDict
    variabledecls::Dict{Symbol, Any} = Dict{Symbol, Any}()

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
    usersoperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

_decldict_fields = (:namedsorts, :arbitrarysorts,
                    :namedoperators, :arbitraryoperators,
                    :variabledecls,
                    :partitionsorts, :partitionops, :feconstants,
                    :usersorts, :useroperators)

# Explicit propeties allows ignoring metadata.
Base.isempty(dd::DeclDict) = all(isempty, Iterators.map(Fix1(getproperty,dd), _decldict_fields))
Base.length(dd::DeclDict)  = sum(length,  Iterators.map(Fix1(getproperty,dd), _decldict_fields))

variabledecls(dd::DeclDict)  = dd.variabledecls
namedsorts(dd::DeclDict)     = dd.namedsorts
arbitrarysorts(dd::DeclDict) = dd.arbitrarysorts
partitionsorts(dd::DeclDict) = dd.partitionsorts
namedoperators(dd::DeclDict) = dd.namedoperators
arbitrary_ops(dd::DeclDict)  = dd.arbitraryoperators
partitionops(dd::DeclDict)   = dd.partitionops
feconstants(dd::DeclDict)    = dd.feconstants

usersorts(dd::DeclDict)      = dd.usersorts
useroperators(dd::DeclDict)  = dd.useroperators

"""
    declarations(dd::DeclDict) -> Iterator
Return an iterator over all the declaration dictionaries' values.
Flattens iterators: variabledecls, namedsorts, arbitrarysorts, partitionsorts, partitionops,
namedoperators, arbitrary_ops, feconstants, usersorts, useroperators.
"""
function declarations(dd::DeclDict)
    Iterators.flatten([
        values(variabledecls(dd)),
        values(namedsorts(dd)),
        values(arbitrarysorts(dd)),
        values(partitionsorts(dd)),
        values(partitionops(dd)),
        values(namedoperators(dd)),
        values(arbitrary_ops(dd)),
        values(feconstants(dd)),
        values(usersorts(dd)),
        values(useroperators(dd)),
    ])
end

has_variable(dd::DeclDict, id::Symbol)       = haskey(variabledecls(dd), id)
has_namedsort(dd::DeclDict, id::Symbol)      = haskey(namedsorts(dd), id)
has_arbitrary_sort(dd::DeclDict, id::Symbol) = haskey(arbitrarysorts(dd), id)
has_partitionsort(dd::DeclDict, id::Symbol)  = haskey(partitionsorts(dd), id)
has_namedop(dd::DeclDict, id::Symbol)        = haskey(namedoperators(dd), id)
has_arbitrary_op(dd::DeclDict, id::Symbol)   = haskey(arbitraryoperators(dd), id)
has_partitionop(dd::DeclDict, id::Symbol)    = haskey(partitionops(dd), id)
has_feconstant(dd::DeclDict, id::Symbol)     = haskey(feconstants(dd), id)

has_usersort(dd::DeclDict, id::Symbol)       = haskey(usersorts(dd), id)
has_useroperator(dd::DeclDict, id::Symbol)   = haskey(usersorts(dd), id)

variable(dd::DeclDict, id::Symbol)       = variabledecls(dd)[id]
named_sort(dd::DeclDict, id::Symbol)     = namedsorts(dd)[id]
arbitrary_sort(dd::DeclDict, id::Symbol) = arbitrarysorts(dd)[id]
partitionsort(dd::DeclDict, id::Symbol)  = partitionsorts(dd)[id]
named_op(dd::DeclDict, id::Symbol)       = namedoperators(dd)[id]
arbitrary_op(dd::DeclDict, id::Symbol)   = arbitraryoperators(dd)[id]
partitionop(dd::DeclDict, id::Symbol)    = partitionops(dd)[id]
feconstant(dd::DeclDict, id::Symbol)     = feconstants(dd)[id]

usersort(dd::DeclDict, id::Symbol)       = usersorts(dd)[id]
useroperator(dd::DeclDict, id::Symbol)   = useroperators(dd)[id]


#TODO :useroperators
_op_dictionaries() = (:namedoperators, :feconstants, :partitionops, :arbitraryoperators)
_ops(dd) = Iterators.map(op -> getfield(dd, op), _op_dictionaries())

"""
    operators(dd::DeclDict)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(dd::DeclDict) = Iterators.flatten(Iterators.map(values, _ops(dd)))

"Does any operator dictionary contain `id`?"
has_operator(dd::DeclDict, id::Symbol) = any(opdict -> haskey(opdict, id), _ops(dd))

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

"""
    validate_declarations(dd::DeclDict) -> Bool
"""
function validate_declarations(dd::DeclDict)
    #! println("validate declarations")
    return true
end

"""
    fill_nonhl!(dd::DeclDict) -> nothing

Fill a DeclDict with values needed by non-high-level networks.

    NamedSort(:integer, "Integer", IntegerSort())
    NamedSort(:natural, "Natural", NaturalSort())
    NamedSort(:positive, "Positive", PositiveSort())
    NamedSort(:real, "Real", RealSort())
    NamedSort(:dot, "Dot", DotSort())

    UserSort(:integer)
    UserSort(:natural)
    UserSort(:positive)
    UserSort(:real)
    UserSort(:dot)
"""
function fill_nonhl!(dd::DeclDict)
    for (tag, name, sort) in ((:integer, "Integer", IntegerSort()),
                              (:natural, "Natural", NaturalSort()),
                              (:positve, "Positive", PositiveSort()),
                              (:real, "Real", RealSort()),
                              (:dot, "Dot", DotSort()),
                              )

        if !has_namedsort(dd, tag)
            namedsorts(dd)[tag] = NamedSort(tag, name, sort)
            !isregistered(PNML.idregistry[], tag) && register_id!(PNML.idregistry[], tag)
        end
        if !has_usersort(dd, tag)
            usersorts(dd)[tag] = UserSort(tag)
            !isregistered(PNML.idregistry[], tag) && register_id!(PNML.idregistry[], tag)
        end
    end
end
