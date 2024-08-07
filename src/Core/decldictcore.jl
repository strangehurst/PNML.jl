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
    # The only explicit attributes are id symbol and name string.
    # We record an optional partition id
    feconstants::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # Allows using an IDREF symbol as a network-level "global".
    # Useful for non-high-level networks that mimic HLNets to share implementation.
    # Long way of saying generic? (in what sense generic?)
    usersorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

_decldict_fields = (:namedsorts, :arbitrarysorts,
                    :namedoperators, :arbitraryoperators,
                    :variabledecls,
                    :partitionsorts, :partitionops, :feconstants,
                    :usersorts)

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

"""
    declarations(dd::DeclDict) -> Iterator
Return an iterator over all the declaration dictionaries' values.
Flattens iterators: variabledecls, namedsorts, arbitrarysorts, partitionsorts, partitionops,
namedoperators, arbitrary_ops, feconstants, usersorts.
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
        values(usersorts(dd)),                               ])
end

has_variable(dd::DeclDict, id::Symbol)       = haskey(variabledecls(dd), id)
has_named_sort(dd::DeclDict, id::Symbol)     = haskey(namedsorts(dd), id)
has_arbitrary_sort(dd::DeclDict, id::Symbol) = haskey(arbitrarysorts(dd), id)
has_partitionsort(dd::DeclDict, id::Symbol)  = haskey(partitionsorts(dd), id)
has_named_op(dd::DeclDict, id::Symbol)       = haskey(namedoperators(dd), id)
has_arbitrary_op(dd::DeclDict, id::Symbol)   = haskey(arbitraryoperators(dd), id)
has_partitionop(dd::DeclDict, id::Symbol)    = haskey(partitionops(dd), id)
has_feconstant(dd::DeclDict, id::Symbol)     = haskey(feconstants(dd), id)

has_usersort(dd::DeclDict, id::Symbol)       = haskey(usersorts(dd), id)

variable(dd::DeclDict, id::Symbol)       = dd.variabledecls[id]
named_sort(dd::DeclDict, id::Symbol)     = dd.namedsorts[id]
arbitrary_sort(dd::DeclDict, id::Symbol) = dd.arbitrarysorts[id]
partitionsort(dd::DeclDict, id::Symbol)  = dd.partitionsorts[id]
named_op(dd::DeclDict, id::Symbol)       = dd.namedoperators[id]
arbitrary_op(dd::DeclDict, id::Symbol)   = dd.arbitraryoperators[id]
partitionop(dd::DeclDict, id::Symbol)    = dd.partitionops[id]
feconstant(dd::DeclDict, id::Symbol)     = dd.feconstants[id]

usersort(dd::DeclDict, id::Symbol)       = dd.usersorts[id]


#TODO
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
    fill_nonhl!(dd::DeclDict; ids::Tuple) -> nothing

Fill a DeclDict with values needed by non-high-level networks.

    NamedSort(:integer, "Integer", IntegerSort(); ids)
    NamedSort(:natural, "Natural", NaturalSort(); ids)
    NamedSort(:positive, "Positive", PositiveSort(); ids)
    NamedSort(:real, "Real", RealSort(); ids)
    NamedSort(:dot, "Dot", DotSort(); ids)

    UserSort(:integer; ids)
    UserSort(:natural; ids)
    UserSort(:positive; ids)
    UserSort(:real; ids)
    UserSort(:dot; ids)
"""
function fill_nonhl!(dd::DeclDict; ids::Tuple)
    for (tag, name, sort) in ((:integer, "Integer", IntegerSort()),
                              (:natural, "Natural", NaturalSort()),
                              (:positve, "Positive", PositiveSort()),
                              (:real, "Real", RealSort()),
                              (:dot, "Dot", DotSort()),
                              )

        if !haskey(dd.namedsorts, tag)
            dd.namedsorts[tag] = NamedSort(tag, name, sort; ids)
            !isregistered(PNML.idregistry[], tag) && register_id!(PNML.idregistry[], tag)
        end
        if !haskey(dd.usersorts, tag)
            dd.usersorts[tag] = UserSort(tag; ids)
            !isregistered(PNML.idregistry[], tag) && register_id!(PNML.idregistry[], tag)
        end
    end
end
